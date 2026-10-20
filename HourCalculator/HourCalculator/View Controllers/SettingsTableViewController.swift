//
//  SettingsViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 6/24/21.
//

import UIKit
import CoreData
import UserNotifications
import StoreKit

class SettingsTableViewController: UITableViewController {
    
    @IBOutlet weak var patchNotesCell: SettingsTableViewCell!
    let userDefaults = UserDefaults.standard
    
    @IBOutlet var hourSwitch: UISwitch!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    // In-App Purchase Product Identifiers (configure these in App Store Connect)
    private let donationProductIDs: [Int: String] = [
        1: "com.cory.HourCalculator.tip1",
        5: "com.cory.HourCalculator.tip5",
        20: "com.cory.HourCalculator.tip20",
        50: "com.cory.HourCalculator.tip50",
        100: "com.cory.HourCalculator.tip100"
    ]
    
    private var selectedDonationAmount: Int = 5
    
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
    
    private var hasStoredImages: Bool {
        let galFetch = NSFetchRequest<Gallery>(entityName: "Gallery")
        galFetch.includesPropertyValues = false
        galFetch.fetchLimit = 1
        let galleryCount = (try? context.count(for: galFetch)) ?? 0
        if galleryCount > 0 { return true }
        
        let infoFetch = NSFetchRequest<TimeCardInfo>(entityName: "TimeCardInfo")
        infoFetch.predicate = NSPredicate(format: "image != nil")
        infoFetch.includesPropertyValues = false
        infoFetch.fetchLimit = 1
        let infoImageCount = (try? context.count(for: infoFetch)) ?? 0
        return infoImageCount > 0
    }
    
    private var hasStoredHistory: Bool {
        let fetch = NSFetchRequest<Hours>(entityName: "Hours")
        fetch.includesPropertyValues = false
        fetch.fetchLimit = 1
        let count = (try? context.count(for: fetch)) ?? 0
        return count > 0
    }
    
    private var hasStoredTimeCards: Bool {
        let fetch = NSFetchRequest<TimeCards>(entityName: "TimeCards")
        fetch.includesPropertyValues = false
        fetch.fetchLimit = 1
        let count = (try? context.count(for: fetch)) ?? 0
        return count > 0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBarController?.tabBar.tintAdjustmentMode = .normal
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        hourSwitch?.onTintColor = currentAccentColor
        updatePatchNotesBadgeUI()
    }
    
    private func updatePatchNotesBadgeUI() {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let hasViewedCurrentVersion = userDefaults.string(forKey: "appVersion") == appVersion && appVersion != nil
        
        if !hasViewedCurrentVersion {
            let size: CGFloat = 22
            let width = max(size, 0.7 * size * 1)
            let badge = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: size))
            badge.text = "1"
            badge.layer.cornerRadius = size / 2
            badge.layer.masksToBounds = true
            badge.textAlignment = .center
            badge.textColor = UIColor.white
            badge.backgroundColor = UIColor.systemRed
            patchNotesCell?.accessoryView = badge
            
