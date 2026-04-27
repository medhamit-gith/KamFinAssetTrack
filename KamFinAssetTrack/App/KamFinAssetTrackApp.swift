//
//  KamFinAssetTrackApp.swift
//  KamFinAssetTrack
//
//  Created by Amit Kamat on 21/04/2026.
//

import SwiftUI
import SwiftData

@main
struct KamFinAssetTrackApp: App {

    let container: ModelContainer = {
        do {
            return try KFATModelContainer.live()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
