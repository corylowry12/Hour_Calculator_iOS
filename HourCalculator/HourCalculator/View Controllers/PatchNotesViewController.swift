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
        tabBarController?.tabBar.items?[3].badgeValue = nil
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Standard AdMob phone banner height
        let bannerHeight: CGFloat = 50.0
        let extraPadding: CGFloat = 8.0
        let bottomInset = bannerHeight + extraPadding
        
        tableView.contentInset.bottom = bottomInset
        tableView.verticalScrollIndicatorInsets.bottom = bottomInset
    }
}
