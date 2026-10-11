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
import GoogleMobileAds

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
    
    lazy var bannerView: BannerView! = BannerView(adSize: AdSizeBanner)
    
    @IBOutlet weak var addBarButton: UIBarButtonItem!
    @IBOutlet weak var infoBarButton: UIBarButtonItem!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    var image: UIImage?
    let userDefaults = UserDefaults.standard
    var cameraIsBeingUsed = false
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    private static let isCameraAvailable: Bool = UIImagePickerController.isSourceTypeAvailable(.camera)
    
    private var currentCard: TimeCards?
    private var cachedTimeCardItems: [TimeCardInfo] = []
    private var currentDisplayImage: UIImage?
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        textField.delegate = self
        
        addBannerViewToView(bannerView)
        bannerView.adUnitID = "ca-app-pub-4546055219731501/2396708566"
        bannerView.rootViewController = self
        
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
        let adHeight: CGFloat = bannerView.frame.height > 0 ? bannerView.frame.height : 60
        tableView.contentInset.bottom = adHeight + 16
        tableView.verticalScrollIndicatorInsets.bottom = adHeight + 16
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
    
    private func updateTableHeader() {
        if hasStoredImage, let displayImage = currentDisplayImage {
            let tableWidth = tableView.bounds.width > 0 ? tableView.bounds.width : view.bounds.width
            let containerHeight: CGFloat = 220
            let headerContainer = UIView(frame: CGRect(x: 0, y: 0, width: tableWidth, height: containerHeight))
            
            headerImageView.image = displayImage
            headerImageView.contentMode = .scaleAspectFill
            headerImageView.layer.cornerRadius = 18
            headerImageView.layer.borderWidth = 1.0
            headerImageView.layer.borderColor = UIColor.separator.withAlphaComponent(0.35).cgColor
            
            headerContainer.addSubview(headerImageView)
            
            let imageRatio = displayImage.size.width / max(displayImage.size.height, 1)
            let maxCardWidth = min(tableWidth - 48, 300)
            
            let aspectConstraint = headerImageView.widthAnchor.constraint(equalTo: headerImageView.heightAnchor, multiplier: imageRatio)
            aspectConstraint.priority = .defaultHigh
            
            NSLayoutConstraint.activate([
                headerImageView.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: 10),
                headerImageView.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -10),
                headerImageView.centerXAnchor.constraint(equalTo: headerContainer.centerXAnchor),
                aspectConstraint,
                headerImageView.widthAnchor.constraint(lessThanOrEqualToConstant: maxCardWidth)
            ])
            
            tableView.tableHeaderView = headerContainer
        } else {
            tableView.tableHeaderView = nil
        }
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
        
        self.updateTableHeader()
        self.tableView.reloadData()
        
        let fullData = galleryRecord?.fullSize ?? cachedTimeCardItems.first(where: { $0.image != nil })?.image
        if let imgData = fullData {
            let cardTargetSize = CGSize(width: 320, height: 220)
            let scale = self.currentDisplayScale
            
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                guard let self = self else { return }
                let crispCardImage = UIImage.downsampledImage(from: imgData, to: cardTargetSize, scale: scale) ?? UIImage(data: imgData)
                
                DispatchQueue.main.async {
                    if self.userDefaults.integer(forKey: "id") == targetID {
                        self.currentDisplayImage = crispCardImage
                        self.headerImageView.image = crispCardImage
                    }
                }
            }
        }
        
        setupAddMenu()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        bannerView.load(Request())
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
        modalVC.view.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        
        let dismissButton = UIButton(frame: modalVC.view.bounds)
        dismissButton.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        dismissButton.addTarget(self, action: #selector(dismissLiquidGlassModal), for: .touchUpInside)
        modalVC.view.addSubview(dismissButton)
        
        let blurEffect = UIBlurEffect(style: .systemThinMaterial)
        let glassContainer = UIVisualEffectView(effect: blurEffect)
        glassContainer.layer.cornerRadius = 24
        glassContainer.layer.masksToBounds = true
        glassContainer.layer.borderWidth = 1.0
        glassContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.25).cgColor
        glassContainer.translatesAutoresizingMaskIntoConstraints = false
        modalVC.view.addSubview(glassContainer)
        
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 32, weight: .semibold)
        let iconImageView = UIImageView(image: UIImage(systemName: "info.circle.fill", withConfiguration: iconConfig))
        iconImageView.tintColor = currentAccentColor
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = entryName
        titleLabel.font = UIFont.systemFont(ofSize: 19, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let divider = UIView()
        divider.backgroundColor = UIColor.separator.withAlphaComponent(0.35)
        divider.translatesAutoresizingMaskIntoConstraints = false
        
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
        
        let dateRow = createInfoCard(icon: "calendar", title: datePrefix, value: dateValue)
        let hoursRow = createInfoCard(icon: "clock.badge.checkmark", title: "Total Hours", value: "\(total) hrs")
        
        stackView.addArrangedSubview(dateRow)
        stackView.addArrangedSubview(hoursRow)
        
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
            
            DispatchQueue.main.async {
                self.saveAndApplyImage(pickedImage: pickedImage, jpegData: jpegData)
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
        self.updateTableHeader()
        self.tableView.reloadData()
        
        let targetID = userDefaults.integer(forKey: "id")
        if let first = cachedTimeCardItems.first {
            first.image = jpegData
        }
        
        let today = Date()
        let formatter1 = DateFormatter()
        formatter1.dateFormat = "MM/dd/yyyy hh:mm a"
        let dateFormatted = formatter1.string(from: today)
        
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
    
    private func removeStoredImage() {
        let targetID = userDefaults.integer(forKey: "id")
        
        self.currentDisplayImage = nil
        self.updateTableHeader()
        self.tableView.reloadData()
        
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
    
    @IBAction func textFieldClose(_ sender: UITextField) {
        let trimmedText = sender.text?.trimmingCharacters(in: .whitespaces)
        let finalName: String? = (trimmedText?.isEmpty ?? true) ? nil : trimmedText
        
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
        let finalName: String? = updatedText.isEmpty ? nil : updatedText
        
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
        
        return range.location < 16
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "viewImage" {
            let dvc = segue.destination as! ImageViewController
            let targetID = userDefaults.integer(forKey: "id")
            
            dvc.placeholderThumbnail = self.currentDisplayImage
            
            let galFetch = NSFetchRequest<Gallery>(entityName: "Gallery")
            galFetch.predicate = NSPredicate(format: "id_number == %d AND fullSize != nil", targetID)
            galFetch.fetchLimit = 1
            
            if let fullData = (try? context.fetch(galFetch))?.first?.fullSize {
                dvc.fullImageData = fullData
            } else if let cachedData = cachedTimeCardItems.first(where: { $0.image != nil })?.image {
                dvc.fullImageData = cachedData
            }
            
            dvc.name = (textField.text?.isEmpty ?? true) ? "Time Card Image" : textField.text
            dvc.index = -1
        }
    }
}
