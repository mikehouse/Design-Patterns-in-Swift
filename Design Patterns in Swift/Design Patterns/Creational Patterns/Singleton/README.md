# Singleton design pattern in Swift

Let's talk about the most discussable and contradictory design pattern `Singleton`. I'm sure this design pattern well know even the beginners in IT field. Some developers love this design pattern, some hate it with all its heart. `Singleton` design pattern we encounter almost at every iOS tutorial on any topic, even in tutorials from Apple. iOS SDK literally filled with singletons, they are everywhere.

```swift
let application = UIApplication.shared
let fileManager = FileManager.default
let userDefaults = UserDefaults.standard
let notificationCenter = NotificationCenter.default
```   

You can see from examples above make a class be `Singleton` the class must have static method (property) that returns an instance of itself, and most importantly every time you call this method the same class instance must be returned. We've just described main goal of this design pattern - method of the class must return the same instance every time and must guarantee that only one instance of this class exists within application (process) life, and must prohibit a client code to create an instance of the class outside of defined static (class) method (that is done via private constructor). As this design pattern works with object creation then this pattern belongs to the creational group of design patterns.

In Swift, it is trivial to describe `Singleton` class.

```swift
final class AppSession {
    private init() { }
    static let shared = AppSession()

    func method1() {}
    func method2() {}
}
```

That is all, from now we can use our singleton object.

```swift
final class LaunchViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    
        AppSession.shared.someMethod()
    }
}
```

Swift guarantees that singleton object will be created in thread safe manner within first access of it, that is there no need for lock mechanisms in multithreaded environment. There were a time when we didn't have that luxury and had to write additional code for singleton creation in multithreaded environment. Let's see how it looked like in Objective C.

 Header file.
 
 ```objectivec
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppSession : NSObject

- (instancetype)init NS_UNAVAILABLE; // Prohibit using default constructor.

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
```

Implementation.

```objectivec
#import "AppSession.h"

@implementation AppSession

+ (instancetype)sharedInstance {
    static AppSession *shared;
    if (shared == nil) {
        @synchronized (self) {
            if (shared == nil) {
                shared = [AppSession new];
            }
        }
    }
    return shared;
}

@end
```

That is called two-step instance initialization. In first check we just check an instance is not created yet, then we acquire the lock on the class and check one more time on nil, and only then we create the object as we are in synchronized block and there no way that instance can be in creation state on second parallel thread.

The beginner in programming might think why do we even need two-step nil check, won't it spend processor time for nothing ? Let's see how it would look like with one-step nil check without synchronization block.

```objectivec
#import "AppSession.h"

@implementation AppSession

+ (instancetype)sharedInstance {
    static AppSession *shared;
    if (shared == nil) {
        shared = [AppSession new];
    }
    return shared;
}

@end
```

Now we got race condition, that is the shared data accessed from different threads at the same time. There can be a case when inside `if` statement might be not one but several threads at the same time, and we will get several instances of singleton class that is violation `Singleton` design pattern principle.

Okay, let use an example with synchronization.

```objectivec
#import "AppSession.h"

@implementation AppSession

+ (instancetype)sharedInstance {
    static AppSession *shared;
    @synchronized (self) {
        if (shared == nil) {
            shared = [AppSession new];            
        }
    }
    return shared;
}

@end
```

Now we got rid of race condition, but we got redundant lock. It is redundant because after object creation we have no needs for synchronized data access anymore. As you might already know locking the shared data to make it thread safe is very expensive operation, and it will heavily hit our application performance.

Let's talk about `Singleton` design pattern itself.

Pros.

- It is guaranteed at any time we have one instance of the class.
- Client has no needs to know how create and configure singleton object, it just uses it as it is.
- Code coupling decreases as `Singleton` described via interfaces.
- Can be accessed from any part of your code in the application (globally accessible).

Cons.

- There is temptation use singleton via global access everywhere violate SOLID principle.
- Increases code coupling if there no abstraction for singleton class.
- Not possible to mock for testing as all constructors are private.
- There almost no ways explicitly pass the dependencies for singleton object creation as all constructors are private. 

It is up to you use this design pattern or not. I mostly do not like singletons and prefer to not use them, but replace it with another design patterns.

Let's see how the singleton can be replaced with Service Locator design pattern.

```swift
/// Not a singleton now.
final class AppSession {
    init(dependencies: Dependencies) { }    
    func someMethod() {}
}
```

Create services locator (in context of the application we might treat it like a singleton) that we pass all over application.

```swift
import UIKit

final class AppDependencies {
    let appSession = AppSession(dependencies: Dependencies())
}

final class LaunchViewController: UIViewController {
    var appSession: AppSession!

    override func viewDidLoad() {
        super.viewDidLoad()
    
        appSession.someMethod()
    }
}

final class AppDelegate: UIResponder, UIApplicationDelegate {

    private lazy var appDependencies = AppDependencies()

    func application(_ application: UIApplication, 
            didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let rootViewController = LaunchViewController()
        rootViewController.appSession = appDependencies.appSession
        // Some setups.
        return true
    }
}
```

As you can see `AppDependencies` class now responsible for objects creation, and as we use this one instance all over the application it is guaranteed is has only one instance. 
