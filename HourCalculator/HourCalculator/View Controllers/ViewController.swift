//
//  ViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 6/22/21.
//
import UIKit
import GoogleMobileAds
import StoreKit
import Instabug

class ViewController: UIViewController {
    
    lazy var bannerView: GADBannerView! = GADBannerView(adSize: kGADAdSizeBanner)
    
    @IBOutlet weak var dateDatePicker: UIDatePicker!
    var window : UIWindow?
    
    var userDefaults = UserDefaults.standard
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var datePickerOutTime: UIDatePicker!
    @IBOutlet weak var calculateButton: UIButton!
    
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
    
    func changeIcon(_ iconName: Any?) {
        if UIApplication.shared.responds(to: #selector(getter: UIApplication.supportsAlternateIcons)) && UIApplication.shared.supportsAlternateIcons {
            
            typealias setAlternateIconName = @convention(c) (NSObject, Selector, NSString?, @escaping (NSError) -> ()) -> ()
            
            let selectorString = "_setAlternateIconName:completionHandler:"
            
            let selector = NSSelectorFromString(selectorString)
            let imp = UIApplication.shared.method(for: selector)
            let method = unsafeBitCast(imp, to: setAlternateIconName.self)
            method(UIApplication.shared, selector, iconName as! NSString?, { _ in })
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if userDefaults.value(forKey: "StoredEmptyHours") == nil{
            userDefaults.set(false, forKey: "StoredEmptyHours")
        }
        if userDefaults.value(forKey: "theme") == nil{
            userDefaults.set(2, forKey: "theme")
        }
        
        if userDefaults.integer(forKey: "theme") == 0 {
            view.window?.overrideUserInterfaceStyle = .light
        }
        else if userDefaults.integer(forKey: "theme") == 1 {
            view.window?.overrideUserInterfaceStyle = .dark
        }
        else if userDefaults.integer(forKey: "theme") == 2 {
            view.window?.overrideUserInterfaceStyle = .unspecified
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //dateLabel.text = ""
        self.dismiss(animated: false, completion: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        dateLabel.text = nil
        //bannerView.delegate = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        //view.layer.shadowPath = UIBezierPath(rect: view.bounds).cgPath
        let os = ProcessInfo().operatingSystemVersion
        
        switch (os.majorVersion, os.minorVersion, os.patchVersion) {
        case (let x, _, _) where x < 14: do {
            dateDatePicker.isHidden = true
        }
        default: do {
            dateDatePicker.isHidden = false
        }
        }
        dateDatePicker.maximumDate = Date()
        
        BugReporting.enabled = true
        
        if userDefaults.integer(forKey: "accent") == 0 {
            calculateButton.backgroundColor = UIColor(rgb: 0x26A69A)
            dateDatePicker.tintColor = UIColor(rgb: 0x26A69A)
            changeIcon(nil)
        }
        else if userDefaults.integer(forKey: "accent") == 1 {
            calculateButton.backgroundColor = UIColor(rgb: 0x7841c4)
            dateDatePicker.tintColor = UIColor(rgb: 0x7841c4)
            changeIcon("purple_logo")
        }
        else if userDefaults.integer(forKey: "accent") == 2 {
            calculateButton.backgroundColor = UIColor(rgb: 0x347deb)
            dateDatePicker.tintColor = UIColor(rgb: 0x347deb)
            changeIcon("blue_logo")
        }
        else if userDefaults.integer(forKey: "accent") == 3 {
            calculateButton.backgroundColor = UIColor(rgb: 0xfc783a)
            dateDatePicker.tintColor = UIColor(rgb: 0xfc783a)
            changeIcon("orange_logo")
        }
        else if userDefaults.integer(forKey: "accent") == 4 {
            calculateButton.backgroundColor = UIColor(rgb: 0xc41d1d)
            dateDatePicker.tintColor = UIColor(rgb: 0xc41d1d)
            changeIcon("red_logo")
        }
        
        if userDefaults.value(forKey: "StoredEmptyHours") == nil{
            userDefaults.set(false, forKey: "StoredEmptyHours")
        }
        
        if userDefaults.value(forKey: "theme") == nil{
            userDefaults.set(2, forKey: "theme")
        }
        
        if userDefaults.integer(forKey: "theme") == 0 {
            window?.overrideUserInterfaceStyle = .light
        }
        else if userDefaults.integer(forKey: "theme") == 1 {
            window?.overrideUserInterfaceStyle = .dark
        }
        else if userDefaults.integer(forKey: "theme") == 2 {
            window?.overrideUserInterfaceStyle = .unspecified
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if userDefaults.value(forKey: "timeCardsSort") == nil {
            userDefaults.set(0, forKey: "timeCardsSort")
        }
        addBannerViewToView(bannerView)
        
        bannerView.adUnitID = "ca-app-pub-4546055219731501/2396708566"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        
        if userDefaults.value(forKey: "historyEnabled") == nil{
            userDefaults.set(0, forKey: "historyEnabled")
        }
        
        if userDefaults.integer(forKey: "historyEnabled") == 0 {
            tabBarController?.tabBar.items?[1].isEnabled = true
        }
        else if userDefaults.integer(forKey: "historyEnabled") == 1 {
            tabBarController?.tabBar.items?[1].isEnabled = false
        }
        
        if userDefaults.value(forKey: "historySort") == nil {
            userDefaults.set(0, forKey: "historySort")
        }
        
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        
        if userDefaults.value(forKey: "appVersion") == nil || userDefaults.value(forKey: "appVersion") as? String != appVersion {
            tabBarController?.tabBar.items?[3].badgeValue = "1"
        }
        
        if userDefaults.value(forKey: "intime") != nil {
            datePicker.date = userDefaults.value(forKey: "intime") as! Date
        }
        if userDefaults.value(forKey: "outtime") != nil {
            datePickerOutTime.date = userDefaults.value(forKey: "outtime") as! Date
        }
        
        userDefaults.removeObject(forKey: "ID")
        
        if userDefaults.integer(forKey: "historyEnabled") == 0 {
            tabBarController?.tabBar.items?[1].badgeValue = String(hourItems.count)
        }
        else {
            tabBarController?.tabBar.items![1].badgeValue = nil
        }
        
        tabBarController?.tabBar.items?[2].badgeValue = String(timeCards.count)
        
    }
    
    
    @IBAction func dateDatePicker(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    var inHour : Int = 0
    var inMinute : Int = 0
    
    @IBAction func inTimeValueChanged(_ sender: Any) {
        userDefaults.set(datePicker.date, forKey: "intime")
        let date = datePicker.date
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        
        inHour = components.hour!
        inMinute = components.minute!
        
    }
    
    //var outTime : String
    var outHour : Int = 0
    var outMinute : Int = 0
    
    
    @IBAction func outTimeValueChanged(_ sender: Any) {
        userDefaults.set(datePickerOutTime.date, forKey: "outtime")
        let outDate = datePickerOutTime.date
        let componentsOut = Calendar.current.dateComponents([.hour, .minute], from: outDate)
        outHour = componentsOut.hour!
        outMinute = componentsOut.minute!
    }
    
    @IBAction func calculateButtonDidTouch(_ sender: UIButton) {
        UIButton.animate(withDuration: 0.05,
                         animations: {
                            sender.transform = CGAffineTransform(scaleX: 0.975, y: 0.96)
                         },
                         completion: { finish in
                            UIButton.animate(withDuration: 0.05, animations: {
                                sender.transform = CGAffineTransform.identity
                            })
                         })
        
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
        
        if hoursDifference < 0 && (12...24).contains(inHour) && (0...12).contains(outHour){
            print("less than zero")
            DispatchQueue.main.async {
                self.PMtoAM(date: date, inHour: self.inHour, inMinute: self.inMinute, outHour: self.outHour, outMinute: self.outMinute, minutesDifference: minutesDifference, hoursDifference: hoursDifference)
            }
        }
        else {
            DispatchQueue.main.async {
                self.AMtoPM(date: date, inHour: self.inHour, inMinute: self.inMinute, outHour: self.outHour, outMinute: self.outMinute, minutesDifference: minutesDifference, hoursDifference: hoursDifference)
            }
        }
        
    }
    
    func PMtoAM(date : Date, inHour : Int, inMinute : Int, outHour : Int, outMinute : Int, minutesDifference : Int, hoursDifference : Int) {
        //let hoursToBeStored = Hours(context: context)
        //hoursDifference = hoursDifference + 24
        let hoursDifference = hoursDifference + 24
        //let date = datePicker.date
        //let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        
        //inHour = components.hour!
        //inMinute = components.minute!
        
        //let outDate = datePickerOutTime.date
        //let componentsOut = Calendar.current.dateComponents([.hour, .minute], from: outDate)
        
        //outHour = componentsOut.hour!
        //outMinute = componentsOut.minute!
        
        //let minutesDifference = outMinute - inMinute
        //let hoursDifference = outHour - inHour + 24
        
        if minutesDifference < 0 {
            let minutesDecimal : Double = Double(minutesDifference) / 60.00
            let minutesRounded = String(round(minutesDecimal * 100) / 100.00)
            let minutesInverted = Double(minutesRounded)! * -1
            let minutes2 = 1.0 - Double(round(minutesInverted * 100) / 100.00)
            let minutes3 = round(minutes2 * 100) / 100.00
            print(minutes3)
            let minutes = String(minutes3).dropFirst(2)
            print(minutes)
            let hours = hoursDifference - 1
            dateLabel.text = "Total Hours: \(hours).\(minutes)"
            
            let total = "\(hours).\(minutes)"
            
            if total == "0.0" {
                if userDefaults.bool(forKey: "StoredEmptyHours") == true {
                    
                    if userDefaults.value(forKey: "historyEnabled") as! Int == 0 {
                        let hoursToBeStored = Hours(context: context)
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "hh:mm a"
                        let inTimeDate = dateFormatter.string(from: datePicker.date)
                        let outTimeDate = dateFormatter.string(from: datePickerOutTime.date)
                        
                        let inTime = inTimeDate
                        let outTime = outTimeDate
                        hoursToBeStored.inTime = inTime
                        hoursToBeStored.outTime = outTime
                        hoursToBeStored.totalHours = "\(hours).\(minutes)"
                        
                        let today = dateDatePicker.date
                        let formatter1 = DateFormatter()
                        formatter1.dateFormat = "MM/dd/yyyy"
                        let dateFormatted = formatter1.string(from: today)
                        hoursToBeStored.date = dateFormatted
                    }
                }
                else {
                    
                    if userDefaults.value(forKey: "historyEnabled") as! Int == 0 {
                        let hoursToBeStored = Hours(context: context)
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "hh:mm a"
                        let inTimeDate = dateFormatter.string(from: datePicker.date)
                        let outTimeDate = dateFormatter.string(from: datePickerOutTime.date)
                        
                        let inTime = inTimeDate
                        let outTime = outTimeDate
                        hoursToBeStored.inTime = inTime
                        hoursToBeStored.outTime = outTime
                        hoursToBeStored.totalHours = "\(hours).\(minutes)"
                        let today = dateDatePicker.date
                        let formatter1 = DateFormatter()
                        formatter1.dateFormat = "MM/dd/yyyy"
                        let dateFormatted = formatter1.string(from: today)
                        hoursToBeStored.date = dateFormatted
                    }
                }
            }
        }
        else {
            let minutesDecimal : Double = Double(minutesDifference) / 60.00
            let minutesRounded = round(minutesDecimal * 100) / 100.00
            let minutesFormatted = String(minutesRounded).dropFirst(2)
            
            dateLabel.text = "Total Hours: \(hoursDifference).\(minutesFormatted)"
            
            let total = "\(hoursDifference).\(minutesFormatted)"
            
            if total == "0.0" {
                if userDefaults.bool(forKey: "StoredEmptyHours") == true {
                    
                    if userDefaults.value(forKey: "historyEnabled") as! Int == 0 {
                        let hoursToBeStored = Hours(context: context)
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "hh:mm a"
                        let inTimeDate = dateFormatter.string(from: datePicker.date)
                        let outTimeDate = dateFormatter.string(from: datePickerOutTime.date)
                        
                        let inTime = inTimeDate
                        let outTime = outTimeDate
                        hoursToBeStored.inTime = inTime
                        hoursToBeStored.outTime = outTime
                        hoursToBeStored.totalHours = "\(hoursDifference).\(minutesFormatted)"
                        
                        let today = dateDatePicker.date
                        let formatter1 = DateFormatter()
                        formatter1.dateFormat = "MM/dd/yyyy"
                        let dateFormatted = formatter1.string(from: today)
                        hoursToBeStored.date = dateFormatted
                    }
                }
            }
            else {
                
                if userDefaults.integer(forKey: "historyEnabled") == 0 {
                    let hoursToBeStored = Hours(context: context)
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "hh:mm a"
                    let inTimeDate = dateFormatter.string(from: datePicker.date)
                    let outTimeDate = dateFormatter.string(from: datePickerOutTime.date)
                    
                    let inTime = inTimeDate
                    let outTime = outTimeDate
                    
                    hoursToBeStored.inTime = inTime
                    hoursToBeStored.outTime = outTime
                    hoursToBeStored.totalHours = "\(hoursDifference).\(minutesFormatted)"
                    let today = dateDatePicker.date
                    let formatter1 = DateFormatter()
                    formatter1.dateFormat = "MM/dd/yyyy"
                    let dateFormatted = formatter1.string(from: today)
                    hoursToBeStored.date = dateFormatted
                }
            }
        }
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        if userDefaults.integer(forKey: "historyEnabled") == 0 {
            tabBarController?.tabBar.items?[1].badgeValue = String(hourItems.count)
        }
        else {
            tabBarController?.tabBar.items?[1].badgeValue = nil
        }
    }
    
    func AMtoPM(date : Date, inHour : Int, inMinute : Int, outHour : Int, outMinute : Int, minutesDifference : Int, hoursDifference : Int) {
        //let hoursToBeStored = Hours(context: context)
        if hoursDifference < 0 {
            dateLabel.text = "In time can not be greater than out time"
        }
        else if minutesDifference < 0 {
            let minutesDecimal : Double = Double(minutesDifference) / 60.00
            let minutesRounded = String(round(minutesDecimal * 100) / 100.00)
            let minutesInverted = Double(minutesRounded)! * -1
            let minutes2 = 1.0 - Double(round(minutesInverted * 100) / 100.00)
            let minutes3 = round(minutes2 * 100) / 100.00
            let minutes = String(minutes3).dropFirst(2)
            let hours = hoursDifference - 1
            if hours < 0 {
                dateLabel.text = "In time can not be greater than out time"
            }
            else {
                dateLabel.text = "Total Hours: \(hours).\(minutes)"
                
                let total = "\(hours).\(minutes)"
                
                if total == "0.0" {
                    if userDefaults.bool(forKey: "StoredEmptyHours") == true {
                        
                        if userDefaults.value(forKey: "historyEnabled") as! Int == 0 {
                            
                            let hoursToBeStored = Hours(context: context)
                            
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "hh:mm a"
                            let inTimeDate = dateFormatter.string(from: datePicker.date)
                            let outTimeDate = dateFormatter.string(from: datePickerOutTime.date)
                            
                            let inTime = inTimeDate
                            let outTime = outTimeDate
                            hoursToBeStored.inTime = inTime
                            hoursToBeStored.outTime = outTime
                            hoursToBeStored.totalHours = "\(hours).\(minutes)"
                            
                            let today = dateDatePicker.date
                            let formatter1 = DateFormatter()
                            formatter1.dateFormat = "MM/dd/yyyy"
                            let dateFormatted = formatter1.string(from: today)
                            hoursToBeStored.date = dateFormatted
                        }
                    }
                }
                else {
                    
                    if userDefaults.value(forKey: "historyEnabled") as! Int == 0 {
                        let hoursToBeStored = Hours(context: context)
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "hh:mm a"
                        let inTimeDate = dateFormatter.string(from: datePicker.date)
                        let outTimeDate = dateFormatter.string(from: datePickerOutTime.date)
                        
                        let inTime = inTimeDate
                        let outTime = outTimeDate
                        hoursToBeStored.inTime = inTime
                        hoursToBeStored.outTime = outTime
                        hoursToBeStored.totalHours = "\(hours).\(minutes)"
                        //hoursToBeStored.date = Date()
                        let today = dateDatePicker.date
                        let formatter1 = DateFormatter()
                        formatter1.dateFormat = "MM/dd/yyyy"
                        let dateFormatted = formatter1.string(from: today)
                        hoursToBeStored.date = dateFormatted
                    }
                }
            }
        }
        else {
            let minutesDecimal : Double = Double(minutesDifference) / 60.00
            let minutesRounded = round(minutesDecimal * 100) / 100.00
            let minutesFormatted = String(minutesRounded).dropFirst(2)
            
            dateLabel.text = "Total Hours: \(hoursDifference).\(minutesFormatted)"
            
            let total = "\(hoursDifference).\(minutesFormatted)"
            //let totalDouble = Double(total)
            
            if total == "0.0" {
                if userDefaults.bool(forKey: "StoredEmptyHours") == true {
                    
                    if userDefaults.value(forKey: "historyEnabled") as! Int == 0 {
                        
                        let hoursToBeStored = Hours(context: context)
                        
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "hh:mm a"
                        let inTimeDate = dateFormatter.string(from: datePicker.date)
                        let outTimeDate = dateFormatter.string(from: datePickerOutTime.date)
                        
                        let inTime = inTimeDate
                        let outTime = outTimeDate
                        hoursToBeStored.inTime = inTime
                        hoursToBeStored.outTime = outTime
                        hoursToBeStored.totalHours = "\(hoursDifference).\(minutesFormatted)"
                        
                        let today = dateDatePicker.date
                        let formatter1 = DateFormatter()
                        formatter1.dateFormat = "MM/dd/yyyy"
                        let dateFormatted = formatter1.string(from: today)
                        hoursToBeStored.date = dateFormatted
                    }
                }
            }
            else {
                
                if userDefaults.integer(forKey: "historyEnabled") == 0 {
                    
                    let hoursToBeStored = Hours(context: context)
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "hh:mm a"
                    let inTimeDate = dateFormatter.string(from: datePicker.date)
                    let outTimeDate = dateFormatter.string(from: datePickerOutTime.date)
                    
                    let inTime = inTimeDate
                    let outTime = outTimeDate
                    
                    hoursToBeStored.inTime = inTime
                    hoursToBeStored.outTime = outTime
                    hoursToBeStored.totalHours = "\(hoursDifference).\(minutesFormatted)"
                    let today = dateDatePicker.date
                    let formatter1 = DateFormatter()
                    formatter1.dateFormat = "MM/dd/yyyy"
                    let dateFormatted = formatter1.string(from: today)
                    hoursToBeStored.date = dateFormatted
                }
            }
        }
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        if userDefaults.integer(forKey: "historyEnabled") == 0 {
            tabBarController?.tabBar.items?[1].badgeValue = String(hourItems.count)
        }
        else {
            tabBarController?.tabBar.items?[1].badgeValue = nil
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
