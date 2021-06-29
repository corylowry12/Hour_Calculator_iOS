//
//  PatchNotesViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 6/26/21.
//

import UIKit

class PatchNotesViewController: UITableViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        
        tableView.tableFooterView = UIView()
        
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let userDefaults = UserDefaults.standard
        userDefaults.set(appVersion, forKey: "appVersion")
        tabBarController?.tabBar.items?[2].badgeValue = nil
    }
}
