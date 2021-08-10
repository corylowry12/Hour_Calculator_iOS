//
//  HistorySettingsTableViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 7/1/21.
//

import UIKit
import CoreData
import Instabug

class HistorySettingsTableViewController: UITableViewController {
    
    let historyEnabled = UserDefaults.standard.integer(forKey: "historyEnabled")
    let historySort = UserDefaults.standard.integer(forKey: "historySort")
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var hourItems: [Hours] {
        
        do {
            let fetchrequest = NSFetchRequest<Hours>(entityName: "Hours")
            let sort = NSSortDescriptor(key: #keyPath(Hours.date), ascending: false)
            fetchrequest.sortDescriptors = [sort]
            return try context.fetch(fetchrequest)
            
        } catch {
            
            print("Couldn't fetch data")
            
        }
        
        return [Hours]()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let userDefaults = UserDefaults.standard
        
        if userDefaults.value(forKey: "historyEnabled") == nil{
            userDefaults.set(0, forKey: "historyEnabled")
        }
        
        if userDefaults.value(forKey: "historySort") == nil {
            userDefaults.set(0, forKey: "historySort")
        }
        
        self.tableView.delegate = self
        
        tableView.allowsSelection = true
        
        tableView.allowsMultipleSelection = true
        
        let indexPath = IndexPath(row: historyEnabled, section: 0)
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        
        let indexPathSort = IndexPath(row: historySort, section: 1)
        
        tableView.delegate?.tableView!(tableView, didSelectRowAt: indexPath)
        tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPathSort)
        
        print(userDefaults.integer(forKey: "historyEnabled"))
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        BugReporting.enabled = true
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            
            let userDefaults = UserDefaults.standard
            
            if indexPath.row == 0 {
                tableView.cellForRow(at: [0, userDefaults.integer(forKey: "historyEnabled")])?.accessoryType = .none
                userDefaults.set(0, forKey: "historyEnabled")
                tableView.cellForRow(at: [0, userDefaults.integer(forKey: "historyEnabled")])?.accessoryType = .checkmark
                tabBarController?.tabBar.items?[1].isEnabled = true
                tabBarController?.tabBar.items?[1].badgeValue = String(hourItems.count)
            }
            else if indexPath.row == 1 {
                tableView.cellForRow(at: [0, userDefaults.integer(forKey: "historyEnabled")])?.accessoryType = .none
                userDefaults.set(1, forKey: "historyEnabled")
                tableView.cellForRow(at: [0, userDefaults.integer(forKey: "historyEnabled")])?.accessoryType = .checkmark
                tabBarController?.tabBar.items?[1].isEnabled = false
                tabBarController?.tabBar.items?[1].badgeValue = nil
            }
        }
        else if indexPath.section == 1 {
            
            let userDefaults = UserDefaults.standard
            
            if indexPath.row == 0 {
                tableView.cellForRow(at: [1, userDefaults.integer(forKey: "historySort")])?.accessoryType = .none
                userDefaults.set(0, forKey: "historySort")
                tableView.cellForRow(at: [1, userDefaults.integer(forKey: "historySort")])?.accessoryType = .checkmark
            }
            
            else if indexPath.row == 1 {
                tableView.cellForRow(at: [1, userDefaults.integer(forKey: "historySort")])?.accessoryType = .none
                userDefaults.set(1, forKey: "historySort")
                tableView.cellForRow(at: [1, userDefaults.integer(forKey: "historySort")])?.accessoryType = .checkmark
            }
            else if indexPath.row == 2 {
                tableView.cellForRow(at: [1, userDefaults.integer(forKey: "historySort")])?.accessoryType = .none
                userDefaults.set(2, forKey: "historySort")
                tableView.cellForRow(at: [1, userDefaults.integer(forKey: "historySort")])?.accessoryType = .checkmark
            }
            else if indexPath.row == 3 {
                tableView.cellForRow(at: [1, userDefaults.integer(forKey: "historySort")])?.accessoryType = .none
                userDefaults.set(3, forKey: "historySort")
                tableView.cellForRow(at: [1, userDefaults.integer(forKey: "historySort")])?.accessoryType = .checkmark
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let selectedIndexPath = tableView.indexPathsForSelectedRows?.first(where: {
            $0.section == indexPath.section
        }) {
            tableView.deselectRow(at: selectedIndexPath, animated: false)
            tableView.cellForRow(at: selectedIndexPath)?.accessoryType = .none
        }
        return indexPath
    }
}
