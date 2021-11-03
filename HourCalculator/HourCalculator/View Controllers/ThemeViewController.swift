//
//  ThemeViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 6/26/21.
//

import UIKit

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}

class ThemeViewController: UITableViewController {
    
    var window: UIWindow?
    @IBOutlet weak var tintImageView: UIImageView!
    @IBOutlet weak var purpleImageView: UIImageView!
    @IBOutlet weak var turquoiseImageView: UIImageView!
    @IBOutlet weak var orangeImageView: UIImageView!
    @IBOutlet weak var redImageView: UIImageView!
    @IBOutlet weak var randomImageView: UIImageView!
    
    let storedThemeValue = UserDefaults.standard.integer(forKey: "theme")
    let storedAccentValue = UserDefaults.standard.integer(forKey: "accent")
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tintImageView.layer.cornerRadius = tintImageView.frame.size.width / 2
        purpleImageView.layer.cornerRadius = purpleImageView.frame.size.width / 2
        turquoiseImageView.layer.cornerRadius = turquoiseImageView.frame.size.width / 2
        orangeImageView.layer.cornerRadius = orangeImageView.frame.size.width / 2
        redImageView.layer.cornerRadius = redImageView.frame.size.width / 2
        randomImageView.layer.cornerRadius = randomImageView.frame.size.width / 2
        
        tableView.allowsSelection = true
        
        tableView.allowsMultipleSelection = true
        
        if UserDefaults.standard.value(forKey: "accent") == nil {
            UserDefaults.standard.set(0, forKey: "accent")
        }
        
        let indexPath = IndexPath(row: storedThemeValue, section: 0)
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        //tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        //tableView.cellForRow(at: indexPath)?.isHighlighted = true
        tableView.delegate?.tableView!(tableView, didSelectRowAt: indexPath)
        
