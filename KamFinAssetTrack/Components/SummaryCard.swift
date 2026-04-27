//
//  SummaryCard.swift
//  KamFinAssetTrack
//
//  Hero gold-gradient card showing the total across a collection of
//  accounts. Appears at the top of AccountList (KFAT-8) and becomes the
//  dashboard hero in Sprint 3 (KFAT-17).
//

import SwiftUI

/// Gold-gradient hero card showing total value and account count.
struct SummaryCard: View {

    let total: Decimal
    let currency: Currency
    let accountCount: Int
    var hidden: Bool = false

    private let gradient = LinearGradient(
        colors: [Color(hex: "#E4C77A"), Color(hex: "#C9A961")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Total Value")
                .font(.subheadline)
                .foregroundStyle(.black.opacity(0.7))
            MoneyText(value: total, currency: currency, hidden: hidden)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.black)
            Text("\(accountCount) \(accountCount == 1 ? "account" : "accounts")")
                .font(.caption)
                .foregroundStyle(.black.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(gradient, in: .rect(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Total value: \(accessibilityValue), across \(accountCount) \(accountCount == 1 ? "account" : "accounts")")
    }

    private var accessibilityValue: String {
        if hidden { return "hidden" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.rawValue
        return formatter.string(from: total as NSDecimalNumber) ?? "zero"
    }
}

#Preview {
    VStack(spacing: 16) {
        SummaryCard(total: 1_584_231.45, currency: .gbp, accountCount: 12)
        SummaryCard(total: 0, currency: .gbp, accountCount: 0)
        SummaryCard(total: 42_500, currency: .gbp, accountCount: 3, hidden: true)
    }
    .padding()
    .background(Color(hex: "#0A1628"))
}
