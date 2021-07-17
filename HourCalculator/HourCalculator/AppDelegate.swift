//
//  AppDelegate.swift
//  HourCalculator
//
//  Created by Cory Lowry on 6/22/21.
//

import UIKit
import GoogleMobileAds
import CoreData
import Siren
import Instabug

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
        Instabug.start(withToken: "12c913aa56061e961162c27164e3a51e", invocationEvents: .shake)
        
        Siren.shared.wail()
        
        Siren.shared.rulesManager = RulesManager(globalRules: .persistent, showAlertAfterCurrentVersionHasBeenReleasedForDays: 5)
        
        return true
        
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func application(_ application: UIApplication, shouldSaveSecureApplicationState coder: NSCoder) -> Bool {
        return true
    }
    
    func application(_ application: UIApplication, shouldRestoreSecureApplicationState coder: NSCoder) -> Bool {
        return true
    }
    
    // MARK: - Core Data Stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        
        let container = NSPersistentContainer(name: "StoredHours")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in if let error = error as NSError? {
            fatalError("Unresolved error \(error), \(error.userInfo)")
        }})
        return container
    }()
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

