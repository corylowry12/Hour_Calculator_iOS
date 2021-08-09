//
//  TimeCardTableViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 7/8/21.
//

import Foundation
import UIKit
import CoreData
import Instabug
import GoogleMobileAds

class TimeCardTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    lazy var bannerView: GADBannerView! = GADBannerView(adSize: kGADAdSizeBanner)
    @IBOutlet weak var sortButton: UIButton!
    
    @IBOutlet var tableView: UITableView!
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let userDefaults = UserDefaults.standard
    
    var undo : Int = 0
    
    var predicateText: String!
    
    var timeCardInfo: [TimeCardInfo] {
        
        do {
            let fetchrequest = NSFetchRequest<TimeCardInfo>(entityName: "TimeCardInfo")
            //let predicate = userDefaults.value(forKey: "id")
            fetchrequest.predicate = NSPredicate(format: "id_number == %@", predicateText!)
            //let sort = NSSortDescriptor(key: #keyPath(TimeCardInfo.date), ascending: false)
            //fetchrequest.sortDescriptors = [sort]
            
            return try context.fetch(fetchrequest)
            
        } catch {
            
            print("Couldn't fetch data")
            
        }
        
        return [TimeCardInfo]()
        
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
                sort = NSSortDescriptor(key: #keyPath(TimeCards.name), ascending: false)
            }
            else if userDefaults.integer(forKey: "timeCardsSort") == 5 {
                sort = NSSortDescriptor(key: #keyPath(TimeCards.name), ascending: true)
            }
            fetchrequest.sortDescriptors = [sort]
            return try context.fetch(fetchrequest)
            
        } catch {
            
            print("Couldn't fetch data")
            
        }
        
        return [TimeCards]()
        
    }
    
    override var canBecomeFirstResponder: Bool {
        get {
            return true
        }
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            if undo == 1 {
                BugReporting.dismiss()
                print("Why are you shaking me?")
                let alert = UIAlertController(title: "Undo", message: "Would you like to undo time card deletion?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [self]_ in
                    (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.rollback()
                    
                    UIView.transition(with: self.tableView, duration: 0.25, options: .transitionCrossDissolve, animations: {self.tableView.reloadData()}, completion: nil)
                    
                    noHoursStoredBackground()
                    
                    undo = 0
                    
                    sortButton.isHidden = false
                    sortButton.alpha = 0
                    UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseInOut], animations: {
                        self.sortButton.alpha = 1.0
                    }, completion: { _ in
                        
                    })
                    
                }))
                alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            else {
                BugReporting.enabled = true
                Instabug.show()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //addBannerViewToView(bannerView)
        
        bannerView.adUnitID = "ca-app-pub-4546055219731501/2396708566"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
        noHoursStoredBackground()
        BugReporting.enabled = false
        self.becomeFirstResponder()
        
        if timeCards.count == 0 {
            sortButton.isHidden = true
            
        }
        else {
            sortButton.isHidden = false
            sortButton.alpha = 0
            UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseInOut], animations: {
                self.sortButton.alpha = 1.0
            }, completion: { _ in
                
            })
        }
        
        view.backgroundColor = tableView.backgroundColor
        
        if userDefaults.integer(forKey: "accent") == 0 {
            sortButton.backgroundColor = UIColor(rgb: 0x26A69A)
        }
        else if userDefaults.integer(forKey: "accent") == 1 {
            sortButton.backgroundColor = UIColor(rgb: 0x7841c4)
        }
        else if userDefaults.integer(forKey: "accent") == 2 {
            sortButton.backgroundColor = UIColor(rgb: 0x347deb)
        }
        else if userDefaults.integer(forKey: "accent") == 3 {
            sortButton.backgroundColor = UIColor(rgb: 0xfc783a)
        }
        else if userDefaults.integer(forKey: "accent") == 4 {
            sortButton.backgroundColor = UIColor(rgb: 0xc41d1d)
        }
        
        if userDefaults.integer(forKey: "timeCardsSort") == 0 {
            sortButton.setTitle("Sort: Date Descending", for: .normal)
        }
        else if userDefaults.integer(forKey: "timeCardsSort") == 1 {
            sortButton.setTitle("Sort: Date Ascending", for: .normal)
        }
        else if userDefaults.integer(forKey: "timeCardsSort") == 2 {
            sortButton.setTitle("Sort: Total Hours Ascending", for: .normal)
        }
        else if userDefaults.integer(forKey: "timeCardsSort") == 3 {
            sortButton.setTitle("Sort: Total Hours Descending", for: .normal)
        }
        else if userDefaults.integer(forKey: "timeCardsSort") == 4 {
            sortButton.setTitle("Sort: Name Ascending", for: .normal)
        }
        else if userDefaults.integer(forKey: "timeCardsSort") == 5 {
            sortButton.setTitle("Sort: Name Descending", for: .normal)
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        undo = 0
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    }
    
    func noHoursStoredBackground() {
        if timeCards.count == 0 {
            let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: accessibilityFrame.size.width, height: accessibilityFrame.size.height))
            messageLabel.text = "There are currently entries stored"
            messageLabel.numberOfLines = 0;
            messageLabel.textAlignment = .center;
            messageLabel.font = UIFont.systemFont(ofSize: 16.0, weight: UIFont.Weight.medium)
            messageLabel.sizeToFit()
            
            tableView.backgroundView = messageLabel;
            tableView.separatorStyle = .none;
        }
        else {
            tableView.backgroundView = nil
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    private var finishedLoadingInitialTableCells = false
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        DispatchQueue.main.async { [self] in
        
        var lastInitialDisplayableCell = false
        
        //change flag as soon as last displayable cell is being loaded (which will mean table has initially loaded)
        if timeCards.count > 0 && !finishedLoadingInitialTableCells {
            if let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows,
               let lastIndexPath = indexPathsForVisibleRows.last, lastIndexPath.row == indexPath.row {
                lastInitialDisplayableCell = true
            }
        }
        
        if !finishedLoadingInitialTableCells {
            
            if lastInitialDisplayableCell {
                finishedLoadingInitialTableCells = true
            }
            
            //animates the cell as it is being displayed for the first time
            cell.transform = CGAffineTransform(translationX: 0, y: tableView.rowHeight/2)
            cell.alpha = 0
            
            UIView.animate(withDuration: 1.0, delay: 0.0, options: [.transitionCrossDissolve], animations: {
                cell.transform = CGAffineTransform(translationX: 0, y: 0)
                cell.alpha = 1
            }, completion: nil)
        }
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let alert = UIAlertController(title: "Warning", message: "You are about to delete a time card entry. Would you like to continue?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [self]_ in
                
            predicateText = "\(timeCards[indexPath.row].id_number)"
            
            if timeCardInfo.count > 0 {
            for i in (0...timeCardInfo.count - 1).reversed() {
                let timeCardInfoToDelete = timeCardInfo[i]
                
                self.context.delete(timeCardInfoToDelete)
            }
            }
            
            let hourToDelete = self.timeCards[indexPath.row]
            self.context.delete(hourToDelete)
            
            self.tableView.deleteRows(at: [indexPath], with: .left)
            noHoursStoredBackground()
            undo = 1
            if timeCards.count == 0 {
                sortButton.alpha = 1
                UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseInOut], animations: {
                    self.sortButton.alpha = 0
                }, completion: {_ in
                    self.sortButton.isHidden = true
                })
            }
            tabBarController?.tabBar.items?[2].badgeValue = String(timeCards.count)
            //(UIApplication.shared.delegate as! AppDelegate).saveContext()
            }))
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: {_ in
                tableView.setEditing(false, animated: true)
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return timeCards.count
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .normal,
                                        title: "Rename") { [self] (action, view, completionHandler) in
            let alert = UIAlertController(title: "Name", message: "Enter a name", preferredStyle: .alert)
            let save = UIAlertAction(title: "Save", style: .default, handler: {_ in
                let nameToBeStored = self.timeCards[indexPath.row]
                let textField = alert.textFields?[0]
                var userText : String!
                if textField?.text == "" {
                    userText = textField?.placeholder
                }
                else if textField?.text?.trimmingCharacters(in: .whitespaces) == "" {
                    userText = "Unknown"
                }
                else {
                    userText = textField!.text?.trimmingCharacters(in: .whitespaces)
                    userText.censor()
                }
                nameToBeStored.name = userText
                (UIApplication.shared.delegate as! AppDelegate).saveContext()
              
                self.tableView.reloadRows(at: [indexPath], with: .none)
                               
                self.undo = 1
            })
            let removePrevious = UIAlertAction(title: "Remove Previous", style: .default, handler: {_ in
                let nameToBeStored = self.timeCards[indexPath.row]
                nameToBeStored.name = nil
                
                self.tableView.reloadRows(at: [indexPath], with: .fade)
                                 
                self.undo = 1
            })
            alert.addTextField { [self] (textField) in
                textField.clearButtonMode = .always
                textField.autocapitalizationType = .words
                textField.autocorrectionType = .no
                
                var name : String!
                if timeCards[indexPath.row].name == nil {
                    name = "Unknown"
                }
                else {
                    name = timeCards[indexPath.row].name
                }
                textField.placeholder = name
            }
            alert.addAction(save)
            if timeCards[indexPath.row].name != nil && timeCards[indexPath.row].name != "Unknown" {
                alert.addAction(removePrevious)
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {_ in
                tableView.setEditing(false, animated: true)
            }))
            alert.preferredAction = save
            self.present(alert, animated: true, completion: nil)
        }
        action.backgroundColor = .systemOrange
        return UISwipeActionsConfiguration(actions: [action])
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if timeCards[indexPath.row].id_number == 0 {
            let alert = UIAlertController(title: "Name", message: "Enter a name", preferredStyle: .alert)
            let save = UIAlertAction(title: "Save", style: .default, handler: {_ in
                let nameToBeStored = self.timeCards[indexPath.row]
                let textField = alert.textFields?[0]
                var userText : String!
                if textField?.text == "" {
                    userText = textField?.placeholder
                }
                else if textField?.text?.trimmingCharacters(in: .whitespaces) == "" {
                    userText = "Unknown"
                }
                else {
                    userText = textField!.text?.trimmingCharacters(in: .whitespaces)
                    userText.censor()
                }
                nameToBeStored.name = userText
                (UIApplication.shared.delegate as! AppDelegate).saveContext()
                
                self.tableView.reloadRows(at: [indexPath], with: .fade)
                
                self.undo = 1
            })
            let removePrevious = UIAlertAction(title: "Remove Previous", style: .default, handler: {_ in
                let nameToBeStored = self.timeCards[indexPath.row]
                nameToBeStored.name = nil
                (UIApplication.shared.delegate as! AppDelegate).saveContext()
                
                self.tableView.reloadRows(at: [indexPath], with: .fade)
                
                self.undo = 1
            })
            alert.addTextField { [self] (textField) in
                textField.clearButtonMode = .always
                textField.autocapitalizationType = .words
                textField.autocorrectionType = .no
                
                var name : String!
                if timeCards[indexPath.row].name == nil {
                    name = "Unknown"
                }
                else {
                    name = timeCards[indexPath.row].name
                }
                textField.placeholder = name
            }
            alert.addAction(save)
            if timeCards[indexPath.row].name != nil && timeCards[indexPath.row].name != "Unknown" {
                alert.addAction(removePrevious)
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.preferredAction = save
            self.present(alert, animated: true, completion: nil)
        }
        else {
            let id = timeCards[indexPath.row].id_number
            let name = timeCards[indexPath.row].name
            let total = timeCards[indexPath.row].total
            let weekOf = timeCards[indexPath.row].week
            userDefaults.setValue(id, forKey: "id")
            userDefaults.setValue(name, forKey: "name")
            userDefaults.setValue(indexPath.row, forKey: "index")
            userDefaults.setValue(total, forKey: "total")
            userDefaults.setValue(weekOf, forKey: "week")
            //print("id is: \(id)")
            
            performSegue(withIdentifier: "timeCardInfo", sender: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let timeCards = timeCards[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "timeCard", for: indexPath) as! TimeCardTableViewCell
        
        let round = round(timeCards.total * 100) / 100.00
        let inTime = timeCards.week
        let total = round
        
        var name : String!
        
        if timeCards.name == nil || timeCards.name?.trimmingCharacters(in: .whitespaces) == "" {
            name = "Name: Unknown"
        }
        else {
            name = "Name: \(timeCards.name ?? "")"
        }
        
        cell.nameLabel.text = name
        if timeCards.numberBeingExported == 1 {
            cell.inTimeLabel.text = "Day Of: \(inTime ?? "Unknown")"
        }
        else if timeCards.numberBeingExported > 1 || timeCards.numberBeingExported == 0 {
            cell.inTimeLabel.text = "Week Of: \(inTime ?? "Unknown")"
        }
        cell.totalLabel.text = "Total Hours: \(total)"
        
        return cell
    }
    
    @IBAction func sortButton(_ sender: UIButton) {
        UIButton.animate(withDuration: 0.05,
                         animations: {
                            sender.transform = CGAffineTransform(scaleX: 0.975, y: 0.96)
                         },
                         completion: { finish in
                            UIButton.animate(withDuration: 0.05, animations: {
                                sender.transform = CGAffineTransform.identity
                            })
                         })
        if userDefaults.integer(forKey: "timeCardsSort") == 0 {
            sender.setTitle("Sort: Date Ascending", for: .normal)
            userDefaults.set(1, forKey: "timeCardsSort")
        }
        else if userDefaults.integer(forKey: "timeCardsSort") == 1 {
            sender.setTitle("Sort: Total Hours Ascending", for: .normal)
            userDefaults.set(2, forKey: "timeCardsSort")
        }
        else if userDefaults.integer(forKey: "timeCardsSort") == 2 {
            sender.setTitle("Sort: Total Hours Descending", for: .normal)
            userDefaults.set(3, forKey: "timeCardsSort")
        }
        else if userDefaults.integer(forKey: "timeCardsSort") == 3 {
            sender.setTitle("Sort: Name Ascending", for: .normal)
            userDefaults.set(4, forKey: "timeCardsSort")
        }
        else if userDefaults.integer(forKey: "timeCardsSort") == 4 {
            sender.setTitle("Sort: Name Descending", for: .normal)
            userDefaults.set(5, forKey: "timeCardsSort")
        }
        else if userDefaults.integer(forKey: "timeCardsSort") == 5 {
            sender.setTitle("Sort: Date Descending", for: .normal)
            userDefaults.set(0, forKey: "timeCardsSort")
        }
        
        UIView.transition(with: tableView,
                          duration: 0.35,
                          options: .transitionCrossDissolve,
                          animations: { () -> Void in
                            self.tableView.reloadData()
                          },
                          completion: nil);
    }
    
    func addBannerViewToView(_ bannerView: GADBannerView) {
        
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        view.addConstraints(
            [NSLayoutConstraint(item: bannerView,
                                attribute: .bottom,
                                relatedBy: .equal,
                                toItem: view.safeAreaLayoutGuide,
                                attribute: .bottom,
                                multiplier: 1,
                                constant: 0),
             NSLayoutConstraint(item: bannerView,
                                attribute: .centerX,
                                relatedBy: .equal,
                                toItem: view,
                                attribute: .centerX,
                                multiplier: 1,
                                constant: 0),
            ])
    }
    
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        addBannerViewToView(bannerView)
        bannerView.alpha = 0
        UIView.animate(withDuration: 1, animations: {
            bannerView.alpha = 1
        })
    }
}
