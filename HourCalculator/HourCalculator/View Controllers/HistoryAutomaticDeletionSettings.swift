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
    
    let userDefaults = UserDefaults.standard
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var hourItems: [Hours] {
        let fetchrequest = NSFetchRequest<Hours>(entityName: "Hours")
        fetchrequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Hours.date), ascending: false)]
        do {
            return try context.fetch(fetchrequest)
        } catch {
            print("Couldn't fetch data: \(error)")
            return []
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorStyle = .singleLine
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateCheckmarks()
    }
    
    private func updateCheckmarks() {
        let currentSelection = userDefaults.integer(forKey: "automaticDeletion")
        let totalRows = tableView.numberOfRows(inSection: 0)
        
        for row in 0..<totalRows {
            let cell = tableView.cellForRow(at: IndexPath(row: row, section: 0))
            cell?.accessoryType = (row == currentSelection) ? .checkmark : .none
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Deselect immediately so separator lines are never suppressed
        tableView.deselectRow(at: indexPath, animated: true)
        
        let previousSelection = userDefaults.integer(forKey: "automaticDeletion")
        let newSelection = indexPath.row
        
        userDefaults.set(newSelection, forKey: "automaticDeletion")
        updateCheckmarks()
        
        let currentCount = hourItems.count
        if newSelection != 0 && newSelection < currentCount {
            let alert = UIAlertController(
                title: "Warning",
                message: "You have more hours stored than entries allowed. Would you like to delete the older entries?",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { [weak self] _ in
                guard let self = self else { return }
                self.purgeExcessHours(keepCount: newSelection)
            }))
            
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { [weak self] _ in
                // Revert back to the previous selection
                self?.userDefaults.set(previousSelection, forKey: "automaticDeletion")
                self?.updateCheckmarks()
            }))
            
            present(alert, animated: true)
        }
    }
    
    private func purgeExcessHours(keepCount: Int) {
        // Fetch items sorted oldest first to safely delete only the overflow entries
        let fetchRequest = NSFetchRequest<Hours>(entityName: "Hours")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Hours.date), ascending: true)]
        
        guard let allHours = try? context.fetch(fetchRequest), allHours.count > keepCount else { return }
        
        let excessCount = allHours.count - keepCount
        for i in 0..<excessCount {
            context.delete(allHours[i])
        }
        
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        
        let remainingCount = hourItems.count
        tabBarController?.tabBar.items?[1].badgeValue = remainingCount > 0 ? String(remainingCount) : nil
    }
}
