//
//  AccountListViewModel.swift
//  KamFinAssetTrack
//
//  Owns the state and business logic for the Account list screen.
//  View models are fully UI-free so they are cheap to unit test.
//
//  Responsibilities:
//  • Grouping accounts by AccountType
//  • Sorting by value descending within each group (ADR-007)
//  • Computing aggregate totals
//  • Soft-delete with 5-second undo (ADR-001)
//
//  NB: this VM does not import SwiftUI. Keep it that way.
//

import Foundation
import SwiftData

// MARK: - Sort strategy

/// Sort strategy for the account list. Sprint 1 ships with `typeGroupedValueDesc`
/// (the PRD default). More strategies land with Settings in v1.1.
enum AccountSort: String, CaseIterable, Sendable {
    case typeGroupedValueDesc
    case nameAsc
    case valueDesc
}

// MARK: - Grouping

/// A single section in the grouped list: one `AccountType` with its accounts.
struct AccountSection: Identifiable, Equatable {
    var id: AccountType { type }
    let type: AccountType
    let accounts: [Account]
    let subtotal: Decimal

    static func == (lhs: AccountSection, rhs: AccountSection) -> Bool {
        lhs.type == rhs.type
            && lhs.subtotal == rhs.subtotal
            && lhs.accounts.map(\.id) == rhs.accounts.map(\.id)
    }
}

// MARK: - Undo state

/// Represents an account that has been "soft-deleted" and may still be
/// restored within the undo window. Holdings are preserved on the object
/// itself — we simply reinsert into the context on undo.
struct PendingDeletion: Identifiable, Equatable {
    let id: UUID
    let accountName: String
    /// The detached Account object, ready to be reinserted if the user
    /// taps Undo before the timer expires.
    let detached: Account
    let scheduledAt: Date

    static func == (lhs: PendingDeletion, rhs: PendingDeletion) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - View model

@Observable
@MainActor
final class AccountListViewModel {

    // MARK: Inputs

    /// How long an undo toast stays visible. Default 5 seconds (ADR-001).
    var undoWindow: TimeInterval = 5.0

    /// Current sort strategy. Type-grouped, value-desc by default.
    var sort: AccountSort = .typeGroupedValueDesc

    // MARK: Outputs

    /// Non-nil while an undo is pending. Views observe this to show the toast.
    private(set) var pendingDeletion: PendingDeletion?

    // MARK: - Derived

    /// Group accounts into sections, respecting the chosen sort strategy.
    func sections(from accounts: [Account]) -> [AccountSection] {
        let active = accounts.filter { !$0.isArchived }

        switch sort {
        case .typeGroupedValueDesc:
            return typeGroupedSections(from: active)
        case .nameAsc:
            let sorted = active.sorted { lhs, rhs in
                lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            return [
                AccountSection(
                    type: .other,
                    accounts: sorted,
                    subtotal: sorted.reduce(Decimal(0)) { $0 + $1.totalValue }
                )
            ]
        case .valueDesc:
            let sorted = active.sorted { $0.totalValue > $1.totalValue }
            return [
                AccountSection(
                    type: .other,
                    accounts: sorted,
                    subtotal: sorted.reduce(Decimal(0)) { $0 + $1.totalValue }
                )
            ]
        }
    }

    private func typeGroupedSections(from accounts: [Account]) -> [AccountSection] {
        // Respect AccountType.allCases order (Property → ISA → Pension → …).
        var sections: [AccountSection] = []
        for type in AccountType.allCases {
            let members = accounts
                .filter { $0.type == type }
                .sorted { $0.totalValue > $1.totalValue }
            guard !members.isEmpty else { continue }
            let subtotal = members.reduce(Decimal(0)) { $0 + $1.totalValue }
            sections.append(AccountSection(type: type, accounts: members, subtotal: subtotal))
        }
        return sections
    }

    /// Total across all active (non-archived) accounts. Currency is expected
    /// to match the user's display currency. Sprint 1 assumes GBP-only totals
    /// for the summary card (FX conversion lands in Sprint 2 via KFAT-14).
    func total(from accounts: [Account]) -> Decimal {
        sections(from: accounts)
            .flatMap(\.accounts)
            .reduce(Decimal(0)) { $0 + $1.totalValue }
    }

    /// Count of non-archived accounts.
    func accountCount(from accounts: [Account]) -> Int {
        accounts.filter { !$0.isArchived }.count
    }

    // MARK: - Delete flow (ADR-001)

    /// Soft-delete an account. The account is removed from the context
    /// immediately (so it vanishes from the live @Query-driven list), but
    /// kept in memory via `pendingDeletion` so it can be restored if the
    /// user taps Undo within `undoWindow`.
    ///
    /// Holdings ride along with the detached object. Because SwiftData's
    /// cascade delete rule only triggers on a *persistent* delete, we avoid
    /// it here by detaching first.
    func requestDelete(_ account: Account, context: ModelContext) {
        // Capture a detached snapshot for restoration.
        let detached = Account(
            name: account.name,
            provider: account.provider,
            type: account.type,
            currency: account.currency,
            notes: account.notes,
            isArchived: account.isArchived
        )
        detached.id = account.id
        detached.createdAt = account.createdAt
        detached.updatedAt = Date()

        // Preserve holdings on the detached snapshot.
        for h in account.holdings {
            let copy = Holding(
                symbol: h.symbol,
                name: h.name,
                units: h.units,
                costBasis: h.costBasis,
                currentValue: h.currentValue,
                valueOverride: h.valueOverride,
                account: detached
            )
            copy.id = h.id
            copy.createdAt = h.createdAt
            copy.lastUpdated = h.lastUpdated
            detached.holdings.append(copy)
        }

        context.delete(account)
        try? context.save()

        pendingDeletion = PendingDeletion(
            id: detached.id,
            accountName: detached.name,
            detached: detached,
            scheduledAt: Date()
        )
    }

    /// Restore the pending deletion if still within the undo window.
    /// Returns true if restoration actually happened.
    @discardableResult
    func undoDeletion(context: ModelContext) -> Bool {
        guard let pending = pendingDeletion else { return false }
        pendingDeletion = nil

        context.insert(pending.detached)
        for h in pending.detached.holdings {
            context.insert(h)
        }
        try? context.save()
        return true
    }

    /// Called by the toast when its timer completes. Clears the pending
    /// deletion without restoring, making the delete permanent.
    func finalizeDeletion() {
        pendingDeletion = nil
    }
}
