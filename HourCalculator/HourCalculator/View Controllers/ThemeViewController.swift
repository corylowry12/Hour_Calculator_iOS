//
//  ThemeViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 6/26/21.
//

import UIKit
import Instabug

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
    
    let storedThemeValue = UserDefaults.standard.integer(forKey: "theme")
    let storedAccentValue = UserDefaults.standard.integer(forKey: "accent")
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tintImageView.layer.cornerRadius = tintImageView.frame.size.width / 2
        purpleImageView.layer.cornerRadius = purpleImageView.frame.size.width / 2
        turquoiseImageView.layer.cornerRadius = turquoiseImageView.frame.size.width / 2
        orangeImageView.layer.cornerRadius = orangeImageView.frame.size.width / 2
        redImageView.layer.cornerRadius = redImageView.frame.size.width / 2
        
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
        
        //segmentedControl.selectedSegmentIndex = storedThemeValue
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        BugReporting.enabled = true
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
        if storedThemeValue != indexPath.row {
            tableView.cellForRow(at: [0, storedThemeValue])?.accessoryType = .none
        }
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(indexPath.row, forKey: "theme")
        
        if indexPath.row == 0 {
            view.window?.overrideUserInterfaceStyle = .light
            userDefaults.set(0, forKey: "theme")
        }
        else if indexPath.row == 1 {
            view.window?.overrideUserInterfaceStyle = .dark
            userDefaults.set(1, forKey: "theme")
        }
        else if indexPath.row == 2 {
            view.window?.overrideUserInterfaceStyle = .unspecified
            userDefaults.set(2, forKey: "theme")
        }
        }
        else if indexPath.section == 1 {
            print("hello world")
            if storedThemeValue != indexPath.row {
                tableView.cellForRow(at: [1, storedThemeValue])?.accessoryType = .none
            }
            if indexPath.row == 0 {
                let accent = UIColor(rgb: 0x26A69A)
                view.window?.tintColor = accent
                UserDefaults.standard.set(0, forKey: "accent")
                changeIcon(nil)
            }
            else if indexPath.row == 1 {
                let accent = UIColor(rgb: 0x7841c4)
                view.window?.tintColor = accent
                UserDefaults.standard.set(1, forKey: "accent")
                changeIcon("purple_logo")
            }
            else if indexPath.row == 2 {
                let accent = UIColor(rgb: 0x347deb)
                view.window?.tintColor = accent
                UserDefaults.standard.set(2, forKey: "accent")
                changeIcon("blue_logo")
            }
            else if indexPath.row == 3 {
                let accent = UIColor(rgb: 0xfc783a)
                view.window?.tintColor = accent
                UserDefaults.standard.set(3, forKey: "accent")
                changeIcon("orange_logo")
            }
            else if indexPath.row == 4 {
                let accent = UIColor(rgb: 0xc41d1d)
                view.window?.tintColor = accent
                UserDefaults.standard.set(4, forKey: "accent")
                changeIcon("red_logo")
            }
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
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
    
   
    
    @IBAction func themeSelectionValueChanged(_ sender: UISegmentedControl) {
        let userDefaults = UserDefaults.standard
        if sender.selectedSegmentIndex == 0 {
            view.window!.overrideUserInterfaceStyle = .light
            userDefaults.set(0, forKey: "theme")
        }
        else if sender.selectedSegmentIndex == 1 {
            view.window!.overrideUserInterfaceStyle = .dark
            userDefaults.set(1, forKey: "theme")
        }
        if sender.selectedSegmentIndex == 2 {
            view.window!.overrideUserInterfaceStyle = .unspecified
            userDefaults.set(2, forKey: "theme")
        }
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
