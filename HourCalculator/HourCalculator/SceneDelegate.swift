//
//  SceneDelegate.swift
//  HourCalculator
//
//  Created by Cory Lowry on 6/22/21.
//

import UIKit
import Siren

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    let userDefaults = UserDefaults.standard
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        
        Siren.shared.wail()
        
        /*if userDefaults.integer(forKey: "accent") == 0 {
            window?.tintColor = UIColor(rgb: 0x26A69A)
        }
        else if userDefaults.integer(forKey: "accent") == 1 {
            window?.tintColor = UIColor(rgb: 0x7841c4)
        }
        else if userDefaults.integer(forKey: "accent") == 2 {
            window?.tintColor = UIColor(rgb: 0x347deb)
        }
        else if userDefaults.integer(forKey: "accent") == 3 {
            window?.tintColor = UIColor(rgb: 0xfc783a)
        }
        else if userDefaults.integer(forKey: "accent") == 4 {
            window?.tintColor = UIColor(rgb: 0xc41d1d)
        }
        else if userDefaults.integer(forKey: "accent") == 5 {
            var number: Int32!
            do {
                number = Int32.random(in: 0...4)
            }
            while number == userDefaults.integer(forKey: "accentRandom") {
                number = Int32.random(in: 0...4)
            }
            //let number = Int.random(in: 0...4)
            var accent : UIColor!
            if number == 0 {
                accent = UIColor(rgb: 0x26A69A)
            }
            else if number == 1 {
                accent = UIColor(rgb: 0x7841c4)
            }
            else if number == 2 {
                accent = UIColor(rgb: 0x347deb)
            }
            else if number == 3 {
                accent = UIColor(rgb: 0xfc783a)
            }
            else if number == 4 {
                accent = UIColor(rgb: 0xc41d1d)
            }
            
            window?.tintColor = accent
            userDefaults.setValue(number, forKey: "accentRandom")
        }*/
        
        window?.tintColor = UserDefaults().colorForKey(key: "accentColor")
        guard let _ = (scene as? UIWindowScene) else { return }
        
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
}

