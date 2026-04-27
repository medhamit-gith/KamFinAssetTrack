//
//  AccountDetailView.swift
//  KamFinAssetTrack
//
//  Detail screen for a single account. Sprint 1 shows a hero + metadata
//  and a holdings-list placeholder. Holdings CRUD is KFAT-9 (Batch 3).
//

import SwiftUI
import SwiftData

struct AccountDetailView: View {

    @Bindable var account: Account

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var showEditSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero
                metadata
                holdingsStub
            }
            .padding(20)
        }
        .background(Color(hex: "#0A1628"))
        .navigationTitle(account.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showEditSheet = true }
                    .foregroundStyle(Color(hex: "#C9A961"))
            }
        }
        .sheet(isPresented: $showEditSheet) {
            AccountFormView(mode: .edit(accountID: account.id), account: account)
        }
    }

    // MARK: - Sections

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                AccountIcon(type: account.type, size: 56)
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.name)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text(account.provider)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
            }

            HStack {
                typeChip
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Total Value")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                MoneyText(value: account.totalValue, currency: account.currency)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#C9A961"))
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(hex: "#12203A"), in: .rect(cornerRadius: 16))
    }

    private var typeChip: some View {
        HStack(spacing: 6) {
            Image(systemName: account.type.iconName)
            Text(account.type.displayName)
        }
        .font(.caption.bold())
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(account.type.accentColor.opacity(0.2), in: Capsule())
        .overlay(Capsule().strokeBorder(account.type.accentColor.opacity(0.5), lineWidth: 1))
        .foregroundStyle(account.type.accentColor)
    }

    private var metadata: some View {
        VStack(alignment: .leading, spacing: 0) {
            metaRow("Currency", "\(account.currency.symbol) \(account.currency.rawValue)")
            divider
            metaRow("Holdings", "\(account.holdingCount)")
            divider
            metaRow("Created", account.createdAt.formatted(date: .abbreviated, time: .omitted))
            divider
            metaRow("Updated", account.updatedAt.formatted(date: .abbreviated, time: .shortened))
            if let notes = account.notes, !notes.isEmpty {
                divider
                VStack(alignment: .leading, spacing: 6) {
                    Text("Notes")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                    Text(notes)
                        .font(.body)
                        .foregroundStyle(.white)
                }
                .padding(.vertical, 12)
            }
        }
        .padding(.horizontal, 16)
        .background(Color(hex: "#12203A"), in: .rect(cornerRadius: 12))
    }

    private func metaRow(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.white)
        }
        .padding(.vertical, 12)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 1)
    }

    private var holdingsStub: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Holdings")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    // Wired in Batch 3 (KFAT-9).
                } label: {
                    Label("Add Holding", systemImage: "plus.circle")
                }
                .disabled(true)
                .foregroundStyle(.white.opacity(0.4))
            }

            if account.holdings.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.largeTitle)
                        .foregroundStyle(.white.opacity(0.3))
                    Text("No holdings yet")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                    Text("Holdings CRUD ships in Batch 3.")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                // Lightweight placeholder listing; full row component ships in Batch 3.
                ForEach(account.holdings) { h in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(h.name)
                                .foregroundStyle(.white)
                            if let sym = h.symbol {
                                Text(sym)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }
                        Spacer()
                        MoneyText(value: h.currentValue, currency: account.currency)
                            .foregroundStyle(.white)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(16)
        .background(Color(hex: "#12203A"), in: .rect(cornerRadius: 12))
    }
}
