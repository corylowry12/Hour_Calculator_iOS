//
//  LiquidGlassCalendarButton.swift
//  HourCalculator
//
//  Created by Cory Lowry on 10/11/26.
//

import UIKit

@IBDesignable
class LiquidGlassCalendarButton: UIButton {
    
    // MARK: - Properties
    
    private var customAccentColor: UIColor?
    
    var onDateChanged: ((Date) -> Void)?
    
    var selectedDate: Date = Date() {
        didSet {
            updateDateTitle()
        }
    }
    
    var activeAccentColor: UIColor {
        if let custom = customAccentColor { return custom }
        let userDefaults = UserDefaults.standard
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
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupButton()
        updateDateTitle()
    }
    
    private func setupButton() {
        layer.cornerRadius = 8
        layer.masksToBounds = true
        backgroundColor = UIColor.systemGray5
        
        removeTarget(nil, action: nil, for: .allEvents)
        addTarget(self, action: #selector(presentCalendarModal), for: .touchUpInside)
        
        updateAppearance()
    }
    
    // MARK: - Theming & Title
    
    func updateAppearance() {
        let accent = activeAccentColor
        tintColor = accent
        backgroundColor = UIColor.systemGray5
        updateDateTitle()
    }
    
    func applyAccentColor(_ accent: UIColor) {
        self.customAccentColor = accent
        updateAppearance()
    }
    
    private func updateDateTitle() {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        let dateString = formatter.string(from: selectedDate)
        
        // Consistent font styling via AttributedString
        var titleAttr = AttributedString(dateString)
        titleAttr.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleAttr.foregroundColor = activeAccentColor
        
        var config = configuration ?? UIButton.Configuration.plain()
        config.attributedTitle = titleAttr
        config.baseForegroundColor = activeAccentColor
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        self.configuration = config
    }
    
    // MARK: - Modal Presentation & Theming
    
    @objc private func presentCalendarModal() {
        guard let parentVC = findParentViewController() else { return }
        
        let accent = activeAccentColor
        
        let alertVC = UIViewController()
        alertVC.modalPresentationStyle = .overFullScreen
        alertVC.modalTransitionStyle = .crossDissolve
        alertVC.view.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        alertVC.view.tintColor = accent
        
        let dismissButton = UIButton(frame: alertVC.view.bounds)
        dismissButton.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        dismissButton.addTarget(self, action: #selector(dismissCalendarModal), for: .touchUpInside)
        alertVC.view.addSubview(dismissButton)
        
        let blurEffect = UIBlurEffect(style: .systemThinMaterial)
        let glassContainer = UIVisualEffectView(effect: blurEffect)
        glassContainer.layer.cornerRadius = 24
        glassContainer.layer.masksToBounds = true
        glassContainer.layer.borderWidth = 1.0
        glassContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        glassContainer.tintColor = accent
        glassContainer.translatesAutoresizingMaskIntoConstraints = false
        alertVC.view.addSubview(glassContainer)
        
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .inline
        picker.maximumDate = Date()
        picker.date = selectedDate
        picker.tintColor = accent
        picker.backgroundColor = .clear
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.addTarget(self, action: #selector(inlineDateChanged(_:)), for: .valueChanged)
        
        glassContainer.contentView.addSubview(picker)
        
        NSLayoutConstraint.activate([
            glassContainer.centerXAnchor.constraint(equalTo: alertVC.view.centerXAnchor),
            glassContainer.centerYAnchor.constraint(equalTo: alertVC.view.centerYAnchor),
            glassContainer.widthAnchor.constraint(equalToConstant: 335),
            
            picker.topAnchor.constraint(equalTo: glassContainer.contentView.topAnchor, constant: 12),
            picker.bottomAnchor.constraint(equalTo: glassContainer.contentView.bottomAnchor, constant: -12),
            picker.leadingAnchor.constraint(equalTo: glassContainer.contentView.leadingAnchor, constant: 12),
            picker.trailingAnchor.constraint(equalTo: glassContainer.contentView.trailingAnchor, constant: -12)
        ])
        
        parentVC.present(alertVC, animated: true)
    }
    
    @objc private func inlineDateChanged(_ sender: UIDatePicker) {
        selectedDate = sender.date
        onDateChanged?(sender.date)
        findParentViewController()?.dismiss(animated: true)
    }
    
    @objc private func dismissCalendarModal() {
        findParentViewController()?.dismiss(animated: true)
    }
    
    private func findParentViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let next = responder?.next {
            if let vc = next as? UIViewController {
                return vc
            }
            responder = next
        }
        return nil
    }
}
