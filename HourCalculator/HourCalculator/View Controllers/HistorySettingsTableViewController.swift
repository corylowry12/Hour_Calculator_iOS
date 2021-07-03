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
        
        self.tableView.delegate = self
        
        tableView.allowsSelection = true
        
        tableView.allowsMultipleSelection = false
        
        let indexPath = IndexPath(row: historyEnabled, section: 0)
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)

        tableView.delegate?.tableView!(tableView, didSelectRowAt: indexPath)
        
        print(userDefaults.integer(forKey: "historyEnabled"))
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
    }

}
