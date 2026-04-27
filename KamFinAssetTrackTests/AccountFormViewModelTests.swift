//
//  AccountFormViewModelTests.swift
//  KamFinAssetTrackTests
//
//  Swift Testing suite for AccountFormViewModel. Covers:
//  • Validation rules (NFR-V1..V5)
//  • Create flow
//  • Edit flow
//  • Type-change warning (AC-7)
//  • Draft persistence round-trip (AC-8)
//

import Foundation
import SwiftData
import Testing
@testable import KamFinAssetTrack

@MainActor
@Suite("KFAT-8 · AccountFormViewModel")
struct AccountFormViewModelTests {

    private func freshContext() throws -> ModelContext {
        let container = try KFATModelContainer.inMemory()
        return ModelContext(container)
    }

    // MARK: - Validation

    @Test("Empty name fails validation")
    func emptyNameFails() {
        let vm = AccountFormViewModel(mode: .create)
        vm.name = "   "   // whitespace-only
        vm.provider = "Hargreaves Lansdown"
        #expect(vm.validate() == .nameEmpty)
        #expect(!vm.isValid)
    }

    @Test("Overlong name fails validation")
    func overlongNameFails() {
        let vm = AccountFormViewModel(mode: .create)
        vm.name = String(repeating: "a", count: 201)
        vm.provider = "Fidelity"
        #expect(vm.validate() == .nameTooLong)
    }

    @Test("Empty provider fails validation")
    func emptyProviderFails() {
        let vm = AccountFormViewModel(mode: .create)
        vm.name = "Valid Name"
        vm.provider = ""
        #expect(vm.validate() == .providerEmpty)
    }

    @Test("Well-formed form is valid")
    func validForm() {
        let vm = AccountFormViewModel(mode: .create)
        vm.name = "HL ISA"
        vm.provider = "Hargreaves Lansdown"
        vm.type = .isa
        vm.currency = .gbp
        #expect(vm.validate() == nil)
        #expect(vm.isValid)
    }

    // MARK: - Create

    @Test("Save in create mode inserts a new Account with trimmed fields")
    func createSaves() throws {
        let ctx = try freshContext()
        let vm = AccountFormViewModel(mode: .create)
        vm.name = "  HL ISA  "
        vm.provider = "  Hargreaves Lansdown "
        vm.type = .isa
        vm.currency = .gbp
        vm.notes = "  long-term  "

        let account = try vm.save(into: ctx)
        #expect(account.name == "HL ISA")
        #expect(account.provider == "Hargreaves Lansdown")
        #expect(account.notes == "long-term")
        #expect(account.type == .isa)
        #expect(account.currency == .gbp)

        let fetched = try ctx.fetch(FetchDescriptor<Account>())
        #expect(fetched.count == 1)
    }

    @Test("Whitespace-only notes persist as nil")
    func whitespaceNotesBecomeNil() throws {
        let ctx = try freshContext()
        let vm = AccountFormViewModel(mode: .create)
        vm.name = "Name"
        vm.provider = "Provider"
        vm.notes = "    "
        let account = try vm.save(into: ctx)
        #expect(account.notes == nil)
    }

