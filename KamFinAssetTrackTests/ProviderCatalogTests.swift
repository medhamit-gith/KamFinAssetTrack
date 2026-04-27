//
//  ProviderCatalogTests.swift
//  KamFinAssetTrackTests
//
//  Swift Testing suite for KFAT-11 — Provider catalogue.
//

import Foundation
import Testing
@testable import KamFinAssetTrack

@Suite("KFAT-11 · Provider Catalogue")
struct ProviderCatalogTests {

    // MARK: - AC-1: Seed catalogue contents

    @Test("AC-1: Seed catalogue contains all expected providers")
    func seedContainsExpectedProviders() {
        let ids = Set(ProviderCatalog.seed.map { $0.id })
        let expected: Set<String> = [
            "hargreaves-lansdown",
            "fidelity",
            "standard-life",
            "jpmorgan-pension",
            "bank-of-america",
            "tsb",
            "black-horse-finance",
            "barclaycard",
            "lic-india",
            "coingecko-wallet",
            "custom"
        ]
        #expect(ids == expected)
    }

    @Test("AC-1: Exactly one custom provider exists")
    func onlyOneCustom() {
        let customs = ProviderCatalog.seed.filter { $0.isCustom }
        #expect(customs.count == 1)
        #expect(customs.first?.id == "custom")
    }

    @Test("AC-1: Provider IDs are all unique")
    func idsAreUnique() {
        let ids = ProviderCatalog.seed.map { $0.id }
        #expect(Set(ids).count == ids.count)
    }

    // MARK: - AC-2: Search

    @Test("AC-2: Substring search for 'Har' surfaces Hargreaves Lansdown")
    func searchByPrefix() {
        let results = ProviderCatalog.search("Har")
        #expect(results.contains { $0.id == "hargreaves-lansdown" })
    }

    @Test("AC-2: Search is case-insensitive")
    func searchCaseInsensitive() {
        let upper = ProviderCatalog.search("BARCLAY")
        let lower = ProviderCatalog.search("barclay")
        #expect(upper.map(\.id) == lower.map(\.id))
        #expect(upper.contains { $0.id == "barclaycard" })
    }

    @Test("AC-2: Empty query returns the full filtered list")
    func emptyQueryReturnsAll() {
        let all = ProviderCatalog.search("")
        #expect(all.count == ProviderCatalog.seed.count)
    }

    @Test("AC-2: Search can be scoped to a specific account type")
    func searchScopedToType() {
        let isaResults = ProviderCatalog.search("", type: .isa)
        // HL and Fidelity serve ISAs; Black Horse does not.
        #expect(isaResults.contains { $0.id == "hargreaves-lansdown" })
        #expect(isaResults.contains { $0.id == "fidelity" })
        #expect(!isaResults.contains { $0.id == "black-horse-finance" })
    }

    // MARK: - AC-4: Duplicate detection

    @Test("AC-4: Custom name matching a seed provider is detected")
    func detectsDuplicateCaseInsensitive() {
        let match = ProviderCatalog.hasSeededMatch(for: "hargreaves lansdown")
        #expect(match?.id == "hargreaves-lansdown")
    }

    @Test("AC-4: Whitespace is trimmed during duplicate detection")
    func duplicateDetectionTrimsWhitespace() {
        let match = ProviderCatalog.hasSeededMatch(for: "   Fidelity   ")
        #expect(match?.id == "fidelity")
    }

    @Test("AC-4: Non-matching name returns nil")
    func nonMatchReturnsNil() {
        #expect(ProviderCatalog.hasSeededMatch(for: "Nationwide") == nil)
    }

    @Test("AC-4: Empty string returns nil (no false positive)")
    func emptyStringReturnsNil() {
        #expect(ProviderCatalog.hasSeededMatch(for: "") == nil)
        #expect(ProviderCatalog.hasSeededMatch(for: "   ") == nil)
    }

    // MARK: - Matching by type

    @Test("matching(type: .crypto) surfaces CoinGecko Wallet and Custom only")
    func cryptoMatching() {
        let cryptoProviders = ProviderCatalog.matching(type: .crypto)
        let ids = cryptoProviders.map(\.id)
        #expect(ids.contains("coingecko-wallet"))
        #expect(ids.contains("custom"))
        // Nothing else offers crypto in the seed list.
        #expect(ids.count == 2)
    }

    @Test("matching(type:) always places Custom at the end")
    func customIsLast() {
        for type in AccountType.allCases {
            let providers = ProviderCatalog.matching(type: type)
            if providers.count > 1 {
                #expect(providers.last?.isCustom == true,
                        "Custom should be last for type \(type)")
            }
        }
    }

    // MARK: - Provider lookup

    @Test("provider(withID:) resolves known slugs")
    func lookupByID() {
        let hl = ProviderCatalog.provider(withID: "hargreaves-lansdown")
        #expect(hl?.name == "Hargreaves Lansdown")
    }

    @Test("provider(withID:) returns nil for unknown slugs")
    func lookupUnknownID() {
        #expect(ProviderCatalog.provider(withID: "definitely-not-real") == nil)
    }
}
