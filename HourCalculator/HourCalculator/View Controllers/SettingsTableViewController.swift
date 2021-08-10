//
//  SettingsViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 6/24/21.
//

import UIKit
import Instabug
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
            if userDefaults.integer(forKey: "timeCardsSort") == 0 {
                sort = NSSortDescriptor(key: #keyPath(TimeCards.week), ascending: false)
            }
            else if userDefaults.integer(forKey: "timeCardsSort") == 1 {
                sort = NSSortDescriptor(key: #keyPath(TimeCards.week), ascending: true)
            }
            else if userDefaults.integer(forKey: "timeCardsSort") == 2 {
                sort = NSSortDescriptor(key: #keyPath(TimeCards.total), ascending: true)
            }
            else if userDefaults.integer(forKey: "timeCardsSort") == 3 {
                sort = NSSortDescriptor(key: #keyPath(TimeCards.total), ascending: false)
            }
            else if userDefaults.integer(forKey: "timeCardsSort") == 4 {
                sort = NSSortDescriptor(key: #keyPath(TimeCards.name), ascending: true)
            }
            else if userDefaults.integer(forKey: "timeCardsSort") == 5 {
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
        
        BugReporting.enabled = true
        
        if userDefaults.integer(forKey: "accent") == 0 {
            hourSwitch?.onTintColor = UIColor(rgb: 0x26A69A)
        }
        else if userDefaults.integer(forKey: "accent") == 1 {
            hourSwitch?.onTintColor = UIColor(rgb: 0x7841c4)
        }
        else if userDefaults.integer(forKey: "accent") == 2 {
            hourSwitch?.onTintColor = UIColor(rgb: 0x347deb)
        }
        else if userDefaults.integer(forKey: "accent") == 3 {
            hourSwitch?.onTintColor = UIColor(rgb: 0xfc783a)
        }
        else if userDefaults.integer(forKey: "accent") == 4 {
            hourSwitch.onTintColor = UIColor(rgb: 0xc41d1d)
        }
        
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        
        if userDefaults.value(forKey: "appVersion") == nil || userDefaults.value(forKey: "appVersion") as? String != appVersion {
            let size: CGFloat = 22
            let width = max(size, 0.7 * size * 1) // perfect circle is smallest allowed
            let badge = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: size))
            badge.text = "1"
            badge.layer.cornerRadius = size / 2
            badge.layer.masksToBounds = true
            badge.textAlignment = .center
            badge.textColor = UIColor.white
            badge.backgroundColor = UIColor.red
            patchNotesCell.accessoryView = badge
        }
        else {
            patchNotesCell.accessoryView = nil
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath == [5, 0] {
            if let url = URL(string: "https://apps.apple.com/us/app/hour-calculator-decimal/id1574062704") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        if indexPath == [6, 0] {
            let alert = UIAlertController(title: "Clear App Data?", message: "Would you like to clear app data? This will delete all stored data!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {_ in
                alert.dismiss(animated: true, completion: nil)
                let alertLoading = UIAlertController(title: "Clearing Data...", message: nil, preferredStyle: .alert)
                let loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 10,y: 5,width: 50, height: 50)) as UIActivityIndicatorView
                loadingIndicator.hidesWhenStopped = true
                loadingIndicator.style = .medium
                loadingIndicator.startAnimating();
                alertLoading.view.addSubview(loadingIndicator)
                self.present(alertLoading, animated: true, completion: nil)
                let when = DispatchTime.now() + 1
                DispatchQueue.main.asyncAfter(deadline: when) {
                    alertLoading.dismiss(animated: true, completion: {
                        self.dismiss(animated: true, completion: nil)
                        self.deleteData()
                    })
                }
            }))
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func deleteData() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Hours.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        // get reference to the persistent container
        let persistentContainer = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
        
        // perform the delete
        do {
            try persistentContainer.viewContext.execute(deleteRequest)
        } catch let error as NSError {
            print(error)
        }
        
        let fetchRequest_timeCards: NSFetchRequest<NSFetchRequestResult> = TimeCards.fetchRequest()
        let deleteRequest_timeCards = NSBatchDeleteRequest(fetchRequest: fetchRequest_timeCards)
        
        // perform the delete
        do {
            try persistentContainer.viewContext.execute(deleteRequest_timeCards)
        } catch let error as NSError {
            print(error)
        }
        
        let size: CGFloat = 22
        let width = max(size, 0.7 * size * 1) // perfect circle is smallest allowed
        let badge = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: size))
        badge.text = "1"
        badge.layer.cornerRadius = size / 2
        badge.layer.masksToBounds = true
        badge.textAlignment = .center
        badge.textColor = UIColor.white
        badge.backgroundColor = UIColor.red
        patchNotesCell.accessoryView = badge
        
        tabBarController?.tabBar.items?[1].isEnabled = true
        tabBarController?.tabBar.items?[1].badgeValue = String(hourItems.count)
        tabBarController?.tabBar.items?[2].badgeValue = String(timeCards.count)
        view.window?.overrideUserInterfaceStyle = .unspecified
        hourSwitch.isOn = false
        view.window?.tintColor = UIColor(rgb: 0x26A69A)
    }
}
