//
//  TimeCardInfoTableViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 8/6/21.
//

import Foundation
import UIKit
import CoreData
import ImageIO
import PhotosUI

extension UIImage {
    static func downsampledImage(from data: Data, to pointSize: CGSize, scale: CGFloat = 2.0) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions) else { return nil }
        
        let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ] as CFDictionary
        
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else { return nil }
        return UIImage(cgImage: downsampledImage)
    }
}

class TimeCardInfoTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
    
    @IBOutlet weak var addBarButton: UIBarButtonItem!
    @IBOutlet weak var infoBarButton: UIBarButtonItem!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    let userDefaults = UserDefaults.standard
    var cameraIsBeingUsed = false
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    private static let isCameraAvailable: Bool = UIImagePickerController.isSourceTypeAvailable(.camera)
    
    // Cached date formatter to eliminate heap churn on saves
    private static let cardDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy hh:mm a"
        return formatter
    }()
    
    private var currentCard: TimeCards?
    private var cachedTimeCardItems: [TimeCardInfo] = []
    private var currentDisplayImage: UIImage?
    
    private var headerConstraints: [NSLayoutConstraint] = []
    
    private let headerImageView: UIImageView = {
        let iv = UIImageView()
        iv.layer.cornerRadius = 16
        iv.layer.masksToBounds = true
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.isUserInteractionEnabled = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    var hasStoredImage: Bool {
        return currentDisplayImage != nil
    }
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldEditingChanged(_:)), for: .editingChanged)
        
        textField.clearButtonMode = .always
        textField.autocapitalizationType = .words
        textField.autocorrectionType = .no
        
        textField.layer.cornerRadius = 12
        textField.layer.masksToBounds = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        headerImageView.addGestureRecognizer(tap)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(imageLongPressed(_:)))
        longPress.minimumPressDuration = 0.45
        headerImageView.addGestureRecognizer(longPress)
        
        setupNavigationButtons()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let bannerHeight: CGFloat = 50.0
        let extraPadding: CGFloat = 8.0
        let bottomInset = bannerHeight + extraPadding
        
        tableView.contentInset.bottom = bottomInset
        tableView.verticalScrollIndicatorInsets.bottom = bottomInset
    }
    
    private func setupNavigationButtons() {
        if infoBarButton == nil {
            let button = UIBarButtonItem(image: UIImage(systemName: "info.circle"), style: .plain, target: self, action: #selector(infoButtonTapped(_:)))
            navigationItem.rightBarButtonItems = [addBarButton, button].compactMap { $0 }
            infoBarButton = button
        } else {
            infoBarButton.target = self
            infoBarButton.action = #selector(infoButtonTapped(_:))
        }
    }
    
    private func updateTableHeader(animated: Bool = false) {
        // Deactivate existing constraints to prevent constraint leakage
        NSLayoutConstraint.deactivate(headerConstraints)
        headerConstraints.removeAll()
        
        if hasStoredImage, let displayImage = currentDisplayImage {
            let tableWidth = tableView.bounds.width > 0 ? tableView.bounds.width : view.bounds.width
            let targetHeight: CGFloat = 220
            let isInserting = (tableView.tableHeaderView == nil) && animated
            
            let headerContainer = UIView(frame: CGRect(x: 0, y: 0, width: tableWidth, height: isInserting ? 0 : targetHeight))
            headerContainer.clipsToBounds = true
            
            headerImageView.image = displayImage
            headerImageView.alpha = isInserting ? 0.0 : 1.0
            headerImageView.contentMode = .scaleAspectFill
            headerImageView.layer.cornerRadius = 18
            headerImageView.layer.borderWidth = 1.0
            headerImageView.layer.borderColor = UIColor.separator.withAlphaComponent(0.35).cgColor
            
            headerContainer.addSubview(headerImageView)
            
            let imageRatio = displayImage.size.width / max(displayImage.size.height, 1)
            let maxCardWidth = min(tableWidth - 48, 300)
            
            let aspectConstraint = headerImageView.widthAnchor.constraint(equalTo: headerImageView.heightAnchor, multiplier: imageRatio)
            aspectConstraint.priority = .defaultHigh
            
            let newConstraints = [
                headerImageView.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: 10),
                headerImageView.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -10),
                headerImageView.centerXAnchor.constraint(equalTo: headerContainer.centerXAnchor),
                aspectConstraint,
                headerImageView.widthAnchor.constraint(lessThanOrEqualToConstant: maxCardWidth)
            ]
            
            headerConstraints = newConstraints
            NSLayoutConstraint.activate(newConstraints)
            
            tableView.tableHeaderView = headerContainer
            
            if isInserting {
                UIView.animate(withDuration: 0.35, delay: 0, options: [.curveEaseOut], animations: { [weak self] in
                    self?.headerImageView.alpha = 1.0
                    headerContainer.frame.size.height = targetHeight
                    self?.tableView.beginUpdates()
                    self?.tableView.tableHeaderView = headerContainer
                    self?.tableView.endUpdates()
                }, completion: nil)
            }
        } else if let currentHeader = tableView.tableHeaderView, animated {
            UIView.animate(withDuration: 0.32, delay: 0, options: [.curveEaseInOut], animations: { [weak self] in
                currentHeader.alpha = 0.0
                currentHeader.frame.size.height = 0
                self?.tableView.beginUpdates()
                self?.tableView.tableHeaderView = currentHeader
                self?.tableView.endUpdates()
            }, completion: { [weak self] _ in
                self?.tableView.tableHeaderView = nil
            })
        } else {
            tableView.tableHeaderView = nil
        }
    }

    private func removeStoredImage() {
        let targetID = userDefaults.integer(forKey: "id")
        
        self.currentDisplayImage = nil
        self.updateTableHeader(animated: true)
        
        for item in cachedTimeCardItems {
            item.image = nil
        }
        
        let galFetch = NSFetchRequest<Gallery>(entityName: "Gallery")
        galFetch.predicate = NSPredicate(format: "id_number == %d", targetID)
        if let galleryItems = try? context.fetch(galFetch) {
            for gal in galleryItems {
                gal.thumbnail = nil
                gal.date = nil
                gal.fullSize = nil
            }
        }
        
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        setupAddMenu()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let targetID = userDefaults.integer(forKey: "id")
        
        let cardFetch = NSFetchRequest<TimeCards>(entityName: "TimeCards")
        cardFetch.predicate = NSPredicate(format: "id_number == %d", targetID)
        cardFetch.fetchLimit = 1
        self.currentCard = (try? context.fetch(cardFetch))?.first
        
        let infoFetch = NSFetchRequest<TimeCardInfo>(entityName: "TimeCardInfo")
        infoFetch.predicate = NSPredicate(format: "id_number == %d", targetID)
        infoFetch.sortDescriptors = [NSSortDescriptor(key: #keyPath(TimeCardInfo.date), ascending: false)]
        self.cachedTimeCardItems = (try? context.fetch(infoFetch)) ?? []
        
        guard let card = self.currentCard else { return }
        
        let cardName = card.name?.trimmingCharacters(in: .whitespaces)
        if cardName == nil || cardName == "" || cardName == "Unknown" {
            textField.text = "Unknown"
            self.navigationItem.title = "Time Card Info"
        } else {
            textField.text = cardName
            self.navigationItem.title = cardName
        }
        
        let themeColor = currentAccentColor
        textField.backgroundColor = themeColor
        navigationController?.navigationBar.tintColor = themeColor
        
        textField.tintColor = UIColor.systemGray2
        view.backgroundColor = tableView.backgroundColor
        
        let galFetch = NSFetchRequest<Gallery>(entityName: "Gallery")
        galFetch.predicate = NSPredicate(format: "id_number == %d", targetID)
        galFetch.fetchLimit = 1
        let galleryRecord = (try? context.fetch(galFetch))?.first
        
        if let thumbData = galleryRecord?.thumbnail, let thumbImage = UIImage(data: thumbData) {
            self.currentDisplayImage = thumbImage
        } else {
            self.currentDisplayImage = nil
        }
        
        self.updateTableHeader(animated: false)
        self.tableView.reloadData()
        
        let fullData = galleryRecord?.fullSize ?? cachedTimeCardItems.first(where: { $0.image != nil })?.image
        if let imgData = fullData {
            let cardTargetSize = CGSize(width: 320, height: 220)
            let scale = self.currentDisplayScale
            
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                guard let self = self else { return }
                let crispCardImage = UIImage.downsampledImage(from: imgData, to: cardTargetSize, scale: scale) ?? UIImage(data: imgData)
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    if self.userDefaults.integer(forKey: "id") == targetID {
                        self.currentDisplayImage = crispCardImage
                        self.headerImageView.image = crispCardImage
                    }
                }
            }
        }
        
        setupAddMenu()
    }
    
    @IBAction func infoButtonTapped(_ sender: Any) {
        guard let card = self.currentCard else { return }
        
        let total = round(card.total * 100.0) / 100.0
        let datePrefix = (card.numberBeingExported == 1) ? "Day Of" : "Week Of"
        let dateValue = card.week ?? "Unknown"
        let entryName = (card.name == nil || card.name?.trimmingCharacters(in: .whitespaces) == "" || card.name == "Unknown") ? "Time Card Info" : card.name!
        
        let modalVC = UIViewController()
        modalVC.modalPresentationStyle = .overFullScreen
        modalVC.modalTransitionStyle = .crossDissolve
        modalVC.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        let dismissButton = UIButton(frame: modalVC.view.bounds)
        dismissButton.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        dismissButton.addTarget(self, action: #selector(dismissLiquidGlassModal), for: .touchUpInside)
        modalVC.view.addSubview(dismissButton)
        
        // systemMaterial adapts cleanly across Light and Dark themes
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let bottomSheetContainer = UIVisualEffectView(effect: blurEffect)
        bottomSheetContainer.layer.cornerRadius = 24
        bottomSheetContainer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        bottomSheetContainer.layer.masksToBounds = true
        bottomSheetContainer.layer.borderWidth = 1.0
        bottomSheetContainer.layer.borderColor = UIColor.separator.withAlphaComponent(0.2).cgColor
        bottomSheetContainer.translatesAutoresizingMaskIntoConstraints = false
        modalVC.view.addSubview(bottomSheetContainer)
        
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
        let iconImageView = UIImageView(image: UIImage(systemName: "info.circle.fill", withConfiguration: iconConfig))
        iconImageView.tintColor = currentAccentColor
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = entryName
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
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
        
        let dateRow = createInfoCard(icon: "calendar", title: datePrefix, value: dateValue)
        let hoursRow = createInfoCard(icon: "clock.badge.checkmark", title: "Total Hours", value: "\(total) hrs")
        
        stackView.addArrangedSubview(dateRow)
        stackView.addArrangedSubview(hoursRow)
        
        bottomSheetContainer.contentView.addSubview(closeButton)
        bottomSheetContainer.contentView.addSubview(iconImageView)
        bottomSheetContainer.contentView.addSubview(titleLabel)
        bottomSheetContainer.contentView.addSubview(divider)
        bottomSheetContainer.contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            bottomSheetContainer.leadingAnchor.constraint(equalTo: modalVC.view.leadingAnchor),
            bottomSheetContainer.trailingAnchor.constraint(equalTo: modalVC.view.trailingAnchor),
            bottomSheetContainer.bottomAnchor.constraint(equalTo: modalVC.view.bottomAnchor),
            
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
            
            stackView.bottomAnchor.constraint(equalTo: modalVC.view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
        
        present(modalVC, animated: true)
    }

    @objc private func dismissLiquidGlassModal() {
        dismiss(animated: true)
    }
    
    func createAddMenu() -> UIMenu {
        let hasImage = hasStoredImage
        var actions: [UIMenuElement] = []
        
        if hasImage {
            let galleryAction = UIAction(title: "Go To Gallery", image: UIImage(systemName: "photo.stack")) { [weak self] _ in
                self?.performSegue(withIdentifier: "gallery", sender: self)
            }
            
            var chooseActions: [UIAction] = []
            if Self.isCameraAvailable {
                chooseActions.append(UIAction(title: "Take Photo", image: UIImage(systemName: "camera")) { [weak self] _ in
                    DispatchQueue.main.async {
                        self?.presentCameraPicker()
                    }
                })
            }
            chooseActions.append(UIAction(title: "Choose Photo", image: UIImage(systemName: "photo.on.rectangle")) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.presentModernPhotoPicker()
                }
            })
            
            let chooseNewMenu = UIMenu(title: "Choose New Image", image: UIImage(systemName: "arrow.triangle.2.circlepath"), children: chooseActions)
            
            let removeAction = UIAction(title: "Remove Image", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                self?.confirmRemoveImage()
            }
            
            actions = [galleryAction, chooseNewMenu, removeAction]
        } else {
            if Self.isCameraAvailable {
                actions.append(UIAction(title: "Take Photo", image: UIImage(systemName: "camera")) { [weak self] _ in
                    DispatchQueue.main.async {
                        self?.presentCameraPicker()
                    }
                })
            }
            
            actions.append(UIAction(title: "Choose Photo", image: UIImage(systemName: "photo.on.rectangle")) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.presentModernPhotoPicker()
                }
            })
        }
        
        return UIMenu(title: hasImage ? "Image Options" : "Add Image", children: actions)
    }
    
    func setupAddMenu() {
        let menu = createAddMenu()
        addBarButton?.menu = menu
        addBarButton?.target = nil
        addBarButton?.action = nil
    }
    
    private func presentModernPhotoPicker() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        
        present(picker, animated: true)
    }
    
    private func presentCameraPicker() {
        guard Self.isCameraAvailable else { return }
        self.cameraIsBeingUsed = true
        
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        
        present(picker, animated: true)
    }
    
    // MARK: - PHPickerViewControllerDelegate
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
        
        provider.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in
            guard let self = self,
                  let pickedImage = image as? UIImage,
                  let jpegData = pickedImage.jpegData(compressionQuality: 0.85) else { return }
            
            DispatchQueue.main.async { [weak self] in
                self?.saveAndApplyImage(pickedImage: pickedImage, jpegData: jpegData)
            }
        }
    }
    
    // MARK: - UIImagePickerControllerDelegate (Camera)
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
        cameraIsBeingUsed = false
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        self.dismiss(animated: true, completion: nil)
        guard let pickedImage = info[.originalImage] as? UIImage,
              let jpegData = pickedImage.jpegData(compressionQuality: 0.85) else { return }
        
        saveAndApplyImage(pickedImage: pickedImage, jpegData: jpegData)
        
        if cameraIsBeingUsed && userDefaults.integer(forKey: "saveImages") == 0 {
            UIImageWriteToSavedPhotosAlbum(pickedImage, nil, nil, nil)
        }
        cameraIsBeingUsed = false
    }
    
    private func saveAndApplyImage(pickedImage: UIImage, jpegData: Data) {
        let thumbSize = CGSize(width: 156, height: 156)
        let thumbData = UIImage.downsampledImage(from: jpegData, to: thumbSize, scale: currentDisplayScale)?.jpegData(compressionQuality: 0.8) ?? jpegData
        
        self.currentDisplayImage = pickedImage
        self.updateTableHeader(animated: true)
        
        let targetID = userDefaults.integer(forKey: "id")
        if let first = cachedTimeCardItems.first {
            first.image = jpegData
        }
        
        let dateFormatted = Self.cardDateFormatter.string(from: Date())
        
        let trimmedText = textField.text?.trimmingCharacters(in: .whitespaces)
        let cardTitle = (trimmedText?.isEmpty ?? true) ? (currentCard?.name ?? "Unknown") : trimmedText
        
        let galFetch = NSFetchRequest<Gallery>(entityName: "Gallery")
        galFetch.predicate = NSPredicate(format: "id_number == %d", targetID)
        galFetch.fetchLimit = 1
        
        if let galleryRecord = (try? context.fetch(galFetch))?.first {
            galleryRecord.thumbnail = thumbData
            galleryRecord.fullSize = jpegData
            galleryRecord.date = dateFormatted
            galleryRecord.name = cardTitle
        } else {
            let galleryContext = Gallery(context: self.context)
            galleryContext.id_number = Int32(targetID)
            galleryContext.thumbnail = thumbData
            galleryContext.fullSize = jpegData
            galleryContext.date = dateFormatted
            galleryContext.name = cardTitle
        }
        
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        setupAddMenu()
    }
    
    private func confirmRemoveImage() {
        let alert = UIAlertController(title: "Remove Image", message: "Are you sure you want to remove this image?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive, handler: { [weak self] _ in
            self?.removeStoredImage()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @objc func imageTapped() {
        guard hasStoredImage else { return }
        performSegue(withIdentifier: "viewImage", sender: nil)
    }
    
    @objc func imageLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, hasStoredImage else { return }
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        let alert = UIAlertController(title: "Image Options", message: "Choose an action for this entry's photo", preferredStyle: .actionSheet)
        if let popover = alert.popoverPresentationController {
            popover.sourceView = headerImageView
            popover.sourceRect = headerImageView.bounds
        }
        
        alert.addAction(UIAlertAction(title: "Go To Gallery", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            self.performSegue(withIdentifier: "gallery", sender: self)
        }))
        
        alert.addAction(UIAlertAction(title: "Choose New Image", style: .default, handler: { [weak self] _ in
            self?.presentImageSourceSheet()
        }))
        
        alert.addAction(UIAlertAction(title: "Remove Image", style: .destructive, handler: { [weak self] _ in
            self?.confirmRemoveImage()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func presentImageSourceSheet() {
        let sheet = UIAlertController(title: "Select Photo", message: "Choose where to source the image", preferredStyle: .actionSheet)
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        if Self.isCameraAvailable {
            sheet.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { [weak self] _ in
                DispatchQueue.main.async {
                    self?.presentCameraPicker()
                }
            }))
        }
        
        sheet.addAction(UIAlertAction(title: "Choose From Library", style: .default, handler: { [weak self] _ in
            DispatchQueue.main.async {
                self?.presentModernPhotoPicker()
            }
        }))
        
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(sheet, animated: true, completion: nil)
    }
    
    @IBAction func addButtonClicked(_ sender: Any) {
        // Handled by addBarButton.menu
    }
    
    // MARK: - UITableView DataSource & Delegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cachedTimeCardItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let hourItems = cachedTimeCardItems[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "timeCardCell", for: indexPath) as! TimeCardInfoTableViewCell
        
        let inTime = hourItems.intime
        let outTime = hourItems.outtime
        let totalHours = hourItems.total_hours
        let date = hourItems.date
        
        cell.inTimeLabel.text = "In Time: \(inTime ?? "Unknown")"
        cell.outTimeLabel.text = "Out Time: \(outTime ?? "Unknown")"
        cell.totalHoursLabel.text = "Total Hours: \(totalHours ?? "Unknown")"
        cell.dateLabel.text = "Date: \(date ?? "Unknown")"
        
        return cell
    }
    
    @objc private func textFieldEditingChanged(_ sender: UITextField) {
        let trimmed = sender.text?.trimmingCharacters(in: .whitespaces) ?? ""
        self.navigationItem.title = trimmed.isEmpty ? "Time Card Info" : trimmed
    }
    
    @IBAction func textFieldClose(_ sender: UITextField) {
        persistTitleUpdate(with: sender.text)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        persistTitleUpdate(with: textField.text)
    }
    
    private func persistTitleUpdate(with text: String?) {
        let trimmedText = text?.trimmingCharacters(in: .whitespaces)
        let finalName: String? = (trimmedText?.isEmpty ?? true) ? nil : trimmedText
        
        self.navigationItem.title = (finalName == nil || finalName == "Unknown") ? "Time Card Info" : finalName
        
        currentCard?.name = finalName
        for info in cachedTimeCardItems {
            info.name = finalName
        }
        
        let targetID = userDefaults.integer(forKey: "id")
        let galFetch = NSFetchRequest<Gallery>(entityName: "Gallery")
        galFetch.predicate = NSPredicate(format: "id_number == %d", targetID)
        if let galItems = try? context.fetch(galFetch) {
            for gal in galItems {
                gal.name = finalName
            }
        }
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string).trimmingCharacters(in: .whitespaces)
        self.navigationItem.title = updatedText.isEmpty ? "Time Card Info" : updatedText
        return range.location < 16
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "viewImage" {
            let dvc = segue.destination as! ImageViewController
            let targetID = userDefaults.integer(forKey: "id")
            
            dvc.placeholderThumbnail = self.currentDisplayImage
            dvc.targetCardID = targetID
            dvc.name = (textField.text?.isEmpty ?? true) ? "Time Card Image" : textField.text
            dvc.index = -1
        }
    }
}
