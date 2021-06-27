//
//  HistoryViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 6/24/21.
//

import UIKit
import GoogleMobileAds
import CoreData

class HistoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
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
    
    var bannerView: GADBannerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return hourItems.count
        
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView.isEditing == false {
            tableView.deselectRow(at: indexPath, animated: false)
            
            let defaults = UserDefaults.standard
            defaults.set(indexPath.row, forKey: "ID")
            
            
            
            performSegue(withIdentifier: "EditItem", sender: nil)
            
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
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {_ in
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
            
            self.tableView.reloadData()
            
            self.tabBarController?.tabBar.items?[1].badgeValue = String(self.hourItems.count)
            
            
        }
        
        ))
        
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        self.present(alert, animated: true)
        
        if hourItems.count > 0 {
            self.deleteAllMenuButton.isEnabled = true
            self.editMenuButton.isEnabled = true
        }
        else {
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
                tableView.setEditing(true, animated: true)
                deleteSelectedButton.isHidden = false
                editButton.title = "Done"
            }
            else {
                tableView.setEditing(true, animated: true)
                deleteSelectedButton.isHidden = false
                editButton.title = "Done"
            }
        }
    }
    
    @IBAction func deleteSelectedButtonTapped(_ sender: Any) {
        
        if let indexPaths = tableView.indexPathsForSelectedRows {
            for indexPath in indexPaths {
                let hourToDelete = self.hourItems[indexPath.row]
                self.context.delete(hourToDelete)
                (UIApplication.shared.delegate as! AppDelegate).saveContext()
                self.tableView.deleteRows(at: [indexPath], with: .fade)
                self.tableView.reloadData()
                tabBarController?.tabBar.items?[1].badgeValue = String(hourItems.count)
            }
            
        }
        
        if (hourItems.count == 0) {
            deleteSelectedButton.isHidden = true
            editButton.title = "Edit"
        }
        
        if hourItems.count > 0 {
            self.deleteAllMenuButton.isEnabled = true
            self.editMenuButton.isEnabled = true
        }
        else {
            self.deleteAllMenuButton.isEnabled = false
            self.editMenuButton.isEnabled = false
        }
        
    }
    
    @IBAction func infoButtonTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "info", sender: nil)
    }
    
    @objc func reloadTableView() {
        self.tableView.reloadData()
        
    }
}
