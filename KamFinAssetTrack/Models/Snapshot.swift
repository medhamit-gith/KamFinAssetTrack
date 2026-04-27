//
//  Snapshot.swift
//  KamFinAssetTrack
//
//  Created by the Kamat Product Development Studio.
//  Sprint 1 · KFAT-7 — SwiftData schema
//

import Foundation
import SwiftData

/// A daily `Snapshot` records the household net worth at end-of-day so that
/// historical charts (Sprint 3) and delta calculations can run without
/// rebuilding the full portfolio from scratch.
///
/// The store uses `dateKey` (yyyy-MM-dd) as the unique key so multiple writes
/// on the same day upsert rather than duplicate.
///
/// Allocation and FX rates are serialised to JSON strings — SwiftData cannot
/// directly persist `[AccountType: Decimal]` dictionaries, and the payloads
/// are small (< 1 KB).
@Model
final class Snapshot {

    // MARK: - Identity

    /// Date key in `yyyy-MM-dd` format. Unique — upsert-on-conflict semantics.
    @Attribute(.unique) var dateKey: String = ""

    // MARK: - Core fields

    /// Total net worth in GBP as at end-of-day.
    var totalNetWorthGBP: Decimal = 0

    /// JSON-encoded `[AccountType.rawValue: Decimal]` showing the allocation
    /// split. Read via `allocation` computed property.
    var allocationJSON: String = "{}"

    /// JSON-encoded `[Currency.rawValue: Decimal]` — GBP-denominated FX rates
    /// used for this snapshot. Preserves historical accuracy if rates change.
    var fxRatesJSON: String = "{}"

    // MARK: - Metadata

    var createdAt: Date = Date()

    // MARK: - Initialisation

    init(date: Date, totalNetWorthGBP: Decimal = 0) {
        self.dateKey = Self.dateKey(from: date)
        self.totalNetWorthGBP = totalNetWorthGBP
        self.allocationJSON = "{}"
        self.fxRatesJSON = "{}"
        self.createdAt = Date()
    }

    // MARK: - Helpers

    /// Canonical `yyyy-MM-dd` string for a given date.
    static func dateKey(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
