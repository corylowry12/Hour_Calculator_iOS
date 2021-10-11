//
//  HistoryAutomaticDeletionSettings.swift
//  HourCalculator
//
//  Created by Cory Lowry on 10/10/21.
//

import Foundation
import UIKit
import CoreData

class HistoryAutomaticDeletionSettings: UITableViewController {
    
    let historyAutomaticDeletion = UserDefaults.standard.integer(forKey: "automaticDeletion")
    
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
        
        let indexPathAutomaticDeletion = IndexPath(row: historyAutomaticDeletion, section: 0)
        
        tableView.selectRow(at: indexPathAutomaticDeletion, animated: false, scrollPosition: .none)
        tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPathAutomaticDeletion)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let userDefaults = UserDefaults.standard
        
        tableView.cellForRow(at: [0, userDefaults.integer(forKey: "automaticDeletion")])?.accessoryType = .none
        userDefaults.set(indexPath.row, forKey: "automaticDeletion")
        tableView.cellForRow(at: [0, userDefaults.integer(forKey: "automaticDeletion")])?.accessoryType = .checkmark
        
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
                tableView.cellForRow(at: [0, userDefaults.integer(forKey: "automaticDeletion")])?.accessoryType = .none
                userDefaults.set(0, forKey: "automaticDeletion")
                tableView.cellForRow(at: [0, userDefaults.integer(forKey: "automaticDeletion")])?.accessoryType = .checkmark
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
}
