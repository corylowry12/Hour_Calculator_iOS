//
//  GalleryCollectionViewViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 8/23/21.
//

import UIKit
import CoreData

class GalleryCollectionViewViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDataSourcePrefetching {
    
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    
    var index: Int!
    var selectedItemIndices = Set<Int>()
    var isSelectionModeActive = false
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let userDefaults = UserDefaults.standard
    
    // In-memory cache for rendered thumbnails
    private let thumbnailImageCache = NSCache<NSNumber, UIImage>()
    
    private var galleryItems: [Gallery] = []
    
    // Cache the accent border CGColor to avoid repeated UserDefaults disk reads while scrolling
    private var cachedBorderColor: CGColor = UIColor(rgb: 0x26A69A).cgColor
    
    // Prevents redundant reloads while batch deletion animation is actively running
    private var isInternalDeletionInProgress = false
    
    // Liquid Glass Tooltip UI
    private var liquidGlassTooltipView: UIView?
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func fetchGalleryItems() {
        let fetchRequest = NSFetchRequest<Gallery>(entityName: "Gallery")
        fetchRequest.predicate = NSPredicate(format: "thumbnail != nil")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Gallery.date), ascending: false)]
        
        // Batch fetch thumbnail and name to avoid SQLite faults during scroll
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.propertiesToFetch = ["id_number", "thumbnail", "name", "date"]
        fetchRequest.relationshipKeyPathsForPrefetching = []
        
        do {
            self.galleryItems = try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch gallery items: \(error)")
            self.galleryItems = []
        }
    }
    
    func noImagesStoredBackground() {
        if galleryItems.isEmpty {
            let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height))
            messageLabel.text = "There are currently no images stored"
            messageLabel.numberOfLines = 0
            messageLabel.textAlignment = .center
            messageLabel.font = UIFont.systemFont(ofSize: 16.0, weight: .medium)
            messageLabel.textColor = .secondaryLabel
            collectionView.backgroundView = messageLabel
        } else {
            collectionView.backgroundView = nil
        }
    }
    
    @objc func handleLongPress(longPressGesture: UILongPressGestureRecognizer) {
        guard longPressGesture.state == .began else { return }
        let point = longPressGesture.location(in: collectionView)
        
        guard let indexPath = collectionView.indexPathForItem(at: point) else { return }
        
        dismissTooltip()
        
        let feedback = UIImpactFeedbackGenerator(style: .medium)
        feedback.impactOccurred()
        
        isSelectionModeActive = true
        selectedItemIndices.insert(indexPath.item)
        updateNavigationBarMenu()
        
        // Animate checkmarks into view across all currently visible cells
        for visibleCell in collectionView.visibleCells {
            if let cell = visibleCell as? GalleryCollectionViewCell {
                cell.checkMark.alpha = 0
                cell.checkMark.isHidden = false
                UIView.animate(withDuration: 0.2) {
                    cell.checkMark.alpha = 1.0
                }
            }
        }
        
        // Spring-shrink the long-pressed cell
        if let targetCell = collectionView.cellForItem(at: indexPath) as? GalleryCollectionViewCell {
            animateCellSelection(targetCell, isSelected: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.prefetchDataSource = self
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = true
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressGesture.minimumPressDuration = 0.45
        collectionView.addGestureRecognizer(longPressGesture)
        
        // Listen for image modifications across other controllers
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDataUpdateNotification),
            name: NSNotification.Name("Update"),
            object: nil
        )
        
        updateNavigationBarMenu()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkAndShowLiquidGlassTooltip()
    }
    
    @objc private func handleDataUpdateNotification() {
        guard !isInternalDeletionInProgress else { return }
        thumbnailImageCache.removeAllObjects()
        cachedBorderColor = resolveBorderColor().cgColor
        fetchGalleryItems()
        collectionView.reloadData()
        noImagesStoredBackground()
        updateNavigationBarMenu()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let bannerHeight: CGFloat = 50.0
        let extraPadding: CGFloat = 8.0
        let bottomInset = bannerHeight + extraPadding
        
        collectionView.contentInset.bottom = bottomInset
        collectionView.verticalScrollIndicatorInsets.bottom = bottomInset
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        cachedBorderColor = resolveBorderColor().cgColor
        thumbnailImageCache.removeAllObjects()
        fetchGalleryItems()
        collectionView.reloadData()
        noImagesStoredBackground()
        updateNavigationBarMenu()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismissTooltip()
        exitSelectionMode()
    }
    
    // MARK: - Liquid Glass Tooltip
    
    private func checkAndShowLiquidGlassTooltip() {
        guard !galleryItems.isEmpty else { return }
        let tooltipShownKey = "hasSeenGalleryLongPressTooltip"
        guard !userDefaults.bool(forKey: tooltipShownKey) else { return }
        userDefaults.set(true, forKey: tooltipShownKey)
        
        // Root container with floating shadow
        let tooltip = UIView()
        tooltip.translatesAutoresizingMaskIntoConstraints = false
        tooltip.layer.shadowColor = UIColor.black.cgColor
        tooltip.layer.shadowOpacity = 0.2
        tooltip.layer.shadowOffset = CGSize(width: 0, height: 6)
        tooltip.layer.shadowRadius = 14
        tooltip.alpha = 0
        tooltip.transform = CGAffineTransform(scaleX: 0.85, y: 0.85).translatedBy(x: 0, y: -10)
        
        // Liquid glass frosted blur material
        let blurEffect = UIBlurEffect(style: .systemThinMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.layer.cornerRadius = 16.0
        blurView.layer.masksToBounds = true
        blurView.layer.borderWidth = 1.0
        blurView.layer.borderColor = UIColor.white.withAlphaComponent(0.22).cgColor
        
        // Tooltip Content - Tinted with the app's current accent color
        let currentAccent = resolveBorderColor()
        let icon = UIImageView(image: UIImage(systemName: "hand.tap.fill"))
        icon.tintColor = currentAccent
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "Long press on items to select them"
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        
        let stack = UIStackView(arrangedSubviews: [icon, label])
        stack.axis = .horizontal
        stack.spacing = 8.0
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        blurView.contentView.addSubview(stack)
        tooltip.addSubview(blurView)
        view.addSubview(tooltip)
        
        NSLayoutConstraint.activate([
            blurView.leadingAnchor.constraint(equalTo: tooltip.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: tooltip.trailingAnchor),
            blurView.topAnchor.constraint(equalTo: tooltip.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: tooltip.bottomAnchor),
            
            stack.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor, constant: -14),
            stack.topAnchor.constraint(equalTo: blurView.contentView.topAnchor, constant: 10),
            stack.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor, constant: -10),
            
            icon.widthAnchor.constraint(equalToConstant: 16),
            icon.heightAnchor.constraint(equalToConstant: 16),
            
            tooltip.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            tooltip.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12)
        ])
        
        // Tap to dismiss early
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissTooltip))
        tooltip.addGestureRecognizer(tap)
        self.liquidGlassTooltipView = tooltip
        
        // Animate entrance
        UIView.animate(withDuration: 0.5, delay: 0.2, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [.curveEaseOut]) {
            tooltip.alpha = 1.0
            tooltip.transform = .identity
        } completion: { _ in
            // Auto dismiss after 3.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { [weak self] in
                self?.dismissTooltip()
            }
        }
    }
    
    @objc private func dismissTooltip() {
        guard let tooltip = liquidGlassTooltipView else { return }
        UIView.animate(withDuration: 0.35, delay: 0, options: [.curveEaseIn]) {
            tooltip.alpha = 0
            tooltip.transform = CGAffineTransform(scaleX: 0.9, y: 0.9).translatedBy(x: 0, y: -6)
        } completion: { [weak self] _ in
            tooltip.removeFromSuperview()
            self?.liquidGlassTooltipView = nil
        }
    }
    
    private func exitSelectionMode() {
        isSelectionModeActive = false
        selectedItemIndices.removeAll()
        updateNavigationBarMenu()
        
        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.5,
            options: [.curveEaseOut]
        ) {
            for visibleCell in self.collectionView.visibleCells {
                if let cell = visibleCell as? GalleryCollectionViewCell {
                    cell.transform = .identity
                    cell.backgroundColor = .systemGray5
                    cell.checkMark.alpha = 0
                }
            }
        } completion: { _ in
            self.collectionView.reloadData()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if isSelectionModeActive {
            selectedItemIndices.remove(indexPath.item)
            updateNavigationBarMenu()
            
            if selectedItemIndices.isEmpty {
                exitSelectionMode()
            } else if let cell = collectionView.cellForItem(at: indexPath) as? GalleryCollectionViewCell {
                animateCellSelection(cell, isSelected: false)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isSelectionModeActive {
            let isNowSelected: Bool
            if selectedItemIndices.contains(indexPath.item) {
                selectedItemIndices.remove(indexPath.item)
                isNowSelected = false
            } else {
                selectedItemIndices.insert(indexPath.item)
                isNowSelected = true
            }
            
            updateNavigationBarMenu()
            
            if selectedItemIndices.isEmpty {
                exitSelectionMode()
            } else if let cell = collectionView.cellForItem(at: indexPath) as? GalleryCollectionViewCell {
                let feedback = UISelectionFeedbackGenerator()
                feedback.selectionChanged()
                animateCellSelection(cell, isSelected: isNowSelected)
            }
        } else {
            index = indexPath.item
            performSegue(withIdentifier: "viewImage", sender: nil)
        }
    }
    
    private func animateCellSelection(_ cell: GalleryCollectionViewCell, isSelected: Bool) {
        UIView.animate(
            withDuration: 0.28,
            delay: 0,
            usingSpringWithDamping: 0.72,
            initialSpringVelocity: 0.6,
            options: [.curveEaseInOut, .allowUserInteraction]
        ) {
            if isSelected {
                cell.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
                cell.backgroundColor = .systemGray2
                cell.checkMark.image = UIImage(systemName: "checkmark.circle.fill")
            } else {
                cell.transform = .identity
                cell.backgroundColor = .systemGray5
                cell.checkMark.image = UIImage(systemName: "checkmark.circle")
            }
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return galleryItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "galleryCell", for: indexPath) as! GalleryCollectionViewCell
        let item = galleryItems[indexPath.item]
        let isSelected = selectedItemIndices.contains(indexPath.item)
        
        cell.checkMark.isHidden = !isSelectionModeActive
        cell.checkMark.alpha = isSelectionModeActive ? 1.0 : 0.0
        
        if isSelected {
            cell.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
            cell.backgroundColor = .systemGray2
            cell.checkMark.image = UIImage(systemName: "checkmark.circle.fill")
        } else {
            cell.transform = .identity
            cell.backgroundColor = .systemGray5
            cell.checkMark.image = UIImage(systemName: "checkmark.circle")
        }
        
        // Fast in-memory retrieval or asynchronous decode fallback
        let cardKey = NSNumber(value: item.id_number)
        if let cached = thumbnailImageCache.object(forKey: cardKey) {
            cell.galleryImage.image = cached
        } else if let thumbData = item.thumbnail {
            cell.galleryImage.image = nil
            let currentItemIndex = indexPath.item
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                guard let image = UIImage(data: thumbData) else { return }
                self?.thumbnailImageCache.setObject(image, forKey: cardKey)
                DispatchQueue.main.async {
                    if let visibleCell = collectionView.cellForItem(at: indexPath) as? GalleryCollectionViewCell,
                       self?.galleryItems.indices.contains(currentItemIndex) == true,
                       self?.galleryItems[currentItemIndex].id_number == item.id_number {
                        visibleCell.galleryImage.image = image
                    }
                }
            }
        } else {
            cell.galleryImage.image = nil
        }
        
        cell.galleryImage.contentMode = .scaleAspectFill
        cell.galleryImage.layer.borderWidth = 2
        cell.galleryImage.layer.borderColor = cachedBorderColor
        cell.galleryImage.layer.cornerRadius = 8
        cell.galleryImage.clipsToBounds = true
        
        let itemName = item.name?.trimmingCharacters(in: .whitespaces)
        cell.nameLabel.text = (itemName == nil || itemName?.isEmpty == true) ? "Unknown" : itemName
        
        return cell
    }
    
    // MARK: - Navigation Bar Menu & Actions
    
    private func updateNavigationBarMenu() {
        guard let shareButton = shareButton else { return }
        
        let hasSelection = !selectedItemIndices.isEmpty
        let selectionCount = selectedItemIndices.count
        
        // Disable button completely and remove menu when no items are selected
        guard hasSelection else {
            shareButton.isEnabled = false
            shareButton.menu = nil
            return
        }
        
        shareButton.isEnabled = true
        
        // Submenu: Share Actions
        var shareSubActions: [UIAction] = []
        
        if selectionCount == 1 {
            let shareImageAndName = UIAction(
                title: "Share Image and Name",
                image: UIImage(systemName: "doc.richtext")
            ) { [weak self] _ in
                self?.executeShareImageAndName()
            }
            shareSubActions.append(shareImageAndName)
        }
        
        let imageTitle = selectionCount == 1 ? "Share Image" : "Share Images"
        let shareImagesAction = UIAction(
            title: imageTitle,
            image: UIImage(systemName: "photo")
        ) { [weak self] _ in
            self?.executeShareImages()
        }
        shareSubActions.append(shareImagesAction)
        
        let nameTitle = selectionCount == 1 ? "Share Name" : "Share Names"
        let shareNamesAction = UIAction(
            title: nameTitle,
            image: UIImage(systemName: "character")
        ) { [weak self] _ in
            self?.executeShareNames()
        }
        shareSubActions.append(shareNamesAction)
        
        let shareSubmenu = UIMenu(
            title: "Share",
            image: UIImage(systemName: "square.and.arrow.up"),
            children: shareSubActions
        )
        
        // Delete Selected Action
        let deleteAction = UIAction(
            title: "Delete Selected (\(selectionCount))",
            image: UIImage(systemName: "trash"),
            attributes: .destructive
        ) { [weak self] _ in
            self?.confirmDeleteSelectedItems()
        }
        
        shareButton.menu = UIMenu(title: "", children: [deleteAction, shareSubmenu])
        shareButton.target = nil
        shareButton.action = nil
    }
    
    private func getActiveSelectedGalleryItems() -> [Gallery] {
        return selectedItemIndices.sorted().compactMap { idx -> Gallery? in
            guard idx < galleryItems.count else { return nil }
            return galleryItems[idx]
        }
    }
    
    private func executeShareImageAndName() {
        let items = getActiveSelectedGalleryItems()
        guard let item = items.first else { return }
        
        var activityItems: [Any] = []
        if let fullData = item.fullSize, let img = UIImage(data: fullData) {
            activityItems.append(img)
        }
        activityItems.append(item.name ?? "Unknown")
        presentActivityController(items: activityItems)
    }
    
    private func executeShareImages() {
        let items = getActiveSelectedGalleryItems()
        let images = items.compactMap { item -> UIImage? in
            guard let data = item.fullSize else { return nil }
            return UIImage(data: data)
        }
        guard !images.isEmpty else { return }
        presentActivityController(items: images)
    }
    
    private func executeShareNames() {
        let items = getActiveSelectedGalleryItems()
        let names = items.map { $0.name ?? "Unknown" }.joined(separator: ", ")
        guard !names.isEmpty else { return }
        presentActivityController(items: [names])
    }
    
    private func confirmDeleteSelectedItems() {
        guard !selectedItemIndices.isEmpty else { return }
        let count = selectedItemIndices.count
        
        let alert = UIAlertController(
            title: "Delete \(count == 1 ? "Image" : "Images")",
            message: "Are you sure you want to permanently delete \(count == 1 ? "this selected image" : "these \(count) selected images")?",
            preferredStyle: .actionSheet
        )
        alert.view.tintColor = resolveBorderColor()
        
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = shareButton
        }
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
            self?.performDeleteSelected()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true)
    }
    
    private func performDeleteSelected() {
        let sortedIndices = selectedItemIndices.sorted(by: >)
        let indexPathsToDelete = sortedIndices.map { IndexPath(item: $0, section: 0) }
        
        // 1. Delete records from Core Data and evict cache
        for idx in sortedIndices {
            guard idx < galleryItems.count else { continue }
            let item = galleryItems[idx]
            let cardID = item.id_number
            
            thumbnailImageCache.removeObject(forKey: NSNumber(value: cardID))
            
            // Clear image reference on matching TimeCardInfo records
            let infoFetch = NSFetchRequest<TimeCardInfo>(entityName: "TimeCardInfo")
            infoFetch.predicate = NSPredicate(format: "id_number == %d", cardID)
            if let infoItems = try? context.fetch(infoFetch) {
                for info in infoItems {
                    info.image = nil
                }
            }
            
            context.delete(item)
        }
        
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        
        // Flag to prevent redundant reloads while batch deletion animation executes
        isInternalDeletionInProgress = true
        NotificationCenter.default.post(name: NSNotification.Name("Update"), object: nil)
        isInternalDeletionInProgress = false
        
        // 2. Remove matching items from local backing array
        for idx in sortedIndices {
            if idx < galleryItems.count {
                galleryItems.remove(at: idx)
            }
        }
        
        // 3. Clear selection mode tracking
        selectedItemIndices.removeAll()
        isSelectionModeActive = false
        updateNavigationBarMenu()
        
        // 4. Perform native batch deletion animation (causes remaining cells to shift and collapse smoothly)
        collectionView.performBatchUpdates({
            collectionView.deleteItems(at: indexPathsToDelete)
        }) { [weak self] _ in
            guard let self = self else { return }
            self.noImagesStoredBackground()
            
            // Ensure remaining visible cells animate cleanly out of selection state
            for visibleCell in self.collectionView.visibleCells {
                if let cell = visibleCell as? GalleryCollectionViewCell {
                    cell.transform = .identity
                    cell.backgroundColor = .systemGray5
                    cell.checkMark.alpha = 0
                    cell.checkMark.isHidden = true
                }
            }
        }
    }
    
    private func presentActivityController(items: [Any]) {
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.barButtonItem = shareButton
        }
        
        activityVC.completionWithItemsHandler = { [weak self] _, _, _, _ in
            self?.exitSelectionMode()
        }
        present(activityVC, animated: true)
    }
    
    // MARK: - Prefetching Data Source
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            guard galleryItems.indices.contains(indexPath.item) else { continue }
            let item = galleryItems[indexPath.item]
            let cardKey = NSNumber(value: item.id_number)
            
            if thumbnailImageCache.object(forKey: cardKey) == nil, let thumbData = item.thumbnail {
                DispatchQueue.global(qos: .utility).async { [weak self] in
                    if let image = UIImage(data: thumbData) {
                        self?.thumbnailImageCache.setObject(image, forKey: cardKey)
                    }
                }
            }
        }
    }
    
    // MARK: - Dynamic 3-Column Flow Layout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let columns: CGFloat = 3
        let sideInset: CGFloat = 16.0
        let itemSpacing: CGFloat = 10.0
        
        let totalHorizontalPadding = (sideInset * 2) + (itemSpacing * (columns - 1))
        let availableWidth = collectionView.bounds.width - totalHorizontalPadding
        let itemWidth = floor(availableWidth / columns)
        
        let itemHeight = itemWidth + 28.0
        return CGSize(width: itemWidth, height: itemHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 16.0, left: 16.0, bottom: 16.0, right: 16.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingFor section: Int) -> CGFloat {
        return 10.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingFor section: Int) -> CGFloat {
        return 16.0
    }
    
    private func resolveBorderColor() -> UIColor {
        let accent = UserDefaults.standard.integer(forKey: "accent")
        switch accent {
        case 0: return UIColor(rgb: 0x26A69A)
        case 1: return UIColor(rgb: 0x7841c4)
        case 2: return UIColor(rgb: 0x347deb)
        case 3: return UIColor(rgb: 0xfc783a)
        case 4: return UIColor(rgb: 0xc41d1d)
        case 5:
            let random = UserDefaults.standard.integer(forKey: "accentRandom")
            switch random {
            case 0: return UIColor(rgb: 0x26A69A)
            case 1: return UIColor(rgb: 0x7841c4)
            case 2: return UIColor(rgb: 0x347deb)
            case 3: return UIColor(rgb: 0xfc783a)
            default: return UIColor(rgb: 0xc41d1d)
            }
        default: return UIColor(rgb: 0x26A69A)
        }
    }
    
    @IBAction func shareButton(_ sender: UIBarButtonItem) {
        // Handled directly via UIMenu in iOS 14+
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "viewImage", let targetIndex = index, targetIndex < galleryItems.count {
            let dvc = segue.destination as! ImageViewController
            let selectedGallery = galleryItems[targetIndex]
            
            dvc.name = selectedGallery.name
            dvc.index = targetIndex
            dvc.targetCardID = Int(selectedGallery.id_number)
        }
    }
}
