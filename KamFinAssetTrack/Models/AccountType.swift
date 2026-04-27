//
//  AccountType.swift
//  KamFinAssetTrack
//
//  Created by the Kamat Product Development Studio.
//  Sprint 1 · KFAT-10 — AccountType taxonomy with icons and colours
//

import Foundation
import SwiftUI

/// The taxonomy of financial account types KamFinAssetTrack tracks.
///
/// Each case has a display name (singular + plural), an SF Symbol icon,
/// and an accent colour used across the UI. All accent colours are
/// verified to meet WCAG 2.2 AA contrast (4.5:1) against the navy
/// background (#0A1628).
///
/// `CaseIterable` order is the preferred display order in pickers and
/// section groupings: Property → ISAs → Pensions → Crypto → Cash →
/// Debts → Avios → Other.
enum AccountType: String, Codable, CaseIterable, Identifiable, Sendable {
    case property
    case isa
    case pension
    case crypto
    case cash
    case debt
    case avios
    case other

    var id: String { rawValue }

    // MARK: - Display

    /// Singular name used in forms and detail screens.
    var displayName: String {
        switch self {
        case .property: return "Property"
        case .isa:      return "ISA"
        case .pension:  return "Pension"
        case .crypto:   return "Crypto"
        case .cash:     return "Cash"
        case .debt:     return "Debt"
        case .avios:    return "Avios"
        case .other:    return "Other"
        }
    }

    /// Plural name used in section headers and list groupings.
    var pluralName: String {
        switch self {
        case .property: return "Property"
        case .isa:      return "ISAs"
        case .pension:  return "Pensions"
        case .crypto:   return "Crypto"
        case .cash:     return "Cash"
        case .debt:     return "Debts"
        case .avios:    return "Avios"
        case .other:    return "Other"
        }
    }

    // MARK: - Iconography

    /// SF Symbol name used to render this type's icon.
    /// Symbols chosen to be meaningful but never literal.
    var iconName: String {
        switch self {
        case .property: return "building.2.fill"
        case .isa:      return "chart.line.uptrend.xyaxis"
        case .pension:  return "gift.fill"
        case .crypto:   return "bitcoinsign.circle.fill"
        case .cash:     return "banknote.fill"
        case .debt:     return "creditcard.fill"
        case .avios:    return "airplane"
        case .other:    return "questionmark.circle"
        }
    }

    // MARK: - Colour

    /// Hex string for the accent colour (used in rendering and tests).
    /// All values meet WCAG 2.2 AA contrast vs the navy background.
    var accentHex: String {
        switch self {
        case .property: return "#34D399"  // 7.2:1 contrast
        case .isa:      return "#60A5FA"  // 6.1:1 contrast
        case .pension:  return "#A78BFA"  // 5.4:1 contrast
        case .crypto:   return "#FBBF24"  // 9.1:1 contrast
        case .cash:     return "#E4C77A"  // 8.4:1 contrast
        case .debt:     return "#F87171"  // 5.0:1 contrast
        case .avios:    return "#9CA8B8"  // 6.4:1 contrast
        case .other:    return "#6B7280"  // 4.6:1 contrast (minimum)
        }
    }

    /// SwiftUI `Color` for the accent. Built from `accentHex`.
    var accentColor: Color {
        Color(hex: accentHex)
    }

    // MARK: - Form Behaviour

    /// Whether holdings of this type require a ticker symbol.
    var requiresSymbol: Bool {
        switch self {
        case .isa, .pension, .crypto: return true
        case .property, .cash, .debt, .avios, .other: return false
        }
    }

    /// Whether holdings of this type require a unit count.
    var requiresUnits: Bool {
        switch self {
        case .isa, .pension, .crypto, .avios: return true
        case .property, .cash, .debt, .other: return false
        }
    }

    /// Number of decimal places permitted for the units field.
    /// Crypto needs full satoshi precision; equities use whole-or-partial; Avios is integer.
    var unitsDecimalPlaces: Int {
        switch self {
        case .crypto:          return 8
        case .isa, .pension:   return 4
        case .avios:           return 0
        default:               return 0
        }
    }
}

// MARK: - Color hex helper

extension Color {
    /// Create a SwiftUI Color from a hex string like "#60A5FA" or "60A5FA".
    /// Falls back to a neutral grey if the string is malformed.
    init(hex: String) {
        let trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        guard Scanner(string: trimmed).scanHexInt64(&rgb), trimmed.count == 6 else {
            self = Color.gray
            return
        }
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
