//
//  SchemaV1.swift
//  KamFinAssetTrack
//
//  Created by the Kamat Product Development Studio.
//  Sprint 1 · KFAT-7 — SwiftData schema version
//

import Foundation
import SwiftData

/// Version 1 of the persistent schema. All future migrations will be authored
/// as `SchemaV2`, `SchemaV3`, etc., with `MigrationPlan` mapping between them.
///
/// See Apple's "Model your schema with SwiftData" session for the migration
/// story. We don't need migrations yet — but by declaring a versioned schema
/// from day one, we avoid a costly retro-fit later.
enum SchemaV1: VersionedSchema {

    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            Account.self,
            Holding.self,
            Snapshot.self,
            PriceQuote.self
        ]
    }
}

/// Factory helpers for creating the app's `ModelContainer`.
///
/// Production code calls `KFATModelContainer.live()` at App root.
/// Tests call `KFATModelContainer.inMemory()` for isolation.
enum KFATModelContainer {

    /// Production container — stored on disk with file protection.
    static func live() throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let configuration = ModelConfiguration(
            "KFAT.Production",
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        return try ModelContainer(for: schema, configurations: configuration)
    }

    /// Test container — in-memory, clean state on every instantiation.
    static func inMemory() throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let configuration = ModelConfiguration(
            "KFAT.Test",
            schema: schema,
            isStoredInMemoryOnly: true,
            allowsSave: true
        )
        return try ModelContainer(for: schema, configurations: configuration)
    }
}
