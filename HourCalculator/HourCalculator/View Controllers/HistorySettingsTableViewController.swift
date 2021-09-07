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
    let historyAutomaticDeletion = UserDefaults.standard.integer(forKey: "automaticDeletion")
    let editDismiss = UserDefaults.standard.integer(forKey: "dismissEdit")
    
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
        
        
        //let userDefaults = UserDefaults.standard
        let indexPath = IndexPath(row: historyEnabled, section: 0)
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        
        let indexPathSort = IndexPath(row: historySort, section: 1)
        
        let indexPathAutomaticDeletion = IndexPath(row: historyAutomaticDeletion, section: 2)
        
        let indexPathEditDismiss = IndexPath(row: editDismiss, section: 3)
        
        tableView.delegate?.tableView!(tableView, didSelectRowAt: indexPath)
        tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPathSort)
        tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPathAutomaticDeletion)
        tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPathEditDismiss)
        
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
            
            tableView.cellForRow(at: [1, userDefaults.integer(forKey: "historySort")])?.accessoryType = .none
            userDefaults.set(indexPath.row, forKey: "historySort")
            tableView.cellForRow(at: [1, userDefaults.integer(forKey: "historySort")])?.accessoryType = .checkmark
            
        }
        else if indexPath.section == 2 {
            
            let userDefaults = UserDefaults.standard
            
            tableView.cellForRow(at: [2, userDefaults.integer(forKey: "automaticDeletion")])?.accessoryType = .none
            userDefaults.set(indexPath.row, forKey: "automaticDeletion")
            tableView.cellForRow(at: [2, userDefaults.integer(forKey: "automaticDeletion")])?.accessoryType = .checkmark
            
            if userDefaults.integer(forKey: "automaticDeletion") < hourItems.count &&
                userDefaults.integer(forKey: "automaticDeletion") != 0 {
                let alert = UIAlertController(title: "Warning", message: "You have more hours stored then entries allowed. Would you like to delete them?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [self]_ in
                    for i in (0...hourItems.count).reversed() {
                        if i > userDefaults.integer(forKey: "automaticDeletion") {
                            let hourToDelete = hourItems.first
                            context.delete(hourToDelete!)
                        }
                    }
                    (UIApplication.shared.delegate as! AppDelegate).saveContext()
                    tabBarController?.tabBar.items?[1].badgeValue = String(hourItems.count)
                }))
                alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { _ in
                    tableView.cellForRow(at: [2, userDefaults.integer(forKey: "automaticDeletion")])?.accessoryType = .none
                    userDefaults.set(0, forKey: "automaticDeletion")
                    tableView.cellForRow(at: [2, userDefaults.integer(forKey: "automaticDeletion")])?.accessoryType = .checkmark
                }))
                self.present(alert, animated: true, completion: nil)
            }
            
        }
        if indexPath.section == 3 {
            let userDefaults = UserDefaults.standard
            if indexPath.row == 0 {
                tableView.cellForRow(at: [3, userDefaults.integer(forKey: "dismissEdit")])?.accessoryType = .none
                userDefaults.set(0, forKey: "dismissEdit")
                tableView.cellForRow(at: [3, userDefaults.integer(forKey: "dismissEdit")])?.accessoryType = .checkmark
            }
            else {
                tableView.cellForRow(at: [3, userDefaults.integer(forKey: "dismissEdit")])?.accessoryType = .none
                userDefaults.set(1, forKey: "dismissEdit")
                tableView.cellForRow(at: [3, userDefaults.integer(forKey: "dismissEdit")])?.accessoryType = .checkmark
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
