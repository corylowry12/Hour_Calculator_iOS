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
        
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        
        if userDefaults.value(forKey: "appVersion") == nil || (userDefaults.value(forKey: "appVersion") as? String) != appVersion {
            let size: CGFloat = 22
            let width = max(size, 0.7 * size * 1)
            let badge = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: size))
            badge.text = "1"
            badge.layer.cornerRadius = size / 2
            badge.layer.masksToBounds = true
            badge.textAlignment = .center
            badge.textColor = UIColor.white
            badge.backgroundColor = UIColor.red
            patchNotesCell?.accessoryView = badge
        } else {
            patchNotesCell?.accessoryView = nil
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
            promptClearAppData(sourceView: cell)
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
    
    // MARK: - Clear Data Helpers
    
    private func promptClearAppData(sourceView: UIView) {
        let actionSheet = UIAlertController(
            title: "Clear App Data",
            message: "Select which data you would like to clear. Deleted records cannot be recovered.",
            preferredStyle: .actionSheet
        )
        
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = sourceView
            popover.sourceRect = sourceView.bounds
        }
        
        let clearImagesAction = UIAlertAction(title: "Clear Images", style: .destructive, handler: { [weak self] _ in
            self?.confirmSpecificDeletion(title: "Clear Images?", message: "Are you sure you want to delete all saved photos and gallery thumbnails?") { [weak self] in
                self?.deleteImagesOnly()
            }
        })
        clearImagesAction.isEnabled = hasStoredImages
        actionSheet.addAction(clearImagesAction)
        
        let clearHistoryAction = UIAlertAction(title: "Clear History", style: .destructive, handler: { [weak self] _ in
            self?.confirmSpecificDeletion(title: "Clear History?", message: "Are you sure you want to delete all logged hours from your history?") { [weak self] in
                self?.deleteHistoryOnly()
            }
        })
        clearHistoryAction.isEnabled = hasStoredHistory
        actionSheet.addAction(clearHistoryAction)
        
        let clearTimeCardsAction = UIAlertAction(title: "Clear Time Cards", style: .destructive, handler: { [weak self] _ in
            self?.confirmSpecificDeletion(title: "Clear Time Cards?", message: "Are you sure you want to delete all saved time cards and entries?") { [weak self] in
                self?.deleteTimeCardsOnly()
            }
        })
        clearTimeCardsAction.isEnabled = hasStoredTimeCards
        actionSheet.addAction(clearTimeCardsAction)
        
        let clearEverythingAction = UIAlertAction(title: "Clear Everything", style: .destructive, handler: { [weak self] _ in
            self?.confirmSpecificDeletion(title: "Clear Everything?", message: "Are you sure you want to clear all app data? This will reset all hours, time cards, photos, and preferences.") { [weak self] in
                self?.deleteData()
            }
        })
        clearEverythingAction.isEnabled = true
        actionSheet.addAction(clearEverythingAction)
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true, completion: nil)
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
                
                self.patchNotesCell?.accessoryView = nil
                
                if let historyTab = self.tabBarController?.tabBar.items?[1] {
                    historyTab.isEnabled = true
                    historyTab.badgeValue = "0"
                }
                
                self.tabBarController?.tabBar.items?[2].badgeValue = "0"
                
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
