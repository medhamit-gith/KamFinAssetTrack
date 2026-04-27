//
//  Holding.swift
//  KamFinAssetTrack
//
//  Created by the Kamat Product Development Studio.
//  Sprint 1 · KFAT-7 — SwiftData schema
//

import Foundation
import SwiftData

/// A `Holding` is a single position within an `Account` — e.g. "VWRL" in an
/// ISA, "8A Bridle Road" in a property account, "ETH" in a crypto wallet.
///
/// The `valueOverride` flag protects manually-entered values from being
/// overwritten by the price refresh pipeline (Sprint 2).
///
/// **Monetary precision**: `Decimal` throughout. Never `Double` — floating-
/// point errors compound across aggregation.
@Model
final class Holding {

    // MARK: - Identity

    @Attribute(.unique) var id: UUID = UUID()

    // MARK: - Core fields

    /// Ticker or coin symbol ("VWRL", "ETH"). `nil` for property / cash / debt.
    var symbol: String? = nil

    /// Human-readable name ("Vanguard FTSE All-World ETF", "8A Bridle Road").
    var name: String = ""

    /// Number of units held. `nil` for non-unit holdings (property, cash, debt).
    /// Stored with up to 8 decimal places for crypto precision.
    var units: Decimal? = nil

    /// Purchase cost basis in the account's currency. Optional.
    var costBasis: Decimal? = nil

    /// Current market value (or manual override) in the account's currency.
    /// Always non-optional — a Holding without a value is nonsensical.
    var currentValue: Decimal = 0

    /// When `true`, the price refresh pipeline will *not* overwrite
    /// `currentValue`. Used for property, pensions, and any asset priced
    /// manually.
    var valueOverride: Bool = false

    /// Timestamp of the last update to `currentValue`.
    var lastUpdated: Date = Date()

    // MARK: - Metadata

    var createdAt: Date = Date()

    // MARK: - Relationships

    /// Inverse of `Account.holdings`. Optional to satisfy CloudKit.
    var account: Account? = nil

    // MARK: - Initialisation

    init(
        symbol: String? = nil,
        name: String,
        units: Decimal? = nil,
        costBasis: Decimal? = nil,
        currentValue: Decimal = 0,
        valueOverride: Bool = false,
        account: Account? = nil
    ) {
        self.id = UUID()
        self.symbol = symbol
        self.name = name
        self.units = units
        self.costBasis = costBasis
        self.currentValue = currentValue
        self.valueOverride = valueOverride
        self.account = account
        self.lastUpdated = Date()
        self.createdAt = Date()
    }

    // MARK: - Computed

    /// Unrealised gain or loss vs cost basis. `nil` when no cost basis recorded.
    var unrealisedPnL: Decimal? {
        guard let cost = costBasis else { return nil }
        return currentValue - cost
    }
}