    @Test("Save throws when validation fails")
    func saveThrowsOnInvalid() throws {
        let ctx = try freshContext()
        let vm = AccountFormViewModel(mode: .create)
        vm.name = ""
        vm.provider = "Provider"
        #expect(throws: AccountFormValidation.self) {
            _ = try vm.save(into: ctx)
        }
    }

    // MARK: - Edit

    @Test("Save in edit mode updates the existing account")
    func editUpdatesExisting() async throws {
        let ctx = try freshContext()
        let existing = Account(name: "Old Name", provider: "Old Provider", type: .cash, currency: .gbp)
        ctx.insert(existing)
        try ctx.save()
        let originalUpdatedAt = existing.updatedAt
        try await Task.sleep(nanoseconds: 50_000_000)   // so updatedAt changes visibly

        let vm = AccountFormViewModel(mode: .edit(accountID: existing.id), account: existing)
        vm.name = "New Name"
        vm.provider = "New Provider"

        _ = try vm.save(into: ctx)
        #expect(existing.name == "New Name")
        #expect(existing.provider == "New Provider")
        #expect(existing.updatedAt > originalUpdatedAt)

        // Exactly one account — no duplicate inserted.
        #expect(try ctx.fetch(FetchDescriptor<Account>()).count == 1)
    }

    // MARK: - Type-change warning (AC-7)

    @Test("shouldWarnOnTypeChange is false in create mode")
    func noWarnInCreateMode() {
        let vm = AccountFormViewModel(mode: .create)
        vm.type = .property
        #expect(!vm.shouldWarnOnTypeChange())
    }

    @Test("shouldWarnOnTypeChange is false when no holdings exist")
    func noWarnWithoutHoldings() {
        let existing = Account(name: "X", provider: "Y", type: .isa)
        let vm = AccountFormViewModel(mode: .edit(accountID: existing.id), account: existing)
        vm.type = .property   // change
        #expect(!vm.shouldWarnOnTypeChange())
    }

    @Test("shouldWarnOnTypeChange is true when editing an account-with-holdings' type")
    func warnsWhenTypeChangesWithHoldings() throws {
        let ctx = try freshContext()
        let existing = Account(name: "X", provider: "Y", type: .isa)
        ctx.insert(existing)
        _ = Holding(symbol: "VWRL", name: "Vanguard", currentValue: 100, account: existing)
        try ctx.save()

        let vm = AccountFormViewModel(mode: .edit(accountID: existing.id), account: existing)
        vm.type = .property
        #expect(vm.shouldWarnOnTypeChange())
    }

    @Test("shouldWarnOnTypeChange is false when type is unchanged, even with holdings")
    func noWarnWhenTypeUnchanged() throws {
        let ctx = try freshContext()
        let existing = Account(name: "X", provider: "Y", type: .isa)
        ctx.insert(existing)
        _ = Holding(name: "H", currentValue: 1, account: existing)
        try ctx.save()

        let vm = AccountFormViewModel(mode: .edit(accountID: existing.id), account: existing)
        // Don't change type.
        #expect(!vm.shouldWarnOnTypeChange())
    }

    // MARK: - Draft persistence (AC-8)

    @Test("snapshot and applyDraft round-trip preserves fields")
    func draftRoundTrip() {
        let vm = AccountFormViewModel(mode: .create)
        vm.name = "Draft Name"
        vm.provider = "Draft Provider"
        vm.type = .crypto
        vm.currency = .usd
        vm.notes = "Draft notes"

        let draft = vm.snapshot()
        let encoded = try! JSONEncoder().encode(draft)
        let decoded = try! JSONDecoder().decode(AccountFormDraft.self, from: encoded)

        let restoredVM = AccountFormViewModel(mode: .create)
        restoredVM.applyDraft(decoded)
        #expect(restoredVM.name == "Draft Name")
        #expect(restoredVM.provider == "Draft Provider")
        #expect(restoredVM.type == .crypto)
        #expect(restoredVM.currency == .usd)
        #expect(restoredVM.notes == "Draft notes")
    }

    @Test("applyDraft is a no-op in edit mode")
    func draftIgnoredInEdit() {
        let existing = Account(name: "Original", provider: "OrigProv", type: .isa)
        let vm = AccountFormViewModel(mode: .edit(accountID: existing.id), account: existing)

        let hostileDraft = AccountFormDraft(
            name: "Should Not Apply",
            provider: "Nope",
            typeRaw: AccountType.crypto.rawValue,
            currencyRaw: Currency.usd.rawValue,
            notes: "nope"
        )
        vm.applyDraft(hostileDraft)

        #expect(vm.name == "Original")
        #expect(vm.provider == "OrigProv")
    }

    @Test("applyDraft handles malformed raw values gracefully")
    func draftMalformedFallsBack() {
        let vm = AccountFormViewModel(mode: .create)
        let malformed = AccountFormDraft(
            name: "N",
            provider: "P",
            typeRaw: "nonsense",
            currencyRaw: "ZZZ"
        )
        vm.applyDraft(malformed)
        #expect(vm.type == .other)
        #expect(vm.currency == .gbp)
    }
}
