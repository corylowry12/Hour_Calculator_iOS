//
//  TimeCardSettingsViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 8/24/21.
//

import Foundation
import UIKit

class TimeCardSettingsViewController: UITableViewController {
    
    let userDefaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorStyle = .singleLine
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateCheckmarks()
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
    
    private func updateCheckmarks() {
        let currentChoice = userDefaults.integer(forKey: "saveImages")
        let totalRows = tableView.numberOfRows(inSection: 0)
        
        for row in 0..<totalRows {
            let cell = tableView.cellForRow(at: IndexPath(row: row, section: 0))
            cell?.accessoryType = (row == currentChoice) ? .checkmark : .none
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Deselect immediately so UIKit never suppresses the separator line
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard indexPath.section == 0 else { return }
        
        userDefaults.set(indexPath.row, forKey: "saveImages")
        updateCheckmarks()
    }
}
