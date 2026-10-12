//
//  HistorySettingsTableViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 7/1/21.
//

import UIKit
import CoreData

class HistorySettingsTableViewController: UITableViewController {
    
    let userDefaults = UserDefaults.standard
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var hourItems: [Hours] {
        do {
            let fetchrequest = NSFetchRequest<Hours>(entityName: "Hours")
            let sort = NSSortDescriptor(key: #keyPath(Hours.date), ascending: false)
            fetchrequest.sortDescriptors = [sort]
            return try context.fetch(fetchrequest)
        } catch {
            print("Couldn't fetch data")
            return []
        }
    }
    
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
        let historyEnabled = userDefaults.integer(forKey: "historyEnabled")
        let historySort = userDefaults.integer(forKey: "historySort")
        let editDismiss = userDefaults.integer(forKey: "dismissEdit")
        
        // Section 0: Toggle History
        for row in 0..<tableView.numberOfRows(inSection: 0) {
            let cell = tableView.cellForRow(at: IndexPath(row: row, section: 0))
            cell?.accessoryType = (row == historyEnabled) ? .checkmark : .none
        }
        
        // Section 1: History Sort
        for row in 0..<tableView.numberOfRows(inSection: 1) {
            let cell = tableView.cellForRow(at: IndexPath(row: row, section: 1))
            cell?.accessoryType = (row == historySort) ? .checkmark : .none
        }
        
        // Section 2: Dismiss Edit View
        for row in 0..<tableView.numberOfRows(inSection: 2) {
            let cell = tableView.cellForRow(at: IndexPath(row: row, section: 2))
            cell?.accessoryType = (row == editDismiss) ? .checkmark : .none
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Deselect immediately so UIKit does not suppress the row's separator
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            userDefaults.set(indexPath.row, forKey: "historyEnabled")
            
            for row in 0..<tableView.numberOfRows(inSection: 0) {
                tableView.cellForRow(at: IndexPath(row: row, section: 0))?.accessoryType = (row == indexPath.row) ? .checkmark : .none
            }
            
            if indexPath.row == 0 {
                tabBarController?.tabBar.items?[1].isEnabled = true
                tabBarController?.tabBar.items?[1].badgeValue = String(hourItems.count)
            } else {
                tabBarController?.tabBar.items?[1].isEnabled = false
                tabBarController?.tabBar.items?[1].badgeValue = nil
            }
        }
        else if indexPath.section == 1 {
            userDefaults.set(indexPath.row, forKey: "historySort")
            for row in 0..<tableView.numberOfRows(inSection: 1) {
                tableView.cellForRow(at: IndexPath(row: row, section: 1))?.accessoryType = (row == indexPath.row) ? .checkmark : .none
            }
        }
        else if indexPath.section == 2 {
            userDefaults.set(indexPath.row, forKey: "dismissEdit")
            for row in 0..<tableView.numberOfRows(inSection: 2) {
                tableView.cellForRow(at: IndexPath(row: row, section: 2))?.accessoryType = (row == indexPath.row) ? .checkmark : .none
            }
        }
    }
}
