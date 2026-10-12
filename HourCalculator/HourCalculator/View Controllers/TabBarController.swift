//
//  TabBarController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 6/28/21.
//

import UIKit
import SwipeableTabBarController
import GoogleMobileAds

class TabBarController: SwipeableTabBarController {
    
    private var bannerView: BannerView!
    private var bannerBottomConstraint: NSLayoutConstraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        
        swipeAnimatedTransitioning?.animationType = SwipeAnimationType.sideBySide
        minimumNumberOfTouches = 2
        
        setupPersistentBannerAd()
    }
    
    override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            
            // Bring both the tab bar and the banner above child content
            view.bringSubviewToFront(tabBar)
            if let banner = bannerView {
                view.bringSubviewToFront(banner)
            }
            
            // Dynamically offset the banner by the actual height of the tab bar
            let tabBarHeight = tabBar.frame.height
            bannerBottomConstraint?.constant = -tabBarHeight
        }
        
        private func setupPersistentBannerAd() {
            let banner = BannerView(adSize: AdSizeBanner)
            banner.adUnitID = "ca-app-pub-4546055219731501/2396708566"
            banner.rootViewController = self
            banner.translatesAutoresizingMaskIntoConstraints = false
            
            view.addSubview(banner)
            self.bannerView = banner
            
            // Anchor to view.bottomAnchor and offset upward by the tab bar's height
            let bottomConstraint = banner.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -tabBar.frame.height)
            self.bannerBottomConstraint = bottomConstraint
            
            NSLayoutConstraint.activate([
                banner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                bottomConstraint,
                banner.widthAnchor.constraint(equalToConstant: AdSizeBanner.size.width),
                banner.heightAnchor.constraint(equalToConstant: AdSizeBanner.size.height)
            ])
            
            banner.load(Request())
        }
}
