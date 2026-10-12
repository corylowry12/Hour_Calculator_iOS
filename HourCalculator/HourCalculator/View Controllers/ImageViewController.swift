//
//  ImageViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 8/25/21.
//

import Foundation
import UIKit
import CoreData

class ImageViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    
    // Companion image view that trails behind during live drags
    private lazy var companionImageView: UIImageView = {
        let iv = UIImageView()
        iv.isUserInteractionEnabled = false
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    var placeholderThumbnail: UIImage?
    var targetCardID: Int = 0
    var name: String?
    var index: Int = -1
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let userDefaults = UserDefaults.standard
    
    private var isAnimatingTransition = false
    private var companionIndex: Int?
    
    // In-memory cache for screen-fitted full-aspect images
    private static let screenImageCache = NSCache<NSNumber, UIImage>()
    
    // Interactive Title UI
    private let titleLabel = UILabel()
    private let titleButton = UIButton(type: .system)
    
    // Liquid Glass Tooltip UI
    private var liquidGlassTooltipView: UIView?
    
    private var currentDisplayScale: CGFloat {
        if let windowScene = view.window?.windowScene {
            return windowScene.screen.scale
        }
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return windowScene.screen.scale
        }
        return traitCollection.displayScale > 0 ? traitCollection.displayScale : 2.0
    }
    
    private var galleryRecords: [(id: Int32, name: String?)] = []
    
    private func fetchGalleryMetadata() {
        guard index != -1 else { return }
        let fetchRequest = NSFetchRequest<NSDictionary>(entityName: "Gallery")
        fetchRequest.resultType = .dictionaryResultType
        fetchRequest.propertiesToFetch = ["id_number", "name"]
        fetchRequest.predicate = NSPredicate(format: "thumbnail != nil")
        let sort = NSSortDescriptor(key: #keyPath(Gallery.date), ascending: false)
        fetchRequest.sortDescriptors = [sort]
        
        if let results = try? context.fetch(fetchRequest) {
            galleryRecords = results.compactMap { dict in
                guard let id = dict["id_number"] as? Int32 else { return nil }
                let cardName = dict["name"] as? String
                return (id: id, name: cardName)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFit
        
        setupCompanionImageView()
        setupInteractiveTitleView()
        updateNavigationTitle(with: name)
        
        setupDeleteButton()
        
        if index != -1 {
            fetchGalleryMetadata()
            setupInteractivePanGesture()
        }
        
        loadActiveImage(animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkAndShowLiquidGlassTooltip()
    }
    
    // MARK: - Interactive Title Bar (Rename)
    
    private func setupInteractiveTitleView() {
        titleButton.translatesAutoresizingMaskIntoConstraints = false
        titleButton.addTarget(self, action: #selector(promptRenameTitle), for: .touchUpInside)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        
        let editIcon = UIImageView(image: UIImage(systemName: "pencil.circle"))
        editIcon.translatesAutoresizingMaskIntoConstraints = false
        editIcon.tintColor = .secondaryLabel
        editIcon.contentMode = .scaleAspectFit
        
        let container = UIStackView(arrangedSubviews: [titleLabel, editIcon])
        container.translatesAutoresizingMaskIntoConstraints = false
        container.axis = .horizontal
        container.spacing = 6.0
        container.alignment = .center
        container.isUserInteractionEnabled = false
        
        titleButton.addSubview(container)
        
        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: titleButton.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: titleButton.centerYAnchor),
            container.leadingAnchor.constraint(greaterThanOrEqualTo: titleButton.leadingAnchor),
            container.trailingAnchor.constraint(lessThanOrEqualTo: titleButton.trailingAnchor),
            editIcon.widthAnchor.constraint(equalToConstant: 18),
            editIcon.heightAnchor.constraint(equalToConstant: 18)
        ])
        
        navigationItem.titleView = titleButton
    }
    
    private func updateNavigationTitle(with newTitle: String?) {
        let display = (newTitle?.trimmingCharacters(in: .whitespaces).isEmpty == false) ? newTitle! : "Time Card Image"
        titleLabel.text = display
        self.title = display
        titleButton.sizeToFit()
    }
    
    @objc private func promptRenameTitle() {
        let currentText = titleLabel.text == "Time Card Image" ? "" : (titleLabel.text ?? "")
        let alert = UIAlertController(title: "Rename Entry", message: "Enter a new name for this time card image.", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "e.g. Week 42 Shift"
            textField.text = currentText
            textField.autocapitalizationType = .words
            textField.clearButtonMode = .whileEditing
        }
        
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { [weak self, weak alert] _ in
            guard let self = self, let enteredText = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespaces) else { return }
            let finalName = enteredText.isEmpty ? "Time Card Image" : enteredText
            self.persistRenamedTitle(finalName)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    private func persistRenamedTitle(_ newName: String) {
        let resolvedID = resolveCurrentCardID()
        
        // 1. Update Gallery entity
        let galFetch = NSFetchRequest<Gallery>(entityName: "Gallery")
        galFetch.predicate = NSPredicate(format: "id_number == %d", resolvedID)
        if let galleryItems = try? context.fetch(galFetch) {
            for gal in galleryItems {
                gal.name = newName
            }
        }
        
        // 2. Update TimeCardInfo entity (only uses id_number)
        let infoFetch = NSFetchRequest<TimeCardInfo>(entityName: "TimeCardInfo")
        infoFetch.predicate = NSPredicate(format: "id_number == %d", resolvedID)
        if let infoItems = try? context.fetch(infoFetch) {
            for info in infoItems {
                info.name = newName
            }
        }
        
        // 3. Update the parent TimeCards entity
        let cardFetch = NSFetchRequest<TimeCards>(entityName: "TimeCards")
        cardFetch.predicate = NSPredicate(format: "id_number == %d", resolvedID)
        if let cardItems = try? context.fetch(cardFetch) {
            for card in cardItems {
                card.name = newName
            }
        }
        
        // 4. Save and broadcast update
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        NotificationCenter.default.post(name: NSNotification.Name("Update"), object: nil)
        
        // 5. Update local view state & metadata cache
        self.name = newName
        updateNavigationTitle(with: newName)
        
        if index != -1 && galleryRecords.indices.contains(index) {
            galleryRecords[index].name = newName
        }
    }
    
    // MARK: - Liquid Glass Tooltip
    
    private func checkAndShowLiquidGlassTooltip() {
        let tooltipShownKey = "hasSeenTitleRenameTooltip"
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
        
        // Tooltip Content
        let icon = UIImageView(image: UIImage(systemName: "hand.tap.fill"))
        icon.tintColor = .label
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "Tap the title above to rename this entry"
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
    
    private func setupCompanionImageView() {
        view.addSubview(companionImageView)
        NSLayoutConstraint.activate([
            companionImageView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            companionImageView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            companionImageView.topAnchor.constraint(equalTo: imageView.topAnchor),
            companionImageView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor)
        ])
        companionImageView.isHidden = true
    }
    
    private func setupDeleteButton() {
        let deleteButton = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: self,
            action: #selector(confirmDeleteImage)
        )
        deleteButton.tintColor = .systemRed
        navigationItem.rightBarButtonItem = deleteButton
    }
    
    @objc private func confirmDeleteImage() {
        let alert = UIAlertController(
            title: "Delete Image",
            message: "Are you sure you want to permanently delete this image?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
            self?.performDeleteAndDismiss()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    private func resolveCurrentCardID() -> Int {
        if index != -1 && galleryRecords.indices.contains(index) {
            return Int(galleryRecords[index].id)
        }
        if targetCardID != 0 {
            return targetCardID
        }
        return userDefaults.integer(forKey: "id")
    }
    
    private func performDeleteAndDismiss() {
        let isFromGallery = (index != -1)
        let resolvedID = resolveCurrentCardID()
        
        // Evict from downsampled image cache
        Self.screenImageCache.removeObject(forKey: NSNumber(value: resolvedID))
        
        // 1. Delete Gallery entity record
        let galFetch = NSFetchRequest<Gallery>(entityName: "Gallery")
        galFetch.predicate = NSPredicate(format: "id_number == %d", resolvedID)
        if let galleryItems = try? context.fetch(galFetch) {
            for gal in galleryItems { context.delete(gal) }
        }
        
        // 2. Clear image reference on matching TimeCardInfo records
        let infoFetch = NSFetchRequest<TimeCardInfo>(entityName: "TimeCardInfo")
        infoFetch.predicate = NSPredicate(format: "id_number == %d", resolvedID)
        if let infoItems = try? context.fetch(infoFetch) {
            for info in infoItems { info.image = nil }
        }
        
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        NotificationCenter.default.post(name: NSNotification.Name("Update"), object: nil)
        
        // If opened from TimeCardInfo view, pop back immediately
        guard isFromGallery else {
            navigationController?.popViewController(animated: true)
            return
        }
        
        // 3. Update the local metadata array
        let deletedIndex = index
        if galleryRecords.indices.contains(deletedIndex) {
            galleryRecords.remove(at: deletedIndex)
        }
        
        // 4. If no photos remain, pop back to the gallery
        guard !galleryRecords.isEmpty else {
            navigationController?.popViewController(animated: true)
            return
        }
        
        // 5. Determine the target index (next image in line, or previous if at the end)
        let movingForward: Bool
        let nextIndex: Int
        if deletedIndex < galleryRecords.count {
            nextIndex = deletedIndex
            movingForward = true
        } else {
            nextIndex = galleryRecords.count - 1
            movingForward = false
        }
        
        // 6. Slide to the next image
        transitionAfterDeletion(to: nextIndex, movingForward: movingForward)
    }
    
    private func transitionAfterDeletion(to nextIndex: Int, movingForward: Bool) {
        guard galleryRecords.indices.contains(nextIndex) else { return }
        isAnimatingTransition = true
        
        let screenWidth = view.bounds.width
        let spacing: CGFloat = 24.0
        let incomingOffset = movingForward ? (screenWidth + spacing) : -(screenWidth + spacing)
        let outgoingTargetX = movingForward ? -(screenWidth + spacing) : (screenWidth + spacing)
        
        // Prepare companion view with correct aspect ratio image of incoming photo
        loadCompanionImage(for: nextIndex)
        companionImageView.transform = CGAffineTransform(translationX: incomingOffset, y: 0)
        companionImageView.isHidden = false
        
        UIView.animate(
            withDuration: 0.32,
            delay: 0,
            usingSpringWithDamping: 0.88,
            initialSpringVelocity: 0.4,
            options: [.curveEaseInOut]
        ) {
            self.imageView.transform = CGAffineTransform(translationX: outgoingTargetX, y: 0)
            self.companionImageView.transform = .identity
        } completion: { [weak self] _ in
            guard let self = self else { return }
            
            // Swap companion image into primary view
            self.imageView.image = self.companionImageView.image
            self.imageView.transform = .identity
            
            self.companionImageView.image = nil
            self.companionImageView.transform = .identity
            self.companionImageView.isHidden = true
            
            self.index = nextIndex
            let item = self.galleryRecords[nextIndex]
            self.updateNavigationTitle(with: item.name)
            
            self.isAnimatingTransition = false
            self.companionIndex = nil
            
            self.loadActiveImage(animated: false)
        }
    }
    
    private func fetchDownsampledImage(for recordID: Int, completion: @escaping (UIImage?) -> Void) {
        let key = NSNumber(value: recordID)
        if let cached = Self.screenImageCache.object(forKey: key) {
            completion(cached)
            return
        }
        
        let screenSize = UIScreen.main.bounds.size
        let scale = currentDisplayScale
        
        DispatchQueue.global(qos: .userInteractive).async {
            let bgContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
            let fetch = NSFetchRequest<Gallery>(entityName: "Gallery")
            fetch.predicate = NSPredicate(format: "id_number == %d", recordID)
            fetch.fetchLimit = 1
            
            var fullData: Data?
            var thumbData: Data?
            
            bgContext.performAndWait {
                if let record = (try? bgContext.fetch(fetch))?.first {
                    fullData = record.fullSize
                    thumbData = record.thumbnail
                    bgContext.refresh(record, mergeChanges: false)
                }
            }
            
            var renderedImage: UIImage?
            if let data = fullData {
                renderedImage = UIImage.downsampledImage(from: data, to: screenSize, scale: scale)
            } else if let tData = thumbData {
                renderedImage = UIImage(data: tData)
            }
            
            if let finalImage = renderedImage {
                Self.screenImageCache.setObject(finalImage, forKey: key)
            }
            
            DispatchQueue.main.async {
                completion(renderedImage)
            }
        }
    }
    
    private func loadActiveImage(animated: Bool = true) {
        let resolvedID = resolveCurrentCardID()
        let targetIndex = self.index
        
        fetchDownsampledImage(for: resolvedID) { [weak self] finalImage in
            guard let self = self, let image = finalImage else { return }
            guard self.index == targetIndex || targetIndex == -1 else { return }
            
            if animated && self.imageView.image != nil {
                UIView.transition(with: self.imageView, duration: 0.15, options: .transitionCrossDissolve) {
                    self.imageView.image = image
                }
            } else {
                self.imageView.image = image
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if index != -1 {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        } else {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    deinit {
        imageView?.image = nil
        companionImageView.image = nil
        liquidGlassTooltipView?.removeFromSuperview()
    }

    // MARK: - Dual-View Interactive Pan Navigation
    
    private func setupInteractivePanGesture() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        imageView.addGestureRecognizer(pan)
    }
    
    @objc private func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
        guard !isAnimatingTransition else { return }
        let translation = recognizer.translation(in: view)
        let velocity = recognizer.velocity(in: view)
        let screenWidth = view.bounds.width
        let spacing: CGFloat = 24.0
        
        let hasPrevious = (index > 0)
        let hasNext = (index < galleryRecords.count - 1)
        
        switch recognizer.state {
        case .began:
            companionIndex = nil
            companionImageView.isHidden = true
            
        case .changed:
            var currentX = translation.x
            
            if (currentX > 0 && !hasPrevious) || (currentX < 0 && !hasNext) {
                currentX *= 0.25
                imageView.transform = CGAffineTransform(translationX: currentX, y: 0)
                companionImageView.isHidden = true
                return
            }
            
            let targetAdjacentIndex: Int?
            let companionBaseOffset: CGFloat
            
            if currentX < 0 && hasNext {
                targetAdjacentIndex = index + 1
                companionBaseOffset = screenWidth + spacing
            } else if currentX > 0 && hasPrevious {
                targetAdjacentIndex = index - 1
                companionBaseOffset = -(screenWidth + spacing)
            } else {
                targetAdjacentIndex = nil
                companionBaseOffset = 0
            }
            
            if let targetIdx = targetAdjacentIndex {
                if companionIndex != targetIdx {
                    companionIndex = targetIdx
                    loadCompanionImage(for: targetIdx)
                }
                companionImageView.isHidden = false
                companionImageView.transform = CGAffineTransform(translationX: companionBaseOffset + currentX, y: 0)
            } else {
                companionImageView.isHidden = true
            }
            
            imageView.transform = CGAffineTransform(translationX: currentX, y: 0)
            
        case .ended, .cancelled:
            let deltaX = translation.x
            let shouldNavigateForward = (deltaX < -screenWidth * 0.25 || velocity.x < -600) && hasNext
            let shouldNavigateBackward = (deltaX > screenWidth * 0.25 || velocity.x > 600) && hasPrevious
            
            if shouldNavigateForward, let companionIdx = companionIndex {
                finishTransition(to: companionIdx, movingForward: true, spacing: spacing)
            } else if shouldNavigateBackward, let companionIdx = companionIndex {
                finishTransition(to: companionIdx, movingForward: false, spacing: spacing)
            } else {
                if (deltaX > 0 && !hasPrevious) || (deltaX < 0 && !hasNext) {
                    flashErrorBackground()
                }
                cancelTransition(spacing: spacing)
            }
            
        default:
            break
        }
    }
    
    private func loadCompanionImage(for targetIndex: Int) {
        guard galleryRecords.indices.contains(targetIndex) else { return }
        let targetID = Int(galleryRecords[targetIndex].id)
        
        fetchDownsampledImage(for: targetID) { [weak self] image in
            guard let self = self, self.companionIndex == targetIndex else { return }
            self.companionImageView.image = image
        }
    }
    
    private func finishTransition(to targetIndex: Int, movingForward: Bool, spacing: CGFloat) {
        isAnimatingTransition = true
        let screenWidth = view.bounds.width
        let primaryTargetX: CGFloat = movingForward ? -(screenWidth + spacing) : (screenWidth + spacing)
        
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 0.9,
            initialSpringVelocity: 0.5,
            options: [.curveEaseOut]
        ) {
            self.imageView.transform = CGAffineTransform(translationX: primaryTargetX, y: 0)
            self.companionImageView.transform = .identity
        } completion: { [weak self] _ in
            guard let self = self else { return }
            
            self.imageView.image = self.companionImageView.image
            self.imageView.transform = .identity
            
            self.companionImageView.image = nil
            self.companionImageView.transform = .identity
            self.companionImageView.isHidden = true
            
            self.index = targetIndex
            let item = self.galleryRecords[targetIndex]
            self.updateNavigationTitle(with: item.name)
            
            self.isAnimatingTransition = false
            self.companionIndex = nil
            
            self.loadActiveImage(animated: false)
        }
    }
    
    private func cancelTransition(spacing: CGFloat) {
        isAnimatingTransition = true
        let screenWidth = view.bounds.width
        
        let companionResetX: CGFloat
        if let cIdx = companionIndex, cIdx > index {
            companionResetX = screenWidth + spacing
        } else {
            companionResetX = -(screenWidth + spacing)
        }
        
        UIView.animate(
            withDuration: 0.35,
            delay: 0,
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: 0.4,
            options: [.curveEaseOut]
        ) {
            self.imageView.transform = .identity
            self.companionImageView.transform = CGAffineTransform(translationX: companionResetX, y: 0)
        } completion: { [weak self] _ in
            guard let self = self else { return }
            self.companionImageView.image = nil
            self.companionImageView.isHidden = true
            self.companionIndex = nil
            self.isAnimatingTransition = false
        }
    }
    
    private func flashErrorBackground() {
        let originalColor = view.backgroundColor
        UIView.animate(withDuration: 0.15, animations: { [weak self] in
            self?.view.backgroundColor = UIColor.systemRed.withAlphaComponent(0.25)
        }) { [weak self] _ in
            UIView.animate(withDuration: 0.2) {
                self?.view.backgroundColor = originalColor
            }
        }
    }
}
