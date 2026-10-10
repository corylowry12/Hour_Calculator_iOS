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
    @IBOutlet weak var moreMenuButton: UIBarButtonItem!
    
    @IBOutlet weak var deleteSelectedButton: UIButton!
    
    var tappedItem: Hours!
    
    let userDefaults = UserDefaults.standard
    
    var totalHoursText: String!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var undo = 0
    var total: Double = 0.0
    
    var currentAccentColor: UIColor {
        let accent = userDefaults.integer(forKey: "accent")
        switch accent {
        case 0: return UIColor(rgb: 0x26A69A)
        case 1: return UIColor(rgb: 0x7841c4)
        case 2: return UIColor(rgb: 0x347deb)
        case 3: return UIColor(rgb: 0xfc783a)
        case 4: return UIColor(rgb: 0xc41d1d)
        default: return UIColor(rgb: 0x26A69A)
        }
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
            editButton?.image = UIImage(systemName: "xmark")
            deleteSelectedButton.isHidden = false
        }
    }
    
    lazy var bannerView: BannerView! = BannerView(adSize: AdSizeBanner)
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake && undo == 1 {
            print("Why are you shaking me?")
            let alert = UIAlertController(title: "Undo", message: "Would you like to undo recent hour deletion?", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [self] _ in
                (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.rollback()
                
                UIView.transition(with: self.tableView, duration: 0.25, options: [.transitionCrossDissolve, .preferredFramesPerSecond60], animations: {
                    self.tableView.reloadData()
                }, completion: nil)
                
                editButton.isEnabled = true
                noHoursStoredBackground()
                undo = 0
                
                tabBarController?.tabBar.items?[1].badgeValue = String(hourItems.count)
                tabBarController?.tabBar.items?[2].badgeValue = String(timeCards.count)
            }))
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
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
        
        let notificationName = NSNotification.Name("Update")
        NotificationCenter.default.addObserver(self, selector: #selector(HistoryViewController.reloadTableView), name: notificationName, object: nil)
        
        editButton.isEnabled = hourItems.count > 0
        
        addBannerViewToView(bannerView)
        bannerView.adUnitID = "ca-app-pub-4546055219731501/2396708566"
        bannerView.rootViewController = self
        bannerView.load(Request())
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.allowsMultipleSelection = true
        tableView.allowsMultipleSelectionDuringEditing = true
        
        noHoursStoredBackground()
        setupMoreMenu()
    }
    
    func noHoursStoredBackground() {
        if hourItems.count == 0 {
            let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.accessibilityFrame.size.width, height: self.accessibilityFrame.size.height))
            messageLabel.text = "There are currently no hours stored"
            messageLabel.numberOfLines = 0
            messageLabel.textAlignment = .center
            messageLabel.font = UIFont.systemFont(ofSize: 16.0, weight: UIFont.Weight.medium)
            messageLabel.sizeToFit()
            self.tableView.backgroundView = messageLabel
            tableView.separatorStyle = .none
        }
        else {
            tableView.backgroundView = nil
        }
    }
    
    private func setupMoreMenu() {
        let deferredMenu = UIDeferredMenuElement { [weak self] completion in
            guard let self = self else {
                completion([])
                return
            }

            let hasItems = !self.hourItems.isEmpty

            let exportAction = UIAction(
                title: "Export",
                image: UIImage(systemName: "square.and.arrow.up"),
                attributes: hasItems ? [] : .disabled
            ) { _ in
                self.handleExport()
                self.setupMoreMenu()
            }

            let infoAction = UIAction(
                title: "Info",
                image: UIImage(systemName: "info.circle"),
                attributes: hasItems ? [] : .disabled
            ) { _ in
                self.handleInfo()
            }

            let deleteAllAction = UIAction(
                title: "Delete All",
                image: UIImage(systemName: "trash"),
                attributes: hasItems ? .destructive : [.destructive, .disabled]
            ) { _ in
                self.handleDeleteAll()
                self.setupMoreMenu()
            }

            completion([exportAction, infoAction, deleteAllAction])
        }

        moreMenuButton.menu = UIMenu(title: "", children: [deferredMenu])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        noHoursStoredBackground()
        self.editButton.isEnabled = hourItems.count > 0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        view.backgroundColor = tableView.backgroundColor
        
        UIView.animate(withDuration: 0.5, delay: 0, options: [.transitionCrossDissolve, .preferredFramesPerSecond60], animations: {
            self.tableView.reloadData()
        }, completion: nil)
        
        deleteSelectedButton.backgroundColor = currentAccentColor
        noHoursStoredBackground()
        editButton.isEnabled = hourItems.count > 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return hourItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let hourItem = hourItems[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "HourItems", for: indexPath) as! TableViewCell
        
        DispatchQueue.main.async {
            let inTime = String(hourItem.inTime ?? "")
            let outTime = String(hourItem.outTime ?? "")
            let totalHours = String(hourItem.totalHours ?? "")
            let date = hourItem.date ?? ""
            
            cell.inTimeLabel.text = "In Time: \(inTime)"
            cell.outTimeLabel.text = "Out Time: \(outTime)"
            cell.totalHoursLabel.text = "Total Hours: \(totalHours)"
            cell.dateLabel.text = "Date: \(date)"
        }
        return cell
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        undo = 0
        tableView.setEditing(false, animated: false)
        editButton?.image = UIImage(systemName: "pencil")
        deleteSelectedButton.isHidden = true
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .destructive, title: "Delete") { (action, view, completionHandler) in
            let alert = UIAlertController(title: "Warning", message: "You are fixing to delete a single entry, would you like to continue?", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
                let hourToDelete = self.hourItems[indexPath.row]
                self.context.delete(hourToDelete)
                
                self.tableView.deleteRows(at: [indexPath], with: .fade)
                self.undo = 1
                self.tabBarController?.tabBar.items?[1].badgeValue = String(self.hourItems.count)
                self.noHoursStoredBackground()
                
                if UserDefaults.standard.integer(forKey: "undoAlertMessage") == 0 {
                    let alert = UIAlertController(title: nil, message: "You can shake your phone in order to restore an hour", preferredStyle: .actionSheet)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
                        UserDefaults.standard.setValue(1, forKey: "undoAlertMessage")
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            }))
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { _ in
                completionHandler(false)
            }))
            self.present(alert, animated: true, completion: nil)
        }
        
        let exportAction = UIContextualAction(style: .normal, title: "Export") { (action, view, completionHandler) in
            let alert = UIAlertController(title: "Warning", message: "You are fixing to export a single hour. Would you like to continue?", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
                var random: Int32!
                repeat {
                    random = Int32.random(in: 1...500)
                } while self.timeCards.contains(where: { $0.id_number == random })
                
                let timeCards = TimeCards(context: self.context)
                let date = "\(self.hourItems[indexPath.row].date ?? "Unknown")"
                timeCards.week = date
                timeCards.id_number = random
                
                let hourToDelete = self.hourItems[indexPath.row]
                self.total = Double(self.hourItems[indexPath.row].totalHours ?? "0") ?? 0.0
                
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
                
                self.noHoursStoredBackground()
                self.tabBarController?.tabBar.items?[2].badgeValue = String(self.timeCards.count)
                self.tabBarController?.tabBar.items?[1].badgeValue = String(self.hourItems.count)
            }))
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { _ in
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
        let action = UIContextualAction(style: .normal, title: "Edit") { (action, view, completionHandler) in
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
        
        if !tableView.isEditing {
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
    
    func addBannerViewToView(_ bannerView: BannerView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        view.addConstraints([
            NSLayoutConstraint(item: bannerView,
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
                               constant: 0)
        ])
    }
    
    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        addBannerViewToView(bannerView)
        bannerView.alpha = 0
        UIView.animate(withDuration: 1, animations: {
            bannerView.alpha = 1
        })
    }
    
    private func handleDeleteAll() {
        if self.tableView.isEditing {
            self.tableView.setEditing(false, animated: true)
            self.deleteSelectedButton.isHidden = true
        }
        
        let alert = UIAlertController(title: "Delete All?", message: "Are you sure you would like to delete all stored hours?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [self] _ in
            undo = 1
            DispatchQueue.main.async {
                for i in (0...self.hourItems.count - 1).reversed() {
                    let index = [0, i] as IndexPath
                    let hourToDelete = self.hourItems[i]
                    
                    self.context.delete(hourToDelete)
                    self.tableView.deleteRows(at: [index], with: .fade)
                }
                self.noHoursStoredBackground()
                tabBarController?.tabBar.items?[1].badgeValue = String(self.hourItems.count)
            }
            
            if UserDefaults.standard.integer(forKey: "undoAlertMessage") == 0 {
                let alert = UIAlertController(title: nil, message: "You can shake your phone in order to restore an hour", preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
                    UserDefaults.standard.setValue(1, forKey: "undoAlertMessage")
                }))
                self.present(alert, animated: true, completion: nil)
            }
            
            let range = NSMakeRange(0, self.tableView.numberOfSections)
            let sections = NSIndexSet(indexesIn: range)
            self.tableView.reloadSections(sections as IndexSet, with: .fade)
            
            self.tabBarController?.tabBar.items?[1].badgeValue = String(self.hourItems.count)
            self.editButton.isEnabled = false
            noHoursStoredBackground()
        }))
        
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    @IBAction func editButtonTapped(_ sender: Any) {
        if hourItems.count > 0 {
            if tableView.isEditing && (tableView.indexPathsForSelectedRows?.count ?? 0) == 0 {
                tableView.setEditing(false, animated: true)
                deleteSelectedButton.isHidden = true
                editButton?.image = UIImage(systemName: "pencil")
            }
            else if tableView.isEditing && (tableView.indexPathsForSelectedRows?.count ?? 0) != 0 {
                tableView.setEditing(false, animated: true)
                deleteSelectedButton.isHidden = true
                editButton?.image = UIImage(systemName: "pencil")
            }
            else {
                deleteSelectedButton.isEnabled = false
                deleteSelectedButton.alpha = 0.80
                tableView.setEditing(true, animated: true)
                deleteSelectedButton.isHidden = false
                editButton?.image = UIImage(systemName: "xmark")
            }
        }
    }
    
    @IBAction func deleteSelectedButtonTapped(_ sender: UIButton) {
        if UserDefaults.standard.integer(forKey: "undoAlertMessage") == 0 {
            let alert = UIAlertController(title: nil, message: "You can shake your phone in order to restore an hour", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
                UserDefaults.standard.setValue(1, forKey: "undoAlertMessage")
            }))
            self.present(alert, animated: true, completion: nil)
        }
        
        let alert = UIAlertController(title: "Warning", message: "You are fixing to delete selected hours. Would you like to continue?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [self] _ in
            if let indexPaths = tableView.indexPathsForSelectedRows {
                let sortedPaths = indexPaths.sorted { $0.row > $1.row }
                
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
            editButton?.image = UIImage(systemName: "pencil")
            deleteSelectedButton.isHidden = true
        }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
        
        editButton.isEnabled = hourItems.count > 0
    }
    
    private func handleInfo() {
        if tableView.isEditing {
            tableView.setEditing(false, animated: true)
            editButton?.image = UIImage(systemName: "pencil")
            deleteSelectedButton.isHidden = true
        }
        showLiquidGlassInfoModal()
    }
    
    private func showLiquidGlassInfoModal() {
        var calculatedTotal = 0.0
        for item in hourItems {
            if let hoursStr = item.totalHours, let val = Double(hoursStr) {
                calculatedTotal += val
            }
        }
        let totalHoursFormatted = round(calculatedTotal * 100.0) / 100.0
        let entriesCount = hourItems.count
        
        let modalVC = UIViewController()
        modalVC.modalPresentationStyle = .overFullScreen
        modalVC.modalTransitionStyle = .crossDissolve
        modalVC.view.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        
        // 1. Dismiss background overlay
        let dismissButton = UIButton(frame: modalVC.view.bounds)
        dismissButton.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        dismissButton.addTarget(self, action: #selector(dismissLiquidGlassModal), for: .touchUpInside)
        modalVC.view.addSubview(dismissButton)
        
        // 2. Liquid Glass Backdrop
        let blurEffect = UIBlurEffect(style: .systemThinMaterial)
        let glassContainer = UIVisualEffectView(effect: blurEffect)
        glassContainer.layer.cornerRadius = 24
        glassContainer.layer.masksToBounds = true
        glassContainer.layer.borderWidth = 1.0
        glassContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.25).cgColor
        glassContainer.translatesAutoresizingMaskIntoConstraints = false
        modalVC.view.addSubview(glassContainer)
        
        // 3. Header Icon & Title
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 32, weight: .semibold)
        let iconImageView = UIImageView(image: UIImage(systemName: "clock.badge.checkmark.fill", withConfiguration: iconConfig))
        iconImageView.tintColor = currentAccentColor
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = "History Summary"
        titleLabel.font = UIFont.systemFont(ofSize: 19, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let divider = UIView()
        divider.backgroundColor = UIColor.separator.withAlphaComponent(0.35)
        divider.translatesAutoresizingMaskIntoConstraints = false
        
        // 4. Info Rows Container
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        func createInfoCard(icon: String, title: String, value: String) -> UIView {
            let card = UIView()
            card.backgroundColor = UIColor.secondarySystemFill.withAlphaComponent(0.35)
            card.layer.cornerRadius = 14
            card.layer.masksToBounds = true
            card.translatesAutoresizingMaskIntoConstraints = false
            
            let rowIcon = UIImageView(image: UIImage(systemName: icon))
            rowIcon.tintColor = currentAccentColor
            rowIcon.contentMode = .scaleAspectFit
            rowIcon.translatesAutoresizingMaskIntoConstraints = false
            
            let textStack = UIStackView()
            textStack.axis = .vertical
            textStack.spacing = 3
            textStack.alignment = .fill
            textStack.translatesAutoresizingMaskIntoConstraints = false
            
            let rowTitle = UILabel()
            rowTitle.text = title.uppercased()
            rowTitle.font = UIFont.systemFont(ofSize: 11, weight: .bold)
            rowTitle.textColor = .secondaryLabel
            
            let rowValue = UILabel()
            rowValue.text = value
            rowValue.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
            rowValue.textColor = .label
            rowValue.adjustsFontSizeToFitWidth = true
            rowValue.minimumScaleFactor = 0.8
            
            textStack.addArrangedSubview(rowTitle)
            textStack.addArrangedSubview(rowValue)
            
            card.addSubview(rowIcon)
            card.addSubview(textStack)
            
            NSLayoutConstraint.activate([
                rowIcon.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
                rowIcon.centerYAnchor.constraint(equalTo: card.centerYAnchor),
                rowIcon.widthAnchor.constraint(equalToConstant: 24),
                rowIcon.heightAnchor.constraint(equalToConstant: 24),
                
                textStack.leadingAnchor.constraint(equalTo: rowIcon.trailingAnchor, constant: 12),
                textStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
                textStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
                textStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10)
            ])
            
            return card
        }
        
        let entriesRow = createInfoCard(icon: "list.bullet.rectangle", title: "Hours Stored", value: "\(entriesCount) \(entriesCount == 1 ? "entry" : "entries")")
        let totalHoursRow = createInfoCard(icon: "hourglass.bottomhalf.filled", title: "Total Hours", value: "\(totalHoursFormatted) hrs")
        
        stackView.addArrangedSubview(entriesRow)
        stackView.addArrangedSubview(totalHoursRow)
        
        // 5. Done Button
        let closeButton = UIButton(type: .system)
        var btnConfig = UIButton.Configuration.filled()
        btnConfig.title = "Done"
        btnConfig.baseBackgroundColor = currentAccentColor
        btnConfig.baseForegroundColor = .white
        btnConfig.cornerStyle = .capsule
        btnConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            return outgoing
        }
        closeButton.configuration = btnConfig
        closeButton.addTarget(self, action: #selector(dismissLiquidGlassModal), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        glassContainer.contentView.addSubview(iconImageView)
        glassContainer.contentView.addSubview(titleLabel)
        glassContainer.contentView.addSubview(divider)
        glassContainer.contentView.addSubview(stackView)
        glassContainer.contentView.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            glassContainer.centerXAnchor.constraint(equalTo: modalVC.view.centerXAnchor),
            glassContainer.centerYAnchor.constraint(equalTo: modalVC.view.centerYAnchor),
            glassContainer.widthAnchor.constraint(equalTo: modalVC.view.widthAnchor, multiplier: 0.84),
            glassContainer.widthAnchor.constraint(lessThanOrEqualToConstant: 350),
            
            iconImageView.topAnchor.constraint(equalTo: glassContainer.contentView.topAnchor, constant: 22),
            iconImageView.centerXAnchor.constraint(equalTo: glassContainer.contentView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 34),
            iconImageView.heightAnchor.constraint(equalToConstant: 34),
            
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: glassContainer.contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: glassContainer.contentView.trailingAnchor, constant: -20),
            
            divider.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 14),
            divider.leadingAnchor.constraint(equalTo: glassContainer.contentView.leadingAnchor, constant: 20),
            divider.trailingAnchor.constraint(equalTo: glassContainer.contentView.trailingAnchor, constant: -20),
            divider.heightAnchor.constraint(equalToConstant: 0.5),
            
            stackView.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: glassContainer.contentView.leadingAnchor, constant: 18),
            stackView.trailingAnchor.constraint(equalTo: glassContainer.contentView.trailingAnchor, constant: -18),
            
            closeButton.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 20),
            closeButton.leadingAnchor.constraint(equalTo: glassContainer.contentView.leadingAnchor, constant: 18),
            closeButton.trailingAnchor.constraint(equalTo: glassContainer.contentView.trailingAnchor, constant: -18),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            closeButton.bottomAnchor.constraint(equalTo: glassContainer.contentView.bottomAnchor, constant: -20)
        ])
        
        present(modalVC, animated: true)
    }
    
    @objc private func dismissLiquidGlassModal() {
        dismiss(animated: true)
    }
    
    @objc func reloadTableView() {
        UIView.animate(withDuration: 0.5, delay: 0, options: [.transitionCrossDissolve, .preferredFramesPerSecond60], animations: {
            self.tableView.reloadData()
        }, completion: nil)
        tabBarController?.tabBar.items?[1].badgeValue = String(hourItems.count)
        editButton.isEnabled = hourItems.count > 0
        noHoursStoredBackground()
    }
    
    func dateFromString(dateStr: String) -> NSDate {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        dateFormatter.locale = NSLocale(localeIdentifier: "en_EN") as Locale
        return dateFormatter.date(from: dateStr)! as NSDate
    }
    
    private func handleExport() {
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
        
        var random: Int32!
        repeat {
            random = Int32.random(in: 1...500)
        } while timeCards.contains(where: { $0.id_number == random })
        
        if tableView.isEditing {
            let alert = UIAlertController(title: "Warning", message: "You are fixing to export selected hours. Would you like to continue?", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
                if let indexPaths = self.tableView.indexPathsForSelectedRows {
                    let sortedPaths = indexPaths.sorted { $0.row > $1.row }
                    let firstIndex = (sortedPaths.last?.row)!
                    let lastIndex = (sortedPaths.first?.row)!
                    
                    let timeCards = TimeCards(context: self.context)
                    let gallery = Gallery(context: self.context)
                    var total = 0.0
                    
                    let date = "\(hoursForExport[firstIndex].date ?? "Unknown")-\(hoursForExport[lastIndex].date ?? "Unknown")"
                    
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
                            total += Double(hoursForExport[index].totalHours ?? "0") ?? 0.0
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
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { _ in
                self.tableView.setEditing(false, animated: true)
            }))
            self.present(alert, animated: true, completion: nil)
            
            deleteSelectedButton.isHidden = true
            editButton?.image = UIImage(systemName: "pencil")
        }
        else {
            if hourItems.count > 7 {
                let alert = UIAlertController(title: "Warning", message: "You have more than 7 hours stored, would you like to continue?", preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
                    let timeCards = TimeCards(context: self.context)
                    let gallery = Gallery(context: self.context)
                    var total = 0.0
                    
                    let date = "\(hoursForExport.first!.date ?? "Unknown")-\(hoursForExport.last!.date ?? "Unknown")"
                    timeCards.week = date
                    timeCards.numberBeingExported = Int64(self.hourItems.count)
                    
                    for i in 0...(self.hourItems.count - 1) {
                        let timeCardsInfo = TimeCardInfo(context: self.context)
                        timeCardsInfo.id_number = random
                        timeCardsInfo.intime = hoursForExport[i].inTime
                        timeCardsInfo.outtime = hoursForExport[i].outTime
                        timeCardsInfo.total_hours = hoursForExport[i].totalHours
                        timeCardsInfo.date = hoursForExport[i].date
                    }
                    
                    for i in (0...(self.hourItems.count - 1)).reversed() {
                        let hourToDelete = hoursForExport[i]
                        total += Double(hoursForExport[i].totalHours ?? "0") ?? 0.0
                        self.context.delete(hourToDelete)
                        let index = [0, i] as IndexPath
                        self.tableView.deleteRows(at: [index], with: .fade)
                    }
                    
                    timeCards.total = total
                    timeCards.id_number = random
                    gallery.id_number = random
                    self.noHoursStoredBackground()
                    self.tabBarController?.tabBar.items?[1].badgeValue = String(self.hourItems.count)
                    self.tabBarController?.tabBar.items?[2].badgeValue = String(self.timeCards.count)
                    self.undo = 1
                }))
                alert.addAction(UIAlertAction(title: "Just Export 7", style: .default, handler: { _ in
                    let timeCards = TimeCards(context: self.context)
                    let gallery = Gallery(context: self.context)
                    var total = 0.0
                    
                    let date = "\(hoursForExport[0].date ?? "Unknown")-\(hoursForExport[6].date ?? "Unknown")"
                    timeCards.week = date
                    
                    for i in 0...6 {
                        let timeCardsInfo = TimeCardInfo(context: self.context)
                        timeCardsInfo.id_number = random
                        timeCardsInfo.intime = hoursForExport[i].inTime
                        timeCardsInfo.outtime = hoursForExport[i].outTime
                        timeCardsInfo.total_hours = hoursForExport[i].totalHours
                        timeCardsInfo.date = hoursForExport[i].date
                    }
                    
                    for i in (0...6).reversed() {
                        let hourToDelete = hoursForExport[i]
                        total += Double(hoursForExport[i].totalHours ?? "0") ?? 0.0
                        self.context.delete(hourToDelete)
                        let index = [0, i] as IndexPath
                        self.tableView.deleteRows(at: [index], with: .fade)
                    }
                    
                    timeCards.total = total
                    timeCards.id_number = random
                    gallery.id_number = random
                    timeCards.numberBeingExported = Int64(7)
                    UIView.animate(withDuration: 0.5, delay: 0, options: [.transitionCrossDissolve, .preferredFramesPerSecond60], animations: {
                        self.tableView.reloadData()
                    }, completion: nil)
                    self.noHoursStoredBackground()
                    self.tabBarController?.tabBar.items?[2].badgeValue = String(self.timeCards.count)
                    self.tabBarController?.tabBar.items?[1].badgeValue = String(self.hourItems.count)
                    self.undo = 1
                }))
                alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            else if hourItems.count == 7 {
                let alert = UIAlertController(title: "Warning", message: "You are fixing to export a weeks worth of hours, would you like to continue?", preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
                    let timeCards = TimeCards(context: self.context)
                    let gallery = Gallery(context: self.context)
                    var total = 0.0
                    let date = "\(hoursForExport.first!.date ?? "Unknown")-\(hoursForExport.last!.date ?? "Unknown")"
                    timeCards.week = date
                    timeCards.numberBeingExported = Int64(self.hourItems.count)
                    
                    for i in 0...(self.hourItems.count - 1) {
                        let timeCardsInfo = TimeCardInfo(context: self.context)
                        timeCardsInfo.id_number = random
                        timeCardsInfo.intime = hoursForExport[i].inTime
                        timeCardsInfo.outtime = hoursForExport[i].outTime
                        timeCardsInfo.total_hours = hoursForExport[i].totalHours
                        timeCardsInfo.date = hoursForExport[i].date
                    }
                    
                    for i in (0...(self.hourItems.count - 1)).reversed() {
                        let hourToDelete = hoursForExport[i]
                        total += Double(hoursForExport[i].totalHours ?? "0") ?? 0.0
                        self.context.delete(hourToDelete)
                        let index = [0, i] as IndexPath
                        self.tableView.deleteRows(at: [index], with: .fade)
                    }
                    
                    timeCards.total = total
                    timeCards.id_number = random
                    gallery.id_number = random
                    self.noHoursStoredBackground()
                    self.tabBarController?.tabBar.items?[1].badgeValue = String(self.hourItems.count)
                    self.tabBarController?.tabBar.items?[2].badgeValue = String(self.timeCards.count)
                    self.undo = 1
                }))
                alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            else {
                let alert = UIAlertController(title: "Warning", message: "You have less than a weeks worth of hours, would you like to continue?", preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [self] _ in
                    let timeCards = TimeCards(context: self.context)
                    let gallery = Gallery(context: self.context)
                    var total = 0.0
                    let date = self.hourItems.count > 1 ? "\(hoursForExport.first!.date ?? "Unknown")-\(hoursForExport.last!.date ?? "Unknown")" : "\(hoursForExport.first!.date ?? "Unknown")"
                    
                    timeCards.week = date
                    timeCards.numberBeingExported = Int64(self.hourItems.count)
                    
                    for i in 0...(hourItems.count - 1) {
                        let timeCardsInfo = TimeCardInfo(context: self.context)
                        timeCardsInfo.id_number = random
                        timeCardsInfo.intime = hoursForExport[i].inTime
                        timeCardsInfo.outtime = hoursForExport[i].outTime
                        timeCardsInfo.total_hours = hoursForExport[i].totalHours
                        timeCardsInfo.date = hoursForExport[i].date
                    }
                    
                    for i in (0...(self.hourItems.count - 1)).reversed() {
                        let hourToDelete = hoursForExport[i]
                        total += Double(hoursForExport[i].totalHours ?? "0") ?? 0.0
                        self.context.delete(hourToDelete)
                        let index = [0, i] as IndexPath
                        self.tableView.deleteRows(at: [index], with: .fade)
                    }
                    
                    timeCards.total = total
                    timeCards.id_number = random
                    gallery.id_number = random
                    
                    noHoursStoredBackground()
                    tabBarController?.tabBar.items?[1].badgeValue = String(self.hourItems.count)
                    self.tabBarController?.tabBar.items?[2].badgeValue = String(self.timeCards.count)
                    undo = 1
                }))
                alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
}
