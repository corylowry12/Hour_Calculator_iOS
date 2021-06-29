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

/*extension TabBarController: UITabBarControllerDelegate {
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        /*guard let fromView =  selectedViewController?.view, let toView = viewController.view else {
             return false
        }
        
        if fromView != toView {
            UIView.transition(from: fromView, to: toView, duration: 0.3, options: .transitionFlipFromLeft, completion: nil)
        }
        print("\(viewController.view)")
        return true*/
        if let fromView = tabBarController.selectedViewController?.view,
                    let toView = viewController.view, fromView != toView,
                    let controllerIndex = self.viewControllers?.firstIndex(of: viewController) {
                    
                    let viewSize = fromView.frame
                    let scrollRight = controllerIndex > tabBarController.selectedIndex
                    
                    // Avoid UI issues when switching tabs fast
                    if fromView.superview?.subviews.contains(toView) == true { return false }
                    
                    fromView.superview?.addSubview(toView)
                    
                    let screenWidth = UIScreen.main.bounds.size.width
                    toView.frame = CGRect(x: (scrollRight ? screenWidth : -screenWidth), y: viewSize.origin.y, width: screenWidth, height: viewSize.size.height)

                    UIView.animate(withDuration: 0.25, delay: TimeInterval(0.0), options: [.curveEaseOut, .preferredFramesPerSecond60], animations: {
                        fromView.frame = CGRect(x: (scrollRight ? -screenWidth : screenWidth), y: viewSize.origin.y, width: screenWidth, height: viewSize.size.height)
                        toView.frame = CGRect(x: 0, y: viewSize.origin.y, width: screenWidth, height: viewSize.size.height)
                    }, completion: { finished in
                        if finished {
                            fromView.removeFromSuperview()
                            tabBarController.selectedIndex = controllerIndex
                        }
                    })
                    return true
                }
                return false
    }
}*/
