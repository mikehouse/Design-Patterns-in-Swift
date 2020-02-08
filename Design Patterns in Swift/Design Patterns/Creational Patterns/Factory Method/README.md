# Factory method design pattern in Swift

Factory Method design pattern like Abstract Factory also belongs to Creation group of design patterns. It helps to separate creation of objects from using them. This technique increase code reusability, decrease code coupling. The client's code doesn't even know what concrete type of object it works with as factory method returns abstract object (or interface). Only this abstract method implementation knows what type of object should be created, how to create it and how to configure it to be ready to be used by the client.

Factory Method design principle almost similar to Abstract Factory design pattern and has the same idea in general. We need to describe a factory abstract class with partial implementation and one factory method for objects creation in it, let subclasses choose needed configuration to help the abstract class fully create and configure an object to pass in back to the client (also this can be solved without subclassing but dependency injection).    

As we are iOS developers let create en example on the code that we work every day with. We will create a factory that creates database services with different configurations, these configurations will be provided with subclasses of factory abstract class. The client will be allowed to call only one factory method to get a database service object.

Describe our factory interface:

```swift
protocol DatabaseFactory {
    
    /// Factory method for objects creation.
    func makePersistentContainer() throws -> NSPersistentContainer
    
    /// The properties the subclasses must implement to give some behaviour
    /// for creating objects.
    var entitiesModels: [NSManagedObjectModel] {get}
    var persistentStoreDescriptions: [NSPersistentStoreDescription] {get}
}
```

Where  

```swift
func makePersistentContainer() throws -> NSPersistentContainer
```

is a factory method for creation the database services. The properties

```swift
var entitiesModels: [NSManagedObjectModel] {get}
var persistentStoreDescriptions: [NSPersistentStoreDescription] {get}
```

must be implemented within implementations to provide needed behaviour.  

Make partial implementation of the factory protocol:

```swift
extension DatabaseFactory {
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
```

As we added the default implementation to our protocol, from this point we can call it abstract class. To fully construct a database service we will ask implementators (subclasses) for additional information at the creation time. Now we are ready to add some implementations of the protocol with different configurations.

Imagine our app is big, and we are smart enough to separate it to several independent modules - `Main App` module, `Users` module, `Billing` and `Invoices` modules. We use `CoreData` framework as persistent store and every module has its own `CoreData` entities scheme. Let's create first database implementation for our main application module, as it is the main module, here we will depend on all other modules and its database schemes.  

```swift
class AppDatabaseProvider: DatabaseFactory {
    
    var entitiesModels: [NSManagedObjectModel] {
        // List all the schemes names.
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
        // Configure `CoreData` as SQLite storage type and give it the url to be stored
        // locally in application's sandbox.
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
```

As we are good developers we write tests. Let's create the database service for `Tests` Xcode target.

```swift
class AppTestsDatabaseProvider: AppDatabaseProvider {
    
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
        // As tests are for the main app target then we need all the same models, 
        // i.e. reuse it from main app service via subclassing.
        return super.entitiesModels
    }
}
```

Our separate `Billing` module (`Billing.framework`) has its own database scheme `Billing.momd`. This module also has its own test suite. Let's create the database service for its tests.

```swift
class BillingTestsDatabaseProvider: DatabaseFactory {
    
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
```

From now, we are all set and can create helper class that will give us the database service depending on the configuration.

```swift
enum DatabaseConfiguration {
    case app
    case appTests
    case billingTests
}
```

```swift
/// This helper for sure is another factory (via DI), that is factory of the factory.
/// I've named it with `Provider` just for simplicity because main factory in this article is `DatabaseProvider`.

final class DatabaseFactoryProvider {
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
```

Below is an example how to use database factory in our application.

