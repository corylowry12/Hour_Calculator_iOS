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
import Instabug

extension UIViewController: UIPopoverPresentationControllerDelegate {
    public func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}

class HistoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var historyNavigationBar: UINavigationBar!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    @IBOutlet var exportMenuButton: UIBarButtonItem!
    @IBOutlet weak var deleteAllMenuButton: UIBarButtonItem!
    @IBOutlet weak var deleteSelectedButton: UIButton!
    @IBOutlet weak var editMenuButton: UIBarButtonItem!
    
    @IBOutlet weak var infoButton: UIBarButtonItem!
    var tappedItem: Hours!
    
    let userDefaults = UserDefaults.standard
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var undo = 0
    
    var hourItems: [Hours] {
        
        do {
            var sort = NSSortDescriptor(key: #keyPath(Hours.date), ascending: false)
            let fetchrequest = NSFetchRequest<Hours>(entityName: "Hours")
            if userDefaults.integer(forKey: "historySort") == 0 {
                sort = NSSortDescriptor(key: #keyPath(Hours.date), ascending: false)
            }
            else if userDefaults.integer(forKey: "historySort") == 1 {
                sort = NSSortDescriptor(key: #keyPath(Hours.date), ascending: true)
            }
            else if userDefaults.integer(forKey: "historySort") == 2 {
                sort = NSSortDescriptor(key: #keyPath(Hours.totalHours), ascending: true)
            }
            else if userDefaults.integer(forKey: "historySort") == 3 {
                sort = NSSortDescriptor(key: #keyPath(Hours.totalHours), ascending: false)
            }
            fetchrequest.sortDescriptors = [sort]
            return try context.fetch(fetchrequest)
            
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
    
    lazy var bannerView: GADBannerView! = GADBannerView(adSize: kGADAdSizeBanner)
    
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
                let alert = UIAlertController(title: "Undo", message: "Would you like to undo recent hour deletion?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [self]_ in
                    (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.rollback()
                    
                    UIView.transition(with: self.tableView, duration: 0.25, options: .transitionCrossDissolve, animations: {self.tableView.reloadData()}, completion: nil)
                    
                    editMenuButton.isEnabled = true
                    infoButton.isEnabled = true
                    deleteAllMenuButton.isEnabled = true
                    exportMenuButton.isEnabled = true
                    noHoursStoredBackground()
                    
                    undo = 0
                    
                    tabBarController?.tabBar.items?[1].badgeValue = String(hourItems.count)
                }))
                alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            else if undo == 0 {
                BugReporting.enabled = true
                Instabug.enabled = true
                Instabug.show()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.becomeFirstResponder()
        
        let defaults = UserDefaults.standard
        if defaults.value(forKey: "undoAlertMessage") == nil {
            defaults.setValue(0, forKey: "undoAlertMessage")
        }
        
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
            exportMenuButton.isEnabled = true
        }
        else {
            self.deleteAllMenuButton.isEnabled = false
            self.editMenuButton.isEnabled = false
            self.exportMenuButton.isEnabled = false
        }
        
        //bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        
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
            self.exportMenuButton.isEnabled = true
        }
        else {
            self.deleteAllMenuButton.isEnabled = false
            self.editMenuButton.isEnabled = false
            self.exportMenuButton.isEnabled = false
        }
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        Instabug.enabled = false
        
       // print(Hours(context: context).date?.min())
        
        tableView.reloadData()
        
        if userDefaults.integer(forKey: "accent") == 0 {
            deleteSelectedButton.backgroundColor = UIColor(rgb: 0x26A69A)
        }
        else if userDefaults.integer(forKey: "accent") == 1 {
            deleteSelectedButton.backgroundColor = UIColor(rgb: 0x7841c4)
        }
        else if userDefaults.integer(forKey: "accent") == 2 {
            deleteSelectedButton.backgroundColor = UIColor(rgb: 0x347deb)
        }
        else if userDefaults.integer(forKey: "accent") == 3 {
            deleteSelectedButton.backgroundColor = UIColor(rgb: 0xfc783a)
        }
        else if userDefaults.integer(forKey: "accent") == 4 {
            deleteSelectedButton.backgroundColor = UIColor(rgb: 0xc41d1d)
        }
        
        noHoursStoredBackground()
        
        let notificationName2 = NSNotification.Name("info")
        NotificationCenter.default.post(name: notificationName2, object: self)
        tableView.reloadData()
        if hourItems.count > 0 {
            self.deleteAllMenuButton.isEnabled = true
            self.editMenuButton.isEnabled = true
            self.infoButton.isEnabled = true
            self.exportMenuButton.isEnabled = true
        }
        else {
            self.deleteAllMenuButton.isEnabled = false
            self.editMenuButton.isEnabled = false
            infoButton.isEnabled = false
            exportMenuButton.isEnabled = false
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return hourItems.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath : IndexPath) -> UITableViewCell {
            
        let hourItems = hourItems[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "HourItems", for: indexPath) as! TableViewCell
        //DispatchQueue.main.async {
        let inTime = String(hourItems.inTime!)
        let outTime = String(hourItems.outTime!)
        let totalHours = String(hourItems.totalHours!)
        let date = hourItems.date!
        
        
        cell.inTimeLabel.text = "In Time: \(inTime)"
        cell.outTimeLabel.text = "Out Time: \(outTime)"
        cell.totalHoursLabel.text = "Total Hours: \(totalHours)"
        cell.dateLabel.text = "Date: \(date)"
        //}
        return cell
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        undo = 0
        tableView.setEditing(false, animated: false)
        editButton.title = "Edit"
        deleteSelectedButton.isHidden = true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            let hourToDelete = self.hourItems[indexPath.row]
            self.context.delete(hourToDelete)
            
            self.tableView.deleteRows(at: [indexPath], with: .fade)
            
            undo = 1
            
            tabBarController?.tabBar.items?[1].badgeValue = String(hourItems.count)
            
            if UserDefaults.standard.integer(forKey: "undoAlertMessage") == 0 {
                let alert = UIAlertController(title: nil, message: "You can shake your phone in order to restore an hour", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: {_ in
                    UserDefaults.standard.setValue(1, forKey: "undoAlertMessage")
                }
                ))
                self.present(alert, animated: true, completion: nil)
            }
            
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
    
    private var finishedLoadingInitialTableCells = false

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {

        var lastInitialDisplayableCell = false

        //change flag as soon as last displayable cell is being loaded (which will mean table has initially loaded)
        if hourItems.count > 0 && !finishedLoadingInitialTableCells {
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

            UIView.animate(withDuration: 0.5, delay: 0.05*Double(indexPath.row), options: [.curveEaseInOut], animations: {
                cell.transform = CGAffineTransform(translationX: 0, y: 0)
                cell.alpha = 1
            }, completion: nil)
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
            undo = 1
            DispatchQueue.main.async {
            for i in (0...hourItems.count - 1).reversed() {
                let index = [0, i] as IndexPath
                let hourToDelete = self.hourItems[i]
                
                self.context.delete(hourToDelete)
                self.tableView.deleteRows(at: [index], with: .fade)
                
            }
                noHoursStoredBackground()
                tabBarController?.tabBar.items?[1].badgeValue = String(hourItems.count)
            }
            
            if UserDefaults.standard.integer(forKey: "undoAlertMessage") == 0 {
                let alert = UIAlertController(title: nil, message: "You can shake your phone in order to restore an hour", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: {_ in
                    UserDefaults.standard.setValue(1, forKey: "undoAlertMessage")
                }
                ))
                self.present(alert, animated: true, completion: nil)
            }
            
            let range = NSMakeRange(0, self.tableView.numberOfSections)
            let sections = NSIndexSet(indexesIn: range)
            self.tableView.reloadSections(sections as IndexSet, with: .fade)
            
            self.tabBarController?.tabBar.items?[1].badgeValue = String(self.hourItems.count)
            
            self.infoButton.isEnabled = false
            self.deleteAllMenuButton.isEnabled = false
            self.editMenuButton.isEnabled = false
            exportMenuButton.isEnabled = false
            
            noHoursStoredBackground()
        }
        
        ))
        
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        self.present(alert, animated: true)
        
        if hourItems.count > 0 {
            self.deleteAllMenuButton.isEnabled = true
            self.editMenuButton.isEnabled = true
            self.exportMenuButton.isEnabled = true
        }
        else {
            self.infoButton.isEnabled = false
            self.deleteAllMenuButton.isEnabled = false
            self.editMenuButton.isEnabled = false
            exportMenuButton.isEnabled = false
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
        
        if UserDefaults.standard.integer(forKey: "undoAlertMessage") == 0 {
            let alert = UIAlertController(title: nil, message: "You can shake your phone in order to restore an hour", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: {_ in
                UserDefaults.standard.setValue(1, forKey: "undoAlertMessage")
            }
            ))
            self.present(alert, animated: true, completion: nil)
        }
        
        if let indexPaths = tableView.indexPathsForSelectedRows {
            let sortedPaths = indexPaths.sorted {$0.row > $1.row}
      
            for i in (0...sortedPaths.count - 1).reversed() {
                let hourToDelete = self.hourItems[i]
                self.context.delete(hourToDelete)
                
                tabBarController?.tabBar.items?[1].badgeValue = String(hourItems.count)
            }
            
            self.tableView.deleteRows(at: indexPaths, with: .fade)
            noHoursStoredBackground()
            
            undo = 1
        }
        
        if (hourItems.count == 0) {
            editButton.isEnabled = false
            deleteSelectedButton.isHidden = false
            infoButton.isEnabled = false
            exportMenuButton.isEnabled = false
        }
        
        if hourItems.count > 0 {
            self.deleteAllMenuButton.isEnabled = true
            self.editMenuButton.isEnabled = true
            exportMenuButton.isEnabled = true
        }
        else {
            self.deleteAllMenuButton.isEnabled = false
            self.editMenuButton.isEnabled = false
            exportMenuButton.isEnabled = false
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
            self.exportMenuButton.isEnabled = false
        }
        noHoursStoredBackground()
    }
  
    @IBAction func exportButton(_ sender: Any) {
        if tableView.isEditing == true {
            tableView.setEditing(false, animated: true)
            deleteSelectedButton.isHidden = true
            editButton.title = "Edit"
        }
        
        var hoursForExport: [Hours] {
            
            do {
                let sort = NSSortDescriptor(key: #keyPath(Hours.date), ascending: true)
                let fetchrequest = NSFetchRequest<Hours>(entityName: "Hours")
                fetchrequest.sortDescriptors = [sort]
                return try context.fetch(fetchrequest)
                
            } catch {
                
                print("Couldn't fetch data")
                
            }
            
            return [Hours]()
            
        }
        
        if hourItems.count > 7 {
        let alert = UIAlertController(title: "Warning", message: "You have more than 7 hours stored, would you like to continue?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {_ in
            let timeCards = TimeCards(context: self.context)
            var total = 0.0

            let date = "\(hoursForExport.first!.date ?? "Unknown")-\(hoursForExport.last!.date ?? "Unkown")"
         
                timeCards.week = date
            for i in (0...self.hourItems.count - 1).reversed() {
                let hourToDelete = hoursForExport[i]
                total += Double(hoursForExport[i].totalHours!)!
                
                self.context.delete(hourToDelete)
                let index = [0, i] as IndexPath
                self.tableView.deleteRows(at: [index], with: .fade)
                
                timeCards.total = total
            }
            self.noHoursStoredBackground()
            self.tabBarController?.tabBar.items?[1].badgeValue = String(self.hourItems.count)
            self.editButton.isEnabled = false
            self.infoButton.isEnabled = false
            self.deleteAllMenuButton.isEnabled = false
            self.exportMenuButton.isEnabled = false
            
            self.undo = 1
        }))
            alert.addAction(UIAlertAction(title: "Just Export 7", style: .default, handler: {_ in
                let timeCards = TimeCards(context: self.context)
                var total = 0.0
                let date = "\(hoursForExport[0].date ?? "Unknown")-\(hoursForExport[6].date ?? "Unkown")"
                    timeCards.week = date
                    for i in (0...6).reversed() {
                    let hourToDelete = hoursForExport[i]
                    total += Double(hoursForExport[i].totalHours!)!
                    
                    self.context.delete(hourToDelete)
                    let index = [0, i] as IndexPath
                    self.tableView.deleteRows(at: [index], with: .fade)
                    
                    timeCards.total = total
                }
                    self.tableView.reloadData()
                self.noHoursStoredBackground()
                self.tabBarController?.tabBar.items?[1].badgeValue = String(self.hourItems.count)
                    if self.hourItems.count == 0 {
                self.editButton.isEnabled = false
                self.infoButton.isEnabled = false
                self.deleteAllMenuButton.isEnabled = false
                self.exportMenuButton.isEnabled = false
                    }
                
                self.undo = 1
            }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
        }
        else if hourItems.count == 7 {
            let alert = UIAlertController(title: "Warning", message: "You are fixing to export a weeks worth of hours, would you like to continue?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {_ in
                let timeCards = TimeCards(context: self.context)
                var total = 0.0
                let date = "\(hoursForExport.first!.date ?? "Unknown")-\(hoursForExport.last!.date ?? "Unkown")"
                    timeCards.week = date
                for i in (0...self.hourItems.count - 1).reversed() {
                    let hourToDelete = hoursForExport[i]
                    total += Double(hoursForExport[i].totalHours!)!
                    
                    self.context.delete(hourToDelete)
                    let index = [0, i] as IndexPath
                    self.tableView.deleteRows(at: [index], with: .fade)
                    
                    timeCards.total = total
                }
                self.noHoursStoredBackground()
                self.tabBarController?.tabBar.items?[1].badgeValue = String(self.hourItems.count)
                self.editButton.isEnabled = false
                self.infoButton.isEnabled = false
                self.deleteAllMenuButton.isEnabled = false
                self.exportMenuButton.isEnabled = false
                
                self.undo = 1
            }))
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        else {
            let alert = UIAlertController(title: "Warning", message: "You have less than a weeks worth of hours, would you like to continue?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [self]_ in
                let timeCards = TimeCards(context: self.context)
                var total = 0.0
                let date = "\(hoursForExport.first!.date ?? "Unknown")-\(hoursForExport.last!.date ?? "Unkown")"
                    timeCards.week = date
                for i in (0...self.hourItems.count - 1).reversed() {
                    let hourToDelete = hoursForExport[i]
                    total += Double(hoursForExport[i].totalHours!)!
                    
                    self.context.delete(hourToDelete)
                    let index = [0, i] as IndexPath
                    self.tableView.deleteRows(at: [index], with: .fade)
                    
                    timeCards.total = total
                }
                noHoursStoredBackground()
                tabBarController?.tabBar.items?[1].badgeValue = String(self.hourItems.count)
                editButton.isEnabled = false
                infoButton.isEnabled = false
                deleteAllMenuButton.isEnabled = false
                exportMenuButton.isEnabled = false
                
                undo = 1
            }))
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}
