//
//  AccountListViewModelTests.swift
//  KamFinAssetTrackTests
//
//  Swift Testing suite for the AccountListViewModel. Covers grouping,
//  sorting, aggregation, and the soft-delete + undo flow (ADR-001).
//

import Foundation
import SwiftData
import Testing
@testable import KamFinAssetTrack

@MainActor
@Suite("KFAT-8 · AccountListViewModel")
struct AccountListViewModelTests {

    // MARK: - Helpers

    private func freshContext() throws -> ModelContext {
        let container = try KFATModelContainer.inMemory()
        return ModelContext(container)
    }

    @discardableResult
    private func seedAccount(
        _ ctx: ModelContext,
        name: String,
        type: AccountType,
        holdingValues: [Decimal] = [],
        isArchived: Bool = false
    ) -> Account {
        let account = Account(name: name, provider: "Test", type: type, isArchived: isArchived)
        ctx.insert(account)
        for (i, v) in holdingValues.enumerated() {
            let h = Holding(name: "h\(i)", currentValue: v, account: account)
            ctx.insert(h)
        }
        return account
    }

    // MARK: - Grouping

    @Test("Type-grouped sort groups by AccountType and respects display order")
    func typeGroupedOrder() throws {
        let ctx = try freshContext()
        seedAccount(ctx, name: "Cash1", type: .cash, holdingValues: [1_000])
        seedAccount(ctx, name: "ISA1", type: .isa, holdingValues: [50_000])
        seedAccount(ctx, name: "Property1", type: .property, holdingValues: [400_000])
        try ctx.save()

        let vm = AccountListViewModel()
        vm.sort = .typeGroupedValueDesc

        let all = try ctx.fetch(FetchDescriptor<Account>())
        let sections = vm.sections(from: all)
        #expect(sections.count == 3)
        // Property first, then ISA, then Cash — matching AccountType.allCases order.
        #expect(sections.map(\.type) == [.property, .isa, .cash])
    }

    @Test("Within a type group, accounts sort by value descending")
    func valueDescWithinGroup() throws {
        let ctx = try freshContext()
        seedAccount(ctx, name: "Small", type: .isa, holdingValues: [5_000])
        seedAccount(ctx, name: "Big", type: .isa, holdingValues: [100_000])
        seedAccount(ctx, name: "Medium", type: .isa, holdingValues: [25_000])
        try ctx.save()

        let vm = AccountListViewModel()
        let sections = vm.sections(from: try ctx.fetch(FetchDescriptor<Account>()))
        let isaSection = sections.first { $0.type == .isa }
        #expect(isaSection?.accounts.map(\.name) == ["Big", "Medium", "Small"])
    }

    @Test("Archived accounts are excluded from sections and totals")
    func archivedExcluded() throws {
        let ctx = try freshContext()
        seedAccount(ctx, name: "Active", type: .cash, holdingValues: [1_000])
        seedAccount(ctx, name: "Archived", type: .cash, holdingValues: [999_999], isArchived: true)
        try ctx.save()

        let vm = AccountListViewModel()
        let all = try ctx.fetch(FetchDescriptor<Account>())
        #expect(vm.total(from: all) == 1_000)
        #expect(vm.accountCount(from: all) == 1)
        let sections = vm.sections(from: all)
        #expect(sections.flatMap(\.accounts).map(\.name) == ["Active"])
    }

    // MARK: - Aggregation

    @Test("Section subtotals equal the sum of holdings within that type")
    func subtotalsSum() throws {
        let ctx = try freshContext()
        seedAccount(ctx, name: "A", type: .isa, holdingValues: [10_000, 15_000])
        seedAccount(ctx, name: "B", type: .isa, holdingValues: [25_000])
        try ctx.save()

        let vm = AccountListViewModel()
        let sections = vm.sections(from: try ctx.fetch(FetchDescriptor<Account>()))
        #expect(sections.first?.subtotal == 50_000)
    }

    @Test("Alternate sort strategies return a single section")
    func alternateSortStrategies() throws {
        let ctx = try freshContext()
        seedAccount(ctx, name: "B", type: .isa, holdingValues: [10])
        seedAccount(ctx, name: "A", type: .cash, holdingValues: [5])
        try ctx.save()

        let vm = AccountListViewModel()
        vm.sort = .nameAsc
        let nameAscSections = vm.sections(from: try ctx.fetch(FetchDescriptor<Account>()))
        #expect(nameAscSections.count == 1)
        #expect(nameAscSections.first?.accounts.map(\.name) == ["A", "B"])

        vm.sort = .valueDesc
        let valueDescSections = vm.sections(from: try ctx.fetch(FetchDescriptor<Account>()))
        #expect(valueDescSections.first?.accounts.map(\.name) == ["B", "A"])
    }

    // MARK: - Delete + Undo

    @Test("requestDelete removes the account and records a pending deletion")
    func deleteCreatesPending() throws {
        let ctx = try freshContext()
        let acc = seedAccount(ctx, name: "DeleteMe", type: .cash, holdingValues: [1_000])
        try ctx.save()

        let vm = AccountListViewModel()
        vm.requestDelete(acc, context: ctx)

        let remaining = try ctx.fetch(FetchDescriptor<Account>())
        #expect(remaining.isEmpty)
        #expect(vm.pendingDeletion?.accountName == "DeleteMe")
    }

    @Test("undoDeletion restores the account with its holdings intact")
    func undoRestoresAccount() throws {
        let ctx = try freshContext()
        let acc = seedAccount(ctx, name: "Restoreable", type: .isa, holdingValues: [100, 200, 300])
        try ctx.save()

        let vm = AccountListViewModel()
        vm.requestDelete(acc, context: ctx)
        #expect(vm.pendingDeletion != nil)

        let success = vm.undoDeletion(context: ctx)
        #expect(success)
        #expect(vm.pendingDeletion == nil)

        let restored = try ctx.fetch(FetchDescriptor<Account>())
        #expect(restored.count == 1)
        #expect(restored.first?.name == "Restoreable")
        #expect(restored.first?.holdings.count == 3)
        #expect(restored.first?.totalValue == 600)
    }

    @Test("finalizeDeletion clears pending without restoring")
    func finalizeMakesDeletePermanent() throws {
        let ctx = try freshContext()
        let acc = seedAccount(ctx, name: "Gone", type: .cash, holdingValues: [1])
        try ctx.save()

        let vm = AccountListViewModel()
        vm.requestDelete(acc, context: ctx)
        vm.finalizeDeletion()

        #expect(vm.pendingDeletion == nil)
        #expect(try ctx.fetch(FetchDescriptor<Account>()).isEmpty)
    }

    @Test("undoDeletion with no pending returns false")
    func undoWithoutPendingNoops() throws {
        let ctx = try freshContext()
        let vm = AccountListViewModel()
        #expect(vm.undoDeletion(context: ctx) == false)
    }

    // MARK: - Edge cases

    @Test("Total across empty list is zero")
    func emptyTotalIsZero() {
        let vm = AccountListViewModel()
        #expect(vm.total(from: []) == 0)
        #expect(vm.accountCount(from: []) == 0)
        #expect(vm.sections(from: []).isEmpty)
    }
}
