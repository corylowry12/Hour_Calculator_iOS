//
//  ThemeViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 6/26/21.
//

import UIKit

class ThemeViewController: UIViewController {
    
    var window: UIWindow?
 
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let storedThemeValue = UserDefaults.standard.integer(forKey: "theme")
        
        segmentedControl.selectedSegmentIndex = storedThemeValue
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
