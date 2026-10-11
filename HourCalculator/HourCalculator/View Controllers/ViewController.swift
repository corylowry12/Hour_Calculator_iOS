//
//  ViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 6/22/21.
//

import UIKit
import GoogleMobileAds

class ViewController: UIViewController {
    
    lazy var bannerView: BannerView! = BannerView(adSize: AdSizeBanner)
    
    @IBOutlet weak var dateDatePicker: LiquidGlassCalendarButton!
    var window: UIWindow?
    
    var userDefaults = UserDefaults.standard
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var datePickerOutTime: UIDatePicker!
    @IBOutlet weak var calculateButton: LiquidGlassButton!
    
    var selectedDate: Date = Date()
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var hourItems: [Hours] {
        do {
            return try context.fetch(Hours.fetchRequest())
        } catch {
            print("Couldn't fetch data")
        }
        return [Hours]()
    }
    
    var timeCards: [TimeCards] {
        do {
            return try context.fetch(TimeCards.fetchRequest())
        } catch {
            print("Couldn't fetch data")
        }
        return [TimeCards]()
    }
    
    func changeIcon(_ iconName: String?) {
        if UIApplication.shared.responds(to: #selector(getter: UIApplication.supportsAlternateIcons)) && UIApplication.shared.supportsAlternateIcons {
            typealias setAlternateIconName = @convention(c) (NSObject, Selector, NSString?, @escaping (NSError) -> ()) -> ()
            let selectorString = "_setAlternateIconName:completionHandler:"
            let selector = NSSelectorFromString(selectorString)
            let imp = UIApplication.shared.method(for: selector)
            let method = unsafeBitCast(imp, to: setAlternateIconName.self)
            method(UIApplication.shared, selector, iconName as NSString?, { _ in })
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        dateLabel.text = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let os = ProcessInfo().operatingSystemVersion
        
        switch (os.majorVersion, os.minorVersion, os.patchVersion) {
        case (let x, _, _) where x < 14:
            dateDatePicker.isHidden = true
        default:
            dateDatePicker.isHidden = false
        }
        
        let accentColor: UIColor
        let accent = userDefaults.integer(forKey: "accent")
        switch accent {
        case 0:
            accentColor = UIColor(rgb: 0x26A69A)
            changeIcon(nil)
        case 1:
            accentColor = UIColor(rgb: 0x7841c4)
            changeIcon("purple_logo")
        case 2:
            accentColor = UIColor(rgb: 0x347deb)
            changeIcon("blue_logo")
        case 3:
            accentColor = UIColor(rgb: 0xfc783a)
            changeIcon("orange_logo")
        case 4:
            accentColor = UIColor(rgb: 0xc41d1d)
            changeIcon("red_logo")
        case 5:
            let randomAccent = userDefaults.integer(forKey: "accentRandom")
            switch randomAccent {
            case 0: accentColor = UIColor(rgb: 0x26A69A)
            case 1: accentColor = UIColor(rgb: 0x7841c4)
            case 2: accentColor = UIColor(rgb: 0x347deb)
            case 3: accentColor = UIColor(rgb: 0xfc783a)
            default: accentColor = UIColor(rgb: 0xc41d1d)
            }
        default:
            accentColor = UIColor(rgb: 0x26A69A)
            changeIcon(nil)
        }
        
        calculateButton?.applyAccentGlassColor(accentColor)
        dateDatePicker.selectedDate = selectedDate
        dateDatePicker.applyAccentColor(accentColor)
        
        if userDefaults.value(forKey: "StoredEmptyHours") == nil {
            userDefaults.set(false, forKey: "StoredEmptyHours")
        }
        
        if userDefaults.value(forKey: "automaticDeletion") == nil {
            userDefaults.setValue(0, forKey: "automaticDeletion")
        }
        
        if userDefaults.value(forKey: "dismissEdit") == nil {
            userDefaults.setValue(1, forKey: "dismissEdit")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self = self else { return }
            if self.userDefaults.integer(forKey: "historyEnabled") == 0 {
                self.tabBarController?.tabBar.items?[1].badgeValue = String(self.hourItems.count)
            } else {
                self.tabBarController?.tabBar.items?[1].badgeValue = nil
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if userDefaults.value(forKey: "theme") == nil {
            userDefaults.set(2, forKey: "theme")
        }
        
        let targetTheme = userDefaults.integer(forKey: "theme")
        let targetStyle: UIUserInterfaceStyle = targetTheme == 0 ? .light : (targetTheme == 1 ? .dark : .unspecified)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { $0.overrideUserInterfaceStyle = targetStyle }
        } else {
            view.window?.overrideUserInterfaceStyle = targetStyle
        }
        
        if userDefaults.value(forKey: "timeCardsSort") == nil {
            userDefaults.set(0, forKey: "timeCardsSort")
        }
        
        addBannerViewToView(bannerView)
        
        bannerView.adUnitID = "ca-app-pub-4546055219731501/2396708566"
        bannerView.rootViewController = self
        bannerView.load(Request())
        
        if userDefaults.value(forKey: "historyEnabled") == nil {
            userDefaults.set(0, forKey: "historyEnabled")
        }
        
        if userDefaults.integer(forKey: "historyEnabled") == 0 {
            tabBarController?.tabBar.items?[1].isEnabled = true
        } else if userDefaults.integer(forKey: "historyEnabled") == 1 {
            tabBarController?.tabBar.items?[1].isEnabled = false
        }
        
        if userDefaults.value(forKey: "historySort") == nil {
            userDefaults.set(0, forKey: "historySort")
        }
        
        if userDefaults.value(forKey: "saveImages") == nil {
            userDefaults.set(0, forKey: "saveImages")
        }
        
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        if userDefaults.value(forKey: "appVersion") == nil || userDefaults.value(forKey: "appVersion") as? String != appVersion {
            tabBarController?.tabBar.items?[3].badgeValue = "1"
        }
        
        if let savedInTime = userDefaults.value(forKey: "intime") as? Date {
            datePicker.date = savedInTime
        }
        if let savedOutTime = userDefaults.value(forKey: "outtime") as? Date {
            datePickerOutTime.date = savedOutTime
        }
        
        if userDefaults.integer(forKey: "historyEnabled") == 0 {
            tabBarController?.tabBar.items?[1].badgeValue = String(hourItems.count)
        } else {
            tabBarController?.tabBar.items?[1].badgeValue = nil
        }
        
        tabBarController?.tabBar.items?[2].badgeValue = String(timeCards.count)
        
        dateDatePicker.selectedDate = selectedDate
        dateDatePicker.onDateChanged = { [weak self] newDate in
            self?.selectedDate = newDate
        }
    }
    
    var inHour: Int = 0
    var inMinute: Int = 0
    
    @IBAction func inTimeValueChanged(_ sender: Any) {
        userDefaults.set(datePicker.date, forKey: "intime")
        let date = datePicker.date
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        inHour = components.hour ?? 0
        inMinute = components.minute ?? 0
    }
    
    var outHour: Int = 0
    var outMinute: Int = 0
    
    @IBAction func outTimeValueChanged(_ sender: Any) {
        userDefaults.set(datePickerOutTime.date, forKey: "outtime")
        let outDate = datePickerOutTime.date
        let componentsOut = Calendar.current.dateComponents([.hour, .minute], from: outDate)
        outHour = componentsOut.hour ?? 0
        outMinute = componentsOut.minute ?? 0
    }
    
    @IBAction func calculateButtonDidTouch(_ sender: UIButton) {
        UIButton.animate(withDuration: 0.05, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.975, y: 0.96)
        }, completion: { _ in
            UIButton.animate(withDuration: 0.05) {
                sender.transform = CGAffineTransform.identity
            }
        })
        
        let date = datePicker.date
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        inHour = components.hour ?? 0
        inMinute = components.minute ?? 0
        
        let outDate = datePickerOutTime.date
        let componentsOut = Calendar.current.dateComponents([.hour, .minute], from: outDate)
        outHour = componentsOut.hour ?? 0
        outMinute = componentsOut.minute ?? 0
        
        let minutesDifference = outMinute - inMinute
        let hoursDifference = outHour - inHour
        
        if hoursDifference < 0 && (12...24).contains(inHour) && (0...12).contains(outHour) {
            DispatchQueue.main.async {
                self.PMtoAM(date: date, inHour: self.inHour, inMinute: self.inMinute, outHour: self.outHour, outMinute: self.outMinute, minutesDifference: minutesDifference, hoursDifference: hoursDifference)
            }
        } else {
            DispatchQueue.main.async {
                self.AMtoPM(date: date, inHour: self.inHour, inMinute: self.inMinute, outHour: self.outHour, outMinute: self.outMinute, minutesDifference: minutesDifference, hoursDifference: hoursDifference)
            }
        }
    }
    
