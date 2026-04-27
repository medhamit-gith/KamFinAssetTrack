//
//  Provider.swift
//  KamFinAssetTrack
//
//  Created by the Kamat Product Development Studio.
//  Sprint 1 · KFAT-11 — Provider catalogue
//

import Foundation

/// A `Provider` is a financial institution or platform that holds one or
/// more of Baks's accounts (e.g. "Hargreaves Lansdown", "Bank of America").
///
/// Providers are not `@Model` entities because the seed list is static.
/// User-entered providers are stored as plain strings on `Account.provider`.
struct Provider: Identifiable, Hashable, Codable, Sendable {

    /// Stable slug used in storage and for equality checks.
    let id: String

    /// Display name shown in the picker.
    let name: String

    /// Country code — "UK", "IN", or "GLOBAL".
    let country: String

    /// Which account types this provider commonly services. Used to filter
    /// the provider picker when creating a specific account type.
    let categories: [AccountType]

    /// `true` sentinel for the special "Custom" entry that opens a free-text
    /// input dialog instead of selecting a seeded provider.
    let isCustom: Bool

    init(
        id: String,
        name: String,
        country: String,
        categories: [AccountType],
        isCustom: Bool = false
    ) {
        self.id = id
        self.name = name
        self.country = country
        self.categories = categories
        self.isCustom = isCustom
    }
}

/// Seed data for the provider picker. Curated from Baks's actual real-world
/// providers captured in the kamat-financial-advisor skill portfolio-data.md.
///
/// To add a new provider:
/// 1. Append to `seed` (stable slug — don't rename slugs of existing entries)
/// 2. Pick an appropriate `categories` list
/// 3. Add a unit test asserting the provider appears in `matching(type:)`
enum ProviderCatalog {

    static let seed: [Provider] = [
        Provider(
            id: "hargreaves-lansdown",
            name: "Hargreaves Lansdown",
            country: "UK",
            categories: [.isa, .pension]
        ),
        Provider(
            id: "fidelity",
            name: "Fidelity",
            country: "UK",
            categories: [.isa, .pension]
        ),
        Provider(
            id: "standard-life",
            name: "Standard Life",
            country: "UK",
            categories: [.pension]
        ),
        Provider(
            id: "jpmorgan-pension",
            name: "JPMorgan Pension",
            country: "UK",
            categories: [.pension]
        ),
        Provider(
            id: "bank-of-america",
            name: "Bank of America",
            country: "UK",
            categories: [.cash, .pension]
        ),
        Provider(
            id: "tsb",
            name: "TSB",
            country: "UK",
            categories: [.cash, .debt]
        ),
        Provider(
            id: "black-horse-finance",
            name: "Black Horse Finance",
            country: "UK",
            categories: [.debt]
        ),
        Provider(
            id: "barclaycard",
            name: "Barclaycard",
            country: "UK",
            categories: [.debt]
        ),
        Provider(
            id: "lic-india",
            name: "LIC (India)",
            country: "IN",
            categories: [.pension]
        ),
        Provider(
            id: "coingecko-wallet",
            name: "CoinGecko Wallet",
            country: "GLOBAL",
            categories: [.crypto]
        ),
        Provider(
            id: "custom",
            name: "Custom",
            country: "GLOBAL",
            categories: AccountType.allCases,
            isCustom: true
        )
    ]

    // MARK: - Queries

    /// Providers that service a given account type, with the "Custom" entry
    /// always surfaced last.
    static func matching(type: AccountType) -> [Provider] {
        let filtered = seed.filter { provider in
            provider.isCustom || provider.categories.contains(type)
        }
        // Ensure "Custom" is always at the bottom of the list.
        return filtered.sorted { lhs, rhs in
            if lhs.isCustom { return false }
            if rhs.isCustom { return true }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    /// Fuzzy-ish search on name and country. Case-insensitive substring match.
    static func search(_ query: String, type: AccountType? = nil) -> [Provider] {
        let pool = type.map { matching(type: $0) } ?? seed
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return pool }
        return pool.filter { provider in
            provider.isCustom ||
            provider.name.localizedCaseInsensitiveContains(trimmed) ||
            provider.country.localizedCaseInsensitiveContains(trimmed)
        }
    }

    /// Look up a provider by its stable slug.
    static func provider(withID id: String) -> Provider? {
        seed.first { $0.id == id }
    }

    /// True when a user-entered custom name case-insensitively matches a
    /// seeded provider. Used by the "already exists" warning on custom entry.
    static func hasSeededMatch(for rawName: String) -> Provider? {
        let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return seed.first { provider in
            !provider.isCustom &&
            provider.name.compare(trimmed, options: .caseInsensitive) == .orderedSame
        }
    }
}
