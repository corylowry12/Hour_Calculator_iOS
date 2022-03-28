//
//  ThemeColor.swift
//  HourCalculator
//
//  Created by Cory Lowry on 3/26/22.
//

import Foundation
import UIKit

class ThemeColor {
    
    func themeColor() -> UIColor {
        
        let userDefaults = UserDefaults.standard
        
        if userDefaults.integer(forKey: "accent") == 0 {
            changeIcon(nil)
            return UIColor(rgb: 0x26A69A)
        }
        
        else if userDefaults.integer(forKey: "accent") == 1 {
            changeIcon("purple_logo")
            return UIColor(rgb: 0x7841c4)
        }
        
        else if userDefaults.integer(forKey: "accent") == 2 {
            changeIcon("blue_logo")
            return UIColor(rgb: 0x347deb)
        }
        
        else if userDefaults.integer(forKey: "accent") == 3 {
            changeIcon("orange_logo")
            return UIColor(rgb: 0xfc783a)
        }
        
        else if userDefaults.integer(forKey: "accent") == 4 {
            changeIcon("red_logo")
            return UIColor(rgb: 0xc41d1d)
        }
        
        else if userDefaults.integer(forKey: "accent") == 5 {
            if userDefaults.integer(forKey: "accentRandom") == 0 {
                changeIcon(nil)
                return UIColor(rgb: 0x26A69A)
            
            }
            else if userDefaults.integer(forKey: "accentRandom") == 1 {
                changeIcon("purple_logo")
                return UIColor(rgb: 0x7841c4)
             
            }
            else if userDefaults.integer(forKey: "accentRandom") == 2 {
                changeIcon("blue_logo")
                return UIColor(rgb: 0x347deb)
            
            }
            else if userDefaults.integer(forKey: "accentRandom") == 3 {
                changeIcon("orange_logo")
                return UIColor(rgb: 0xfc783a)
              
            }
            else if userDefaults.integer(forKey: "accentRandom") == 4 {
                changeIcon("red_logo")
                return UIColor(rgb: 0xc41d1d)
            
            }
        }
        
        return UIColor(rgb: 0x26A69A)
    }
    
    func changeIcon(_ iconName: Any?) {
        if UIApplication.shared.responds(to: #selector(getter: UIApplication.supportsAlternateIcons)) && UIApplication.shared.supportsAlternateIcons {
            
            typealias setAlternateIconName = @convention(c) (NSObject, Selector, NSString?, @escaping (NSError) -> ()) -> ()
            
            let selectorString = "_setAlternateIconName:completionHandler:"
            
            let selector = NSSelectorFromString(selectorString)
            let imp = UIApplication.shared.method(for: selector)
            let method = unsafeBitCast(imp, to: setAlternateIconName.self)
            method(UIApplication.shared, selector, iconName as! NSString?, { _ in })
        }
    }
}
