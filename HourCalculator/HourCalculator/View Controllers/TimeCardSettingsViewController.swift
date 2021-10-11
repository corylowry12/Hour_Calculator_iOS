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
        
        tableView.allowsSelection = true
        
        self.tableView.delegate = self
        
        //tableView.allowsMultipleSelection = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        let indexPath = IndexPath(row: userDefaults.integer(forKey: "saveImages"), section: 0)
        
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            print("index is \(indexPath.row)")
            tableView.cellForRow(at: [0, userDefaults.integer(forKey: "saveImages")])?.accessoryType = .none
            userDefaults.set(indexPath.row, forKey: "saveImages")
            tableView.cellForRow(at: [0, userDefaults.integer(forKey: "saveImages")])?.accessoryType = .checkmark
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
}
