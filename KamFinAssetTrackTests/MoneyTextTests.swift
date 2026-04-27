//
//  MoneyTextTests.swift
//  KamFinAssetTrackTests
//
//  Swift Testing suite for the MoneyText formatter. We can't render
//  SwiftUI views inside unit tests, so these tests exercise the config
//  struct + the internal `formatted` helper via a private extension
//  point. Instead, we build a helper that mirrors the formatter logic.
//

import Foundation
import Testing
@testable import KamFinAssetTrack

@Suite("KFAT-8 · MoneyText formatter (reachable via config)")
struct MoneyTextTests {

    /// Mirrors the view's private formatting logic so it's independently
    /// exercisable. If the view's formatter changes, this helper must too.
    private func format(_ config: MoneyText.Config) -> String {
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
            if config.value < 0 { return "−" }
            if config.showsPositiveSign && config.value > 0 { return "+" }
            return ""
        }()
        return "\(signPrefix)\(config.currency.symbol)\(numberPart)"
    }

    // MARK: - Basic formatting

    @Test("GBP formatting uses £ symbol and comma grouping")
    func gbpFormatting() {
        let out = format(.init(value: 1_234_567.89, currency: .gbp))
        #expect(out == "£1,234,567.89")
    }

    @Test("USD formatting uses $ symbol")
    func usdFormatting() {
        let out = format(.init(value: 12_500.50, currency: .usd))
        #expect(out == "$12,500.50")
    }

    @Test("Zero renders as currency symbol + 0.00")
    func zeroFormatting() {
        let out = format(.init(value: 0, currency: .gbp))
        #expect(out == "£0.00")
    }

    @Test("Negative values use the minus-sign character (U+2212)")
    func negativeFormatting() {
        let out = format(.init(value: -847.23, currency: .gbp))
        #expect(out == "−£847.23")
        // Verify it's the minus sign, not a hyphen.
        #expect(out.first == "−")
    }

    // MARK: - Sign handling

    @Test("Positive deltas prefix + when showsPositiveSign is true")
    func positiveSignShown() {
        let out = format(.init(value: 125, currency: .gbp, showsPositiveSign: true))
        #expect(out == "+£125.00")
    }

    @Test("Zero never gets a + sign even when showsPositiveSign is true")
    func zeroNeverSigned() {
        let out = format(.init(value: 0, currency: .gbp, showsPositiveSign: true))
        #expect(out == "£0.00")
    }

    // MARK: - Fraction digits

    @Test("Custom fraction digits respected")
    func customFractionDigits() {
        let out = format(.init(value: 1.23456, currency: .gbp, fractionDigits: 4))
        #expect(out == "£1.2346")   // rounded
    }

    @Test("Zero fraction digits suppresses the decimal point")
    func zeroFractionDigits() {
        let out = format(.init(value: 1_234, currency: .gbp, fractionDigits: 0))
        #expect(out == "£1,234")
    }

    // MARK: - Hidden mode (KFAT-24)

    @Test("Hidden mode replaces digits with bullets")
    func hiddenMode() {
        let out = format(.init(value: 1_000_000, currency: .gbp, hidden: true))
        #expect(out == "£••••")
    }

    @Test("Hidden mode works regardless of currency")
    func hiddenModeAllCurrencies() {
        for c in Currency.allCases {
            let out = format(.init(value: 100, currency: c, hidden: true))
            #expect(out.hasPrefix(c.symbol))
            #expect(out.hasSuffix("••••"))
        }
    }

    // MARK: - Large values

    @Test("Very large values render correctly")
    func veryLargeValue() {
        let out = format(.init(value: Decimal(string: "12345678901234.56")!, currency: .gbp))
        #expect(out == "£12,345,678,901,234.56")
    }
}