    func PMtoAM(date: Date, inHour: Int, inMinute: Int, outHour: Int, outMinute: Int, minutesDifference: Int, hoursDifference: Int) {
        let adjustedHours = hoursDifference + 24
        
        if minutesDifference < 0 {
            let minutesDecimal = Double(minutesDifference) / 60.00
            let minutesRounded = String(round(minutesDecimal * 100) / 100.00)
            let minutesInverted = (Double(minutesRounded) ?? 0) * -1
            let minutes2 = 1.0 - (round(minutesInverted * 100) / 100.00)
            let minutes3 = round(minutes2 * 100) / 100.00
            let minutes = String(minutes3).dropFirst(2)
            let hours = adjustedHours - 1
            if hours < 0 {
                dateLabel.text = "In time can not be greater than out time"
            } else {
                dateLabel.text = "Total Hours: \(hours).\(minutes)"
                let total = "\(hours).\(minutes)"
                
                if total != "0.0" || userDefaults.bool(forKey: "StoredEmptyHours") {
                    if userDefaults.integer(forKey: "historyEnabled") == 0 {
                        saveEntry(totalHours: total, hours: hours, minutes: String(minutes))
                    }
                }
            }
        } else {
            let minutesDecimal = Double(minutesDifference) / 60.00
            let minutesRounded = round(minutesDecimal * 100) / 100.00
            let minutesFormatted = String(minutesRounded).dropFirst(2)
            
            dateLabel.text = "Total Hours: \(adjustedHours).\(minutesFormatted)"
            let total = "\(adjustedHours).\(minutesFormatted)"
            
            if total != "0.0" || userDefaults.bool(forKey: "StoredEmptyHours") {
                if userDefaults.integer(forKey: "historyEnabled") == 0 {
                    saveEntry(totalHours: total, hours: adjustedHours, minutes: String(minutesFormatted))
                }
            }
        }
        
        finalizeCalculation()
    }
    
