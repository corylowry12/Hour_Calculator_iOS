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
import UniformTypeIdentifiers
import PhotosUI

class TimeCardTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIDocumentPickerDelegate, PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    lazy var bannerView: BannerView! = BannerView(adSize: AdSizeBanner)
    
    @IBOutlet weak var sortBarButton: UIBarButtonItem!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var optionsBarButton: UIBarButtonItem!
    @IBOutlet var tableView: UITableView!
    
    var context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let userDefaults = UserDefaults.standard
    
    // In-memory cache to keep 60/120 FPS table scrolling smooth
    private let thumbnailCache = NSCache<NSNumber, UIImage>()
    
    var undo: Int = 0
    var predicateText: String!
    private var pendingTargetCardID: Int32?
    
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
    
    private var currentDisplayScale: CGFloat {
        if let windowScene = view.window?.windowScene {
            return windowScene.screen.scale
        }
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return windowScene.screen.scale
        }
        return traitCollection.displayScale > 0 ? traitCollection.displayScale : 2.0
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
    
    @objc func handleLongPress(longPressGesture: UILongPressGestureRecognizer) {
        guard longPressGesture.state == .began else { return }
        
        let p = longPressGesture.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: p) else { return }
        
        if tableView.isEditing {
            let feedback = UIImpactFeedbackGenerator(style: .medium)
            feedback.impactOccurred()
            
            for row in 0..<timeCards.count {
                let targetPath = IndexPath(row: row, section: 0)
                tableView.selectRow(at: targetPath, animated: true, scrollPosition: .none)
            }
            setupOptionsMenu()
        } else {
            setEditingMode(true, animated: true)
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            setupOptionsMenu()
        }
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
                self.setupOptionsMenu()
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
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressGesture.minimumPressDuration = 0.5
        tableView.addGestureRecognizer(longPressGesture)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.allowsMultipleSelection = true
        tableView.allowsMultipleSelectionDuringEditing = true
        
        editButton?.isEnabled = timeCards.count > 0
        setupSortMenu()
        setupOptionsMenu()
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
        setupOptionsMenu()
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
        setupOptionsMenu()
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
    
    // MARK: - Options Menu
    
    func setupOptionsMenu() {
        guard let optionsBarButton = optionsBarButton else { return }
        
        let isEditingMode = tableView.isEditing
        let selectedCount = tableView.indexPathsForSelectedRows?.count ?? 0
        let hasAnyItems = !timeCards.isEmpty
        
        let canExport = isEditingMode ? (selectedCount > 0) : hasAnyItems
        let exportTitle = (isEditingMode && selectedCount > 0) ? "Export Selected (\(selectedCount))" : "Export to CSV"
        
        let exportAction = UIAction(
            title: exportTitle,
            image: UIImage(systemName: "square.and.arrow.up"),
            attributes: canExport ? [] : .disabled
        ) { [weak self] _ in
            guard let self = self else { return }
            self.promptExportCSVConfirmation(onlySelected: isEditingMode)
        }
        
        let importAction = UIAction(
            title: "Import from CSV",
            image: UIImage(systemName: "square.and.arrow.down")
        ) { [weak self] _ in
            self?.presentCSVDocumentPicker()
        }
        
        let deleteTitle = (isEditingMode && selectedCount > 0) ? "Delete Selected (\(selectedCount))" : "Delete All"
        let deleteAllAction = UIAction(
            title: deleteTitle,
            image: UIImage(systemName: "trash"),
            attributes: hasAnyItems ? .destructive : [.destructive, .disabled]
        ) { [weak self] _ in
            guard let self = self else { return }
            if isEditingMode && selectedCount > 0 {
                self.confirmDeleteSelected()
            } else {
                self.confirmDeleteAll()
            }
        }
        
        optionsBarButton.menu = UIMenu(title: "", children: [deleteAllAction, exportAction, importAction])
        optionsBarButton.target = nil
        optionsBarButton.action = nil
    }
    
    private func confirmDeleteSelected() {
        guard let selectedPaths = tableView.indexPathsForSelectedRows, !selectedPaths.isEmpty else { return }
        let alert = UIAlertController(
            title: "Warning",
            message: "You are about to delete \(selectedPaths.count) selected time card(s). Would you like to continue?",
            preferredStyle: .actionSheet
        )
        alert.view.tintColor = currentAccentColor
        
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { [weak self] _ in
            guard let self = self else { return }
            let sortedPaths = selectedPaths.sorted(by: { $0.row > $1.row })
            
            for indexPath in sortedPaths {
                let card = self.timeCards[indexPath.row]
                let cardID = card.id_number
                self.thumbnailCache.removeObject(forKey: NSNumber(value: cardID))
                
                let infoFetch = NSFetchRequest<TimeCardInfo>(entityName: "TimeCardInfo")
                infoFetch.predicate = NSPredicate(format: "id_number == %d", cardID)
                if let infos = try? self.context.fetch(infoFetch) {
                    for info in infos { self.context.delete(info) }
                }
                
                let galFetch = NSFetchRequest<Gallery>(entityName: "Gallery")
                galFetch.predicate = NSPredicate(format: "id_number == %d", cardID)
                if let gals = try? self.context.fetch(galFetch) {
                    for gal in gals { self.context.delete(gal) }
                }
                
                self.context.delete(card)
            }
            
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
            self.undo = 1
            self.setEditingMode(false, animated: true)
            
            UIView.transition(with: self.tableView, duration: 0.35, options: .transitionCrossDissolve, animations: {
                self.tableView.reloadData()
            }, completion: nil)
            
            self.editButton?.isEnabled = self.timeCards.count > 0
            self.noHoursStoredBackground()
            self.setupSortMenu()
            self.setupOptionsMenu()
            self.tabBarController?.tabBar.items?[2].badgeValue = String(self.timeCards.count)
        }))
        
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func confirmDeleteAll() {
        if tableView.isEditing {
            setEditingMode(false, animated: true)
        }
        
        let alert = UIAlertController(
            title: "Delete All?",
            message: "Are you sure you would like to delete all stored time cards?",
            preferredStyle: .actionSheet
        )
        alert.view.tintColor = currentAccentColor
        
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { [weak self] _ in
            guard let self = self else { return }
            
            for card in self.timeCards {
                let cardID = card.id_number
                self.thumbnailCache.removeObject(forKey: NSNumber(value: cardID))
                
                let infoFetch = NSFetchRequest<TimeCardInfo>(entityName: "TimeCardInfo")
                infoFetch.predicate = NSPredicate(format: "id_number == %d", cardID)
                if let infos = try? self.context.fetch(infoFetch) {
                    for info in infos {
                        self.context.delete(info)
                    }
                }
                
                let galFetch = NSFetchRequest<Gallery>(entityName: "Gallery")
                galFetch.predicate = NSPredicate(format: "id_number == %d", cardID)
                if let gals = try? self.context.fetch(galFetch) {
                    for gal in gals {
                        self.context.delete(gal)
                    }
                }
                
                self.context.delete(card)
            }
            
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
            self.undo = 1
            
            UIView.transition(with: self.tableView, duration: 0.35, options: .transitionCrossDissolve, animations: {
                self.tableView.reloadData()
            }, completion: nil)
            
            self.editButton?.isEnabled = false
            self.noHoursStoredBackground()
            self.setupSortMenu()
            self.setupOptionsMenu()
            self.tabBarController?.tabBar.items?[2].badgeValue = "0"
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func promptExportCSVConfirmation(onlySelected: Bool) {
        let title = onlySelected ? "Export Selected to CSV" : "Export to CSV"
        let alert = UIAlertController(
            title: title,
            message: "Attached receipt photos and time card images cannot be exported into CSV format and will be excluded. Would you like to proceed?",
            preferredStyle: .alert
        )
        alert.view.tintColor = currentAccentColor
        
        alert.addAction(UIAlertAction(title: "Export", style: .default, handler: { [weak self] _ in
            self?.generateAndShareCSV(onlySelected: onlySelected)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func generateAndShareCSV(onlySelected: Bool) {
        let cardsToExport: [TimeCards]
        if onlySelected, let selectedPaths = tableView.indexPathsForSelectedRows {
            cardsToExport = selectedPaths.map { self.timeCards[$0.row] }
        } else {
            cardsToExport = self.timeCards
        }
        
        var csvContent = "Time Card ID,Time Card Name,Period / Date,Card Total Hours,Entry Date,In Time,Out Time,Entry Hours\n"
        
        for card in cardsToExport {
            let cardID = "\(card.id_number)"
            let escapedCardName = "\"\(card.name?.replacingOccurrences(of: "\"", with: "\"\"") ?? "Unknown")\""
            let escapedPeriod = "\"\(card.week?.replacingOccurrences(of: "\"", with: "\"\"") ?? "Unknown")\""
            let cardTotal = "\(round(card.total * 100) / 100.0)"
            
            let fetchRequest = NSFetchRequest<TimeCardInfo>(entityName: "TimeCardInfo")
            fetchRequest.predicate = NSPredicate(format: "id_number == %d", card.id_number)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(TimeCardInfo.date), ascending: true)]
            
            let entries = (try? context.fetch(fetchRequest)) ?? []
            
            if entries.isEmpty {
                csvContent += "\(cardID),\(escapedCardName),\(escapedPeriod),\(cardTotal),\"--\",\"--\",\"--\",\"--\"\n"
            } else {
                for item in entries {
                    let entryDate = "\"\(item.date?.replacingOccurrences(of: "\"", with: "\"\"") ?? "Unknown")\""
                    let inTime = "\"\(item.intime?.replacingOccurrences(of: "\"", with: "\"\"") ?? "Unknown")\""
                    let outTime = "\"\(item.outtime?.replacingOccurrences(of: "\"", with: "\"\"") ?? "Unknown")\""
                    let entryHours = "\"\(item.total_hours?.replacingOccurrences(of: "\"", with: "\"\"") ?? "Unknown")\""
                    
                    csvContent += "\(cardID),\(escapedCardName),\(escapedPeriod),\(cardTotal),\(entryDate),\(inTime),\(outTime),\(entryHours)\n"
                }
            }
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_h-mm-a"
        let timestamp = formatter.string(from: Date())
        let fileName = "HourCalculator_TimeCards_\(timestamp).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)
            
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            activityVC.view.tintColor = currentAccentColor
            
            if let popover = activityVC.popoverPresentationController {
                popover.barButtonItem = optionsBarButton
            }
            
            present(activityVC, animated: true, completion: nil)
        } catch {
            let errorAlert = UIAlertController(title: "Export Failed", message: "Unable to generate CSV file: \(error.localizedDescription)", preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(errorAlert, animated: true, completion: nil)
        }
    }
    
    // MARK: - CSV Import Logic
    
    private func presentCSVDocumentPicker() {
        let types: [UTType] = [.commaSeparatedText, .text, .plainText]
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileURL = urls.first else { return }
        
        let shouldStopAccessing = selectedFileURL.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
                selectedFileURL.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let csvData = try String(contentsOf: selectedFileURL, encoding: .utf8)
            parseAndImportCSV(csvData)
        } catch {
            showImportAlert(title: "Import Error", message: "Failed to read the selected file: \(error.localizedDescription)")
        }
    }
    
    private func parseCSVRow(_ rowString: String) -> [String] {
        var columns: [String] = []
        var currentField = ""
        var insideQuotes = false
        
        var iterator = rowString.makeIterator()
        while let char = iterator.next() {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                columns.append(currentField.trimmingCharacters(in: .whitespaces))
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        columns.append(currentField.trimmingCharacters(in: .whitespaces))
        
        return columns.map { field in
            var trimmed = field
            if trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"") && trimmed.count >= 2 {
                trimmed.removeFirst()
                trimmed.removeLast()
            }
            return trimmed.replacingOccurrences(of: "\"\"", with: "\"")
        }
    }
    
    private func parseAndImportCSV(_ rawString: String) {
        let cleanText = rawString.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        let lines = cleanText.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        guard lines.count > 1 else {
            showImportAlert(title: "Empty File", message: "The selected CSV contains no time card records to import.")
            return
        }
        
        let headerCols = parseCSVRow(lines[0])
        let hasIDColumn = headerCols.first?.lowercased().contains("id") ?? false
        
        var importedCardsCount = 0
        var importedEntriesCount = 0
        
        var cardMap: [Int32: TimeCards] = [:]
        
        let allExisting = self.timeCards
        var nextAutoID: Int32 = (allExisting.map { $0.id_number }.max() ?? 0) + 1
        
        for index in 1..<lines.count {
            let cols = parseCSVRow(lines[index])
            guard cols.count >= 7 else { continue }
            
            let cardIDString: String
            let cardName: String
            let cardPeriod: String
            let cardTotalStr: String
            let entryDate: String
            let entryIn: String
            let entryOut: String
            let entryHours: String
            
            if hasIDColumn {
                cardIDString = cols[0]
                cardName = cols[1]
                cardPeriod = cols[2]
                cardTotalStr = cols[3]
                entryDate = cols.count > 4 ? cols[4] : "--"
                entryIn = cols.count > 5 ? cols[5] : "--"
                entryOut = cols.count > 6 ? cols[6] : "--"
                entryHours = cols.count > 7 ? cols[7] : "--"
            } else {
                cardIDString = "0"
                cardName = cols[0]
                cardPeriod = cols[1]
                cardTotalStr = cols[2]
                entryDate = cols.count > 3 ? cols[3] : "--"
                entryIn = cols.count > 4 ? cols[4] : "--"
                entryOut = cols.count > 5 ? cols[5] : "--"
                entryHours = cols.count > 6 ? cols[6] : "--"
            }
            
            let parsedID = Int32(cardIDString) ?? 0
            let finalCardID: Int32
            if parsedID > 0 {
                finalCardID = parsedID
                if finalCardID >= nextAutoID {
                    nextAutoID = finalCardID + 1
                }
            } else {
                finalCardID = nextAutoID
                nextAutoID += 1
            }
            
            let targetCard: TimeCards
            if let existing = cardMap[finalCardID] {
                targetCard = existing
            } else {
                let fetchRequest = NSFetchRequest<TimeCards>(entityName: "TimeCards")
                fetchRequest.predicate = NSPredicate(format: "id_number == %d", finalCardID)
                fetchRequest.fetchLimit = 1
                
                if let found = (try? context.fetch(fetchRequest))?.first {
                    targetCard = found
                } else {
                    targetCard = TimeCards(context: context)
                    targetCard.id_number = finalCardID
                    importedCardsCount += 1
                }
                
                targetCard.name = (cardName.isEmpty || cardName == "Unknown") ? nil : cardName
                targetCard.week = cardPeriod
                targetCard.total = Double(cardTotalStr) ?? 0.0
                targetCard.numberBeingExported = (cardPeriod.lowercased().contains("day") || targetCard.week?.contains("/") == true) ? 1 : 2
                
                cardMap[finalCardID] = targetCard
            }
            
            if entryDate != "--" && !entryDate.isEmpty && entryIn != "--" && entryOut != "--" {
                let info = TimeCardInfo(context: context)
                info.id_number = finalCardID
                info.name = targetCard.name
                info.date = entryDate
                info.intime = entryIn
                info.outtime = entryOut
                info.total_hours = entryHours
                importedEntriesCount += 1
            }
        }
        
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        
        UIView.transition(with: self.tableView, duration: 0.35, options: .transitionCrossDissolve, animations: {
            self.tableView.reloadData()
        }, completion: nil)
        
        self.editButton?.isEnabled = self.timeCards.count > 0
        self.noHoursStoredBackground()
        self.setupSortMenu()
        self.setupOptionsMenu()
        self.tabBarController?.tabBar.items?[2].badgeValue = String(self.timeCards.count)
        
        showImportAlert(
            title: "Import Complete",
            message: "Successfully imported \(importedCardsCount) time card(s) and \(importedEntriesCount) entries."
        )
    }
    
    private func showImportAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.view.tintColor = currentAccentColor
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
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
                self.setupOptionsMenu()
                
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
    
    // MARK: - Photo Attachment Logic
    
    private func promptAttachPhoto(for cardID: Int32) {
        pendingTargetCardID = cardID
        let alert = UIAlertController(title: "Attach Photo", message: "Choose an image source to attach to this time card", preferredStyle: .alert)
        alert.view.tintColor = currentAccentColor
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { [weak self] _ in
                self?.presentCameraPicker()
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Choose Photo", style: .default, handler: { [weak self] _ in
            self?.presentPhotoPicker()
        }))
        
        let existingGalleryFetch = NSFetchRequest<Gallery>(entityName: "Gallery")
        existingGalleryFetch.predicate = NSPredicate(format: "id_number == %d", cardID)
        existingGalleryFetch.fetchLimit = 1
        if let existingRecord = (try? context.fetch(existingGalleryFetch))?.first, existingRecord.thumbnail != nil || existingRecord.fullSize != nil {
            alert.addAction(UIAlertAction(title: "Remove Photo", style: .destructive, handler: { [weak self] _ in
                self?.removeAttachedPhoto(for: cardID)
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    private func presentPhotoPicker() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    private func presentCameraPicker() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .camera
        present(picker, animated: true, completion: nil)
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] (image, _) in
            guard let self = self, let pickedImage = image as? UIImage, let cardID = self.pendingTargetCardID else { return }
            DispatchQueue.main.async {
                self.saveAttachedImage(pickedImage, for: cardID)
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let pickedImage = info[.originalImage] as? UIImage, let cardID = pendingTargetCardID else { return }
        saveAttachedImage(pickedImage, for: cardID)
    }
    
    private func saveAttachedImage(_ image: UIImage, for cardID: Int32) {
        guard let jpegData = image.jpegData(compressionQuality: 0.85) else { return }
        let thumbSize = CGSize(width: 156, height: 156)
        
        UIGraphicsBeginImageContextWithOptions(thumbSize, false, currentDisplayScale)
        image.draw(in: CGRect(origin: .zero, size: thumbSize))
        let thumbImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let thumbData = thumbImage?.jpegData(compressionQuality: 0.8) ?? jpegData
        
        thumbnailCache.setObject(thumbImage ?? image, forKey: NSNumber(value: cardID))
        
        let cardFetch = NSFetchRequest<TimeCards>(entityName: "TimeCards")
        cardFetch.predicate = NSPredicate(format: "id_number == %d", cardID)
        cardFetch.fetchLimit = 1
        let cardName = (try? context.fetch(cardFetch))?.first?.name ?? "Unknown"
        
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy hh:mm a"
        let dateFormatted = formatter.string(from: today)
        
        let infoFetch = NSFetchRequest<TimeCardInfo>(entityName: "TimeCardInfo")
        infoFetch.predicate = NSPredicate(format: "id_number == %d", cardID)
        if let infoItems = try? context.fetch(infoFetch), let firstInfo = infoItems.first {
            firstInfo.image = jpegData
        }
        
        let galFetch = NSFetchRequest<Gallery>(entityName: "Gallery")
        galFetch.predicate = NSPredicate(format: "id_number == %d", cardID)
        galFetch.fetchLimit = 1
        
        if let galleryRecord = (try? context.fetch(galFetch))?.first {
            galleryRecord.thumbnail = thumbData
            galleryRecord.fullSize = jpegData
            galleryRecord.date = dateFormatted
            galleryRecord.name = cardName
        } else {
            let galleryRecord = Gallery(context: context)
            galleryRecord.id_number = cardID
            galleryRecord.thumbnail = thumbData
            galleryRecord.fullSize = jpegData
            galleryRecord.date = dateFormatted
            galleryRecord.name = cardName
        }
        
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        
        UIView.transition(with: tableView, duration: 0.35, options: .transitionCrossDissolve, animations: {
            self.tableView.reloadData()
        }, completion: nil)
    }
    
    private func removeAttachedPhoto(for cardID: Int32) {
        thumbnailCache.removeObject(forKey: NSNumber(value: cardID))
        
        let galFetch = NSFetchRequest<Gallery>(entityName: "Gallery")
        galFetch.predicate = NSPredicate(format: "id_number == %d", cardID)
        if let galleryItems = try? context.fetch(galFetch) {
            for gal in galleryItems {
                context.delete(gal)
            }
        }
        
        let infoFetch = NSFetchRequest<TimeCardInfo>(entityName: "TimeCardInfo")
        infoFetch.predicate = NSPredicate(format: "id_number == %d", cardID)
        if let infoItems = try? context.fetch(infoFetch) {
            for info in infoItems {
                info.image = nil
            }
        }
        
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        
        UIView.transition(with: tableView, duration: 0.35, options: .transitionCrossDissolve, animations: {
            self.tableView.reloadData()
        }, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !tableView.isEditing else { return nil }
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completionHandler) in
            guard let self = self else { return }
            let alert = UIAlertController(title: "Warning", message: "You are about to delete a time card entry. Would you like to continue?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
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
                self.setupOptionsMenu()
                
                self.tabBarController?.tabBar.items?[2].badgeValue = String(self.timeCards.count)
                completionHandler(true)
            }))
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { _ in
                completionHandler(false)
            }))
            self.present(alert, animated: true, completion: nil)
        }
        deleteAction.backgroundColor = .systemRed
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !tableView.isEditing else { return nil }
        
        let renameAction = UIContextualAction(style: .normal, title: "Rename") { [weak self] (_, _, completionHandler) in
            self?.presentRenameAlert(forRowAt: indexPath)
            completionHandler(true)
        }
        renameAction.backgroundColor = .systemOrange
        
        let photoAction = UIContextualAction(style: .normal, title: "Photo") { [weak self] (_, _, completionHandler) in
            guard let self = self else { return }
            let card = self.timeCards[indexPath.row]
            self.promptAttachPhoto(for: card.id_number)
            completionHandler(true)
        }
        photoAction.backgroundColor = .systemBlue
        
        return UISwipeActionsConfiguration(actions: [renameAction, photoAction])
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            setupOptionsMenu()
            return
        }
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
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            setupOptionsMenu()
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
