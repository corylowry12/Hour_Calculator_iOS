//
//  ViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 6/22/21.
//

import UIKit
import GoogleMobileAds

class ViewController: UIViewController {
    
    var bannerView: GADBannerView!

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var datePickerOutTime: UIDatePicker!
    @IBOutlet weak var calculateButton: UIButton!
    @IBOutlet weak var NavigationBar: UINavigationBar!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        
        addBannerViewToView(bannerView)
        
        bannerView.adUnitID = "ca-app-pub-4546055219731501/2396708566"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        
    }
    
    
    
    var inHour : Int = 0
    var inMinute : Int = 0
    
    
    
    @IBAction func inTimeValueChanged(_ sender: Any) {
        let date = datePicker.date
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        
        inHour = components.hour!
        inMinute = components.minute!

    }
    
    //var outTime : String
    var outHour : Int = 0
    var outMinute : Int = 0
    
    
    @IBAction func outTimeValueChanged(_ sender: Any) {
        let outDate = datePickerOutTime.date
        let componentsOut = Calendar.current.dateComponents([.hour, .minute], from: outDate)
        outHour = componentsOut.hour!
        outMinute = componentsOut.minute!
    }
    
    @IBAction func calculateButtonDidTouch(_ sender: Any) {
        
        let date = datePicker.date
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        
        inHour = components.hour!
        inMinute = components.minute!
        
        let outDate = datePickerOutTime.date
        let componentsOut = Calendar.current.dateComponents([.hour, .minute], from: outDate)
        
        outHour = componentsOut.hour!
        outMinute = componentsOut.minute!
        
        let minutesDifference = outMinute - inMinute
        let hoursDifference = outHour - inHour
        
        if hoursDifference < 0 {
            dateLabel.text = "In time can not be greater than out time"
        }
        else if minutesDifference < 0 {
            let minutesDecimal : Double = Double(minutesDifference) / 60.00
            let minutesRounded = round(minutesDecimal * 100) / 100.00
            let minutesFormatted = String(minutesRounded).dropFirst(3)
            
            let minutes = 100 - (minutesFormatted as NSString).integerValue
            
            let hours = hoursDifference - 1
            if hours < 0 {
                dateLabel.text = "In time can not be greater than out time"
            }
            else {
            dateLabel.text = "Total Hours: \(hours).\(minutes)"
            }
        }
            else {
                let minutesDecimal : Double = Double(minutesDifference) / 60.00
                let minutesRounded = round(minutesDecimal * 100) / 100.00
                let minutesFormatted = String(minutesRounded).dropFirst(2)
            
                dateLabel.text = "Total Hours: \(hoursDifference).\(minutesFormatted)"
            }
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
    
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        addBannerViewToView(bannerView)
        bannerView.alpha = 0
        UIView.animate(withDuration: 1, animations: {
            bannerView.alpha = 1
        })
    }
    }
