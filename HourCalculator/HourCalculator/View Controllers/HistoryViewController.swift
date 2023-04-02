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
    
    @IBOutlet weak var historyNavigationBar: UINavigationBar!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var deleteSelected1: UIButton!
    
    @IBOutlet var exportMenuButton: UIBarButtonItem!
    @IBOutlet weak var deleteAllMenuButton: UIBarButtonItem!
    //@IBOutlet weak var deleteSelected1: UIButton!
    @IBOutlet weak var editMenuButton: UIBarButtonItem!
    
    @IBOutlet weak var infoButton: UIBarButtonItem!
    var tappedItem: Hours!
    
    let userDefaults = UserDefaults.standard
    
    var totalHoursText : String!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var undo = 0
    var total : Double = 0.0
    
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
                sort = NSSortDescriptor(key: #keyPath(Hours.totalHours), ascending: false)
            }
            else if userDefaults.integer(forKey: "historySort") == 3 {
                sort = NSSortDescriptor(key: #keyPath(Hours.totalHours), ascending: true)
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
            tableView.setEditing(true, animated: true)
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            editButton.title = "Cancel"
            deleteSelected1.isHidden = false
        }
    }
    
    //lazy var bannerView: GADBannerView! = GADBannerView(adSize: kGADAdSizeBanner)
    
    override var canBecomeFirstResponder: Bool {
        get {
            return true
        }
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            if undo == 1 {
    
                print("Why are you shaking me?")
                let alert = UIAlertController(title: "Undo", message: "Would you like to undo recent hour deletion?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [self]_ in
                    (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.rollback()
                    
                    UIView.transition(with: self.tableView, duration: 0.25, options: [.transitionCrossDissolve, .preferredFramesPerSecond60], animations: {self.tableView.reloadData()}, completion: nil)
                    
                    editMenuButton.isEnabled = true
                    infoButton.isEnabled = true
                    deleteAllMenuButton.isEnabled = true
                    exportMenuButton.isEnabled = true
                    noHoursStoredBackground()
                    
                    undo = 0
                    
                    tabBarController?.tabBar.items?[1].badgeValue = String(hourItems.count)
                    tabBarController?.tabBar.items?[2].badgeValue = String(timeCards.count)
                }))
                alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
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
        
        //let notificationName2 = NSNotification.Name("info")
        // NotificationCenter.default.post(name: notificationName2, object: nil)
        
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
        
        //addBannerViewToView(bannerView)
        
        //bannerView.adUnitID = "ca-app-pub-4546055219731501/2396708566"
        //bannerView.rootViewController = self
        //bannerView.load(GADRequest())
        
        self.tableView.delegate = self
        
        self.tableView.dataSource = self
        
        tableView.tableFooterView = UIView()
        
        tableView.allowsMultipleSelection = true
        
        tableView.allowsMultipleSelectionDuringEditing = true
        
        noHoursStoredBackground()
    }
    
    func noHoursStoredBackground() {
        if hourItems.count == 0 {
            
            let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.accessibilityFrame.size.width, height: self.accessibilityFrame.size.height))
            messageLabel.text = "There are currently no hours stored"
            messageLabel.numberOfLines = 0;
            messageLabel.textAlignment = .center;
            messageLabel.font = UIFont.systemFont(ofSize: 16.0, weight: UIFont.Weight.medium)
            messageLabel.sizeToFit()
            self.tableView.backgroundView = messageLabel;
            
            tableView.separatorStyle = .none;
        }
        else {
            tableView.backgroundView = nil
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        noHoursStoredBackground()
        
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
        
        view.backgroundColor = tableView.backgroundColor
        
        UIView.animate(withDuration: 0.5, delay: 0, options: [.transitionCrossDissolve, .preferredFramesPerSecond60], animations: {
            self.tableView.reloadData()
        }, completion: nil)
        
        deleteSelected1.backgroundColor = UserDefaults().colorForKey(key: "accentColor")
        
        noHoursStoredBackground()
    
        UIView.animate(withDuration: 0.5, delay: 0, options: [.transitionCrossDissolve, .preferredFramesPerSecond60], animations: {
            self.tableView.reloadData()
        }, completion: nil)
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
        DispatchQueue.main.async {
            let inTime = String(hourItems.inTime!)
            let outTime = String(hourItems.outTime!)
            let totalHours = String(hourItems.totalHours!)
            let date = hourItems.date!
            let breakTime = hourItems.breakTime
            
            
            cell.inTimeLabel.text = "In Time: \(inTime)"
            cell.outTimeLabel.text = "Out Time: \(outTime)"
            cell.totalHoursLabel.text = "Total Hours: \(totalHours)"
            
            if breakTime == nil || breakTime == "" {
                cell.breakTimeLabel.text = "Break Time: 0 Minutes"
            }
            else {
                cell.breakTimeLabel.text = "Break Time: \(breakTime ?? "0") Minutes"
            }
            
            cell.dateLabel.text = "Date: \(date)"
        }
        return cell
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        undo = 0
        tableView.setEditing(false, animated: false)
        editButton.title = "Edit"
        deleteSelected1.isHidden = true
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .destructive,
                                        title: "Delete") { (action, view, completionHandler) in
            let alert = UIAlertController(title: "Warning", message: "You are fixing to delete a single entry, would you like to continue?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {_ in
                let hourToDelete = self.hourItems[indexPath.row]
                self.context.delete(hourToDelete)
                
                self.tableView.deleteRows(at: [indexPath], with: .fade)
                
                self.undo = 1
                
                self.tabBarController?.tabBar.items?[1].badgeValue = String(self.hourItems.count)
                
                self.noHoursStoredBackground()
                
                if UserDefaults.standard.integer(forKey: "undoAlertMessage") == 0 {
                    let alert = UIAlertController(title: nil, message: "You can shake your phone in order to restore an hour", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: {_ in
                        UserDefaults.standard.setValue(1, forKey: "undoAlertMessage")
                    }
                    ))
                    self.present(alert, animated: true, completion: nil)
                }
            }))
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: {_ in
                completionHandler(false)
            }))
            self.present(alert, animated: true, completion: nil)
        }
        let exportAction = UIContextualAction(style: .normal, title: "Export") { (action, view, completionHandler) in
            let alert = UIAlertController(title: "Warning", message: "You are fixing to export a single hour. Would you like to continue?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {_ in
                var random : Int32!
                do {
                    random = Int32.random(in: 1...500)
                }
                while self.timeCards.contains(where: { $0.id_number == random }) {
                    random = Int32.random(in: 1...500)
                }
                
                let timeCards = TimeCards(context: self.context)
                let date = "\(self.hourItems[indexPath.row].date ?? "Unknown")"
                timeCards.week = date
                timeCards.id_number = random
                
                let hourToDelete = self.hourItems[indexPath.row]
                self.total = Double(self.hourItems[indexPath.row].totalHours!)!
                
                let timeCardsInfo = TimeCardInfo(context: self.context)
                timeCardsInfo.id_number = random
                timeCardsInfo.intime = self.hourItems[indexPath.row].inTime
                timeCardsInfo.outtime = self.hourItems[indexPath.row].outTime
                timeCardsInfo.total_hours = self.hourItems[indexPath.row].totalHours
                timeCardsInfo.date = self.hourItems[indexPath.row].date
                
                let gallery = Gallery(context: self.context)
                gallery.id_number = random
                
                self.context.delete(hourToDelete)
                self.tableView.deleteRows(at: [indexPath], with: .left)
                
                self.undo = 1
                
                timeCards.total = self.total
                timeCards.numberBeingExported = Int64(1)
                //UIView.animate(withDuration: 0.5, delay: 0, options: [.transitionCrossDissolve, .preferredFramesPerSecond60], animations: {
                   // self.tableView.reloadData()
                //}, completion: nil)
                self.noHoursStoredBackground()
                self.tabBarController?.tabBar.items?[2].badgeValue = String(self.timeCards.count)
                self.tabBarController?.tabBar.items?[1].badgeValue = String(self.hourItems.count)
                if self.hourItems.count == 0 {
                    self.editButton.isEnabled = false
                    self.infoButton.isEnabled = false
                    self.deleteAllMenuButton.isEnabled = false
                    self.exportMenuButton.isEnabled = false
                }
            }))
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: {_ in
                completionHandler(false)
            }))
            self.present(alert, animated: true, completion: nil)
        }
        let swipeActionConfig = UISwipeActionsConfiguration(actions: [action, exportAction])
        action.backgroundColor = .systemRed
        exportAction.backgroundColor = .systemBlue
        return swipeActionConfig
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
            deleteSelected1.isEnabled = true
            deleteSelected1.alpha = 1.0
            
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
            deleteSelected1.isEnabled = false
            deleteSelected1.alpha = 0.80
        }
    }
    
    private var finishedLoadingInitialTableCells = false
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if hourItems.count > 0 {
            DispatchQueue.main.async { [self] in
                
                var lastInitialDisplayableCell = false
                
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
                    
                    cell.transform = CGAffineTransform(translationX: 0, y: tableView.rowHeight/2)
                    cell.alpha = 0
                    
                    UIView.animate(withDuration: 0.25, delay: 0.0, options: [.transitionCrossDissolve, .preferredFramesPerSecond60], animations: {
                        cell.transform = CGAffineTransform(translationX: 0, y: 0)
                        cell.alpha = 1
                    }, completion: nil)
                }
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
            self.deleteSelected1.isHidden = true
            self.editButton.title = "Edit"
        }
        
        let alert = UIAlertController(title: "Delete All?", message: "Are you sure you would like to delete all stored hours?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [self]_ in
            undo = 1
            DispatchQueue.main.async { [self] in
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
                deleteSelected1.isHidden = true
                editButton.title = "Edit"
            }
            else if tableView.isEditing == true && tableView.indexPathsForSelectedRows?.count != 0 {
                tableView.setEditing(false, animated: true)
                deleteSelected1.isHidden = true
                editButton.title = "Edit"
            }
            else if tableView.isEditing == false {
                deleteSelected1.isEnabled = false
                deleteSelected1.alpha = 0.80
                tableView.setEditing(true, animated: true)
                deleteSelected1.isHidden = false
                editButton.title = "Cancel"
            }
            else {
                deleteSelected1.isEnabled = false
                deleteSelected1.alpha = 0.80
                tableView.setEditing(true, animated: true)
                deleteSelected1.isHidden = false
                editButton.title = "Cancel"
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 70, right: 0)
        }
        else {
            self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 45, right: 0)
        }
    }
    
    func deleteSelectedDialog() {
        if UserDefaults.standard.integer(forKey: "undoAlertMessage") == 0 {
            let alert = UIAlertController(title: nil, message: "You can shake your phone in order to restore an hour", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: {_ in
                UserDefaults.standard.setValue(1, forKey: "undoAlertMessage")
                self.deleteSelected()
            }
            ))
            self.present(alert, animated: true, completion: nil)
        }
        else {
            deleteSelected()
        }
    }
    
    func deleteSelected() {
        
        let alert = UIAlertController(title: "Warning", message: "You are fixing to delete selected hours. Would you like to continue?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [self]_ in
        if let indexPaths = tableView.indexPathsForSelectedRows {
            let sortedPaths = indexPaths.sorted {$0.row > $1.row}
            
            var items = [Hours]()
            for indexPath in sortedPaths {
                items.append(hourItems[indexPath.row])
            }
            
            for item in items.reversed() {
                if let index = hourItems.firstIndex(of: item) {
                    let hourToDelete = self.hourItems[index]
                    
                    context.delete(hourToDelete)
                    
                }
            }
            
            self.tableView.deleteRows(at: sortedPaths, with: .fade)
            noHoursStoredBackground()
            tabBarController?.tabBar.items?[1].badgeValue = String(hourItems.count)
            undo = 1
        }
            
            tableView.setEditing(false, animated: true)
            editButton.title = "Edit"
            deleteSelected1.isHidden = true
            
        }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
        
        if (hourItems.count == 0) {
            editButton.isEnabled = false
            deleteSelected1.isHidden = false
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
    }
    
    //@IBAction func deleteSelected1Tapped(_ sender: UIButton) {
        
        
        
   // }
    
    
    @IBAction func deleteSelected1ButtonTapped(_ sender: Any) {
        
        deleteSelectedDialog()
    }
    
    @IBAction func infoButtonTapped(_ sender: UIBarButtonItem) {
        if tableView.isEditing == true {
            tableView.setEditing(false, animated: true)
            editButton.title = "Edit"
            deleteSelected1.isHidden = true
        }
        
        self.calculate()
        
    }
    
    func calculate() {
        DispatchQueue.main.async {
            
            var rounded = 0.0
            
            let count = self.hourItems.count - 1
            print("count is \(count)")
            self.total = 0.0
            do {
                if self.hourItems.count > 0 {
                    for n in 0...count {
                        self.total += Double(self.hourItems[n].totalHours!)!

                    }
                    rounded = round(self.total * 100.00) / 100.00
                    self.totalHoursText = "Total Hours: \(rounded)"
                }
                else {
                    self.totalHoursText = "Total Hours: 0"
                }
            }
            self.dismiss(animated: true, completion: nil)
            let titleFont = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20)]
            let titleAttrString = NSMutableAttributedString(string: self.totalHoursText, attributes: titleFont)
            
            var alert = UIAlertController()
            
            if UIDevice.current.userInterfaceIdiom == .pad {
                alert = UIAlertController(title: nil, message: nil,  preferredStyle: .actionSheet)
                let popover = alert.popoverPresentationController
                popover!.sourceView = self.view
                popover?.barButtonItem = self.infoButton as UIBarButtonItem
            }
            else {
            alert = UIAlertController(title: nil, message: nil,  preferredStyle: .actionSheet)
            
            }
            alert.setValue(titleAttrString, forKey:"attributedTitle")
            
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            self.present(alert, animated: true)
        }
    }
    
    @objc func reloadTableView() {
        UIView.animate(withDuration: 0.5, delay: 0, options: [.transitionCrossDissolve, .preferredFramesPerSecond60], animations: {
            self.tableView.reloadData()
        }, completion: nil)
        tabBarController?.tabBar.items?[1].badgeValue = String(hourItems.count)
        if hourItems.count == 0 {
            self.deleteAllMenuButton.isEnabled = false
            self.editMenuButton.isEnabled = false
            self.infoButton.isEnabled = false
            self.exportMenuButton.isEnabled = false
        }
        noHoursStoredBackground()
    }
    
    func dateFromString(dateStr: String) -> NSDate {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"

        // Eric D's suggestion, forcing locale to en_EN
        dateFormatter.locale = NSLocale(localeIdentifier: "en_EN") as Locale

        return dateFormatter.date(from: dateStr)! as NSDate
    }
    
    @IBAction func exportButton(_ sender: Any) {
        
        var hoursForExport: [Hours] {
            
            do {
                let fetchrequest = NSFetchRequest<Hours>(entityName: "Hours")
                let sort = NSSortDescriptor(key: #keyPath(Hours.date), ascending: true)
                fetchrequest.sortDescriptors = [sort]
                return try context.fetch(fetchrequest)
                
            } catch {
                
                print("Couldn't fetch data")
                
            }
            
            return [Hours]()
            
        }
        
        var random : Int32!
        do {
            random = Int32.random(in: 1...500)
        }
        while timeCards.contains(where: { $0.id_number == random }) {
            random = Int32.random(in: 1...500)
        }
        
        if tableView.isEditing == true {
            let alert = UIAlertController(title: "Warning", message: "You are fixing to export selected hours. Would you like to continue?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {_ in
                if let indexPaths = self.tableView.indexPathsForSelectedRows {
                    let sortedPaths = indexPaths.sorted {$0.row > $1.row}
                    let firstIndex = (sortedPaths.last?.row)!
                    let lastIndex = (sortedPaths.first?.row)!
                    
                    let timeCards = TimeCards(context: self.context)
                    let gallery = Gallery(context: self.context)
                    var total = 0.0
                    
                    let date = "\(hoursForExport[firstIndex].date ?? "Unknown")-\(hoursForExport[lastIndex].date ?? "Unkown")"
                    
                    timeCards.week = date
                    timeCards.numberBeingExported = Int64(self.hourItems.count)
                    
                    var items = [Hours]()
                    for indexPath in sortedPaths {
                        items.append(self.hourItems[indexPath.row])
                    }
                    
                    for item in items.reversed() {
                        if let index = self.hourItems.firstIndex(of: item) {
                            
                            let timeCardsInfo = TimeCardInfo(context: self.context)
                            timeCardsInfo.id_number = random
                            timeCardsInfo.intime = hoursForExport[index].inTime
                            timeCardsInfo.outtime = hoursForExport[index].outTime
                            timeCardsInfo.total_hours = hoursForExport[index].totalHours
                            timeCardsInfo.date = hoursForExport[index].date
                            
                            let hourToDelete = self.hourItems[index]
                            total += Double(hoursForExport[index].totalHours!)!
                            
                            self.context.delete(hourToDelete)
                            
                        }
                    }
                    self.tableView.deleteRows(at: sortedPaths, with: .fade)
                    
                    timeCards.total = total
                    timeCards.id_number = random
                    gallery.id_number = random
                    self.noHoursStoredBackground()
                    self.tabBarController?.tabBar.items?[1].badgeValue = String(self.hourItems.count)
                    
                    self.tabBarController?.tabBar.items?[2].badgeValue = String(self.timeCards.count)
                    self.undo = 1
                    self.tableView.setEditing(false, animated: true)
                }
            }))
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: {_ in
                self.tableView.setEditing(false, animated: true)
            }))
            self.present(alert, animated: true, completion: nil)
            
            //tableView.setEditing(false, animated: true)
            deleteSelected1.isHidden = true
            editButton.title = "Edit"
        }
        else {
            if hourItems.count > 7 {
                let alert = UIAlertController(title: "Warning", message: "You have more than 7 hours stored, would you like to continue?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {_ in
                    let timeCards = TimeCards(context: self.context)
                    let gallery = Gallery(context: self.context)
                    var total = 0.0
                    
                    let date = "\(hoursForExport.first!.date ?? "Unknown")-\(hoursForExport.last!.date ?? "Unkown")"
                    timeCards.week = date
                    timeCards.numberBeingExported = Int64(self.hourItems.count)
                    
                    for i in (0...self.hourItems.count - 1) {
                        
                        let timeCardsInfo = TimeCardInfo(context: self.context)
                        timeCardsInfo.id_number = random
                        timeCardsInfo.intime = hoursForExport[i].inTime
                        timeCardsInfo.outtime = hoursForExport[i].outTime
                        timeCardsInfo.total_hours = hoursForExport[i].totalHours
                        timeCardsInfo.date = hoursForExport[i].date
                        
                    }
                    
                    for i in (0...self.hourItems.count - 1).reversed() {
                        let hourToDelete = hoursForExport[i]
                        total += Double(hoursForExport[i].totalHours!)!
                        
                        self.context.delete(hourToDelete)
                        let index = [0, i] as IndexPath
                        self.tableView.deleteRows(at: [index], with: .fade)
                        
                        timeCards.total = total
                    }
                    timeCards.id_number = random
                    gallery.id_number = random
                    self.noHoursStoredBackground()
                    self.tabBarController?.tabBar.items?[1].badgeValue = String(self.hourItems.count)
                    self.editButton.isEnabled = false
                    self.infoButton.isEnabled = false
                    self.deleteAllMenuButton.isEnabled = false
                    self.exportMenuButton.isEnabled = false
                    self.tabBarController?.tabBar.items?[2].badgeValue = String(self.timeCards.count)
                    self.undo = 1
                }))
                alert.addAction(UIAlertAction(title: "Just Export 7", style: .default, handler: {_ in
                    let timeCards = TimeCards(context: self.context)
                    let gallery = Gallery(context: self.context)
                    var total = 0.0
                    
                    let date = "\(hoursForExport[0].date ?? "Unknown")-\(hoursForExport[6].date ?? "Unkown")"
                    timeCards.week = date
                    
                    for i in (0...6) {
                        
                        let timeCardsInfo = TimeCardInfo(context: self.context)
                        timeCardsInfo.id_number = random
                        timeCardsInfo.intime = hoursForExport[i].inTime
                        timeCardsInfo.outtime = hoursForExport[i].outTime
                        timeCardsInfo.total_hours = hoursForExport[i].totalHours
                        timeCardsInfo.date = hoursForExport[i].date
                        
                    }
                    
                    for i in (0...6).reversed() {
                        let hourToDelete = hoursForExport[i]
                        total += Double(hoursForExport[i].totalHours!)!
                        
                        self.context.delete(hourToDelete)
                        let index = [0, i] as IndexPath
                        self.tableView.deleteRows(at: [index], with: .fade)
                        
                        timeCards.total = total
                    }
                    timeCards.id_number = random
                    gallery.id_number = random
                    timeCards.numberBeingExported = Int64(7)
                    UIView.animate(withDuration: 0.5, delay: 0, options: [.transitionCrossDissolve, .preferredFramesPerSecond60], animations: {
                        self.tableView.reloadData()
                    }, completion: nil)
                    self.noHoursStoredBackground()
                    self.tabBarController?.tabBar.items?[2].badgeValue = String(self.timeCards.count)
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
                    let gallery = Gallery(context: self.context)
                    var total = 0.0
                    let date = "\(hoursForExport.first!.date ?? "Unknown")-\(hoursForExport.last!.date ?? "Unkown")"
                    timeCards.week = date
                    timeCards.numberBeingExported = Int64(self.hourItems.count)
                    
                    for i in (0...self.hourItems.count - 1) {
                        
                        let timeCardsInfo = TimeCardInfo(context: self.context)
                        timeCardsInfo.id_number = random
                        timeCardsInfo.intime = hoursForExport[i].inTime
                        timeCardsInfo.outtime = hoursForExport[i].outTime
                        timeCardsInfo.total_hours = hoursForExport[i].totalHours
                        timeCardsInfo.date = hoursForExport[i].date
                        
                    }
                    
                    for i in (0...self.hourItems.count - 1).reversed() {
                        let hourToDelete = hoursForExport[i]
                        total += Double(hoursForExport[i].totalHours!)!
                        
                        self.context.delete(hourToDelete)
                        let index = [0, i] as IndexPath
                        self.tableView.deleteRows(at: [index], with: .fade)
                        
                        timeCards.total = total
                    }
                    timeCards.id_number = random
                    gallery.id_number = random
                    self.noHoursStoredBackground()
                    self.tabBarController?.tabBar.items?[1].badgeValue = String(self.hourItems.count)
                    self.editButton.isEnabled = false
                    self.infoButton.isEnabled = false
                    self.deleteAllMenuButton.isEnabled = false
                    self.exportMenuButton.isEnabled = false
                    self.tabBarController?.tabBar.items?[2].badgeValue = String(self.timeCards.count)
                    self.undo = 1
                }))
                alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            else {
                let alert = UIAlertController(title: "Warning", message: "You have less than a weeks worth of hours, would you like to continue?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [self]_ in
                    let timeCards = TimeCards(context: self.context)
                    let gallery = Gallery(context: self.context)
                    
                    var total = 0.0
                    var date : String!
                    if self.hourItems.count > 1 {
                        date = "\(hoursForExport.first!.date ?? "Unknown")-\(hoursForExport.last!.date ?? "Unkown")"
                    }
                    else {
                        date = "\(hoursForExport.first!.date ?? "Unknown")"
                    }
                    timeCards.week = date
                    timeCards.numberBeingExported = Int64(self.hourItems.count)
                    
                    for i in (0...hourItems.count - 1) {
                        
                        let timeCardsInfo = TimeCardInfo(context: self.context)
                        timeCardsInfo.id_number = random
                        timeCardsInfo.intime = hoursForExport[i].inTime
                        timeCardsInfo.outtime = hoursForExport[i].outTime
                        timeCardsInfo.total_hours = hoursForExport[i].totalHours
                        timeCardsInfo.date = hoursForExport[i].date
                        
                    }
                    for i in (0...self.hourItems.count - 1).reversed() {
                        let hourToDelete = hoursForExport[i]
                        total += Double(hoursForExport[i].totalHours!)!
                        
                        self.context.delete(hourToDelete)
                        let index = [0, i] as IndexPath
                        self.tableView.deleteRows(at: [index], with: .fade)
                        
                    }
                    
                    timeCards.total = total
                    timeCards.id_number = random
                    gallery.id_number = random
                    
                    noHoursStoredBackground()
                    tabBarController?.tabBar.items?[1].badgeValue = String(self.hourItems.count)
                    editButton.isEnabled = false
                    infoButton.isEnabled = false
                    deleteAllMenuButton.isEnabled = false
                    exportMenuButton.isEnabled = false
                    self.tabBarController?.tabBar.items?[2].badgeValue = String(self.timeCards.count)
                    undo = 1
                }))
                alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
}
