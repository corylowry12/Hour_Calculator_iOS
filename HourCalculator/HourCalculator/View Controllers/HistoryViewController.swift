//
//  HistoryViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 6/24/21.
//

import UIKit
import GoogleMobileAds
import CoreData
import PhotosUI
import SwipeableTabBarController

class HistoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var historyNavigationBar: UINavigationBar!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var moreMenuButton: UIBarButtonItem!
    
    var tappedItem: Hours!
    
    let userDefaults = UserDefaults.standard
    
    var totalHoursText: String!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var undo = 0
    var total: Double = 0.0
    
    private var pendingExportItems: [Hours] = []
    private var pendingDeletePaths: [IndexPath] = []
    private var pendingExportImage: UIImage?
    
    private weak var exportModalVC: UIViewController?
    private weak var exportModalTextField: UITextField?
    private weak var exportModalPhotoButton: UIButton?
    private weak var exportModalPreviewImageView: UIImageView?
    
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
    
    private var currentDisplayScale: CGFloat {
        if let windowScene = view.window?.windowScene {
            return windowScene.screen.scale
        }
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return windowScene.screen.scale
        }
        return traitCollection.displayScale > 0 ? traitCollection.displayScale : 2.0
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
        guard longPressGesture.state == .began else { return }
        
        let p = longPressGesture.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: p) else { return }
        
        if tableView.isEditing {
            let feedback = UIImpactFeedbackGenerator(style: .medium)
            feedback.impactOccurred()
            
            for row in 0..<hourItems.count {
                let targetPath = IndexPath(row: row, section: 0)
                tableView.selectRow(at: targetPath, animated: true, scrollPosition: .none)
            }
            setupMoreMenu()
        } else {
            setEditingMode(true, animated: true)
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            setupMoreMenu()
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
                setupMoreMenu()
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
    
    private func setEditingMode(_ editing: Bool, animated: Bool) {
        tableView.setEditing(editing, animated: animated)
        editButton?.image = UIImage(systemName: editing ? "xmark" : "pencil")
        setupMoreMenu()
        
        if editing {
            showSelectAllTooltipIfNeeded()
        }
    }
    
    private func showSelectAllTooltipIfNeeded() {
        guard !userDefaults.bool(forKey: "hasShownSelectAllTooltip") else { return }
        userDefaults.set(true, forKey: "hasShownSelectAllTooltip")
        
        let blurEffect = UIBlurEffect(style: .systemThinMaterial)
        let tooltip = UIVisualEffectView(effect: blurEffect)
        tooltip.layer.cornerRadius = 18
        tooltip.layer.masksToBounds = true
        tooltip.layer.borderWidth = 1.0
        tooltip.layer.borderColor = UIColor.white.withAlphaComponent(0.25).cgColor
        tooltip.translatesAutoresizingMaskIntoConstraints = false
        
        let icon = UIImageView(image: UIImage(systemName: "hand.tap.fill"))
        icon.tintColor = currentAccentColor
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "Tip: Long press any row while editing to select all entries."
        label.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        
        tooltip.contentView.addSubview(icon)
        tooltip.contentView.addSubview(label)
        view.addSubview(tooltip)
        
        let topAnchorTarget = historyNavigationBar?.bottomAnchor ?? view.safeAreaLayoutGuide.topAnchor
        
        NSLayoutConstraint.activate([
            tooltip.topAnchor.constraint(equalTo: topAnchorTarget, constant: 10),
            tooltip.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tooltip.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            icon.leadingAnchor.constraint(equalTo: tooltip.contentView.leadingAnchor, constant: 14),
            icon.centerYAnchor.constraint(equalTo: tooltip.contentView.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 22),
            icon.heightAnchor.constraint(equalToConstant: 22),
            
            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: tooltip.contentView.trailingAnchor, constant: -14),
            label.topAnchor.constraint(equalTo: tooltip.contentView.topAnchor, constant: 10),
            label.bottomAnchor.constraint(equalTo: tooltip.contentView.bottomAnchor, constant: -10)
        ])
        
        tooltip.alpha = 0
        tooltip.transform = CGAffineTransform(translationX: 0, y: -16)
        
        UIView.animate(withDuration: 0.35, delay: 0.1, options: [.curveEaseOut], animations: {
            tooltip.alpha = 1.0
            tooltip.transform = .identity
        }) { _ in
            UIView.animate(withDuration: 0.35, delay: 3.5, options: [.curveEaseIn], animations: {
                tooltip.alpha = 0
                tooltip.transform = CGAffineTransform(translationX: 0, y: -16)
            }) { _ in
                tooltip.removeFromSuperview()
            }
        }
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
        guard let moreMenuButton = moreMenuButton else { return }
        
        guard !hourItems.isEmpty else {
            moreMenuButton.isEnabled = false
            moreMenuButton.menu = nil
            return
        }
        
        moreMenuButton.isEnabled = true
        let isEditingMode = tableView.isEditing
        let selectedCount = tableView.indexPathsForSelectedRows?.count ?? 0
        
        let canExport = isEditingMode ? (selectedCount > 0) : true
        let canShowInfo = isEditingMode ? (selectedCount > 0) : true
        
        let exportTitle = (isEditingMode && selectedCount > 0) ? "Export Selected (\(selectedCount))" : "Export"
        let exportAction = UIAction(
            title: exportTitle,
            image: UIImage(systemName: "square.and.arrow.up"),
            attributes: canExport ? [] : .disabled
        ) { [weak self] _ in
            self?.handleExport()
        }

        let infoAction = UIAction(
            title: "Info",
            image: UIImage(systemName: "info.circle"),
            attributes: canShowInfo ? [] : .disabled
        ) { [weak self] _ in
            self?.handleInfo()
        }

        let deleteTitle = (isEditingMode && selectedCount > 0) ? "Delete Selected (\(selectedCount))" : "Delete All"
        let deleteAction = UIAction(
            title: deleteTitle,
            image: UIImage(systemName: "trash"),
            attributes: .destructive
        ) { [weak self] _ in
            guard let self = self else { return }
            if isEditingMode && selectedCount > 0 {
                self.confirmDeleteSelected()
            } else {
                self.handleDeleteAll()
            }
        }

        moreMenuButton.menu = UIMenu(title: "", children: [exportAction, infoAction, deleteAction])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        noHoursStoredBackground()
        self.editButton.isEnabled = hourItems.count > 0
        self.moreMenuButton.isEnabled = hourItems.count > 0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        view.backgroundColor = tableView.backgroundColor
        
        UIView.animate(withDuration: 0.5, delay: 0, options: [.transitionCrossDissolve, .preferredFramesPerSecond60], animations: {
            self.tableView.reloadData()
        }, completion: nil)
        
        noHoursStoredBackground()
        editButton.isEnabled = hourItems.count > 0
        setupMoreMenu()
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
        setEditingMode(false, animated: false)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .destructive, title: "Delete") { (action, view, completionHandler) in
            let alert = UIAlertController(title: "Warning", message: "You are fixing to delete a single entry, would you like to continue?", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { _ in
                let hourToDelete = self.hourItems[indexPath.row]
                self.context.delete(hourToDelete)
                (UIApplication.shared.delegate as! AppDelegate).saveContext()
                
                self.tableView.deleteRows(at: [indexPath], with: .fade)
                self.undo = 1
                self.tabBarController?.tabBar.items?[1].badgeValue = String(self.hourItems.count)
                self.noHoursStoredBackground()
                self.editButton.isEnabled = self.hourItems.count > 0
                self.setupMoreMenu()
                
                if UserDefaults.standard.integer(forKey: "undoAlertMessage") == 0 {
                    let undoAlert = UIAlertController(title: nil, message: "You can shake your phone in order to restore an hour", preferredStyle: .actionSheet)
                    undoAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
                        UserDefaults.standard.setValue(1, forKey: "undoAlertMessage")
                    }))
                    self.present(undoAlert, animated: true, completion: nil)
                }
            }))
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { _ in
                completionHandler(false)
            }))
            self.present(alert, animated: true, completion: nil)
        }
        
        let exportAction = UIContextualAction(style: .normal, title: "Export") { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            let hourToExport = self.hourItems[indexPath.row]
            self.promptExportNaming(itemsToExport: [hourToExport], indexPathsToDelete: [indexPath])
            completionHandler(true)
        }
        
        let swipeActionConfig = UISwipeActionsConfiguration(actions: [action, exportAction])
        action.backgroundColor = .systemRed
        exportAction.backgroundColor = .systemBlue
        return swipeActionConfig
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            setupMoreMenu()
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            let selectedHour = hourItems[indexPath.row]
            performSegue(withIdentifier: "EditItem", sender: selectedHour)
        }
    }

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .normal, title: "Edit") { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            let selectedHour = self.hourItems[indexPath.row]
            self.performSegue(withIdentifier: "EditItem", sender: selectedHour)
            completionHandler(true)
        }
        action.backgroundColor = .systemOrange
        return UISwipeActionsConfiguration(actions: [action])
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            setupMoreMenu()
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
    
    private func confirmDeleteSelected() {
        guard let indexPaths = tableView.indexPathsForSelectedRows, !indexPaths.isEmpty else { return }
        let alert = UIAlertController(title: "Warning", message: "You are fixing to delete selected hours. Would you like to continue?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { [weak self] _ in
            guard let self = self else { return }
            let sortedPaths = indexPaths.sorted { $0.row > $1.row }
            
            var items = [Hours]()
            for indexPath in sortedPaths {
                items.append(self.hourItems[indexPath.row])
            }
            
            for item in items.reversed() {
                if let index = self.hourItems.firstIndex(of: item) {
                    let hourToDelete = self.hourItems[index]
                    self.context.delete(hourToDelete)
                }
            }
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
            
            self.tableView.deleteRows(at: sortedPaths, with: .fade)
            self.noHoursStoredBackground()
            self.tabBarController?.tabBar.items?[1].badgeValue = String(self.hourItems.count)
            self.undo = 1
            
            self.setEditingMode(false, animated: true)
            self.editButton.isEnabled = self.hourItems.count > 0
            self.setupMoreMenu()
            
            if self.userDefaults.integer(forKey: "undoAlertMessage") == 0 {
                let undoAlert = UIAlertController(title: nil, message: "You can shake your phone in order to restore an hour", preferredStyle: .actionSheet)
                undoAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { [weak self] _ in
                    self?.userDefaults.setValue(1, forKey: "undoAlertMessage")
                }))
                self.present(undoAlert, animated: true, completion: nil)
            }
        }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func handleDeleteAll() {
        if self.tableView.isEditing {
            setEditingMode(false, animated: true)
        }
        
        let alert = UIAlertController(title: "Delete All?", message: "Are you sure you would like to delete all stored hours?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { [self] _ in
            undo = 1
            DispatchQueue.main.async {
                for i in (0...self.hourItems.count - 1).reversed() {
                    let index = [0, i] as IndexPath
                    let hourToDelete = self.hourItems[i]
                    self.context.delete(hourToDelete)
                    self.tableView.deleteRows(at: [index], with: .fade)
                }
                (UIApplication.shared.delegate as! AppDelegate).saveContext()
                self.noHoursStoredBackground()
                tabBarController?.tabBar.items?[1].badgeValue = String(self.hourItems.count)
                self.editButton.isEnabled = false
                self.setupMoreMenu()
                
                if UserDefaults.standard.integer(forKey: "undoAlertMessage") == 0 {
                    let undoAlert = UIAlertController(title: nil, message: "You can shake your phone in order to restore an hour", preferredStyle: .actionSheet)
                    undoAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
                        UserDefaults.standard.setValue(1, forKey: "undoAlertMessage")
                    }))
                    self.present(undoAlert, animated: true, completion: nil)
                }
            }
            
            let range = NSMakeRange(0, self.tableView.numberOfSections)
            let sections = NSIndexSet(indexesIn: range)
            self.tableView.reloadSections(sections as IndexSet, with: .fade)
            
            self.tabBarController?.tabBar.items?[1].badgeValue = String(self.hourItems.count)
            self.editButton.isEnabled = false
            noHoursStoredBackground()
            setupMoreMenu()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    @IBAction func editButtonTapped(_ sender: Any) {
        guard hourItems.count > 0 else { return }
        setEditingMode(!tableView.isEditing, animated: true)
    }
    
    private func handleInfo() {
        let targetItems: [Hours]
        let isSelectionFiltered: Bool
        
        if tableView.isEditing {
            guard let indexPaths = tableView.indexPathsForSelectedRows, !indexPaths.isEmpty else { return }
            let sortedPaths = indexPaths.sorted(by: { $0.row < $1.row })
            targetItems = sortedPaths.map { hourItems[$0.row] }
            isSelectionFiltered = true
        } else {
            targetItems = hourItems
            isSelectionFiltered = false
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.showLiquidGlassInfoModal(items: targetItems, isSelection: isSelectionFiltered)
        }
    }

    private func showLiquidGlassInfoModal(items: [Hours], isSelection: Bool) {
        var calculatedTotal = 0.0
        for item in items {
            if let hoursStr = item.totalHours, let val = Double(hoursStr) {
                calculatedTotal += val
            }
        }
        let totalHoursFormatted = round(calculatedTotal * 100.0) / 100.0
        let entriesCount = items.count
        
        let modalVC = UIViewController()
        modalVC.modalPresentationStyle = .overFullScreen
        modalVC.modalTransitionStyle = .crossDissolve
        modalVC.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        // Tap dimmed backdrop above the sheet to dismiss
        let dismissButton = UIButton(frame: modalVC.view.bounds)
        dismissButton.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        dismissButton.addTarget(self, action: #selector(dismissLiquidGlassModal), for: .touchUpInside)
        modalVC.view.addSubview(dismissButton)
        
        // Fixed bottom container pinned to the bottom of the screen
        let blurEffect = UIBlurEffect(style: .systemMaterialDark)
        let bottomSheetContainer = UIVisualEffectView(effect: blurEffect)
        bottomSheetContainer.layer.cornerRadius = 24
        bottomSheetContainer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        bottomSheetContainer.layer.masksToBounds = true
        bottomSheetContainer.layer.borderWidth = 1.0
        bottomSheetContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.15).cgColor
        bottomSheetContainer.translatesAutoresizingMaskIntoConstraints = false
        modalVC.view.addSubview(bottomSheetContainer)
        
        // Top-left circular 'X' dismiss button
        let closeButton = UIButton(type: .system)
        var closeConfig = UIButton.Configuration.plain()
        let xSymbolConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        closeConfig.image = UIImage(systemName: "xmark", withConfiguration: xSymbolConfig)
        closeConfig.baseForegroundColor = .secondaryLabel
        closeConfig.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)
        closeButton.configuration = closeConfig
        closeButton.backgroundColor = UIColor.secondarySystemFill
        closeButton.layer.cornerRadius = 15
        closeButton.layer.masksToBounds = true
        closeButton.addAction(UIAction { [weak modalVC] _ in
            modalVC?.dismiss(animated: true)
        }, for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 32, weight: .semibold)
        let iconImageView = UIImageView(image: UIImage(systemName: "clock.badge.checkmark.fill", withConfiguration: iconConfig))
        iconImageView.tintColor = currentAccentColor
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = isSelection ? "Selected Summary" : "History Summary"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let divider = UIView()
        divider.backgroundColor = UIColor.separator.withAlphaComponent(0.35)
        divider.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        func createInfoCard(icon: String, title: String, value: String) -> UIView {
            let card = UIView()
            card.backgroundColor = UIColor.secondarySystemFill
            card.layer.cornerRadius = 14
            card.layer.masksToBounds = true
            card.translatesAutoresizingMaskIntoConstraints = false
            
            let rowIcon = UIImageView(image: UIImage(systemName: icon))
            rowIcon.tintColor = currentAccentColor
            rowIcon.contentMode = .scaleAspectFit
            rowIcon.translatesAutoresizingMaskIntoConstraints = false
            
            let textStack = UIStackView()
            textStack.axis = .vertical
            textStack.spacing = 2
            textStack.alignment = .fill
            textStack.translatesAutoresizingMaskIntoConstraints = false
            
            let rowTitle = UILabel()
            rowTitle.text = title.uppercased()
            rowTitle.font = UIFont.systemFont(ofSize: 11, weight: .bold)
            rowTitle.textColor = .secondaryLabel
            
            let rowValue = UILabel()
            rowValue.text = value
            rowValue.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            rowValue.textColor = .label
            rowValue.adjustsFontSizeToFitWidth = true
            rowValue.minimumScaleFactor = 0.8
            
            textStack.addArrangedSubview(rowTitle)
            textStack.addArrangedSubview(rowValue)
            
            card.addSubview(rowIcon)
            card.addSubview(textStack)
            
            NSLayoutConstraint.activate([
                rowIcon.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                rowIcon.centerYAnchor.constraint(equalTo: card.centerYAnchor),
                rowIcon.widthAnchor.constraint(equalToConstant: 24),
                rowIcon.heightAnchor.constraint(equalToConstant: 24),
                
                textStack.leadingAnchor.constraint(equalTo: rowIcon.trailingAnchor, constant: 14),
                textStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
                textStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
                textStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
            ])
            
            return card
        }
        
        let countTitle = isSelection ? "Selected Entries" : "Hours Stored"
        let entriesRow = createInfoCard(icon: "list.bullet.rectangle", title: countTitle, value: "\(entriesCount) \(entriesCount == 1 ? "entry" : "entries")")
        let totalHoursRow = createInfoCard(icon: "hourglass.bottomhalf.filled", title: "Total Hours", value: "\(totalHoursFormatted) hrs")
        
        stackView.addArrangedSubview(entriesRow)
        stackView.addArrangedSubview(totalHoursRow)
        
        bottomSheetContainer.contentView.addSubview(closeButton)
        bottomSheetContainer.contentView.addSubview(iconImageView)
        bottomSheetContainer.contentView.addSubview(titleLabel)
        bottomSheetContainer.contentView.addSubview(divider)
        bottomSheetContainer.contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            // Pinned flush to the very bottom edge of the display
            bottomSheetContainer.leadingAnchor.constraint(equalTo: modalVC.view.leadingAnchor),
            bottomSheetContainer.trailingAnchor.constraint(equalTo: modalVC.view.trailingAnchor),
            bottomSheetContainer.bottomAnchor.constraint(equalTo: modalVC.view.bottomAnchor),
            
            // Top-left 'X' button
            closeButton.topAnchor.constraint(equalTo: bottomSheetContainer.contentView.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: bottomSheetContainer.contentView.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),
            
            iconImageView.topAnchor.constraint(equalTo: bottomSheetContainer.contentView.topAnchor, constant: 20),
            iconImageView.centerXAnchor.constraint(equalTo: bottomSheetContainer.contentView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 34),
            iconImageView.heightAnchor.constraint(equalToConstant: 34),
            
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: bottomSheetContainer.contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: bottomSheetContainer.contentView.trailingAnchor, constant: -20),
            
            divider.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            divider.leadingAnchor.constraint(equalTo: bottomSheetContainer.contentView.leadingAnchor, constant: 20),
            divider.trailingAnchor.constraint(equalTo: bottomSheetContainer.contentView.trailingAnchor, constant: -20),
            divider.heightAnchor.constraint(equalToConstant: 0.5),
            
            stackView.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 14),
            stackView.leadingAnchor.constraint(equalTo: bottomSheetContainer.contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: bottomSheetContainer.contentView.trailingAnchor, constant: -20),
            
            // Anchored directly to safe area bottom for proper home indicator padding
            stackView.bottomAnchor.constraint(equalTo: modalVC.view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
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
        setupMoreMenu()
    }
    
    func dateFromString(dateStr: String) -> NSDate {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        dateFormatter.locale = NSLocale(localeIdentifier: "en_EN") as Locale
        return dateFormatter.date(from: dateStr)! as NSDate
    }
    
    private func handleExport() {
        guard !hourItems.isEmpty else { return }
        
        let itemsToExport: [Hours]
        let deletePaths: [IndexPath]
        
        if tableView.isEditing {
            guard let indexPaths = tableView.indexPathsForSelectedRows, !indexPaths.isEmpty else { return }
            let sortedIndexPaths = indexPaths.sorted(by: { $0.row < $1.row })
            itemsToExport = sortedIndexPaths.map { self.hourItems[$0.row] }
            deletePaths = indexPaths.sorted(by: { $0.row > $1.row })
        } else {
            deletePaths = (0..<hourItems.count).reversed().map { IndexPath(row: $0, section: 0) }
            itemsToExport = hourItems
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.promptExportNaming(itemsToExport: itemsToExport, indexPathsToDelete: deletePaths)
        }
    }
    
    private func promptExportNaming(itemsToExport: [Hours], indexPathsToDelete: [IndexPath]) {
        self.pendingExportItems = itemsToExport
        self.pendingDeletePaths = indexPathsToDelete
        self.pendingExportImage = nil
        
        showExportModal()
    }
    
    private func showExportModal() {
        let modalVC = UIViewController()
        modalVC.modalPresentationStyle = .overFullScreen
        modalVC.modalTransitionStyle = .crossDissolve
        modalVC.view.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        self.exportModalVC = modalVC
        
        let dismissButton = UIButton(frame: modalVC.view.bounds)
        dismissButton.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        dismissButton.addTarget(self, action: #selector(dismissExportModal), for: .touchUpInside)
        modalVC.view.addSubview(dismissButton)
        
        let blurEffect = UIBlurEffect(style: .systemThinMaterial)
        let glassContainer = UIVisualEffectView(effect: blurEffect)
        glassContainer.layer.cornerRadius = 24
        glassContainer.layer.masksToBounds = true
        glassContainer.layer.borderWidth = 1.0
        glassContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.25).cgColor
        glassContainer.translatesAutoresizingMaskIntoConstraints = false
        modalVC.view.addSubview(glassContainer)
        
        let titleLabel = UILabel()
        titleLabel.text = "Export Time Card"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let subtitleLabel = UILabel()
        let count = pendingExportItems.count
        subtitleLabel.text = "Exporting \(count) \(count == 1 ? "entry" : "entries")"
        subtitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let textField = UITextField()
        textField.placeholder = "e.g., Pay Period 1, Acme Corp"
        textField.font = UIFont.systemFont(ofSize: 15)
        textField.backgroundColor = UIColor.secondarySystemFill
        textField.layer.cornerRadius = 10
        textField.clearButtonMode = .whileEditing
        textField.autocapitalizationType = .words
        textField.autocorrectionType = .no
        textField.returnKeyType = .done
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 42))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        self.exportModalTextField = textField
        
        let photoButton = UIButton(type: .system)
        var photoConfig = UIButton.Configuration.tinted()
        photoConfig.image = UIImage(systemName: "camera.badge.ellipsis")
        photoConfig.title = " Attach Photo"
        photoConfig.baseBackgroundColor = currentAccentColor
        photoConfig.baseForegroundColor = currentAccentColor
        photoConfig.cornerStyle = .medium
        photoConfig.imagePadding = 6
        photoButton.configuration = photoConfig
        photoButton.menu = createInlinePhotoMenu()
        photoButton.showsMenuAsPrimaryAction = true
        photoButton.translatesAutoresizingMaskIntoConstraints = false
        self.exportModalPhotoButton = photoButton
        
        let previewImageView = UIImageView()
        previewImageView.contentMode = .scaleAspectFill
        previewImageView.layer.cornerRadius = 8
        previewImageView.layer.masksToBounds = true
        previewImageView.layer.borderWidth = 1.5
        previewImageView.layer.borderColor = currentAccentColor.cgColor
        previewImageView.isHidden = true
        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        self.exportModalPreviewImageView = previewImageView
        
        let buttonStack = UIStackView()
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        
        let cancelButton = UIButton(type: .system)
        var cancelConfig = UIButton.Configuration.gray()
        cancelConfig.title = "Cancel"
        cancelConfig.cornerStyle = .capsule
        cancelButton.configuration = cancelConfig
        cancelButton.addTarget(self, action: #selector(dismissExportModal), for: .touchUpInside)
        
        let exportBtn = UIButton(type: .system)
        var exportBtnConfig = UIButton.Configuration.filled()
        exportBtnConfig.title = "Export"
        exportBtnConfig.baseBackgroundColor = currentAccentColor
        exportBtnConfig.baseForegroundColor = .white
        exportBtnConfig.cornerStyle = .capsule
        exportBtn.configuration = exportBtnConfig
        exportBtn.addTarget(self, action: #selector(confirmExportTapped), for: .touchUpInside)
        
        buttonStack.addArrangedSubview(cancelButton)
        buttonStack.addArrangedSubview(exportBtn)
        
        glassContainer.contentView.addSubview(titleLabel)
        glassContainer.contentView.addSubview(subtitleLabel)
        glassContainer.contentView.addSubview(textField)
        glassContainer.contentView.addSubview(photoButton)
        glassContainer.contentView.addSubview(previewImageView)
        glassContainer.contentView.addSubview(buttonStack)
        
        NSLayoutConstraint.activate([
            glassContainer.centerXAnchor.constraint(equalTo: modalVC.view.centerXAnchor),
            glassContainer.centerYAnchor.constraint(equalTo: modalVC.view.centerYAnchor, constant: -30),
            glassContainer.widthAnchor.constraint(equalTo: modalVC.view.widthAnchor, multiplier: 0.85),
            glassContainer.widthAnchor.constraint(lessThanOrEqualToConstant: 340),
            
            titleLabel.topAnchor.constraint(equalTo: glassContainer.contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: glassContainer.contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: glassContainer.contentView.trailingAnchor, constant: -16),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: glassContainer.contentView.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: glassContainer.contentView.trailingAnchor, constant: -16),
            
            textField.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 16),
            textField.leadingAnchor.constraint(equalTo: glassContainer.contentView.leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: glassContainer.contentView.trailingAnchor, constant: -16),
            textField.heightAnchor.constraint(equalToConstant: 42),
            
            photoButton.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 12),
            photoButton.leadingAnchor.constraint(equalTo: glassContainer.contentView.leadingAnchor, constant: 16),
            photoButton.heightAnchor.constraint(equalToConstant: 38),
            
            previewImageView.centerYAnchor.constraint(equalTo: photoButton.centerYAnchor),
            previewImageView.leadingAnchor.constraint(equalTo: photoButton.trailingAnchor, constant: 10),
            previewImageView.trailingAnchor.constraint(lessThanOrEqualTo: glassContainer.contentView.trailingAnchor, constant: -16),
            previewImageView.widthAnchor.constraint(equalToConstant: 36),
            previewImageView.heightAnchor.constraint(equalToConstant: 36),
            
            buttonStack.topAnchor.constraint(equalTo: photoButton.bottomAnchor, constant: 20),
            buttonStack.leadingAnchor.constraint(equalTo: glassContainer.contentView.leadingAnchor, constant: 16),
            buttonStack.trailingAnchor.constraint(equalTo: glassContainer.contentView.trailingAnchor, constant: -16),
            buttonStack.heightAnchor.constraint(equalToConstant: 42),
            buttonStack.bottomAnchor.constraint(equalTo: glassContainer.contentView.bottomAnchor, constant: -20)
        ])
        
        present(modalVC, animated: true)
    }
    
    @objc private func dismissExportModal() {
        exportModalVC?.dismiss(animated: true) { [weak self] in
            self?.pendingExportImage = nil
            self?.pendingExportItems = []
            self?.pendingDeletePaths = []
            self?.exportModalVC = nil
        }
    }
    
    @objc private func confirmExportTapped() {
        let input = exportModalTextField?.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let customName: String? = input.isEmpty ? "Unknown" : input
        let attachedImage = pendingExportImage
        
        let targetCardID = executeExport(
            itemsToExport: pendingExportItems,
            customName: customName,
            indexPathsToDelete: pendingDeletePaths
        )
        
        if let image = attachedImage {
            attachImageToCard(cardID: targetCardID, cardName: customName, image: image)
        }
        
        dismissExportModal()
    }
    
    private func createInlinePhotoMenu() -> UIMenu {
        var actions: [UIAction] = []
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            actions.append(UIAction(title: "Take Photo", image: UIImage(systemName: "camera")) { [weak self] _ in
                self?.presentCameraPicker()
            })
        }
        
        actions.append(UIAction(title: "Choose Photo", image: UIImage(systemName: "photo.on.rectangle")) { [weak self] _ in
            self?.presentModernPhotoPicker()
        })
        
        return UIMenu(title: "Attach Time Card Picture", children: actions)
    }
    
    private func presentModernPhotoPicker() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        (exportModalVC ?? self).present(picker, animated: true)
    }
    
    private func presentCameraPicker() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .camera
        (exportModalVC ?? self).present(picker, animated: true)
    }
    
    // MARK: - PHPickerViewControllerDelegate
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
        
        provider.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in
            guard let self = self, let pickedImage = image as? UIImage else { return }
            DispatchQueue.main.async {
                self.pendingExportImage = pickedImage
                self.updateExportModalPhotoPreview(image: pickedImage)
            }
        }
    }
    
    // MARK: - UIImagePickerControllerDelegate (Camera)
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        guard let pickedImage = info[.originalImage] as? UIImage else { return }
        
        self.pendingExportImage = pickedImage
        updateExportModalPhotoPreview(image: pickedImage)
        
        if userDefaults.integer(forKey: "saveImages") == 0 {
            UIImageWriteToSavedPhotosAlbum(pickedImage, nil, nil, nil)
        }
    }
    
    private func updateExportModalPhotoPreview(image: UIImage) {
        exportModalPreviewImageView?.image = image
        exportModalPreviewImageView?.isHidden = false
        
        if var config = exportModalPhotoButton?.configuration {
            config.title = " Change Photo"
            config.image = UIImage(systemName: "checkmark.circle.fill")
            exportModalPhotoButton?.configuration = config
        }
    }
    
    private func attachImageToCard(cardID: Int32, cardName: String?, image: UIImage) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self,
                  let jpegData = image.jpegData(compressionQuality: 0.85) else { return }
            
            let thumbSize = CGSize(width: 156, height: 156)
            let thumbData = UIImage.downsampledImage(from: jpegData, to: thumbSize, scale: self.currentDisplayScale)?.jpegData(compressionQuality: 0.8) ?? jpegData
            let cardTitle = cardName ?? "Unknown"
            
            let today = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd/yyyy hh:mm a"
            let dateFormatted = formatter.string(from: today)
            
            DispatchQueue.main.async {
                let infoFetch = NSFetchRequest<TimeCardInfo>(entityName: "TimeCardInfo")
                infoFetch.predicate = NSPredicate(format: "id_number == %d", cardID)
                if let infoItems = try? self.context.fetch(infoFetch), let firstInfo = infoItems.first {
                    firstInfo.image = jpegData
                }
                
                let galFetch = NSFetchRequest<Gallery>(entityName: "Gallery")
                galFetch.predicate = NSPredicate(format: "id_number == %d", cardID)
                galFetch.fetchLimit = 1
                
                if let galleryRecord = (try? self.context.fetch(galFetch))?.first {
                    galleryRecord.thumbnail = thumbData
                    galleryRecord.fullSize = jpegData
                    galleryRecord.date = dateFormatted
                    galleryRecord.name = cardTitle
                } else {
                    let galleryRecord = Gallery(context: self.context)
                    galleryRecord.id_number = cardID
                    galleryRecord.thumbnail = thumbData
                    galleryRecord.fullSize = jpegData
                    galleryRecord.date = dateFormatted
                    galleryRecord.name = cardTitle
                }
                
                (UIApplication.shared.delegate as! AppDelegate).saveContext()
                NotificationCenter.default.post(name: NSNotification.Name("Update"), object: nil)
            }
        }
    }
    
    @discardableResult
    private func executeExport(itemsToExport: [Hours], customName: String?, indexPathsToDelete: [IndexPath]) -> Int32 {
        var random: Int32!
        repeat {
            random = Int32.random(in: 1...500)
        } while timeCards.contains(where: { $0.id_number == random })
        
        let timeCards = TimeCards(context: self.context)
        let gallery = Gallery(context: self.context)
        timeCards.id_number = random
        timeCards.name = customName
        gallery.id_number = random
        gallery.name = customName
        
        let firstDate = itemsToExport.first?.date ?? "Unknown"
        let lastDate = itemsToExport.last?.date ?? "Unknown"
        timeCards.week = (itemsToExport.count > 1) ? "\(firstDate)-\(lastDate)" : firstDate
        timeCards.numberBeingExported = Int64(itemsToExport.count)
        
        var calculatedTotal = 0.0
        for item in itemsToExport {
            let timeCardsInfo = TimeCardInfo(context: self.context)
            timeCardsInfo.id_number = random
            timeCardsInfo.name = customName
            timeCardsInfo.intime = item.inTime
            timeCardsInfo.outtime = item.outTime
            timeCardsInfo.total_hours = item.totalHours
            timeCardsInfo.date = item.date
            
            calculatedTotal += Double(item.totalHours ?? "0") ?? 0.0
            self.context.delete(item)
        }
        
        timeCards.total = calculatedTotal
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        
        self.tableView.deleteRows(at: indexPathsToDelete, with: .fade)
        self.noHoursStoredBackground()
        self.tabBarController?.tabBar.items?[1].badgeValue = String(self.hourItems.count)
        self.tabBarController?.tabBar.items?[2].badgeValue = String(self.timeCards.count)
        self.undo = 1
        
        if tableView.isEditing {
            self.setEditingMode(false, animated: true)
        } else {
            setupMoreMenu()
        }
        
        return random
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EditItem" {
            let destinationVC: EditViewController?
            if let navVC = segue.destination as? UINavigationController {
                destinationVC = navVC.topViewController as? EditViewController
            } else {
                destinationVC = segue.destination as? EditViewController
            }
            
            if let hourItem = sender as? Hours {
                destinationVC?.currentHourItem = hourItem
            }
        }
    }
}
