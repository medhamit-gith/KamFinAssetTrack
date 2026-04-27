//
//  Currency.swift
//  KamFinAssetTrack
//
//  Created by the Kamat Product Development Studio.
//  Sprint 1 · KFAT-7
//

import Foundation

/// The set of currencies KamFinAssetTrack supports at v1.
///
/// The raw value is the ISO-4217 code used for FX lookups and display.
/// New cases should be added alphabetically and the `symbol` / `displayOrder`
/// properties updated.
enum Currency: String, Codable, CaseIterable, Identifiable, Sendable {
    case gbp = "GBP"
    case inr = "INR"
    case usd = "USD"
    case eur = "EUR"

    var id: String { rawValue }

    /// Prefix symbol shown before monetary values.
    /// Follows PRD decision: symbol-prefix convention.
    var symbol: String {
        switch self {
        case .gbp: return "£"
        case .inr: return "₹"
        case .usd: return "$"
        case .eur: return "€"
        }
    }

    /// Human-readable name used in pickers.
    var displayName: String {
        switch self {
        case .gbp: return "British Pound"
        case .inr: return "Indian Rupee"
        case .usd: return "US Dollar"
        case .eur: return "Euro"
        }
    }

    /// Sort order for picker presentation. GBP always first.
    var displayOrder: Int {
        switch self {
        case .gbp: return 0
        case .usd: return 1
        case .eur: return 2
        case .inr: return 3
        }
    }

    /// Default currency when none is specified.
    static let `default`: Currency = .gbp
}
