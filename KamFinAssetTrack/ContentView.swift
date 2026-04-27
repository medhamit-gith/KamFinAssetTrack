//
//  ContentView.swift
//  KamFinAssetTrack
//
//  Root content view. After Batch 2, this simply hosts the Account list.
//  The full tab-bar shell ships in Sprint 3 when the Dashboard tab arrives.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        AccountListView()
            .preferredColorScheme(.dark)
    }
}

#Preview {
    let schema = Schema([Account.self, Holding.self, Snapshot.self, PriceQuote.self])
    let config = ModelConfiguration("Preview", schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    return ContentView().modelContainer(container)
}
