//
//  TabBarController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 6/28/21.
//

import UIKit
import GoogleMobileAds

class TabBarController: UITabBarController, UITabBarControllerDelegate {
    
    private var bannerView: BannerView!
    private var bannerBottomConstraint: NSLayoutConstraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        setupPersistentBannerAd()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        view.bringSubviewToFront(tabBar)
        if let banner = bannerView {
            view.bringSubviewToFront(banner)
        }
        
        // Offset above the tab bar frame safely without cross-hierarchy constraints
        let tabBarHeight = tabBar.frame.height
        bannerBottomConstraint?.constant = -tabBarHeight
    }
    
    private func setupPersistentBannerAd() {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = "ca-app-pub-4546055219731501/2396708566"
        banner.rootViewController = self
        banner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(banner)
        
        // Pin strictly within view's own coordinate system
        let bottomConstraint = banner.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        
        NSLayoutConstraint.activate([
            banner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bottomConstraint,
            banner.widthAnchor.constraint(equalToConstant: 320),
            banner.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        self.bannerBottomConstraint = bottomConstraint
        self.bannerView = banner
        banner.load(Request())
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if let nav = viewController as? UINavigationController {
            nav.popToRootViewController(animated: false)
        }
    }
}
