//
//  MoneyText.swift
//  KamFinAssetTrack
//
//  A reusable currency display that renders monetary values with
//  tabular digits, correct symbol placement, and Dynamic Type support
//  capped at `.accessibility1` (per Sprint 1 Design Package).
//
//  Usage:
//      MoneyText(.init(value: 1_234_567.89, currency: .gbp))
//      MoneyText(.init(value: account.totalValue, currency: account.currency))
//

import SwiftUI

// MARK: - View

/// A standardised display for currency amounts across KFAT.
///
/// Uses monospaced digits so columns of numbers align. Respects Dynamic
/// Type up to `.accessibility1` — beyond that, tabular alignment breaks
/// down in list rows, so the design package caps money displays here.
struct MoneyText: View {

    // MARK: Config

    struct Config: Equatable {
        var value: Decimal
        var currency: Currency
        /// When `true`, the value is replaced with dots (••••) — used by
        /// the Hide Balances mode (KFAT-24, Sprint 3). Default `false`.
        var hidden: Bool = false
        /// Maximum fraction digits. Default 2 (standard money).
        var fractionDigits: Int = 2
        /// Whether to prefix with a + sign for positive deltas. Used by
        /// the Movers view (KFAT-19, Sprint 3). Default `false`.
        var showsPositiveSign: Bool = false
    }

    let config: Config

    // MARK: Environment

    @Environment(\.sizeCategory) private var sizeCategory

    // MARK: Body

    var body: some View {
        Text(formatted)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .accessibilityLabel(accessibilityLabel)
    }

    // MARK: Formatting

    private var formatted: String {
        if config.hidden { return config.currency.symbol + "••••" }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = config.fractionDigits
        formatter.maximumFractionDigits = config.fractionDigits
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","

        let absValue = abs(config.value) as NSDecimalNumber
        let numberPart = formatter.string(from: absValue) ?? "0"
        let signPrefix: String = {
            if config.value < 0 { return "−" }        // U+2212 minus sign (not hyphen)
            if config.showsPositiveSign && config.value > 0 { return "+" }
            return ""
        }()

        return "\(signPrefix)\(config.currency.symbol)\(numberPart)"
    }

    private var accessibilityLabel: String {
        if config.hidden { return "\(config.currency.displayName), hidden" }
        let valueFormatter = NumberFormatter()
        valueFormatter.numberStyle = .currency
        valueFormatter.currencyCode = config.currency.rawValue
        valueFormatter.maximumFractionDigits = config.fractionDigits
        let value = valueFormatter.string(from: config.value as NSDecimalNumber) ?? ""
        return value
    }
}

// MARK: - Convenience inits

extension MoneyText {
    init(value: Decimal, currency: Currency, hidden: Bool = false) {
        self.config = Config(value: value, currency: currency, hidden: hidden)
    }
}

// MARK: - Previews

#Preview("Various") {
    VStack(alignment: .leading, spacing: 12) {
        MoneyText(value: 1_234_567.89, currency: .gbp)
            .font(.largeTitle.bold())
        MoneyText(value: 12_500, currency: .usd)
            .font(.title)
        MoneyText(value: -847.23, currency: .gbp)
            .font(.body)
            .foregroundStyle(.red)
        MoneyText(config: .init(value: 125.50, currency: .gbp, showsPositiveSign: true))
            .font(.body)
            .foregroundStyle(.green)
        MoneyText(value: 1_234_567.89, currency: .gbp, hidden: true)
            .font(.title2)
    }
    .padding()
    .background(Color(hex: "#0A1628"))
    .foregroundStyle(.white)
}
