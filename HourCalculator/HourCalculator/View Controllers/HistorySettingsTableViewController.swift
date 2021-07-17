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
            if historyEnabled != indexPath.row {
                tableView.cellForRow(at: [0, historyEnabled])?.accessoryType = .none
            }
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
            
            let userDefaults = UserDefaults.standard
            userDefaults.setValue(indexPath.row, forKey: "historyEnabled")
            
            if indexPath.row == 0 {
                userDefaults.set(0, forKey: "historyEnabled")
                tabBarController?.tabBar.items?[1].isEnabled = true
                tabBarController?.tabBar.items?[1].badgeValue = String(hourItems.count)
            }
            else if indexPath.row == 1 {
                userDefaults.set(1, forKey: "historyEnabled")
                tabBarController?.tabBar.items?[1].isEnabled = false
                tabBarController?.tabBar.items?[1].badgeValue = nil
            }
            
            print(userDefaults.integer(forKey: "historyEnabled"))
            }
            else if indexPath.section == 1 {
                if historySort != indexPath.row {
                    tableView.cellForRow(at: [1, historySort])?.accessoryType = .none
                }
                tableView.cellForRow(at: [1, indexPath.row])?.accessoryType = .checkmark
                
                if indexPath.row == 0 {
                    print("row 0")
                    UserDefaults.standard.set(0, forKey: "historySort")
                }
                
                else if indexPath.row == 1 {
                    print("row 1")
                    UserDefaults.standard.set(1, forKey: "historySort")
                }
                else if indexPath.row == 2 {
                    print("row 2")
                    UserDefaults.standard.set(2, forKey: "historySort")
                }
                else if indexPath.row == 3 {
                    print("row 3")
                    UserDefaults.standard.set(3, forKey: "historySort")
                }
            }
        }
        
        override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
            //tableView.cellForRow(at: indexPath)?.accessoryType = .none
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
