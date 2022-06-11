//
//  AdViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 5/21/22.
//

import Foundation
import UIKit
import GoogleMobileAds

class AdViewController: UIViewController {
    
    @IBOutlet weak var adView: UIView!
    
    lazy var bannerView: GADBannerView! = GADBannerView(adSize: kGADAdSizeFullBanner)
    
    override func viewDidLoad() {
        
        addBannerViewToView(bannerView)
        
        bannerView.adUnitID = "ca-app-pub-4546055219731501/2396708566"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        
        
        
    }
    
    func addBannerViewToView(_ bannerView: GADBannerView) {
        
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        view.addConstraints(
            [NSLayoutConstraint(item: bannerView,
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
}
