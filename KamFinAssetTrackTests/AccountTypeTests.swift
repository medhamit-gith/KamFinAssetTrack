//
//  AccountTypeTests.swift
//  KamFinAssetTrackTests
//
//  Swift Testing suite for KFAT-10 — AccountType taxonomy.
//

import Foundation
import Testing
@testable import KamFinAssetTrack

@Suite("KFAT-10 · AccountType Taxonomy")
struct AccountTypeTests {

    // MARK: - AC-1: Every case has display metadata

    @Test("AC-1: All cases have non-empty display metadata",
          arguments: AccountType.allCases)
    func metadataIsNonEmpty(type: AccountType) {
        #expect(!type.displayName.isEmpty)
        #expect(!type.pluralName.isEmpty)
        #expect(!type.iconName.isEmpty)
        #expect(!type.accentHex.isEmpty)
    }

    // MARK: - AC-2: Icons are valid SF Symbol names

    @Test("AC-2: Icon names follow the SF Symbol naming convention",
          arguments: AccountType.allCases)
    func iconNamesAreWellFormed(type: AccountType) {
        let icon = type.iconName
        // SF Symbols use lowercase letters, digits, and dots only.
        let allowed = CharacterSet.lowercaseLetters
            .union(.decimalDigits)
            .union(CharacterSet(charactersIn: "."))
        #expect(icon.unicodeScalars.allSatisfy { allowed.contains($0) },
                "Icon '\(icon)' contains invalid characters for SF Symbol names")
    }

    // MARK: - AC-3: Hex colours are well-formed

    @Test("AC-3: Accent hex values are 7 characters starting with #",
          arguments: AccountType.allCases)
    func accentHexIsWellFormed(type: AccountType) {
        let hex = type.accentHex
        #expect(hex.count == 7)
        #expect(hex.hasPrefix("#"))
        let body = String(hex.dropFirst())
        #expect(body.allSatisfy { $0.isHexDigit })
    }

    // MARK: - AC-4: CaseIterable order drives UI grouping

    @Test("AC-4: Preferred display order matches design spec")
    func caseIterableOrderMatchesDesign() {
        // Property → ISA → Pension → Crypto → Cash → Debt → Avios → Other
        let expected: [AccountType] = [
            .property, .isa, .pension, .crypto, .cash, .debt, .avios, .other
        ]
        #expect(AccountType.allCases == expected)
    }

    // MARK: - Form behaviour matrix

    @Test("Form behaviour: ISA requires symbol and units")
    func isaFormRequirements() {
        #expect(AccountType.isa.requiresSymbol)
        #expect(AccountType.isa.requiresUnits)
        #expect(AccountType.isa.unitsDecimalPlaces == 4)
    }

    @Test("Form behaviour: Property does not require symbol or units")
    func propertyFormRequirements() {
        #expect(!AccountType.property.requiresSymbol)
        #expect(!AccountType.property.requiresUnits)
    }

    @Test("Form behaviour: Crypto needs 8-decimal units")
    func cryptoPrecision() {
        #expect(AccountType.crypto.requiresSymbol)
        #expect(AccountType.crypto.requiresUnits)
        #expect(AccountType.crypto.unitsDecimalPlaces == 8)
    }

    @Test("Form behaviour: Avios stores integer units")
    func aviosIntegerUnits() {
        #expect(AccountType.avios.requiresUnits)
        #expect(!AccountType.avios.requiresSymbol)
        #expect(AccountType.avios.unitsDecimalPlaces == 0)
    }

    // MARK: - EC-2: Unknown raw values fall back to .other

    @Test("EC-2: Malformed raw values fall back to .other")
    func malformedRawValueFallsBack() {
        #expect(AccountType(rawValue: "nonsense") == nil)
        // The Account model's computed property handles the fallback.
        let account = Account(name: "Test", provider: "X", type: .cash)
        account.typeRaw = "gibberish"
        #expect(account.type == .other)
    }
}
