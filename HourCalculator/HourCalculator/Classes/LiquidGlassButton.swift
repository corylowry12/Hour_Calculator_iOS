//
//  LiquidGlassButton.swift
//  HourCalculator
//
//  Created by Cory Lowry on 10/11/26.
//

import UIKit

@IBDesignable
class LiquidGlassButton: UIButton {
    
    // MARK: - Backing Layers & Subviews
    
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    private let glossLayer = CAGradientLayer()
    private let tintUnderlayView = UIView()
    private let customTitleLabel = UILabel()
    
    private var customAccentColor: UIColor?
    
    private var activeAccentColor: UIColor {
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
    
    @IBInspectable var cornerRadiusRatio: CGFloat = 0.5 {
        didSet { setNeedsLayout() }
    }
    
    @IBInspectable var glassBorderWidth: CGFloat = 1.0 {
        didSet { layer.borderWidth = glassBorderWidth }
    }
    
    // Prevent external callers / Storyboard from stomping on the glass effect
    override var backgroundColor: UIColor? {
        get { return super.backgroundColor }
        set {
            if newValue != .clear && newValue != nil {
                self.customAccentColor = newValue
                updateAppearance()
            }
            super.backgroundColor = .clear
        }
    }
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGlass()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGlass()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if let currentText = super.title(for: .normal), !currentText.isEmpty {
            customTitleLabel.text = currentText
        } else if customTitleLabel.text == nil || customTitleLabel.text?.isEmpty == true {
            customTitleLabel.text = "Calculate"
        }
        super.setTitle("", for: .normal)
        super.backgroundColor = .clear
        updateAppearance()
    }
    
    // MARK: - Setup
    
    private func setupGlass() {
        super.backgroundColor = .clear
        
        layer.cornerCurve = .continuous
        layer.masksToBounds = true
        layer.borderWidth = glassBorderWidth
        
        // 1. Accent color underlay
        tintUnderlayView.isUserInteractionEnabled = false
        tintUnderlayView.layer.cornerCurve = .continuous
        addSubview(tintUnderlayView)
        
        // 2. Pure UIKit blur
        blurView.isUserInteractionEnabled = false
        blurView.clipsToBounds = true
        blurView.layer.cornerCurve = .continuous
        addSubview(blurView)
        
        // 3. Specular highlight
        glossLayer.startPoint = CGPoint(x: 0.1, y: 0.0)
        glossLayer.endPoint = CGPoint(x: 0.9, y: 1.0)
        layer.addSublayer(glossLayer)
        
        // 4. Custom Top-Level Label
        customTitleLabel.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        customTitleLabel.textColor = .white
        customTitleLabel.textAlignment = .center
        customTitleLabel.isUserInteractionEnabled = false
        customTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        customTitleLabel.layer.shadowColor = UIColor.black.withAlphaComponent(0.35).cgColor
        customTitleLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        customTitleLabel.layer.shadowRadius = 2.0
        customTitleLabel.layer.shadowOpacity = 1.0
        customTitleLabel.layer.masksToBounds = false
        
        addSubview(customTitleLabel)
        
        NSLayoutConstraint.activate([
            customTitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            customTitleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            customTitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 16),
            customTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16)
        ])
        
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
                self.updateAppearance()
            }
        }
        
        updateAppearance()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let targetCorner = bounds.height * cornerRadiusRatio
        layer.cornerRadius = targetCorner
        tintUnderlayView.layer.cornerRadius = targetCorner
        blurView.layer.cornerRadius = targetCorner
        glossLayer.cornerRadius = targetCorner
        
        tintUnderlayView.frame = bounds
        blurView.frame = bounds
        glossLayer.frame = bounds
        
        sendSubviewToBack(blurView)
        sendSubviewToBack(tintUnderlayView)
        bringSubviewToFront(customTitleLabel)
    }
    
    func updateAppearance() {
        let accent = activeAccentColor
        
        tintUnderlayView.backgroundColor = accent.withAlphaComponent(0.85)
        layer.borderColor = UIColor.white.withAlphaComponent(0.35).cgColor
        
        glossLayer.colors = [
            UIColor.white.withAlphaComponent(0.40).cgColor,
            UIColor.white.withAlphaComponent(0.08).cgColor,
            UIColor.clear.cgColor
        ]
        
        customTitleLabel.textColor = .white
    }
    
    func applyAccentGlassColor(_ accent: UIColor) {
        self.customAccentColor = accent
        updateAppearance()
    }
    
    // MARK: - Overrides to sync with standard button calls
    
    override func setTitle(_ title: String?, for state: UIControl.State) {
        if state == .normal {
            customTitleLabel.text = title
            super.setTitle("", for: state)
        } else {
            super.setTitle(title, for: state)
        }
    }
    
    override func title(for state: UIControl.State) -> String? {
        if state == .normal {
            return customTitleLabel.text
        }
        return super.title(for: state)
    }
    
    // MARK: - Touch Animation
    
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(
                withDuration: 0.18,
                delay: 0,
                usingSpringWithDamping: 0.75,
                initialSpringVelocity: 0.3,
                options: [.curveEaseInOut, .allowUserInteraction]
            ) {
                if self.isHighlighted {
                    self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                    self.alpha = 0.88
                } else {
                    self.transform = .identity
                    self.alpha = 1.0
                }
            }
        }
    }
}
