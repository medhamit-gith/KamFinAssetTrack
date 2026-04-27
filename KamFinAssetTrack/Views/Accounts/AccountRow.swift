//
//  AccountRow.swift
//  KamFinAssetTrack
//
//  Single row in the Account list: typed icon + name/provider + right-
//  aligned current value.
//

import SwiftUI
import SwiftData

struct AccountRow: View {

    let account: Account
    var hidden: Bool = false   // honoured when Hide Balances mode lands (KFAT-24)

    var body: some View {
        HStack(spacing: 12) {
            AccountIcon(type: account.type)

            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.body)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(account.provider)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            MoneyText(value: account.totalValue, currency: account.currency, hidden: hidden)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double-tap to view details")
    }

    private var accessibilityLabel: String {
        let typeName = account.type.displayName
        let holdingsPhrase: String = {
            switch account.holdingCount {
            case 0: return "no holdings"
            case 1: return "1 holding"
            default: return "\(account.holdingCount) holdings"
            }
        }()
        if hidden {
            return "\(account.name), \(account.provider), \(typeName), value hidden, \(holdingsPhrase)"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = account.currency.rawValue
        let value = formatter.string(from: account.totalValue as NSDecimalNumber) ?? ""
        return "\(account.name), \(account.provider), \(typeName), \(value), \(holdingsPhrase)"
    }
}

#Preview {
    let schema = Schema([Account.self, Holding.self, Snapshot.self, PriceQuote.self])
    let config = ModelConfiguration("Preview", schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    let ctx = ModelContext(container)
    let a = Account(name: "HL Stocks & Shares ISA", provider: "Hargreaves Lansdown", type: .isa, currency: .gbp)
    ctx.insert(a)
    _ = Holding(symbol: "VWRL", name: "Vanguard FTSE All-World", units: 850, currentValue: 95_120, account: a)

    return List {
        AccountRow(account: a)
            .listRowBackground(Color(hex: "#12203A"))
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .background(Color(hex: "#0A1628"))
}