    func AMtoPM(date: Date, inHour: Int, inMinute: Int, outHour: Int, outMinute: Int, minutesDifference: Int, hoursDifference: Int) {
        if hoursDifference < 0 {
            dateLabel.text = "In time can not be greater than out time"
        } else if minutesDifference < 0 {
            let minutesDecimal = Double(minutesDifference) / 60.00
            let minutesRounded = String(round(minutesDecimal * 100) / 100.00)
            let minutesInverted = (Double(minutesRounded) ?? 0) * -1
            let minutes2 = 1.0 - (round(minutesInverted * 100) / 100.00)
            let minutes3 = round(minutes2 * 100) / 100.00
            let minutes = String(minutes3).dropFirst(2)
            let hours = hoursDifference - 1
            if hours < 0 {
                dateLabel.text = "In time can not be greater than out time"
            } else {
                dateLabel.text = "Total Hours: \(hours).\(minutes)"
                let total = "\(hours).\(minutes)"
                
                if total != "0.0" || userDefaults.bool(forKey: "StoredEmptyHours") {
                    if userDefaults.integer(forKey: "historyEnabled") == 0 {
                        saveEntry(totalHours: total, hours: hours, minutes: String(minutes))
                    }
                }
            }
        } else {
            let minutesDecimal = Double(minutesDifference) / 60.00
            let minutesRounded = round(minutesDecimal * 100) / 100.00
            let minutesFormatted = String(minutesRounded).dropFirst(2)
            
            dateLabel.text = "Total Hours: \(hoursDifference).\(minutesFormatted)"
            let total = "\(hoursDifference).\(minutesFormatted)"
            
            if total != "0.0" || userDefaults.bool(forKey: "StoredEmptyHours") {
                if userDefaults.integer(forKey: "historyEnabled") == 0 {
                    saveEntry(totalHours: total, hours: hoursDifference, minutes: String(minutesFormatted))
                }
            }
        }
        
        finalizeCalculation()
    }
    
    private func saveEntry(totalHours: String, hours: Int, minutes: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        let inTimeDate = dateFormatter.string(from: datePicker.date)
        let outTimeDate = dateFormatter.string(from: datePickerOutTime.date)
        
        let formatter1 = DateFormatter()
        formatter1.dateFormat = "MM/dd/yyyy"
        let dateFormatted = formatter1.string(from: selectedDate)
        
        storeHours(inTime: inTimeDate, outTime: outTimeDate, totalHours: totalHours, date: dateFormatted, hours: hours, minutes: minutes)
    }
    
    private func finalizeCalculation() {
        let autoDel = userDefaults.integer(forKey: "automaticDeletion")
        if autoDel != 0 && hourItems.count > autoDel {
            if let hourToDelete = hourItems.first {
                context.delete(hourToDelete)
            }
        }
        
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        if userDefaults.integer(forKey: "historyEnabled") == 0 {
            tabBarController?.tabBar.items?[1].badgeValue = String(hourItems.count)
        } else {
            tabBarController?.tabBar.items?[1].badgeValue = nil
        }
    }
    
    func storeHours(inTime: String, outTime: String, totalHours: String, date: String, hours: Int, minutes: String) {
        let hoursToBeStored = Hours(context: context)
        hoursToBeStored.inTime = inTime
        hoursToBeStored.outTime = outTime
        hoursToBeStored.totalHours = "\(hours).\(minutes)"
        hoursToBeStored.date = date
    }
    
    func addBannerViewToView(_ bannerView: BannerView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        view.addConstraints([
            NSLayoutConstraint(item: bannerView, attribute: .bottom, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: bannerView, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
        ])
    }
    
    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        addBannerViewToView(bannerView)
        bannerView.alpha = 0
        UIView.animate(withDuration: 1) {
            bannerView.alpha = 1
        }
    }
}
