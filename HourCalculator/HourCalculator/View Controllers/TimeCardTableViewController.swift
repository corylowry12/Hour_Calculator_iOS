//
//  TimeCardTableViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 7/8/21.
//

import Foundation
import UIKit
import CoreData
import GoogleMobileAds

class TimeCardTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    lazy var bannerView: BannerView! = BannerView(adSize: AdSizeBanner)
    
    @IBOutlet weak var sortBarButton: UIBarButtonItem!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet var tableView: UITableView!
    
    var context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let userDefaults = UserDefaults.standard
    
    // In-memory cache to keep 60/120 FPS table scrolling smooth
    private let thumbnailCache = NSCache<NSNumber, UIImage>()
    
    var undo: Int = 0
    var predicateText: String!
    
    var currentAccentColor: UIColor {
        let accent = userDefaults.integer(forKey: "accent")
        switch accent {
        case 0: return UIColor(rgb: 0x26A69A)
        case 1: return UIColor(rgb: 0x7841c4)
        case 2: return UIColor(rgb: 0x347deb)
        case 3: return UIColor(rgb: 0xfc783a)
        case 4: return UIColor(rgb: 0xc41d1d)
        case 5:
            let randomAccent = userDefaults.integer(forKey: "accentRandom")
            switch randomAccent {
            case 0: return UIColor(rgb: 0x26A69A)
            case 1: return UIColor(rgb: 0x7841c4)
            case 2: return UIColor(rgb: 0x347deb)
            case 3: return UIColor(rgb: 0xfc783a)
            default: return UIColor(rgb: 0xc41d1d)
            }
        default: return UIColor(rgb: 0x26A69A)
        }
    }
    
    var gallery: [Gallery] {
        do {
            let fetchrequest = NSFetchRequest<Gallery>(entityName: "Gallery")
            fetchrequest.predicate = NSPredicate(format: "id_number == %@", predicateText!)
            let sort = NSSortDescriptor(key: #keyPath(Gallery.date), ascending: false)
            fetchrequest.sortDescriptors = [sort]
            return try context.fetch(fetchrequest)
        } catch {
            print("Couldn't fetch data")
        }
        return [Gallery]()
    }
    
    var timeCardInfo: [TimeCardInfo] {
        do {
            let fetchrequest = NSFetchRequest<TimeCardInfo>(entityName: "TimeCardInfo")
            fetchrequest.predicate = NSPredicate(format: "id_number == %@", predicateText!)
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
                sort = NSSortDescriptor(key: #keyPath(TimeCards.name), ascending: false)
            } else if sortChoice == 5 {
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
        return true
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake && undo == 1 {
            let alert = UIAlertController(title: "Undo Deletion", message: "Would you like to restore the deleted time card entry?", preferredStyle: .alert)
            alert.view.tintColor = currentAccentColor
            alert.addAction(UIAlertAction(title: "Restore", style: .default, handler: { [weak self] _ in
                guard let self = self else { return }
                (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.rollback()
                
                UIView.transition(with: self.tableView, duration: 0.35, options: .transitionCrossDissolve, animations: {
                    self.tableView.reloadData()
                }, completion: nil)
                
                self.editButton?.isEnabled = self.timeCards.count > 0
                self.noHoursStoredBackground()
                self.undo = 0
                self.setupSortMenu()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addBannerViewToView(bannerView)
        bannerView.adUnitID = "ca-app-pub-4546055219731501/2396708566"
        bannerView.rootViewController = self
        bannerView.load(Request())
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.allowsMultipleSelection = true
        tableView.allowsMultipleSelectionDuringEditing = true
        
        editButton?.isEnabled = timeCards.count > 0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        thumbnailCache.removeAllObjects()
        tableView.reloadData()
        noHoursStoredBackground()
        self.becomeFirstResponder()
        view.backgroundColor = tableView.backgroundColor
        
        editButton?.isEnabled = timeCards.count > 0
        setupSortMenu()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        undo = 0
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        setEditingMode(false, animated: false)
    }
    
    // MARK: - Edit Mode Logic
    
    private func setEditingMode(_ editing: Bool, animated: Bool) {
        tableView.setEditing(editing, animated: animated)
        editButton?.image = UIImage(systemName: editing ? "xmark" : "pencil")
        sortBarButton?.isEnabled = !editing && timeCards.count > 0
    }
    
    @IBAction func editButtonTapped(_ sender: Any) {
        guard timeCards.count > 0 else { return }
        setEditingMode(!tableView.isEditing, animated: true)
    }
    
    func setupSortMenu() {
        guard let sortBarButton = sortBarButton else { return }
        
        guard timeCards.count > 0 && !tableView.isEditing else {
            sortBarButton.isEnabled = false
            sortBarButton.menu = nil
            return
        }
        
        sortBarButton.isEnabled = true
        let currentSort = userDefaults.integer(forKey: "timeCardsSort")
        
        let sortOptions: [(title: String, icon: String, value: Int)] = [
            ("Date Descending", "calendar.badge.clock", 0),
            ("Date Ascending", "calendar", 1),
            ("Total Hours Ascending", "arrow.up.circle", 2),
            ("Total Hours Descending", "arrow.down.circle", 3),
            ("Name Descending", "textformat.size.smaller", 4),
            ("Name Ascending", "textformat.size.larger", 5)
        ]
        
        let actions = sortOptions.map { option in
            UIAction(
                title: option.title,
                image: UIImage(systemName: option.icon),
                state: (currentSort == option.value) ? .on : .off
            ) { [weak self] _ in
                guard let self = self else { return }
                self.userDefaults.set(option.value, forKey: "timeCardsSort")
                self.setupSortMenu()
                
                UIView.transition(with: self.tableView, duration: 0.35, options: .transitionCrossDissolve, animations: {
                    self.tableView.reloadData()
                }, completion: nil)
            }
        }
        
        let menu = UIMenu(title: "Sort Entries", options: .displayInline, children: actions)
        sortBarButton.menu = menu
        sortBarButton.target = nil
        sortBarButton.action = nil
    }
    
    func noHoursStoredBackground() {
        if timeCards.count == 0 {
            let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: accessibilityFrame.size.width, height: accessibilityFrame.size.height))
            messageLabel.text = "There are currently no entries stored"
            messageLabel.numberOfLines = 0
            messageLabel.textAlignment = .center
            messageLabel.font = UIFont.systemFont(ofSize: 16.0, weight: UIFont.Weight.medium)
            messageLabel.sizeToFit()
            
            tableView.backgroundView = messageLabel
            tableView.separatorStyle = .none
        } else {
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
                
                cell.transform = CGAffineTransform(translationX: 0, y: tableView.rowHeight / 2)
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
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [weak self] _ in
                guard let self = self else { return }
                
                let deletedID = self.timeCards[indexPath.row].id_number
                self.predicateText = "\(deletedID)"
                self.thumbnailCache.removeObject(forKey: NSNumber(value: deletedID))
                
                if self.timeCardInfo.count > 0 {
                    for i in (0...self.timeCardInfo.count - 1).reversed() {
                        let timeCardInfoToDelete = self.timeCardInfo[i]
                        self.context.delete(timeCardInfoToDelete)
                    }
                }
                
                let hourToDelete = self.timeCards[indexPath.row]
                self.context.delete(hourToDelete)
                
                if self.gallery.count > 0 {
                    let galleryToDelete = self.gallery[0]
                    self.context.delete(galleryToDelete)
                }
                
                self.tableView.deleteRows(at: [indexPath], with: .left)
                self.editButton?.isEnabled = self.timeCards.count > 0
                self.noHoursStoredBackground()
                self.undo = 1
                self.setupSortMenu()
                
                self.tabBarController?.tabBar.items?[2].badgeValue = String(self.timeCards.count)
            }))
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { _ in
                tableView.setEditing(false, animated: true)
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return timeCards.count
    }
    
    private func presentRenameAlert(forRowAt indexPath: IndexPath) {
        let currentCard = self.timeCards[indexPath.row]
        let currentName = currentCard.name?.trimmingCharacters(in: .whitespaces)
        let isCustomName = (currentName != nil && currentName != "" && currentName != "Unknown")
        
        let alert = UIAlertController(title: "Name", message: "Enter a name", preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let textField = alert.textFields?[0]
            var userText: String!
            if textField?.text == "" {
                userText = textField?.placeholder
            } else if textField?.text?.trimmingCharacters(in: .whitespaces) == "" {
                userText = "Unknown"
            } else {
                userText = textField!.text?.trimmingCharacters(in: .whitespaces)
            }
            
            // 1. Update parent TimeCards record
            currentCard.name = userText
            
            // 2. Update child TimeCardInfo records for this id_number
            let fetchRequest = NSFetchRequest<TimeCardInfo>(entityName: "TimeCardInfo")
            fetchRequest.predicate = NSPredicate(format: "id_number == %d", currentCard.id_number)
            if let matchingInfo = try? self.context.fetch(fetchRequest) {
                for info in matchingInfo {
                    info.name = userText
                }
            }
            
            // 3. Update Gallery record if present
            let galleryFetch = NSFetchRequest<Gallery>(entityName: "Gallery")
            galleryFetch.predicate = NSPredicate(format: "id_number == %d", currentCard.id_number)
            if let matchingGallery = try? self.context.fetch(galleryFetch) {
                for gal in matchingGallery {
                    gal.name = userText
                }
            }
            
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
            self.userDefaults.setValue(userText, forKey: "name")
            
            UIView.transition(with: self.tableView, duration: 0.35, options: .transitionCrossDissolve, animations: {
                self.tableView.reloadData()
            }, completion: nil)
            
            self.undo = 1
        }
        
        let removePrevious = UIAlertAction(title: "Remove Previous", style: .default) { [weak self] _ in
            guard let self = self else { return }
            currentCard.name = nil
            
            let fetchRequest = NSFetchRequest<TimeCardInfo>(entityName: "TimeCardInfo")
            fetchRequest.predicate = NSPredicate(format: "id_number == %d", currentCard.id_number)
            if let matchingInfo = try? self.context.fetch(fetchRequest) {
                for info in matchingInfo {
                    info.name = nil
                }
            }
            
            let galleryFetch = NSFetchRequest<Gallery>(entityName: "Gallery")
            galleryFetch.predicate = NSPredicate(format: "id_number == %d", currentCard.id_number)
            if let matchingGallery = try? self.context.fetch(galleryFetch) {
                for gal in matchingGallery {
                    gal.name = nil
                }
            }
            
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
            self.userDefaults.removeObject(forKey: "name")
            
            UIView.transition(with: self.tableView, duration: 0.35, options: .transitionCrossDissolve, animations: {
                self.tableView.reloadData()
            }, completion: nil)
            
            self.undo = 1
        }
        
        alert.addTextField { [weak self] textField in
            guard let self = self else { return }
            textField.clearButtonMode = .always
            textField.autocapitalizationType = .words
            textField.autocorrectionType = .no
            
            let name = self.timeCards[indexPath.row].name ?? "Unknown"
            textField.placeholder = name
            textField.text = isCustomName ? currentName : ""
        }
        
        alert.addAction(saveAction)
        if isCustomName {
            alert.addAction(removePrevious)
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.tableView.setEditing(false, animated: true)
        })
        alert.preferredAction = saveAction
        
        self.present(alert, animated: true)
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !tableView.isEditing else { return nil }
        let action = UIContextualAction(style: .normal, title: "Rename") { [weak self] (action, view, completionHandler) in
            self?.presentRenameAlert(forRowAt: indexPath)
            completionHandler(true)
        }
        action.backgroundColor = .systemOrange
        return UISwipeActionsConfiguration(actions: [action])
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing { return }
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedCard = timeCards[indexPath.row]
        
        if selectedCard.id_number == 0 {
            presentRenameAlert(forRowAt: indexPath)
        } else {
            let matchedIndex = timeCards.firstIndex(where: { $0.id_number == selectedCard.id_number }) ?? indexPath.row
            
            userDefaults.setValue(selectedCard.id_number, forKey: "id")
            userDefaults.setValue(selectedCard.name ?? "Unknown", forKey: "name")
            userDefaults.setValue(matchedIndex, forKey: "index")
            userDefaults.setValue(selectedCard.total, forKey: "total")
            userDefaults.setValue(selectedCard.week, forKey: "week")
            
            performSegue(withIdentifier: "timeCardInfo", sender: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let card = timeCards[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "timeCard", for: indexPath) as! TimeCardTableViewCell
        
        let roundTotal = round(card.total * 100) / 100.00
        let inTime = card.week
        
        var name: String!
        if card.name == nil || card.name?.trimmingCharacters(in: .whitespaces) == "" {
            name = "Name: Unknown"
        } else {
            name = "Name: \(card.name ?? "")"
        }
        
        cell.nameLabel.text = name
        if card.numberBeingExported == 1 {
            cell.inTimeLabel.text = "Day Of: \(inTime ?? "Unknown")"
        } else if card.numberBeingExported > 1 || card.numberBeingExported == 0 {
            cell.inTimeLabel.text = "Week Of: \(inTime ?? "Unknown")"
        }
        cell.totalLabel.text = "Total Hours: \(roundTotal)"
        
        // Thumbnail handling
        let cardIDNumber = NSNumber(value: card.id_number)
        
        if let cachedImage = thumbnailCache.object(forKey: cardIDNumber) {
            cell.thumbnailImageView.image = cachedImage
            cell.thumbnailImageView.isHidden = false
        } else {
            let cardID = card.id_number
            let fetchRequest = NSFetchRequest<Gallery>(entityName: "Gallery")
            fetchRequest.predicate = NSPredicate(format: "id_number == %d", cardID)
            fetchRequest.fetchLimit = 1
            
            if let galleryRecord = (try? context.fetch(fetchRequest))?.first,
               let thumbData = galleryRecord.thumbnail,
               let thumbnailImage = UIImage(data: thumbData) {
                thumbnailCache.setObject(thumbnailImage, forKey: cardIDNumber)
                cell.thumbnailImageView.image = thumbnailImage
                cell.thumbnailImageView.isHidden = false
            } else {
                cell.thumbnailImageView.image = nil
                cell.thumbnailImageView.isHidden = true
            }
        }
        
        return cell
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
}
