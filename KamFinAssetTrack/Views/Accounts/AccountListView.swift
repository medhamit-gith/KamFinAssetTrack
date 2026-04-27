//
//  AccountListView.swift
//  KamFinAssetTrack
//
//  Main Account list screen. Shows a summary card at the top, a grouped
//  list of accounts sorted by value within type, and a floating + button
//  to create new accounts.
//
//  Implements ACs 1, 2, 3, 4, 5, 6, 9 from the Scope Package.
//

import SwiftUI
import SwiftData

struct AccountListView: View {

    // MARK: Environment

    @Environment(\.modelContext) private var context
    @Query(sort: \Account.createdAt, order: .reverse) private var accounts: [Account]

    // MARK: State

    @State private var vm = AccountListViewModel()
    @State private var showCreateSheet = false
    @State private var accountPendingDelete: Account?

    // MARK: Body

    var body: some View {
        NavigationStack {
            Group {
                if vm.accountCount(from: accounts) == 0 {
                    EmptyAccountsView { showCreateSheet = true }
                } else {
                    populatedList
                }
            }
            .navigationTitle("Accounts")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color(hex: "#0A1628"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color(hex: "#C9A961"))
                    }
                    .accessibilityLabel("Add new account")
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                AccountFormView(mode: .create)
            }
            .confirmationDialog(
                "Delete this account?",
                isPresented: Binding(
                    get: { accountPendingDelete != nil },
                    set: { if !$0 { accountPendingDelete = nil } }
                ),
                titleVisibility: .visible,
                presenting: accountPendingDelete
            ) { account in
                Button("Delete", role: .destructive) {
                    vm.requestDelete(account, context: context)
                    accountPendingDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    accountPendingDelete = nil
                }
            } message: { account in
                if account.holdingCount > 0 {
                    Text("\(account.name) has \(account.holdingCount) holdings. They will all be removed.")
                } else {
                    Text("\(account.name) will be removed. You have 5 seconds to undo.")
                }
            }
        }
    }

    // MARK: - Populated state

    private var populatedList: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 16) {
                    SummaryCard(
                        total: vm.total(from: accounts),
                        currency: .gbp,  // Multi-currency conversion in Sprint 2 (KFAT-14)
                        accountCount: vm.accountCount(from: accounts)
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)

                    ForEach(vm.sections(from: accounts)) { section in
                        sectionView(section)
                            .padding(.horizontal)
                    }
                    .padding(.bottom, 80)
                }
            }
            .background(Color(hex: "#0A1628"))

            if let pending = vm.pendingDeletion {
                UndoToast(
                    accountName: pending.accountName,
                    totalSeconds: vm.undoWindow,
                    onUndo: { vm.undoDeletion(context: context) },
                    onTimeout: { vm.finalizeDeletion() }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: vm.pendingDeletion)
    }

    // MARK: - Section

    @ViewBuilder
    private func sectionView(_ section: AccountSection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(section.type.pluralName)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                MoneyText(value: section.subtotal, currency: .gbp)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(section.accounts.enumerated()), id: \.element.id) { pair in
                    let account = pair.element
                    NavigationLink(value: account.id) {
                        AccountRow(account: account)
                            .padding(.horizontal, 12)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            accountPendingDelete = account
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button {
                            account.isArchived = true
                            try? context.save()
                        } label: {
                            Label("Archive", systemImage: "archivebox")
                        }
                        .tint(.orange)
                    }
                    if pair.offset < section.accounts.count - 1 {
                        Rectangle()
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 1)
                            .padding(.leading, 64)
                    }
                }
            }
            .background(Color(hex: "#12203A"), in: .rect(cornerRadius: 12))
        }
        .navigationDestination(for: UUID.self) { accountID in
            if let account = accounts.first(where: { $0.id == accountID }) {
                AccountDetailView(account: account)
            } else {
                Text("Account not found")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview("Empty") {
    let schema = Schema([Account.self, Holding.self, Snapshot.self, PriceQuote.self])
    let config = ModelConfiguration("Preview", schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    return AccountListView().modelContainer(container)
}

#Preview("Populated") {
    let schema = Schema([Account.self, Holding.self, Snapshot.self, PriceQuote.self])
    let config = ModelConfiguration("Preview", schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    let ctx = ModelContext(container)

    let hl = Account(name: "HL Stocks & Shares ISA", provider: "Hargreaves Lansdown", type: .isa, currency: .gbp)
    let fidelity = Account(name: "Fidelity SIPP", provider: "Fidelity", type: .pension, currency: .gbp)
    let edith = Account(name: "16 Edith Court", provider: "Manual", type: .property, currency: .gbp)
    let eth = Account(name: "Ethereum", provider: "CoinGecko Wallet", type: .crypto, currency: .gbp)
    ctx.insert(hl); ctx.insert(fidelity); ctx.insert(edith); ctx.insert(eth)

    _ = Holding(symbol: "VWRL", name: "Vanguard FTSE All-World ETF", units: 850, currentValue: 95_120, account: hl)
    _ = Holding(name: "SIPP Valuation", currentValue: 242_000, valueOverride: true, account: fidelity)
    _ = Holding(name: "Property Value", currentValue: 750_000, valueOverride: true, account: edith)
    _ = Holding(symbol: "ETH", name: "Ethereum", units: 4.2, currentValue: 12_300, account: eth)

    try? ctx.save()
    return AccountListView().modelContainer(container)
}
