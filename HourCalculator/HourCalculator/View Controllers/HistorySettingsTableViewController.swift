//
//  HistorySettingsTableViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 7/1/21.
//

import UIKit
import CoreData


class HistorySettingsTableViewController: UITableViewController {
    
    let historyEnabled = UserDefaults.standard.integer(forKey: "historyEnabled")
    let historySort = UserDefaults.standard.integer(forKey: "historySort")
    let editDismiss = UserDefaults.standard.integer(forKey: "dismissEdit")
    
    let storedThemeValue = UserDefaults.standard.integer(forKey: "theme")
    
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
        
        let indexPath = IndexPath(row: historyEnabled, section: 0)
        let indexPathSort = IndexPath(row: historySort, section: 1)
        let indexPathEditDismiss = IndexPath(row: editDismiss, section: 2)
        
        print("edit index is \(indexPathEditDismiss)")
        
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        tableView.selectRow(at: indexPathSort, animated: false, scrollPosition: .none)
        tableView.selectRow(at: indexPathEditDismiss, animated: false, scrollPosition: .none)
        
        tableView.delegate?.tableView!(tableView, didSelectRowAt: indexPath)
        tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPathSort)
        tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPathEditDismiss)
        
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
            
            tableView.cellForRow(at: [1, userDefaults.integer(forKey: "historySort")])?.accessoryType = .none
            userDefaults.set(indexPath.row, forKey: "historySort")
            tableView.cellForRow(at: [1, userDefaults.integer(forKey: "historySort")])?.accessoryType = .checkmark
            
        }
        else if indexPath.section == 2 {
            
            let userDefaults = UserDefaults.standard
            if indexPath.row == 0 {
                tableView.cellForRow(at: [2, userDefaults.integer(forKey: "dismissEdit")])?.accessoryType = .none
                userDefaults.set(0, forKey: "dismissEdit")
                tableView.cellForRow(at: [2, userDefaults.integer(forKey: "dismissEdit")])?.accessoryType = .checkmark
            }
            else {
                tableView.cellForRow(at: [2, userDefaults.integer(forKey: "dismissEdit")])?.accessoryType = .none
                userDefaults.set(1, forKey: "dismissEdit")
                tableView.cellForRow(at: [2, userDefaults.integer(forKey: "dismissEdit")])?.accessoryType = .checkmark
            }
            
        }
    }
 
   /* override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let selectedIndexPath = tableView.indexPathsForSelectedRows?.first(where: {
            $0.section == indexPath.section
        }) {
            tableView.deselectRow(at: selectedIndexPath, animated: false)
            tableView.cellForRow(at: selectedIndexPath)?.accessoryType = .none
        }
        return indexPath
    }*/
}
