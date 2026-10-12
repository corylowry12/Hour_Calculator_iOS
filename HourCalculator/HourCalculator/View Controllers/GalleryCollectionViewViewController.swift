//
//  GalleryCollectionViewViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 8/23/21.
//

import UIKit
import CoreData

class GalleryCollectionViewViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    
    var index: Int!
    var selectedItemIndices = Set<Int>()
    var isSelectionModeActive = false
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    // 1. Cached in-memory array to eliminate repetitive disk queries
    private var galleryItems: [Gallery] = []
    
    private func fetchGalleryItems() {
        let fetchRequest = NSFetchRequest<Gallery>(entityName: "Gallery")
        // Compound predicate so both conditions are enforced
        fetchRequest.predicate = NSPredicate(format: "thumbnail != nil AND fullSize != nil")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Gallery.date), ascending: false)]
        fetchRequest.returnsObjectsAsFaults = false
        
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
        
        let feedback = UIImpactFeedbackGenerator(style: .medium)
        feedback.impactOccurred()
        
        isSelectionModeActive = true
        selectedItemIndices.insert(indexPath.item)
        shareButton.isEnabled = true
        
        collectionView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = true
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressGesture.minimumPressDuration = 0.45
        collectionView.addGestureRecognizer(longPressGesture)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Standard AdMob phone banner height
        let bannerHeight: CGFloat = 50.0
        let extraPadding: CGFloat = 8.0
        let bottomInset = bannerHeight + extraPadding
        
        tableView.contentInset.bottom = bottomInset
        tableView.verticalScrollIndicatorInsets.bottom = bottomInset
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        shareButton.isEnabled = !selectedItemIndices.isEmpty
        fetchGalleryItems()
        collectionView.reloadData()
        noImagesStoredBackground()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        exitSelectionMode()
    }
    
    private func exitSelectionMode() {
        isSelectionModeActive = false
        selectedItemIndices.removeAll()
        shareButton.isEnabled = false
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if isSelectionModeActive {
            selectedItemIndices.remove(indexPath.item)
            shareButton.isEnabled = !selectedItemIndices.isEmpty
            
            if selectedItemIndices.isEmpty {
                exitSelectionMode()
            } else {
                collectionView.reloadItems(at: [indexPath])
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isSelectionModeActive {
            if selectedItemIndices.contains(indexPath.item) {
                selectedItemIndices.remove(indexPath.item)
            } else {
                selectedItemIndices.insert(indexPath.item)
            }
            shareButton.isEnabled = !selectedItemIndices.isEmpty
            
            if selectedItemIndices.isEmpty {
                exitSelectionMode()
            } else {
                collectionView.reloadItems(at: [indexPath])
            }
        } else {
            index = indexPath.item
            performSegue(withIdentifier: "viewImage", sender: nil)
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
        
        if isSelected {
            cell.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
            cell.backgroundColor = .systemGray2
            cell.checkMark.image = UIImage(systemName: "checkmark.seal.fill")
        } else {
            cell.transform = .identity
            cell.backgroundColor = .systemGray5
            cell.checkMark.image = UIImage(systemName: "checkmark.seal")
        }
        
        if let thumbData = item.thumbnail {
            cell.galleryImage.image = UIImage(data: thumbData)
        } else {
            cell.galleryImage.image = nil
        }
        
        cell.galleryImage.contentMode = .scaleAspectFill
        cell.galleryImage.layer.borderWidth = 2
        cell.galleryImage.layer.borderColor = setBorderColor().cgColor
        cell.galleryImage.layer.cornerRadius = 8
        cell.galleryImage.clipsToBounds = true
        
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        cell.layer.shadowRadius = 4.0
        cell.layer.shadowOpacity = 0.25
        cell.layer.masksToBounds = false
        cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: 10).cgPath
        
        let itemName = item.name?.trimmingCharacters(in: .whitespaces)
        cell.nameLabel.text = (itemName == nil || itemName?.isEmpty == true) ? "Unknown" : itemName
        
        return cell
    }
    
    func setBorderColor() -> UIColor {
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
        guard !selectedItemIndices.isEmpty else { return }
        
        let alert = UIAlertController(title: "Share", message: "What would you like to share?", preferredStyle: .actionSheet)
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = sender
        }
        
        let selectedItems = selectedItemIndices.sorted().compactMap { idx -> Gallery? in
            guard idx < galleryItems.count else { return nil }
            return galleryItems[idx]
        }
        
        if selectedItems.count == 1, let item = selectedItems.first {
            alert.addAction(UIAlertAction(title: "Image and Name", style: .default, handler: { [weak self] _ in
                guard let self = self else { return }
                var activityItems: [Any] = []
                if let fullData = item.fullSize, let img = UIImage(data: fullData) {
                    activityItems.append(img)
                }
                activityItems.append(item.name ?? "Unknown")
                self.presentActivityController(items: activityItems)
            }))
        }
        
        alert.addAction(UIAlertAction(title: selectedItems.count == 1 ? "Image" : "Images", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            let images = selectedItems.compactMap { item -> UIImage? in
                guard let data = item.fullSize else { return nil }
                return UIImage(data: data)
            }
            self.presentActivityController(items: images)
        }))
        
        alert.addAction(UIAlertAction(title: selectedItems.count == 1 ? "Name" : "Names", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            let names = selectedItems.map { $0.name ?? "Unknown" }.joined(separator: ", ")
            self.presentActivityController(items: [names])
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] _ in
            self?.exitSelectionMode()
        }))
        
        present(alert, animated: true)
    }
    
    private func presentActivityController(items: [Any]) {
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        activityVC.completionWithItemsHandler = { [weak self] _, _, _, _ in
            self?.exitSelectionMode()
        }
        present(activityVC, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "viewImage", let targetIndex = index, targetIndex < galleryItems.count {
            let dvc = segue.destination as! ImageViewController
            let selectedGallery = galleryItems[targetIndex]
            
            // 1. Pass the cached thumbnail so the screen appears instantly
            if let thumbData = selectedGallery.thumbnail {
                dvc.placeholderThumbnail = UIImage(data: thumbData)
            }
            
            // 2. Pass raw data without main-thread JPEG decompression
            dvc.fullImageData = selectedGallery.fullSize
            dvc.name = selectedGallery.name
            dvc.index = targetIndex
        }
    }

}
