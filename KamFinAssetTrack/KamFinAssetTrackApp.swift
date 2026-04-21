//
//  KamFinAssetTrackApp.swift
//  KamFinAssetTrack
//
//  Created by Amit Kamat on 21/04/2026.
//

import SwiftUI
import CoreData

@main
struct KamFinAssetTrackApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