            navigationController?.tabBarItem.badgeValue = "1"
            tabBarController?.tabBar.items?.last?.badgeValue = "1"
        } else {
            patchNotesCell?.accessoryView = nil
            navigationController?.tabBarItem.badgeValue = nil
            tabBarController?.tabBar.items?.last?.badgeValue = nil
        }
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Section 0, Position 0: Donate / Tip Jar
        if indexPath.section == 0 && indexPath.row == 0 {
            showDonationBottomSheet()
            return
        }
        
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        let cellText = (cell.textLabel?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        if cellText.contains("rate") || cellText.contains("review") || cellText.contains("app store") || (indexPath.section == 6 && indexPath.row == 0) {
            if let url = URL(string: "https://apps.apple.com/us/app/hour-calculator-decimal/id1574062704") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            return
        }
        
        if indexPath.section == 7 && indexPath.row == 0 {
            showClearAppDataBottomSheet()
            return
        }
    }
    
    // MARK: - Donation Bottom Sheet
    
    private func showDonationBottomSheet() {
        let modalVC = UIViewController()
        modalVC.modalPresentationStyle = .overFullScreen
        modalVC.modalTransitionStyle = .crossDissolve
        modalVC.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        let dismissButton = UIButton(frame: modalVC.view.bounds)
        dismissButton.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        dismissButton.addAction(UIAction { [weak modalVC] _ in
            modalVC?.dismiss(animated: true)
        }, for: .touchUpInside)
        modalVC.view.addSubview(dismissButton)
        
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
        let iconImageView = UIImageView(image: UIImage(systemName: "heart.fill", withConfiguration: iconConfig))
        iconImageView.tintColor = currentAccentColor
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = "Support the Developer"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Choose an amount to support ongoing development."
        subtitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let divider = UIView()
        divider.backgroundColor = UIColor.separator.withAlphaComponent(0.35)
        divider.translatesAutoresizingMaskIntoConstraints = false
        
        let amountsRow1 = [1, 5, 20]
        let amountsRow2 = [50, 100]
        var optionButtons: [Int: UIButton] = [:]
        
        let mainTierStack = UIStackView()
        mainTierStack.axis = .vertical
        mainTierStack.spacing = 10
        mainTierStack.alignment = .fill
        mainTierStack.distribution = .fillEqually
        mainTierStack.translatesAutoresizingMaskIntoConstraints = false
        
        let row1Stack = UIStackView()
        row1Stack.axis = .horizontal
        row1Stack.spacing = 10
        row1Stack.distribution = .fillEqually
        
        let row2Stack = UIStackView()
        row2Stack.axis = .horizontal
        row2Stack.spacing = 10
        row2Stack.distribution = .fillEqually
        
        let donateActionButton = UIButton(type: .system)
        
        func updateSelectionUI() {
            for (amt, btn) in optionButtons {
                let isSelected = (amt == self.selectedDonationAmount)
                btn.backgroundColor = isSelected ? self.currentAccentColor : UIColor.secondarySystemFill
                btn.layer.borderColor = isSelected ? self.currentAccentColor.cgColor : UIColor.separator.withAlphaComponent(0.2).cgColor
                btn.layer.borderWidth = isSelected ? 2.0 : 1.0
                
                var config = btn.configuration ?? UIButton.Configuration.filled()
                config.baseForegroundColor = isSelected ? .white : .label
                btn.configuration = config
            }
            
            var actionConfig = donateActionButton.configuration ?? UIButton.Configuration.filled()
            actionConfig.title = "Leave a tip of $\(self.selectedDonationAmount)"
            donateActionButton.configuration = actionConfig
        }
        
        func createTierButton(amount: Int) -> UIButton {
            let button = UIButton(type: .system)
            var config = UIButton.Configuration.filled()
            config.title = "$\(amount)"
            config.baseBackgroundColor = .clear
            config.cornerStyle = .medium
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = UIFont.systemFont(ofSize: 16, weight: .bold)
                return outgoing
            }
            button.configuration = config
            button.layer.cornerRadius = 14
            button.layer.masksToBounds = true
            button.heightAnchor.constraint(equalToConstant: 44).isActive = true
            button.addAction(UIAction { [weak self] _ in
                self?.selectedDonationAmount = amount
                updateSelectionUI()
            }, for: .touchUpInside)
            return button
        }
        
        for amt in amountsRow1 {
            let btn = createTierButton(amount: amt)
            optionButtons[amt] = btn
            row1Stack.addArrangedSubview(btn)
        }
        
        for amt in amountsRow2 {
            let btn = createTierButton(amount: amt)
            optionButtons[amt] = btn
            row2Stack.addArrangedSubview(btn)
        }
        
        mainTierStack.addArrangedSubview(row1Stack)
        mainTierStack.addArrangedSubview(row2Stack)
        
        var actionConfig = UIButton.Configuration.filled()
        actionConfig.title = "Leave a tip of $\(selectedDonationAmount)"
        actionConfig.baseBackgroundColor = currentAccentColor
        actionConfig.baseForegroundColor = .white
        actionConfig.cornerStyle = .capsule
        actionConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 17, weight: .bold)
            return outgoing
        }
        donateActionButton.configuration = actionConfig
        donateActionButton.addAction(UIAction { [weak self, weak modalVC] _ in
            guard let self = self else { return }
            self.executeDonationPurchase(amount: self.selectedDonationAmount, presentingVC: modalVC)
        }, for: .touchUpInside)
        donateActionButton.translatesAutoresizingMaskIntoConstraints = false
        
        updateSelectionUI()
        
        bottomSheetContainer.contentView.addSubview(closeButton)
        bottomSheetContainer.contentView.addSubview(iconImageView)
        bottomSheetContainer.contentView.addSubview(titleLabel)
        bottomSheetContainer.contentView.addSubview(subtitleLabel)
        bottomSheetContainer.contentView.addSubview(divider)
        bottomSheetContainer.contentView.addSubview(mainTierStack)
        bottomSheetContainer.contentView.addSubview(donateActionButton)
        
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
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: bottomSheetContainer.contentView.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: bottomSheetContainer.contentView.trailingAnchor, constant: -24),
            
            divider.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 14),
            divider.leadingAnchor.constraint(equalTo: bottomSheetContainer.contentView.leadingAnchor, constant: 20),
            divider.trailingAnchor.constraint(equalTo: bottomSheetContainer.contentView.trailingAnchor, constant: -20),
            divider.heightAnchor.constraint(equalToConstant: 0.5),
            
            mainTierStack.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 16),
            mainTierStack.leadingAnchor.constraint(equalTo: bottomSheetContainer.contentView.leadingAnchor, constant: 20),
            mainTierStack.trailingAnchor.constraint(equalTo: bottomSheetContainer.contentView.trailingAnchor, constant: -20),
            
            donateActionButton.topAnchor.constraint(equalTo: mainTierStack.bottomAnchor, constant: 18),
            donateActionButton.leadingAnchor.constraint(equalTo: bottomSheetContainer.contentView.leadingAnchor, constant: 20),
            donateActionButton.trailingAnchor.constraint(equalTo: bottomSheetContainer.contentView.trailingAnchor, constant: -20),
            donateActionButton.heightAnchor.constraint(equalToConstant: 48),
            
            donateActionButton.bottomAnchor.constraint(equalTo: modalVC.view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
        
        present(modalVC, animated: true)
    }
    
    // MARK: - StoreKit 2 Purchase Flow
    
    private func executeDonationPurchase(amount: Int, presentingVC: UIViewController?) {
        guard let productID = donationProductIDs[amount] else { return }
        
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            do {
                let products = try await Product.products(for: [productID])
                guard let product = products.first else {
                    let alert = UIAlertController(title: "Notice", message: "In-App Purchases are currently being configured in App Store Connect for \(productID).", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    presentingVC?.present(alert, animated: true)
                    return
                }
                
                let result = try await product.purchase()
                switch result {
                case .success(let verification):
                    switch verification {
                    case .verified(let transaction):
                        await transaction.finish()
                        presentingVC?.dismiss(animated: true) { [weak self] in
                            self?.showSuccessAlert(title: "Thank You! ❤️", message: "Your contribution of $\(amount) directly supports ongoing updates and improvements.")
                        }
                    case .unverified:
                        break
                    }
                case .userCancelled, .pending:
                    break
                @unknown default:
                    break
                }
            } catch {
                let alert = UIAlertController(title: "Purchase Error", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                presentingVC?.present(alert, animated: true)
            }
        }
    }
    
    // MARK: - Fully Expanded, Non-Draggable Clear App Data Bottom Sheet
    
    private enum ClearOptionKey: CaseIterable {
        case images
        case history
        case timeCards
        case preferences
        case everything
    }
    
    private func showClearAppDataBottomSheet() {
        let sheetVC = UIViewController()
        sheetVC.view.backgroundColor = .systemBackground
        sheetVC.modalPresentationStyle = .pageSheet
        sheetVC.isModalInPresentation = true // Disables interactive downward dragging
        
        if let sheet = sheetVC.sheetPresentationController {
            sheet.detents = [.large()] // Expanded all the way
            sheet.prefersGrabberVisible = false // Removes drag indicator handle
        }
        
        var selectedKeys = Set<ClearOptionKey>()
        var optionButtons: [ClearOptionKey: UIButton] = [:]
        var checkmarkViews: [ClearOptionKey: UIImageView] = [:]
        
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
        closeButton.addAction(UIAction { [weak sheetVC] _ in
            sheetVC?.dismiss(animated: true)
        }, for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 34, weight: .semibold)
        let iconImageView = UIImageView(image: UIImage(systemName: "trash.circle.fill", withConfiguration: iconConfig))
        iconImageView.tintColor = .systemRed
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = "Clear App Data"
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Select which records or preferences to erase. Deleted items cannot be recovered."
        subtitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let divider = UIView()
        divider.backgroundColor = UIColor.separator.withAlphaComponent(0.35)
        divider.translatesAutoresizingMaskIntoConstraints = false
        
        let optionsStack = UIStackView()
        optionsStack.axis = .vertical
        optionsStack.spacing = 10
        optionsStack.alignment = .fill
        optionsStack.distribution = .fillEqually
        optionsStack.translatesAutoresizingMaskIntoConstraints = false
        
        let clearDataButton = UIButton(type: .system)
        var clearDataConfig = UIButton.Configuration.filled()
        clearDataConfig.title = "Clear Data"
        clearDataConfig.baseBackgroundColor = .systemRed
        clearDataConfig.baseForegroundColor = .white
        clearDataConfig.cornerStyle = .capsule
        clearDataConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 16, weight: .bold)
            return outgoing
        }
        clearDataButton.configuration = clearDataConfig
        clearDataButton.translatesAutoresizingMaskIntoConstraints = false
        
        func syncButtonAppearance(for key: ClearOptionKey) {
            guard let button = optionButtons[key], let checkmark = checkmarkViews[key] else { return }
            let isSelected = selectedKeys.contains(key)
            
            var config = button.configuration ?? UIButton.Configuration.filled()
            config.baseBackgroundColor = isSelected
                ? UIColor.systemRed.withAlphaComponent(0.24)
                : UIColor.systemRed.withAlphaComponent(0.10)
            button.configuration = config
            
            button.layer.borderWidth = isSelected ? 2.0 : 1.0
            button.layer.borderColor = isSelected
                ? UIColor.systemRed.cgColor
                : UIColor.systemRed.withAlphaComponent(0.25).cgColor
            
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
            checkmark.image = UIImage(systemName: isSelected ? "checkmark.circle.fill" : "circle", withConfiguration: symbolConfig)
            checkmark.tintColor = isSelected ? .systemRed : .tertiaryLabel
        }
        
        func updateAllSelectionsUI() {
            UIView.performWithoutAnimation {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                
                for key in ClearOptionKey.allCases {
                    syncButtonAppearance(for: key)
                }
                
                let count = selectedKeys.count
                let hasSelection = count > 0
                clearDataButton.isEnabled = hasSelection
                clearDataButton.alpha = hasSelection ? 1.0 : 0.45
                
                if selectedKeys.contains(.everything) {
                    clearDataButton.configuration?.title = "Clear Everything"
                } else if count > 0 {
                    clearDataButton.configuration?.title = "Clear Selected (\(count))"
                } else {
                    clearDataButton.configuration?.title = "Clear Data"
                }
                
                CATransaction.commit()
                sheetVC.view.layoutIfNeeded()
            }
        }
        
        func handleOptionTapped(key: ClearOptionKey) {
            let feedback = UISelectionFeedbackGenerator()
            feedback.selectionChanged()
            
            let subcategoryKeys: Set<ClearOptionKey> = [.images, .history, .timeCards, .preferences]
            
            if key == .everything {
                if selectedKeys.contains(.everything) {
                    selectedKeys.removeAll()
                } else {
                    selectedKeys = Set(ClearOptionKey.allCases)
                }
            } else {
                if selectedKeys.contains(key) {
                    selectedKeys.remove(key)
                    selectedKeys.remove(.everything)
                } else {
                    selectedKeys.insert(key)
                    if subcategoryKeys.isSubset(of: selectedKeys) {
                        selectedKeys.insert(.everything)
                    }
                }
            }
            updateAllSelectionsUI()
        }
        
        func createSelectableOptionButton(
            key: ClearOptionKey,
            title: String,
            subtitle: String,
            iconName: String,
            isEnabled: Bool
        ) -> UIButton {
            let button = UIButton(type: .system)
            var config = UIButton.Configuration.filled()
            config.baseBackgroundColor = UIColor.systemRed.withAlphaComponent(0.10)
            config.baseForegroundColor = .systemRed
            config.cornerStyle = .medium
            config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 54, bottom: 10, trailing: 46)
            
            var titleAttr = AttributedString(title)
            titleAttr.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
            config.attributedTitle = titleAttr
            
            var subAttr = AttributedString(subtitle)
            subAttr.font = UIFont.systemFont(ofSize: 11, weight: .regular)
            subAttr.foregroundColor = UIColor.systemRed.withAlphaComponent(0.85)
            config.attributedSubtitle = subAttr
            
            button.configuration = config
            button.contentHorizontalAlignment = .leading
            button.layer.cornerRadius = 14
            button.layer.masksToBounds = true
            button.isEnabled = isEnabled
            button.alpha = isEnabled ? 1.0 : 0.45
            
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
            let iconImageView = UIImageView(image: UIImage(systemName: iconName, withConfiguration: symbolConfig))
            iconImageView.tintColor = .systemRed
            iconImageView.contentMode = .scaleAspectFit
            iconImageView.isUserInteractionEnabled = false
            iconImageView.translatesAutoresizingMaskIntoConstraints = false
            button.addSubview(iconImageView)
            
            let checkSymbolConfig = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
            let checkmarkImageView = UIImageView(image: UIImage(systemName: "circle", withConfiguration: checkSymbolConfig))
            checkmarkImageView.tintColor = .tertiaryLabel
            checkmarkImageView.contentMode = .scaleAspectFit
            checkmarkImageView.isUserInteractionEnabled = false
            checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false
            button.addSubview(checkmarkImageView)
            
            NSLayoutConstraint.activate([
                iconImageView.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
                iconImageView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
                iconImageView.widthAnchor.constraint(equalToConstant: 26),
                iconImageView.heightAnchor.constraint(equalToConstant: 26),
                
                checkmarkImageView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16),
                checkmarkImageView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
                checkmarkImageView.widthAnchor.constraint(equalToConstant: 22),
                checkmarkImageView.heightAnchor.constraint(equalToConstant: 22)
            ])
            
            button.addAction(UIAction { _ in
                handleOptionTapped(key: key)
            }, for: .touchUpInside)
            
            optionButtons[key] = button
            checkmarkViews[key] = checkmarkImageView
            return button
        }
        
        let clearImagesButton = createSelectableOptionButton(
            key: .images,
            title: "Clear Images",
            subtitle: "Delete all saved time card photos and gallery thumbnails",
            iconName: "photo.stack",
            isEnabled: hasStoredImages
        )
        
        let clearHistoryButton = createSelectableOptionButton(
            key: .history,
            title: "Clear History",
            subtitle: "Delete all calculated decimal hours and shift logs",
            iconName: "clock.arrow.circlepath",
            isEnabled: hasStoredHistory
        )
        
        let clearTimeCardsButton = createSelectableOptionButton(
            key: .timeCards,
            title: "Clear Time Cards",
            subtitle: "Delete all saved time cards and weekly punch entries",
            iconName: "calendar.badge.clock",
            isEnabled: hasStoredTimeCards
        )
        
        let clearPreferencesButton = createSelectableOptionButton(
            key: .preferences,
            title: "Clear User Preferences",
            subtitle: "Reset themes, accent colors, and toggles without deleting logs",
            iconName: "paintpalette",
            isEnabled: true
        )
        
        let clearEverythingButton = createSelectableOptionButton(
            key: .everything,
            title: "Clear Everything",
            subtitle: "Factory reset all hours, cards, photos, and preferences",
            iconName: "exclamationmark.triangle.fill",
            isEnabled: true
        )
        
        optionsStack.addArrangedSubview(clearImagesButton)
        optionsStack.addArrangedSubview(clearHistoryButton)
        optionsStack.addArrangedSubview(clearTimeCardsButton)
        optionsStack.addArrangedSubview(clearPreferencesButton)
        optionsStack.addArrangedSubview(clearEverythingButton)
        
        clearDataButton.addAction(UIAction { [weak self, weak sheetVC] _ in
            guard let self = self, !selectedKeys.isEmpty else { return }
            
            let targets = selectedKeys
            sheetVC?.dismiss(animated: true) { [weak self] in
                self?.confirmBatchExecution(for: targets)
            }
        }, for: .touchUpInside)
        
        updateAllSelectionsUI()
        
        sheetVC.view.addSubview(closeButton)
        sheetVC.view.addSubview(iconImageView)
        sheetVC.view.addSubview(titleLabel)
        sheetVC.view.addSubview(subtitleLabel)
        sheetVC.view.addSubview(divider)
        sheetVC.view.addSubview(optionsStack)
        sheetVC.view.addSubview(clearDataButton)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: sheetVC.view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: sheetVC.view.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),
            
            iconImageView.topAnchor.constraint(equalTo: sheetVC.view.safeAreaLayoutGuide.topAnchor, constant: 20),
            iconImageView.centerXAnchor.constraint(equalTo: sheetVC.view.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: sheetVC.view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: sheetVC.view.trailingAnchor, constant: -20),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: sheetVC.view.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: sheetVC.view.trailingAnchor, constant: -24),
            
            divider.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 14),
            divider.leadingAnchor.constraint(equalTo: sheetVC.view.leadingAnchor, constant: 20),
            divider.trailingAnchor.constraint(equalTo: sheetVC.view.trailingAnchor, constant: -20),
            divider.heightAnchor.constraint(equalToConstant: 0.5),
            
            optionsStack.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 16),
            optionsStack.leadingAnchor.constraint(equalTo: sheetVC.view.leadingAnchor, constant: 20),
            optionsStack.trailingAnchor.constraint(equalTo: sheetVC.view.trailingAnchor, constant: -20),
            
            clearDataButton.topAnchor.constraint(equalTo: optionsStack.bottomAnchor, constant: 16),
            clearDataButton.leadingAnchor.constraint(equalTo: sheetVC.view.leadingAnchor, constant: 20),
            clearDataButton.trailingAnchor.constraint(equalTo: sheetVC.view.trailingAnchor, constant: -20),
            clearDataButton.heightAnchor.constraint(equalToConstant: 48),
            clearDataButton.bottomAnchor.constraint(lessThanOrEqualTo: sheetVC.view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
        
        present(sheetVC, animated: true)
    }
    
    private func confirmBatchExecution(for selectedKeys: Set<ClearOptionKey>) {
        if selectedKeys.contains(.everything) {
            confirmSpecificDeletion(
                title: "Clear Everything?",
                message: "Are you sure you want to clear all app data? This will reset all hours, time cards, photos, and preferences."
            ) { [weak self] in
                self?.deleteData()
            }
            return
        }
        
        var selectedItemDescriptions: [String] = []
        if selectedKeys.contains(.images) { selectedItemDescriptions.append("images") }
        if selectedKeys.contains(.history) { selectedItemDescriptions.append("shift history") }
        if selectedKeys.contains(.timeCards) { selectedItemDescriptions.append("time cards") }
        if selectedKeys.contains(.preferences) { selectedItemDescriptions.append("user preferences") }
        
        let messageList = selectedItemDescriptions.joined(separator: ", ")
        let alert = UIAlertController(
            title: "Clear Selected Data?",
            message: "Are you sure you want to delete the selected item(s): \(messageList)? This action cannot be undone.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
            guard let self = self else { return }
            
            if selectedKeys.contains(.images) {
                self.executeBatchDelete(for: ["Gallery"])
                let fetchRequest = NSFetchRequest<TimeCardInfo>(entityName: "TimeCardInfo")
                if let records = try? self.context.fetch(fetchRequest) {
                    for record in records { record.image = nil }
                    (UIApplication.shared.delegate as! AppDelegate).saveContext()
                }
            }
            
            if selectedKeys.contains(.history) {
                self.executeBatchDelete(for: ["Hours"])
                self.tabBarController?.tabBar.items?[1].badgeValue = "0"
            }
            
            if selectedKeys.contains(.timeCards) {
                self.executeBatchDelete(for: ["TimeCards", "TimeCardInfo"])
                self.userDefaults.removeObject(forKey: "id")
                self.userDefaults.removeObject(forKey: "index")
                self.userDefaults.removeObject(forKey: "total")
                self.userDefaults.removeObject(forKey: "week")
                self.userDefaults.removeObject(forKey: "name")
                self.userDefaults.synchronize()
                self.tabBarController?.tabBar.items?[2].badgeValue = "0"
            }
            
            if selectedKeys.contains(.preferences) {
                if let domain = Bundle.main.bundleIdentifier {
                    self.userDefaults.removePersistentDomain(forName: domain)
                    self.userDefaults.synchronize()
                }
                self.hourSwitch?.isOn = false
                self.hourSwitch?.onTintColor = UIColor(rgb: 0x26A69A)
                self.view.window?.overrideUserInterfaceStyle = .unspecified
                self.view.window?.tintColor = UIColor(rgb: 0x26A69A)
                self.navigationController?.navigationBar.tintColor = UIColor(rgb: 0x26A69A)
                self.tabBarController?.tabBar.tintColor = UIColor(rgb: 0x26A69A)
                
                self.updatePatchNotesBadgeUI()
            }
            
            NotificationCenter.default.post(name: NSNotification.Name("Update"), object: nil)
            self.tableView.reloadData()
            self.showSuccessAlert(title: "Selected Data Cleared", message: "Your selected records and preferences have been cleared.")
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func confirmSpecificDeletion(title: String, message: String, confirmedAction: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            confirmedAction()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func executeBatchDelete(for entityNames: [String]) {
        let persistentContainer = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
        
        for entity in entityNames {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            do {
                try persistentContainer.persistentStoreCoordinator.execute(deleteRequest, with: persistentContainer.viewContext)
            } catch {
                print("Failed batch delete for \(entity): \(error)")
            }
        }
        
        persistentContainer.viewContext.reset()
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    }
    
    private func showSuccessAlert(title: String, message: String) {
        let successAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        successAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(successAlert, animated: true, completion: nil)
    }
    
    private func deleteImagesOnly() {
        executeBatchDelete(for: ["Gallery"])
        
        let fetchRequest = NSFetchRequest<TimeCardInfo>(entityName: "TimeCardInfo")
        if let records = try? context.fetch(fetchRequest) {
            for record in records {
                record.image = nil
            }
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("Update"), object: nil)
        showSuccessAlert(title: "Images Cleared", message: "All stored entry images and gallery thumbnails have been deleted.")
    }
    
    private func deleteHistoryOnly() {
        executeBatchDelete(for: ["Hours"])
        
        tabBarController?.tabBar.items?[1].badgeValue = "0"
        NotificationCenter.default.post(name: NSNotification.Name("Update"), object: nil)
        showSuccessAlert(title: "History Cleared", message: "All saved shift history records have been deleted.")
    }
    
    private func deleteTimeCardsOnly() {
        executeBatchDelete(for: ["TimeCards", "TimeCardInfo"])
        
        userDefaults.removeObject(forKey: "id")
        userDefaults.removeObject(forKey: "index")
        userDefaults.removeObject(forKey: "total")
        userDefaults.removeObject(forKey: "week")
        userDefaults.removeObject(forKey: "name")
        userDefaults.synchronize()
        
        tabBarController?.tabBar.items?[2].badgeValue = "0"
        NotificationCenter.default.post(name: NSNotification.Name("Update"), object: nil)
        showSuccessAlert(title: "Time Cards Cleared", message: "All saved time cards and logged card entries have been deleted.")
    }
    
    private func deletePreferencesOnly() {
        if let domain = Bundle.main.bundleIdentifier {
            userDefaults.removePersistentDomain(forName: domain)
            userDefaults.synchronize()
        }
        
        hourSwitch?.isOn = false
        hourSwitch?.onTintColor = UIColor(rgb: 0x26A69A)
        
        view.window?.overrideUserInterfaceStyle = .unspecified
        view.window?.tintColor = UIColor(rgb: 0x26A69A)
        navigationController?.navigationBar.tintColor = UIColor(rgb: 0x26A69A)
        tabBarController?.tabBar.tintColor = UIColor(rgb: 0x26A69A)
        
        updatePatchNotesBadgeUI()
        
        NotificationCenter.default.post(name: NSNotification.Name("Update"), object: nil)
        tableView.reloadData()
        
        showSuccessAlert(
            title: "Preferences Cleared",
            message: "All theme settings, custom colors, and user preferences have been reset to default values. Your logged hours, time cards, and images were preserved."
        )
    }
    
    func deleteData() {
        let alertLoading = UIAlertController(title: "Clearing Data...", message: "\n\n", preferredStyle: .alert)
        
        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.startAnimating()
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        alertLoading.view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: alertLoading.view.centerXAnchor),
            loadingIndicator.bottomAnchor.constraint(equalTo: alertLoading.view.bottomAnchor, constant: -20)
        ])
        
        present(alertLoading, animated: true) { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                guard let self = self else { return }
                
                if let domain = Bundle.main.bundleIdentifier {
                    UserDefaults.standard.removePersistentDomain(forName: domain)
                    UserDefaults.standard.synchronize()
                }
                
                self.executeBatchDelete(for: ["Hours", "TimeCards", "TimeCardInfo", "Gallery"])
                
                if let historyTab = self.tabBarController?.tabBar.items?[1] {
                    historyTab.isEnabled = true
                    historyTab.badgeValue = "0"
                }
                
                self.tabBarController?.tabBar.items?[2].badgeValue = "0"
                
                self.updatePatchNotesBadgeUI()
                
                NotificationCenter.default.post(name: NSNotification.Name("Update"), object: nil)
                
                self.view.window?.overrideUserInterfaceStyle = .unspecified
                self.hourSwitch?.isOn = false
                self.view.window?.tintColor = UIColor(rgb: 0x26A69A)
                
                self.tableView.reloadData()
                
                alertLoading.dismiss(animated: true) { [weak self] in
                    self?.showSuccessAlert(title: "Data Cleared", message: "All stored data and preferences have been successfully reset.")
                }
            }
        }
    }
}
