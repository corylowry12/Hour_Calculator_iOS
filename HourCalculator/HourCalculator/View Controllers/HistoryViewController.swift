//
//  HistoryViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 6/24/21.
//

import UIKit
import GoogleMobileAds
import CoreData
import SwipeableTabBarController

class HistoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var historyNavigationBar: UINavigationBar!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    @IBOutlet weak var deleteAllMenuButton: UIBarButtonItem!
    @IBOutlet weak var deleteSelectedButton: UIButton!
    @IBOutlet weak var editMenuButton: UIBarButtonItem!
    
    @IBOutlet weak var infoButton: UIBarButtonItem!
    var tappedItem: Hours!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    
    var hourItems: [Hours] {
        
        do {
            
            return try context.fetch(Hours.fetchRequest())
            
        } catch {
            
            print("Couldn't fetch data")
            
        }
        
        return [Hours]()
        
    }
    
    @objc func handleLongPress(longPressGesture: UILongPressGestureRecognizer) {
        let p = longPressGesture.location(in: tableView)
        let indexPath = tableView.indexPathForRow(at: p)
        if indexPath == nil {
            print("Long press failed")
        }
        else if longPressGesture.state == UIGestureRecognizer.State.began {
            print("Long press on row, at \(indexPath!.row)")
            tableView.setEditing(true, animated: true)
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            editButton.title = "Cancel"
            deleteSelectedButton.isHidden = false
        }
    }
    
    var bannerView: GADBannerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressGesture.minimumPressDuration = 0.5
        tableView.addGestureRecognizer(longPressGesture)
        
        let notificationName2 = NSNotification.Name("info")
        NotificationCenter.default.post(name: notificationName2, object: nil)
        
        let notificationName = NSNotification.Name("Update")
        NotificationCenter.default.addObserver(self, selector: #selector(HistoryViewController.reloadTableView), name: notificationName, object: nil)
        
        if hourItems.count > 0 {
            self.deleteAllMenuButton.isEnabled = true
            self.editMenuButton.isEnabled = true
        }
        else {
            self.deleteAllMenuButton.isEnabled = false
            self.editMenuButton.isEnabled = false
        }
        
        bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        
        
        addBannerViewToView(bannerView)
        
        bannerView.adUnitID = "ca-app-pub-4546055219731501/2396708566"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        
        self.tableView.delegate = self
        
        self.tableView.dataSource = self
        
        tableView.tableFooterView = UIView()
        
        tableView.allowsMultipleSelection = true
        
        tableView.allowsMultipleSelectionDuringEditing = true
        
        noHoursStoredBackground()
    }
    
    func noHoursStoredBackground() {
        if hourItems.count == 0 {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: accessibilityFrame.size.width, height: accessibilityFrame.size.height))
            messageLabel.text = "There are currently no hours stored"
        messageLabel.textColor = .black
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
    
    override func viewDidAppear(_ animated: Bool) {
        let notificationName2 = NSNotification.Name("info")
        NotificationCenter.default.post(name: notificationName2, object: self)
        
        noHoursStoredBackground()
        
        tableView.reloadData()
        if hourItems.count > 0 {
            self.deleteAllMenuButton.isEnabled = true
            self.editMenuButton.isEnabled = true
        }
        else {
            self.deleteAllMenuButton.isEnabled = false
            self.editMenuButton.isEnabled = false
        }
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
       /* let indexPath = NSIndexPath(row: 0, section: 0) as IndexPath
        /*tableView.beginUpdates()
        tableView.reloadRows(at: [indexPath], with: .automatic)*/
        tableView.beginUpdates()
        tableView.reloadRows(at: [indexPath], with: .fade)
        tableView.endUpdates()*/
        
        noHoursStoredBackground()
        
        let notificationName2 = NSNotification.Name("info")
        NotificationCenter.default.post(name: notificationName2, object: self)
        tableView.reloadData()
        if hourItems.count > 0 {
            self.deleteAllMenuButton.isEnabled = true
            self.editMenuButton.isEnabled = true
            self.infoButton.isEnabled = true
        }
        else {
            self.deleteAllMenuButton.isEnabled = false
            self.editMenuButton.isEnabled = false
            infoButton.isEnabled = false
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return hourItems.count
        
    }
    
    func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        tableView.setEditing(true, animated: true)
        editButton.title = "Cancel"
        deleteSelectedButton.isHidden = false
    }
    
    func tableViewDidEndMultipleSelectionInteraction(_ tableView: UITableView) {
        print("\(#function)")
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath : IndexPath) -> UITableViewCell {
           
           let hourItems = hourItems[indexPath.row]
           
           let cell = tableView.dequeueReusableCell(withIdentifier: "HourItems", for: indexPath) as! TableViewCell
           
           let inTime : String = String(hourItems.inTime!)
           let outTime: String = String(hourItems.outTime!)
           let totalHours = hourItems.totalHours!
           let date = hourItems.date!
           
           
           cell.inTimeLabel.text = "In Time: \(inTime)"
           cell.outTimeLabel.text = "Out Time: \(outTime)"
           cell.totalHoursLabel.text = "Total Hours: \(totalHours)"
           cell.dateLabel.text = "Date: \(date)"
           
           return cell
            
       }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        tableView.setEditing(false, animated: false)
        editButton.title = "Edit"
        deleteSelectedButton.isHidden = true
        
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let hourToDelete = self.hourItems[indexPath.row]
            self.context.delete(hourToDelete)
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
            
            self.tableView.deleteRows(at: [indexPath], with: .fade)
            
            var hoursItems: [Hours] {
                
                do {
                    return try context.fetch(Hours.fetchRequest())
                }
                catch {
                    print("There was an error")
                }
                
                return [Hours]()
            }
            
            tabBarController?.tabBar.items?[1].badgeValue = String(hoursItems.count)
            
        }
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .normal,
                                        title: "Edit") { (action, view, completionHandler) in
            let defaults = UserDefaults.standard
            defaults.set(indexPath.row, forKey: "ID")
            
            self.performSegue(withIdentifier: "EditItem", sender: nil)
        }
        action.backgroundColor = .systemOrange
        return UISwipeActionsConfiguration(actions: [action])
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.count > 0 {
            deleteSelectedButton.isEnabled = true
            deleteSelectedButton.alpha = 1.0
           
        }
        
        if tableView.isEditing == false {
            tableView.deselectRow(at: indexPath, animated: false)
            
            let defaults = UserDefaults.standard
            defaults.set(indexPath.row, forKey: "ID")
            
            
            
            performSegue(withIdentifier: "EditItem", sender: nil)
            
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.indexPathsForSelectedRows == nil {
            deleteSelectedButton.isEnabled = false
            deleteSelectedButton.alpha = 0.80
        }
    }
    
   
    
    @objc func didPressDelete() {
        let selectedRows = self.tableView.indexPathsForSelectedRows
        if selectedRows != nil {
            for var selectionIndex in selectedRows! {
                while selectionIndex.item >= hourItems.count {
                    selectionIndex.item -= 1
                }
                tableView(tableView, commit: .delete, forRowAt: selectionIndex)
            }
        }
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
    
    @IBAction func deleteAllTapped(_ sender: UIBarButtonItem) {
        
        if self.tableView.isEditing == true {
            self.tableView.setEditing(false, animated: true)
            self.deleteSelectedButton.isHidden = true
            self.editButton.title = "Edit"
        }
        
        let alert = UIAlertController(title: "Delete All?", message: "Are you sure you would like to delete all stored hours?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [self]_ in
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let context = delegate.persistentContainer.viewContext
        
            let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Hours")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
            
            do {
                try context.execute(deleteRequest)
                try context.save()
            } catch {
                print ("There was an error")
            }
            
            //self.tableView.reloadData()
            let range = NSMakeRange(0, self.tableView.numberOfSections)
            let sections = NSIndexSet(indexesIn: range)
            self.tableView.reloadSections(sections as IndexSet, with: .fade)
            
            self.tabBarController?.tabBar.items?[1].badgeValue = String(self.hourItems.count)
            
            self.infoButton.isEnabled = false
            self.deleteAllMenuButton.isEnabled = false
            self.editMenuButton.isEnabled = false
            
            noHoursStoredBackground()
        }
        
        ))
        
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        self.present(alert, animated: true)
        
        if hourItems.count > 0 {
            self.deleteAllMenuButton.isEnabled = true
            self.editMenuButton.isEnabled = true
        }
        else {
            self.infoButton.isEnabled = false
            self.deleteAllMenuButton.isEnabled = false
            self.editMenuButton.isEnabled = false
        }
    }
    
    
    @IBAction func editButtonTapped(_ sender: Any) {
        
        if hourItems.count > 0 {
            
            if tableView.isEditing == true && tableView.indexPathsForSelectedRows?.count == 0 {
                
                tableView.setEditing(false, animated: true)
                deleteSelectedButton.isHidden = true
                editButton.title = "Edit"
            }
            else if tableView.isEditing == true && tableView.indexPathsForSelectedRows?.count != 0 {
                tableView.setEditing(false, animated: true)
                deleteSelectedButton.isHidden = true
                editButton.title = "Edit"
            }
            else if tableView.isEditing == false {
                deleteSelectedButton.isEnabled = false
                deleteSelectedButton.alpha = 0.80
                tableView.setEditing(true, animated: true)
                deleteSelectedButton.isHidden = false
                editButton.title = "Cancel"
            }
            else {
                deleteSelectedButton.isEnabled = false
                deleteSelectedButton.alpha = 0.80
                tableView.setEditing(true, animated: true)
                deleteSelectedButton.isHidden = false
                editButton.title = "Cancel"
            }
        }
    }
    
    @IBAction func deleteSelectedButtonTapped(_ sender: UIButton) {
       
        if let indexPaths = tableView.indexPathsForSelectedRows {
            let sortedPaths = indexPaths.sorted {$0.row > $1.row}
            /*for indexPath in indexPaths {
                let hourToDelete = self.hourItems[indexPath.row]
                self.context.delete(hourToDelete)
                (UIApplication.shared.delegate as! AppDelegate).saveContext()
                self.tableView.deleteRows(at: [indexPath], with: .fade)
                self.tableView.reloadData()
                tabBarController?.tabBar.items?[1].badgeValue = String(hourItems.count)
            }*/
            for i in (0...sortedPaths.count - 1).reversed() {
                let hourToDelete = self.hourItems[i]
                self.context.delete(hourToDelete)
                (UIApplication.shared.delegate as! AppDelegate).saveContext()
                
                
                tabBarController?.tabBar.items?[1].badgeValue = String(hourItems.count)
            }
            
            self.tableView.deleteRows(at: indexPaths, with: .fade)
           noHoursStoredBackground()
        }
        
        
        
        
       if (hourItems.count == 0) {
        editButton.isEnabled = false
        deleteSelectedButton.isHidden = false
        infoButton.isEnabled = false
        }
        
        if hourItems.count > 0 {
            self.deleteAllMenuButton.isEnabled = true
            self.editMenuButton.isEnabled = true
        }
        else {
            self.deleteAllMenuButton.isEnabled = false
            self.editMenuButton.isEnabled = false
        }
        
        tableView.setEditing(false, animated: true)
        editButton.title = "Edit"
        deleteSelectedButton.isHidden = true
        
        
    }
    
    @IBAction func infoButtonTapped(_ sender: UIBarButtonItem) {
        if tableView.isEditing == true {
            tableView.setEditing(false, animated: true)
            editButton.title = "Edit"
            deleteSelectedButton.isHidden = true
        }
        
        let notificationName = NSNotification.Name("info")
        NotificationCenter.default.post(name: notificationName, object: nil)
        performSegue(withIdentifier: "info", sender: nil)
    }
    
    @objc func reloadTableView() {
        self.tableView.reloadData()
        tabBarController?.tabBar.items?[1].badgeValue = String(hourItems.count)
        if hourItems.count == 0 {
            self.deleteAllMenuButton.isEnabled = false
            self.editMenuButton.isEnabled = false
            self.infoButton.isEnabled = false
        }
        noHoursStoredBackground()
    }
}
