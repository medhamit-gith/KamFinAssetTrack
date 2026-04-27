//
//  PriceQuote.swift
//  KamFinAssetTrack
//
//  Created by the Kamat Product Development Studio.
//  Sprint 1 · KFAT-7 — SwiftData schema
//

import Foundation
import SwiftData

/// A `PriceQuote` is a point-in-time market price for a symbol. Used by the
/// price refresh pipeline (Sprint 2) to populate `Holding.currentValue` for
/// holdings where `valueOverride == false`.
///
/// Multiple quotes per symbol are allowed — this is an audit log, not a
/// single-value cache.
@Model
final class PriceQuote {

    @Attribute(.unique) var id: UUID = UUID()

    /// Ticker or coin symbol this quote refers to.
    var symbol: String = ""

    /// Value of one unit, expressed in `currency`.
    var value: Decimal = 0

    /// Raw currency code. Use `currency` computed property.
    var currencyRaw: String = Currency.default.rawValue

    /// Timestamp when this quote was observed.
    var asOf: Date = Date()

    /// Source of the quote — "yahoo", "coingecko", "frankfurter", "manual".
    var source: String = "manual"

    init(
        symbol: String,
        value: Decimal,
        currency: Currency = .default,
        asOf: Date = Date(),
        source: String = "manual"
    ) {
        self.id = UUID()
        self.symbol = symbol
        self.value = value
        self.currencyRaw = currency.rawValue
        self.asOf = asOf
        self.source = source
    }

    var currency: Currency {
        Currency(rawValue: currencyRaw) ?? .default
    }
}
