//
//  LiquidGlassButton.swift
//  HourCalculator
//
//  Created by Cory Lowry on 10/11/26.
//


//
//  LiquidGlassButton.swift
//  HourCalculator
//
//  Created by Cory Lowry on 10/11/26.
//

import UIKit

@IBDesignable
class LiquidGlassButton: UIButton {
    
    // MARK: - Properties
    
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
    private let glossLayer = CAGradientLayer()
    
    @IBInspectable var cornerRadiusRatio: CGFloat = 0.5 { // 0.5 = pill / capsule
        didSet { setNeedsLayout() }
    }
    
    @IBInspectable var glassBorderWidth: CGFloat = 1.0 {
        didSet { layer.borderWidth = glassBorderWidth }
    }
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGlass()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGlass()
    }
    
    // MARK: - Setup
    
    private func setupGlass() {
        backgroundColor = .clear
        
        // 1. Layer corner configuration
        layer.cornerCurve = .continuous
        layer.masksToBounds = true
        layer.borderWidth = glassBorderWidth
        layer.borderColor = UIColor.white.withAlphaComponent(0.28).cgColor
        
        // 2. Backdrop Blur View
        blurView.isUserInteractionEnabled = false
        blurView.clipsToBounds = true
        blurView.layer.cornerCurve = .continuous
        insertSubview(blurView, at: 0)
        
        // 3. Specular Liquid Highlight Gradient
        glossLayer.colors = [
            UIColor.white.withAlphaComponent(0.35).cgColor,
            UIColor.white.withAlphaComponent(0.05).cgColor,
            UIColor.clear.cgColor
        ]
        glossLayer.locations = [0.0, 0.45, 1.0]
        glossLayer.startPoint = CGPoint(x: 0.2, y: 0.0)
        glossLayer.endPoint = CGPoint(x: 0.8, y: 1.0)
        layer.insertSublayer(glossLayer, above: blurView.layer)
        
        // 4. Default Content Styling
        titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let targetCorner = bounds.height * cornerRadiusRatio
        layer.cornerRadius = targetCorner
        blurView.layer.cornerRadius = targetCorner
        
        blurView.frame = bounds
        glossLayer.frame = bounds
        glossLayer.cornerRadius = targetCorner
        
        // Ensure subviews like titleLabel and imageView stay above the blur and gloss
        if let titleLabel = titleLabel { bringSubviewToFront(titleLabel) }
        if let imageView = imageView { bringSubviewToFront(imageView) }
    }
    
    // MARK: - Liquid Spring Press Animation
    
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                usingSpringWithDamping: 0.7,
                initialSpringVelocity: 0.4,
                options: [.curveEaseInOut, .allowUserInteraction]
            ) {
                if self.isHighlighted {
                    self.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
                    self.alpha = 0.85
                    self.blurView.effect = UIBlurEffect(style: .systemMaterial)
                } else {
                    self.transform = .identity
                    self.alpha = 1.0
                    self.blurView.effect = UIBlurEffect(style: .systemThinMaterial)
                }
            }
        }
    }
    
    // MARK: - Dynamic Tint Adaptation
    
    func applyAccentGlassColor(_ accent: UIColor) {
        tintColor = accent
        setTitleColor(accent, for: .normal)
        layer.borderColor = accent.withAlphaComponent(0.35).cgColor
        
        glossLayer.colors = [
            accent.withAlphaComponent(0.28).cgColor,
            accent.withAlphaComponent(0.06).cgColor,
            UIColor.clear.cgColor
        ]
    }
}
