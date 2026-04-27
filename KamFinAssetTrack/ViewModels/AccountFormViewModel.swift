//
//  AccountFormViewModel.swift
//  KamFinAssetTrack
//
//  Owns the state and validation for the Account create/edit form.
//  UI-free so it is cheap to unit test.
//
//  Responsibilities:
//  • Hold form field state (name, provider, type, currency, notes)
//  • Validate per NFR-V1..V5 from Scope Package
//  • Save to SwiftData (create or update)
//  • Type-change warning detection (AC-7 from Scope)
//  • Codable conformance for @SceneStorage draft persistence (AC-8)
//

import Foundation
import SwiftData

// MARK: - Mode

/// Form mode: creating a fresh account, or editing an existing one.
enum AccountFormMode: Equatable {
    case create
    case edit(accountID: UUID)
}

// MARK: - Validation errors

enum AccountFormValidation: Error, Equatable {
    case nameEmpty
    case nameTooLong
    case providerEmpty
}

// MARK: - Draft (for @SceneStorage persistence)

/// Serialisable snapshot of a form in progress. Stored in @SceneStorage
/// so that backgrounding the app preserves the user's in-progress entry.
struct AccountFormDraft: Codable, Equatable {
    var name: String = ""
    var provider: String = "Manual"
    var typeRaw: String = AccountType.other.rawValue
    var currencyRaw: String = Currency.default.rawValue
    var notes: String = ""
    var modeAccountID: UUID? = nil
}

// MARK: - View model

@Observable
@MainActor
final class AccountFormViewModel {

    // MARK: Mode

    let mode: AccountFormMode

    // MARK: Fields

    var name: String = ""
    var provider: String = "Manual"
    var type: AccountType = .other
    var currency: Currency = .default
    var notes: String = ""

    // MARK: State

    /// Set when the user changes the type of an account that already has
    /// holdings — we surface a confirmation dialog (AC-7).
    var pendingTypeChange: AccountType?

    /// The original type at the time of editing; used to detect a change.
    private var originalType: AccountType?

    /// The account being edited, or nil in `.create` mode.
    private var editing: Account?

    // MARK: Init

    init(mode: AccountFormMode, account: Account? = nil) {
        self.mode = mode
        if case .edit = mode, let account {
            self.editing = account
            self.originalType = account.type
            self.name = account.name
            self.provider = account.provider
            self.type = account.type
            self.currency = account.currency
            self.notes = account.notes ?? ""
        }
    }

    // MARK: - Draft persistence

    /// Snapshot the current form as a draft for @SceneStorage.
    func snapshot() -> AccountFormDraft {
        AccountFormDraft(
            name: name,
            provider: provider,
            typeRaw: type.rawValue,
            currencyRaw: currency.rawValue,
            notes: notes,
            modeAccountID: editing?.id
        )
    }

    /// Apply a persisted draft. Only used in `.create` mode — drafts for
    /// edits are discarded because the canonical source is SwiftData.
    func applyDraft(_ draft: AccountFormDraft) {
        guard case .create = mode else { return }
        self.name = draft.name
        self.provider = draft.provider
        self.type = AccountType(rawValue: draft.typeRaw) ?? .other
        self.currency = Currency(rawValue: draft.currencyRaw) ?? .default
        self.notes = draft.notes
    }

    // MARK: - Validation

    /// Validate the current form. Returns `nil` if valid, else the first
    /// error (order: name → provider). Name is trimmed in place.
    func validate() -> AccountFormValidation? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return .nameEmpty }
        if trimmed.count > 200 { return .nameTooLong }
        let trimmedProvider = provider.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedProvider.isEmpty { return .providerEmpty }
        return nil
    }

    /// Convenience: is the form currently valid?
    var isValid: Bool { validate() == nil }

    // MARK: - Type-change warning (AC-7)

    /// Detect a type change that affects existing holdings. Returns
    /// `true` if the user should be shown a confirmation before saving.
    func shouldWarnOnTypeChange() -> Bool {
        guard case .edit = mode,
              let editing,
              let originalType,
              originalType != type,
              !editing.holdings.isEmpty
        else { return false }
        return true
    }

    // MARK: - Save

    /// Persist the form to the model context. Caller is responsible for
    /// having checked `shouldWarnOnTypeChange()` and optionally confirming
    /// with the user first.
    @discardableResult
    func save(into context: ModelContext) throws -> Account {
        if let error = validate() { throw error }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedProvider = provider.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        switch mode {
        case .create:
            let account = Account(
                name: trimmedName,
                provider: trimmedProvider,
                type: type,
                currency: currency,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes
            )
            context.insert(account)
            try context.save()
            return account

        case .edit:
            guard let editing else {
                // Defensive — `.edit` mode without an account is a programmer error.
                throw AccountFormValidation.nameEmpty
            }
            editing.name = trimmedName
            editing.provider = trimmedProvider
            editing.typeRaw = type.rawValue
            editing.currencyRaw = currency.rawValue
            editing.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
            editing.updatedAt = Date()
            try context.save()
            return editing
        }
    }
}
