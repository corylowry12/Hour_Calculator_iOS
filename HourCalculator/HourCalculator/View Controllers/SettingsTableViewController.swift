//
//  SettingsViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 6/24/21.
//

import UIKit
import CoreData
import UserNotifications
import Darwin

class SettingsTableViewController: UITableViewController {
    
    @IBOutlet weak var patchNotesCell: SettingsTableViewCell!
    let userDefaults = UserDefaults.standard
    
    @IBOutlet var hourSwitch: UISwitch!
    
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
    
    var timeCards: [TimeCards] {
        do {
            var sort = NSSortDescriptor(key: #keyPath(TimeCards.week), ascending: false)
            let fetchrequest = NSFetchRequest<TimeCards>(entityName: "TimeCards")
            let sortChoice = userDefaults.integer(forKey: "timeCardsSort")
            if sortChoice == 0 {
                sort = NSSortDescriptor(key: #keyPath(TimeCards.week), ascending: false)
            } else if sortChoice == 1 {
                sort = NSSortDescriptor(key: #keyPath(TimeCards.week), ascending: true)
            } else if sortChoice == 2 {
                sort = NSSortDescriptor(key: #keyPath(TimeCards.total), ascending: true)
            } else if sortChoice == 3 {
                sort = NSSortDescriptor(key: #keyPath(TimeCards.total), ascending: false)
            } else if sortChoice == 4 {
                sort = NSSortDescriptor(key: #keyPath(TimeCards.name), ascending: true)
            } else if sortChoice == 5 {
                sort = NSSortDescriptor(key: #keyPath(TimeCards.name), ascending: false)
            }
            fetchrequest.sortDescriptors = [sort]
            return try context.fetch(fetchrequest)
        } catch {
            print("Couldn't fetch data")
        }
        return [TimeCards]()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let accent = userDefaults.integer(forKey: "accent")
        if accent == 0 {
            hourSwitch?.onTintColor = UIColor(rgb: 0x26A69A)
        } else if accent == 1 {
            hourSwitch?.onTintColor = UIColor(rgb: 0x7841c4)
        } else if accent == 2 {
            hourSwitch?.onTintColor = UIColor(rgb: 0x347deb)
        } else if accent == 3 {
            hourSwitch?.onTintColor = UIColor(rgb: 0xfc783a)
        } else if accent == 4 {
            hourSwitch?.onTintColor = UIColor(rgb: 0xc41d1d)
        } else if accent == 5 {
            let randomAccent = userDefaults.integer(forKey: "accentRandom")
            if randomAccent == 0 {
                hourSwitch?.onTintColor = UIColor(rgb: 0x26A69A)
            } else if randomAccent == 1 {
                hourSwitch?.onTintColor = UIColor(rgb: 0x7841c4)
            } else if randomAccent == 2 {
                hourSwitch?.onTintColor = UIColor(rgb: 0x347deb)
            } else if randomAccent == 3 {
                hourSwitch?.onTintColor = UIColor(rgb: 0xfc783a)
            } else if randomAccent == 4 {
                hourSwitch?.onTintColor = UIColor(rgb: 0xc41d1d)
            }
        }
        
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        
        if userDefaults.value(forKey: "appVersion") == nil || (userDefaults.value(forKey: "appVersion") as? String) != appVersion {
            let size: CGFloat = 22
            let width = max(size, 0.7 * size * 1)
            let badge = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: size))
            badge.text = "1"
            badge.layer.cornerRadius = size / 2
            badge.layer.masksToBounds = true
            badge.textAlignment = .center
            badge.textColor = UIColor.white
            badge.backgroundColor = UIColor.red
            patchNotesCell?.accessoryView = badge
        } else {
            patchNotesCell?.accessoryView = nil
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        let cellText = (cell.textLabel?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Identify by cell text or fallback to matched indexes
        if cellText.contains("rate") || cellText.contains("review") || cellText.contains("app store") || (indexPath.section == 5 && indexPath.row == 0) {
            if let url = URL(string: "https://apps.apple.com/us/app/hour-calculator-decimal/id1574062704") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            return
        }
        
        if cellText.contains("clear") || cellText.contains("reset") || (indexPath.section == 6 && indexPath.row == 0) || (indexPath.section == 7 && indexPath.row == 0) {
            promptClearAppData()
            return
        }
    }
    
    private func promptClearAppData() {
        let alert = UIAlertController(
            title: "Clear App Data?",
            message: "Are you sure you want to clear all app data? This will permanently delete all stored hours, time cards, and images.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Clear Everything", style: .destructive, handler: { [weak self] _ in
            guard let self = self else { return }
            
            let alertLoading = UIAlertController(title: "Clearing Data...", message: nil, preferredStyle: .alert)
            let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.style = .medium
            loadingIndicator.startAnimating()
            alertLoading.view.addSubview(loadingIndicator)
            
            self.present(alertLoading, animated: true) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    self.deleteData()
                    alertLoading.dismiss(animated: true) {
                        let successAlert = UIAlertController(title: "Data Cleared", message: "All stored data and preferences have been successfully reset.", preferredStyle: .alert)
                        successAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(successAlert, animated: true, completion: nil)
                    }
                }
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func deleteData() {
        // 1. Clear UserDefaults
        if let domain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.synchronize()
        }
        
        // 2. Clear Core Data entities
        let persistentContainer = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
        let entityNames = ["Hours", "TimeCards", "TimeCardInfo", "Gallery"]
        
        for entity in entityNames {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            do {
                try persistentContainer.persistentStoreCoordinator.execute(deleteRequest, with: persistentContainer.viewContext)
            } catch {
                print("Failed batch delete for \(entity): \(error)")
            }
        }
        
        // 3. Reset the context memory cache & save
        persistentContainer.viewContext.reset()
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        
        // 4. Reset badge notification counts and UI state
        patchNotesCell?.accessoryView = nil
        tabBarController?.tabBar.items?[1].badgeValue = nil
        tabBarController?.tabBar.items?[2].badgeValue = nil
        
        NotificationCenter.default.post(name: NSNotification.Name("Update"), object: nil)
        
        view.window?.overrideUserInterfaceStyle = .unspecified
        hourSwitch?.isOn = false
        view.window?.tintColor = UIColor(rgb: 0x26A69A)
        
        tableView.reloadData()
    }
}
