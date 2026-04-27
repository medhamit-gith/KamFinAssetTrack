//
//  Account.swift
//  KamFinAssetTrack
//
//  Created by the Kamat Product Development Studio.
//  Sprint 1 · KFAT-7 — SwiftData schema
//

import Foundation
import SwiftData

/// An `Account` is a container for one or more `Holding`s and represents a
/// real-world place where money lives — an ISA, a pension scheme, a property,
/// a crypto wallet, a debt.
///
/// **CloudKit-compatibility**: every property is either optional or has a
/// default value so the store is drop-in sync-ready when KFAT-23 arrives in
/// Sprint 3. Do not add non-optional properties without a default.
///
/// **Cascade semantics**: deleting an Account deletes all its Holdings via
/// `@Relationship(deleteRule: .cascade, inverse: \Holding.account)`.
@Model
final class Account {

    // MARK: - Identity

    /// Stable UUID used as a sync-safe primary key.
    @Attribute(.unique) var id: UUID = UUID()

    // MARK: - Core fields

    /// User-visible account name (e.g. "HL Stocks & Shares ISA").
    var name: String = ""

    /// Provider display string (e.g. "Hargreaves Lansdown").
    /// See `ProviderCatalog` for the seeded list.
    var provider: String = "Manual"

    /// Raw storage for `AccountType`. Use the `type` computed property to read.
    /// Kept as `String` rather than enum to keep SwiftData + CloudKit happy.
    var typeRaw: String = AccountType.other.rawValue

    /// Raw storage for `Currency`. Use the `currency` computed property.
    var currencyRaw: String = Currency.default.rawValue

    // MARK: - Metadata

    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var isArchived: Bool = false
    var notes: String? = nil

    // MARK: - Relationships

    @Relationship(deleteRule: .cascade, inverse: \Holding.account)
    var holdings: [Holding] = []

    // MARK: - Initialisation

    init(
        name: String,
        provider: String,
        type: AccountType,
        currency: Currency = .default,
        notes: String? = nil,
        isArchived: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.provider = provider
        self.typeRaw = type.rawValue
        self.currencyRaw = currency.rawValue
        self.notes = notes
        self.isArchived = isArchived
        self.createdAt = Date()
        self.updatedAt = Date()
        self.holdings = []
    }

    // MARK: - Computed

    /// Strongly-typed account type. Falls back to `.other` on malformed data.
    var type: AccountType {
        AccountType(rawValue: typeRaw) ?? .other
    }

    /// Strongly-typed currency. Falls back to `.gbp` on malformed data.
    var currency: Currency {
        Currency(rawValue: currencyRaw) ?? .default
    }

    /// Sum of all holding current values. Does not apply FX conversion —
    /// that is the dashboard's job (Sprint 3).
    var totalValue: Decimal {
        holdings.reduce(Decimal(0)) { $0 + $1.currentValue }
    }

    /// Number of holdings within this account.
    var holdingCount: Int {
        holdings.count
    }
}
