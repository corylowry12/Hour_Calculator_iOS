//
//  TabBarController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 6/28/21.
//

import UIKit
import SwipeableTabBarController

class TabBarController: SwipeableTabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        
        swipeAnimatedTransitioning?.animationType = SwipeAnimationType.sideBySide
        minimumNumberOfTouches = 2
    }
}
