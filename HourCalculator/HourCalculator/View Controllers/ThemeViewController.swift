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

class ThemeViewController: UITableViewController, UIColorPickerViewControllerDelegate {
    
    var window: UIWindow?
    @IBOutlet weak var customColorImageVIew: UIImageView!
    
    let storedThemeValue = UserDefaults.standard.integer(forKey: "theme")
    let storedAccentValue = UserDefaults.standard.integer(forKey: "accent")
    override func viewDidLoad() {
        super.viewDidLoad()
        
        customColorImageVIew.backgroundColor = UserDefaults().colorForKey(key: "accentColor")
        customColorImageVIew.layer.cornerRadius = customColorImageVIew.frame.size.width / 2
        
        tableView.allowsSelection = true
        
        tableView.allowsMultipleSelection = true
        
        let indexPath = IndexPath(row: storedThemeValue, section: 0)
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        //tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        //tableView.cellForRow(at: indexPath)?.isHighlighted = true
        tableView.delegate?.tableView!(tableView, didSelectRowAt: indexPath)
        
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
                
                let colorPickerVC = UIColorPickerViewController()
                colorPickerVC.selectedColor =  UserDefaults().colorForKey(key: "accentColor")!
                colorPickerVC.delegate = self
                colorPickerVC.supportsAlpha = false
                present(colorPickerVC, animated: true)
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
    
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        let color = viewController.selectedColor
        //viewController.selectedColor.
        self.view.window?.tintColor = color
        print("My Color \(color)")
        UserDefaults().setColor(color: color, forKey: "accentColor")
        customColorImageVIew.backgroundColor = UserDefaults().colorForKey(key: "accentColor")
    }
}
