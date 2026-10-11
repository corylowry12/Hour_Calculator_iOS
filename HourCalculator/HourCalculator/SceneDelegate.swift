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
        guard let _ = (scene as? UIWindowScene) else { return }
        
        Siren.shared.wail()
        
        // 1. Apply theme style immediately before window is displayed
        let savedTheme = userDefaults.integer(forKey: "theme")
        let targetStyle: UIUserInterfaceStyle
        switch savedTheme {
        case 0:
            targetStyle = .light
        case 1:
            targetStyle = .dark
        default:
            targetStyle = .unspecified
        }
        window?.overrideUserInterfaceStyle = targetStyle
        
        // 2. Configure accent tint color
        if userDefaults.integer(forKey: "accent") == 0 {
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
            repeat {
                number = Int32.random(in: 0...4)
            } while number == userDefaults.integer(forKey: "accentRandom")
            
            var accent: UIColor!
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
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}
