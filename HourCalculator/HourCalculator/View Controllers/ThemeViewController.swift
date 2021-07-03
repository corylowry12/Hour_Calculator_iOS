//
//  ThemeViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 6/26/21.
//

import UIKit

class ThemeViewController: UITableViewController {
    
    var window: UIWindow?
    
    let storedThemeValue = UserDefaults.standard.integer(forKey: "theme")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.allowsSelection = true
        
        tableView.allowsMultipleSelection = false
        
        let indexPath = IndexPath(row: storedThemeValue, section: 0)
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        //tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        //tableView.cellForRow(at: indexPath)?.isHighlighted = true
        tableView.delegate?.tableView!(tableView, didSelectRowAt: indexPath)
        
        //segmentedControl.selectedSegmentIndex = storedThemeValue
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
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
}
