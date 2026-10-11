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
    
    private var hasStoredImages: Bool {
        let galFetch = NSFetchRequest<Gallery>(entityName: "Gallery")
        galFetch.fetchLimit = 1
        let galleryCount = (try? context.count(for: galFetch)) ?? 0
        if galleryCount > 0 { return true }
        
        let infoFetch = NSFetchRequest<TimeCardInfo>(entityName: "TimeCardInfo")
        infoFetch.predicate = NSPredicate(format: "image != nil")
        infoFetch.fetchLimit = 1
        let infoImageCount = (try? context.count(for: infoFetch)) ?? 0
        return infoImageCount > 0
    }
    
    private var hasStoredHistory: Bool {
        let fetch = NSFetchRequest<Hours>(entityName: "Hours")
        fetch.fetchLimit = 1
        let count = (try? context.count(for: fetch)) ?? 0
        return count > 0
    }
    
    private var hasStoredTimeCards: Bool {
        let fetch = NSFetchRequest<TimeCards>(entityName: "TimeCards")
        fetch.fetchLimit = 1
        let count = (try? context.count(for: fetch)) ?? 0
        return count > 0
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
        
        if cellText.contains("rate") || cellText.contains("review") || cellText.contains("app store") || (indexPath.section == 5 && indexPath.row == 0) {
            if let url = URL(string: "https://apps.apple.com/us/app/hour-calculator-decimal/id1574062704") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            return
        }
        
        if indexPath.section == 6 && indexPath.row == 0 {
            promptClearAppData(sourceView: cell)
            return
        }
    }
    
    private func promptClearAppData(sourceView: UIView) {
        let actionSheet = UIAlertController(
            title: "Clear App Data",
            message: "Select which data you would like to clear. Deleted records cannot be recovered.",
            preferredStyle: .actionSheet
        )
        
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = sourceView
            popover.sourceRect = sourceView.bounds
        }
        
        let clearImagesAction = UIAlertAction(title: "Clear Images", style: .destructive, handler: { [weak self] _ in
            self?.confirmSpecificDeletion(title: "Clear Images?", message: "Are you sure you want to delete all saved photos and gallery thumbnails?") {
                self?.deleteImagesOnly()
            }
        })
        clearImagesAction.isEnabled = hasStoredImages
        actionSheet.addAction(clearImagesAction)
        
        let clearHistoryAction = UIAlertAction(title: "Clear History", style: .destructive, handler: { [weak self] _ in
            self?.confirmSpecificDeletion(title: "Clear History?", message: "Are you sure you want to delete all logged hours from your history?") {
                self?.deleteHistoryOnly()
            }
        })
        clearHistoryAction.isEnabled = hasStoredHistory
        actionSheet.addAction(clearHistoryAction)
        
        let clearTimeCardsAction = UIAlertAction(title: "Clear Time Cards", style: .destructive, handler: { [weak self] _ in
            self?.confirmSpecificDeletion(title: "Clear Time Cards?", message: "Are you sure you want to delete all saved time cards and entries?") {
                self?.deleteTimeCardsOnly()
            }
        })
        clearTimeCardsAction.isEnabled = hasStoredTimeCards
        actionSheet.addAction(clearTimeCardsAction)
        
        let clearEverythingAction = UIAlertAction(title: "Clear Everything", style: .destructive, handler: { [weak self] _ in
            self?.confirmSpecificDeletion(title: "Clear Everything?", message: "Are you sure you want to clear all app data? This will reset all hours, time cards, photos, and preferences.") {
                self?.deleteData()
            }
        })
        clearEverythingAction.isEnabled = true
        actionSheet.addAction(clearEverythingAction)
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true, completion: nil)
    }
    
    private func confirmSpecificDeletion(title: String, message: String, confirmedAction: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            confirmedAction()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func executeBatchDelete(for entityNames: [String]) {
        let persistentContainer = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
        
        for entity in entityNames {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            do {
                try persistentContainer.persistentStoreCoordinator.execute(deleteRequest, with: persistentContainer.viewContext)
            } catch {
                print("Failed batch delete for \(entity): \(error)")
            }
        }
        
        persistentContainer.viewContext.reset()
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    }
    
    private func showSuccessAlert(title: String, message: String) {
        let successAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        successAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(successAlert, animated: true, completion: nil)
    }
    
    private func deleteImagesOnly() {
        executeBatchDelete(for: ["Gallery"])
        
        let fetchRequest = NSFetchRequest<TimeCardInfo>(entityName: "TimeCardInfo")
        if let records = try? context.fetch(fetchRequest) {
            for record in records {
                record.image = nil
            }
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("Update"), object: nil)
        showSuccessAlert(title: "Images Cleared", message: "All stored entry images and gallery thumbnails have been deleted.")
    }
    
    private func deleteHistoryOnly() {
        executeBatchDelete(for: ["Hours"])
        
        tabBarController?.tabBar.items?[1].badgeValue = "0"
        NotificationCenter.default.post(name: NSNotification.Name("Update"), object: nil)
        showSuccessAlert(title: "History Cleared", message: "All saved shift history records have been deleted.")
    }
    
    private func deleteTimeCardsOnly() {
        executeBatchDelete(for: ["TimeCards", "TimeCardInfo"])
        
        userDefaults.removeObject(forKey: "id")
        userDefaults.removeObject(forKey: "index")
        userDefaults.removeObject(forKey: "total")
        userDefaults.removeObject(forKey: "week")
        userDefaults.removeObject(forKey: "name")
        userDefaults.synchronize()
        
        tabBarController?.tabBar.items?[2].badgeValue = "0"
        NotificationCenter.default.post(name: NSNotification.Name("Update"), object: nil)
        showSuccessAlert(title: "Time Cards Cleared", message: "All saved time cards and logged card entries have been deleted.")
    }
    
    func deleteData() {
        let alertLoading = UIAlertController(title: "Clearing Data...", message: "\n\n", preferredStyle: .alert)
        
        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.startAnimating()
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        alertLoading.view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: alertLoading.view.centerXAnchor),
            loadingIndicator.bottomAnchor.constraint(equalTo: alertLoading.view.bottomAnchor, constant: -20)
        ])
        
        present(alertLoading, animated: true) { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                if let domain = Bundle.main.bundleIdentifier {
                    UserDefaults.standard.removePersistentDomain(forName: domain)
                    UserDefaults.standard.synchronize()
                }
                
                self.executeBatchDelete(for: ["Hours", "TimeCards", "TimeCardInfo", "Gallery"])
                
                self.patchNotesCell?.accessoryView = nil
                self.tabBarController?.tabBar.items?[1].badgeValue = "0"
                self.tabBarController?.tabBar.items?[2].badgeValue = "0"
                
                NotificationCenter.default.post(name: NSNotification.Name("Update"), object: nil)
                
                self.view.window?.overrideUserInterfaceStyle = .unspecified
                self.hourSwitch?.isOn = false
                self.view.window?.tintColor = UIColor(rgb: 0x26A69A)
                
                self.tableView.reloadData()
                
                alertLoading.dismiss(animated: true) {
                    self.showSuccessAlert(title: "Data Cleared", message: "All stored data and preferences have been successfully reset.")
                }
            }
        }
    }

}