```swift
import UIKit
import CoreData

final class LaunchViewController: UIViewController {
    var persistentContainer: NSPersistentContainer!

    override func viewDidLoad() {
        super.viewDidLoad()
    
        let request: NSFetchRequest<User> = NSFetchRequest<User>(entityName: "User")
        let users: [User] = persistentContainer.viewContext.fetch(request)
        self.didLoadUsers(users)
    }
}

final class AppDelegate: UIResponder, UIApplicationDelegate {

    private let dbFactoryProvider = DatabaseFactoryProvider()
    private lazy var persistentContainer: NSPersistentContainer = {
        let factory = self.dbFactoryProvider.create(.app)
        return try! factory.makePersistentContainer()
    }()

    func application(_ application: UIApplication, 
            didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let rootViewController = LaunchViewController()
        rootViewController.persistentContainer = persistentContainer
        // Some setups.
        return true
    }
}
```

Main application test suite.

```swift
import XCTest

final class AppLogicTests: XCTestCase {

    private let dbFactoryProvider = DatabaseFactoryProvider()
    private var persistentContainer: NSPersistentContainer!

    override func setUp() {        
        let factory = self.dbFactoryProvider.create(.appTests)
        self.persistentContainer = try! factory.makePersistentContainer()

        super.setup()
    }

    override func tearDown() {
        // Drop persistent store on every test run.
        // It is safe as database is in-memory type.
        self.persistentContainer = nil

        super.tearDown()
    }

    func testSomeLogic() {
        let context = persistentContainer.viewContext
        // tests
    }
}
```

`Billing` module test suite.

```swift
import XCTest

final class BillingLogicTests: XCTestCase {

    private let dbFactoryProvider = DatabaseFactoryProvider()
    private var persistentContainer: NSPersistentContainer!

    override func setUp() {        
        let factory = self.dbFactoryProvider.create(.billingTests)
        self.persistentContainer = try! factory.makePersistentContainer()

        super.setup()
    }

    override func tearDown() {
        // Drop persistent store on every test run.
        // It is safe as database is in-memory type.
        self.persistentContainer = nil

        super.tearDown()
    }

    func testSomeLogic() {
        let context = persistentContainer.viewContext
        // tests
    }
}
```

From the code above you can see how easy it is to create a database service in two lines of code

```swift
let factory = DatabaseFactoryProvider().create(.app)
let persistentContainer = try! factory.makePersistentContainer()
```

`Note 1` It's better to describe Factory protocol with other protocols, that means instead of returning concrete class `NSPersistentContainer` better return some protocol, the same applies for all properties and methods of the factory, but as we heavily use `CoreData` framework that is hard to abstract it away, then will just stick with it.

`Note 2` You might see that we copy-pasted the code for creation `NSPersistentStoreDescription` object with `In Memory` behaviour, this is good place to extract this logic to another one factory or some more appropriate design pattern.

`Note 3` this factory method design pattern also can be implemented with no subclassing, but dependency injection (DI).

How it might look like with DI.

```swift
protocol DatabaseProperties {
    var entitiesModels: [NSManagedObjectModel] {get}
    var persistentStoreDescriptions: [NSPersistentStoreDescription] {get}
}
```

```swift
/// First version with DI.
protocol DatabaseFactoryDI {
    
    /// Inject database settings for our needs.
    init(properties: DatabaseProperties)
    
    /// Factory method for objects creation.
    func makePersistentContainer() throws -> NSPersistentContainer
}
```

```swift
/// Another one version with DI.
protocol DatabaseFactoryDI2 {
    
    /// Factory method for objects creation.
    func makePersistentContainer(properties: DatabaseProperties) throws -> NSPersistentContainer
}
```

```swift
/// Actual DI version implementation.
final class DatabaseProviderDIImpl: DatabaseFactoryDI {
    private let properties: DatabaseProperties
    init(properties: DatabaseProperties) {
        self.properties = properties
    }
    
    /// The same implementation as it is in `DatabaseProvider.makePersistentContainer(_:)`.
    func makePersistentContainer() throws -> NSPersistentContainer {
        fatalError() // `fatalError` just to be able to compile the project.
    }
}
```





