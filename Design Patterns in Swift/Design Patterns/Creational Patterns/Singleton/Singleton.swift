//
//  Singleton.swift
//  Design Patterns in Swift
//
//  Created by Mikhail Demidov on 09.02.2020.
//

import UIKit

private final class AppSession {
    private init() { }
    
    static let shared = AppSession()
    
    func someMethod() {}
}

private let application = UIApplication.shared
private let fileManager = FileManager.default
private let userDefaults = UserDefaults.standard
private let notificationCenter = NotificationCenter.default
