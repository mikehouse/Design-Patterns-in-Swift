//
//  FactoryMethod.swift
//  Design Patterns in Swift
//
//  Created by Mikhail Demidov on 04.02.2020.
//

import Foundation
import CoreData

private protocol DatabaseFactory {
    
    /// Factory method for objects creation.
    func makePersistentContainer() throws -> NSPersistentContainer
    
    /// The properties the subclasses must implement to give some behaviour
    /// for creating objects.
    var entitiesModels: [NSManagedObjectModel] {get}
    var persistentStoreDescriptions: [NSPersistentStoreDescription] {get}
}

extension DatabaseFactory {
    
    /// Default implementation. From now this protocol acts as
    /// abstract class.
    func makePersistentContainer() throws -> NSPersistentContainer {
        let group = DispatchGroup()
        group.enter()
        
        var error: Error?
        let models = NSManagedObjectModel(byMerging: self.entitiesModels)!
        let container = NSPersistentContainer(name: "-", managedObjectModel: models)
        container.persistentStoreDescriptions = self.persistentStoreDescriptions
        container.loadPersistentStores { description, err in
            error = err
            group.leave()
        }
        
        group.wait()
        
        if let error = error {
            throw error
        }
        
        return container
    }
}

private class AppDatabaseProvider: DatabaseFactory {
    
    var entitiesModels: [NSManagedObjectModel] {
        let modelsNames: [String] = ["Users", "Invoices", "Billing"]
        let bundle = Bundle.main
        return modelsNames
            .compactMap { (name) -> URL? in
                bundle.url(forResource: name, withExtension: "momd")
            }
            .compactMap { (url) -> NSManagedObjectModel? in
                NSManagedObjectModel(contentsOf: url)
            }
    }
    
    var persistentStoreDescriptions: [NSPersistentStoreDescription] {
        let description = NSPersistentStoreDescription()
        description.type = NSSQLiteStoreType
        description.isReadOnly = false
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        description.url = FileManager.default.temporaryDirectory
            .appendingPathComponent("com.example.app", isDirectory: false)
            .appendingPathExtension("sqlite")
        
        return [description]
    }
}

private class AppTestsDatabaseProvider: AppDatabaseProvider {
    
    override var persistentStoreDescriptions: [NSPersistentStoreDescription] {
        let description = NSPersistentStoreDescription()
        // In the tests we create In Memory database, then no need to set URL to the store.
        description.type = NSInMemoryStoreType
        description.isReadOnly = false
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        return [description]
    }
    
    override var entitiesModels: [NSManagedObjectModel] {
        // As tests are for App target then we need all the same models.
        return super.entitiesModels
    }
}

/// Assume our app has separated the logic to work with billing system, that is moved out to
/// its own Billing.framework. This framework also has its own database scheme named `billing.momd`.
/// To write the test against this framework we can reuse `DatabaseProvider` with some tweaks to work
/// with `Billing` database scheme only.

/// Billing.framework test suite setup.

private class BillingTestsDatabaseProvider: DatabaseFactory {
    
    /// Setup the scheme for this framework as only testing `Billing` logic.
    var entitiesModels: [NSManagedObjectModel] {
        let bundle = Bundle(for: type(of: self).self)
        let url = bundle.url(forResource: "Billing", withExtension: "momd")!
        return [NSManagedObjectModel(contentsOf: url)!]
    }
    
    var persistentStoreDescriptions: [NSPersistentStoreDescription] {
        let description = NSPersistentStoreDescription()
        // In the tests we create In Memory database, then no need to set URL to the store.
        description.type = NSInMemoryStoreType
        description.isReadOnly = false
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        return [description]
    }
}

private enum DatabaseConfiguration {
    case app
    case appTests
    case billingTests
}

/// This helper for sure is another factory (via DI), that is factory of the factory.
/// I've named it with `Provider` just for simplicity because main factory in this article is `DatabaseProvider`.

private final class DatabaseFactoryProvider {
    func create(kind: DatabaseConfiguration) -> DatabaseFactory {
        switch kind {
        case .app:
            return AppDatabaseProvider()
        case .appTests:
            return AppTestsDatabaseProvider()
        case .billingTests:
            return BillingTestsDatabaseProvider()
        }
    }
}

private let helper = DatabaseFactoryProvider()

/// App database.
private let appDatabase: DatabaseFactory = helper.create(kind: .app)
/// App tests.
private let appTestsDatabase: DatabaseFactory = helper.create(kind: .appTests)
/// Billing module tests.
private let billingTestsDatabase: DatabaseFactory = helper.create(kind: .billingTests)

/// Note 1, also it's better to describe Factory protocol with other protocols, that means instead of returning concrete class
/// `NSPersistentContainer` better return some protocol, the same applies for all properties and methods of the factory,
/// as we heavily use `CoreData` framework that is hard to abstract away, then will just stick with it.

/// Note 2, You might see that we copy-pasted (one time) the code for creation `NSPersistentStoreDescription` object
/// with `In Memory` behaviour, this is good place to extract this logic to another one factory or
/// some more appropriate design pattern.

/// Note 3, this factory method design pattern also can be implemented with no subclassing, but dependency injection (DI).
/// How it might look like with DI.

private protocol DatabaseProperties {
    var entitiesModels: [NSManagedObjectModel] {get}
    var persistentStoreDescriptions: [NSPersistentStoreDescription] {get}
}

/// First version with DI.
private protocol DatabaseFactoryDI {
    
    /// Inject database settings for our needs.
    init(properties: DatabaseProperties)
    
    /// Factory method for objects creation.
    func makePersistentContainer() throws -> NSPersistentContainer
}

/// Another one version with DI.
private protocol DatabaseFactoryDI2 {
    
    /// Factory method for objects creation.
    func makePersistentContainer(properties: DatabaseProperties) throws -> NSPersistentContainer
}

/// Actual DI version implementation.
private final class DatabaseProviderDIImpl: DatabaseFactoryDI {
    private let properties: DatabaseProperties
    init(properties: DatabaseProperties) {
        self.properties = properties
    }
    
    /// The same implementation as it is in `DatabaseProvider.makePersistentContainer(_:)`.
    func makePersistentContainer() throws -> NSPersistentContainer {
        fatalError() // `fatalError` just to be able to compile the project.
    }
}