        let indexPathAccent = IndexPath(row: storedAccentValue, section: 1)
        tableView.selectRow(at: indexPathAccent, animated: false, scrollPosition: .none)
        tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPathAccent)
        
        let indexPathFont = IndexPath(row: UserDefaults.standard.integer(forKey: "fontName"), section: 2)
        tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPathFont)
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            
            let userDefaults = UserDefaults.standard
            
            if indexPath.row == 0 {
                tableView.cellForRow(at: [0, userDefaults.integer(forKey: "theme")])?.accessoryType = .none
              
                UIView.transition(with: view.window ?? UIWindow(), duration: 0.5, options: [.transitionCrossDissolve, .curveEaseInOut], animations: {
                    self.view.window?.overrideUserInterfaceStyle = .light
                }, completion: nil)
                userDefaults.set(0, forKey: "theme")
                tableView.cellForRow(at: [0, userDefaults.integer(forKey: "theme")])?.accessoryType = .checkmark
            }
            else if indexPath.row == 1 {
                tableView.cellForRow(at: [0, userDefaults.integer(forKey: "theme")])?.accessoryType = .none
                UIView.transition(with: view.window ?? UIWindow(), duration: 0.5, options: [.transitionCrossDissolve, .curveEaseInOut], animations: {
                    self.view.window?.overrideUserInterfaceStyle = .dark
                }, completion: nil)
                userDefaults.set(1, forKey: "theme")
                tableView.cellForRow(at: [0, userDefaults.integer(forKey: "theme")])?.accessoryType = .checkmark
            }
            else if indexPath.row == 2 {
                tableView.cellForRow(at: [0, userDefaults.integer(forKey: "theme")])?.accessoryType = .none
                UIView.transition(with: view.window ?? UIWindow(), duration: 0.5, options: [.transitionCrossDissolve, .curveEaseInOut], animations: {
                    self.view.window?.overrideUserInterfaceStyle = .unspecified
                }, completion: nil)
                userDefaults.set(2, forKey: "theme")
                tableView.cellForRow(at: [0, userDefaults.integer(forKey: "theme")])?.accessoryType = .checkmark
            }
        }
        else if indexPath.section == 1 {
            if indexPath.row == 0 {
                tableView.cellForRow(at: [1, UserDefaults.standard.integer(forKey: "accent")])?.accessoryType = .none
                let accent = UIColor(rgb: 0x26A69A)
                UIView.transition(with: view.window ?? UIWindow(), duration: 0.5, options: [.transitionCrossDissolve, .curveEaseInOut], animations: {
                    self.view.window?.tintColor = accent
                }, completion: nil)
                UserDefaults.standard.set(0, forKey: "accent")
                changeIcon(nil)
                tableView.cellForRow(at: [1, UserDefaults.standard.integer(forKey: "accent")])?.accessoryType = .checkmark
            }
            else if indexPath.row == 1 {
                tableView.cellForRow(at: [1, UserDefaults.standard.integer(forKey: "accent")])?.accessoryType = .none
                let accent = UIColor(rgb: 0x7841c4)
                UIView.transition(with: view.window ?? UIWindow(), duration: 0.5, options: [.transitionCrossDissolve, .curveEaseInOut], animations: {
                    self.view.window?.tintColor = accent
                }, completion: nil)
                UserDefaults.standard.set(1, forKey: "accent")
                changeIcon("purple_logo")
                tableView.cellForRow(at: [1, UserDefaults.standard.integer(forKey: "accent")])?.accessoryType = .checkmark
            }
            else if indexPath.row == 2 {
                tableView.cellForRow(at: [1, UserDefaults.standard.integer(forKey: "accent")])?.accessoryType = .none
                let accent = UIColor(rgb: 0x347deb)
                UIView.transition(with: view.window ?? UIWindow(), duration: 0.5, options: [.transitionCrossDissolve, .curveEaseInOut], animations: {
                    self.view.window?.tintColor = accent
                }, completion: nil)
                UserDefaults.standard.set(2, forKey: "accent")
                changeIcon("blue_logo")
                tableView.cellForRow(at: [1, UserDefaults.standard.integer(forKey: "accent")])?.accessoryType = .checkmark
            }
            else if indexPath.row == 3 {
                tableView.cellForRow(at: [1, UserDefaults.standard.integer(forKey: "accent")])?.accessoryType = .none
                let accent = UIColor(rgb: 0xfc783a)
                UIView.transition(with: view.window ?? UIWindow(), duration: 0.5, options: [.transitionCrossDissolve, .curveEaseInOut], animations: {
                    self.view.window?.tintColor = accent
                }, completion: nil)
                UserDefaults.standard.set(3, forKey: "accent")
                changeIcon("orange_logo")
                tableView.cellForRow(at: [1, UserDefaults.standard.integer(forKey: "accent")])?.accessoryType = .checkmark
            }
            else if indexPath.row == 4 {
                tableView.cellForRow(at: [1, UserDefaults.standard.integer(forKey: "accent")])?.accessoryType = .none
                let accent = UIColor(rgb: 0xc41d1d)
                UIView.transition(with: view.window ?? UIWindow(), duration: 0.5, options: [.transitionCrossDissolve, .curveEaseInOut], animations: {
                    self.view.window?.tintColor = accent
                }, completion: nil)
                UserDefaults.standard.set(4, forKey: "accent")
                changeIcon("red_logo")
                tableView.cellForRow(at: [1, UserDefaults.standard.integer(forKey: "accent")])?.accessoryType = .checkmark
            }
            
            else if indexPath.row == 5 {
                tableView.cellForRow(at: [1, UserDefaults.standard.integer(forKey: "accent")])?.accessoryType = .none
                let number = Int.random(in: 0...4)
                var accent : UIColor!
                if number == 0 {
                    accent = UIColor(rgb: 0x26A69A)
                    changeIcon(nil)
                }
                else if number == 1 {
                    accent = UIColor(rgb: 0x7841c4)
                    changeIcon("purple_logo")
                }
                else if number == 2 {
                    accent = UIColor(rgb: 0x347deb)
                    changeIcon("blue_logo")
                }
                else if number == 3 {
                    accent = UIColor(rgb: 0xfc783a)
                    changeIcon("orange_logo")
                }
                else if number == 4 {
                    accent = UIColor(rgb: 0xc41d1d)
                    changeIcon("red_logo")
                }
                UIView.transition(with: view.window ?? UIWindow(), duration: 0.5, options: [.transitionCrossDissolve, .curveEaseInOut], animations: {
                    self.view.window?.tintColor = accent
                }, completion: nil)
                UserDefaults.standard.set(5, forKey: "accent")
                tableView.cellForRow(at: [1, UserDefaults.standard.integer(forKey: "accent")])?.accessoryType = .checkmark
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        // Find any selected row in this section
        if let selectedIndexPath = tableView.indexPathsForSelectedRows?.first(where: {
            $0.section == indexPath.section
        }) {
            // Deselect the row
            tableView.deselectRow(at: selectedIndexPath, animated: false)
            // deselectRow doesn't fire the delegate method so need to
            // unset the checkmark here
            tableView.cellForRow(at: selectedIndexPath)?.accessoryType = .none
        }
        return indexPath
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
