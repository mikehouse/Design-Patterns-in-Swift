//
//  Singleton.swift
//  Design Patterns in Swift
//
//  Created by Mikhail Demidov on 09.02.2020.
//

import UIKit

private final class AppSession {
    init(dependencies: Dependencies) { }
    
    struct Dependencies {
    }
    
    func someMethod() {}
}

private let application = UIApplication.shared
private let fileManager = FileManager.default
private let userDefaults = UserDefaults.standard
private let notificationCenter = NotificationCenter.default

private final class AppDependencies {
    let appSession = AppSession(dependencies: AppSession.Dependencies())
}

private let appDependencies = AppDependencies()

private final class LaunchViewController: UIViewController {
    private let appSession: AppSession
    init(appSession: AppSession) {
        self.appSession = appSession
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.appSession.someMethod()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
