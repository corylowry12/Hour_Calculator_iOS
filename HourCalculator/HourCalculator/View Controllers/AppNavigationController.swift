//
//  AppNavigationController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 10/12/26.
//


//
//  AppNavigationController.swift
//  HourCalculator
//

import UIKit

class AppNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBarAppearance()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        enforceSystemMargins()
    }
    
    private func configureNavigationBarAppearance() {
        navigationBar.prefersLargeTitles = true
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.titlePositionAdjustment = .zero
        
        navigationBar.standardAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        if #available(iOS 15.0, *) {
            navigationBar.compactScrollEdgeAppearance = appearance
        }
    }
    
    private func enforceSystemMargins() {
        let standardMargin: CGFloat = 16.0
        navigationBar.layoutMargins.left = standardMargin
        navigationBar.layoutMargins.right = standardMargin
        navigationBar.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 0,
            leading: standardMargin,
            bottom: 0,
            trailing: standardMargin
        )
    }
}
