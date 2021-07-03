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
    
    var window : UIWindow?
    
    let userDefaults = UserDefaults.standard
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var datePickerOutTime: UIDatePicker!
    @IBOutlet weak var calculateButton: UIButton!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
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
        dateLabel.text = ""
    }
    
    override func viewWillAppear(_ animated: Bool) {
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        
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
        let device = UIDevice.current.name
        
        if userDefaults.value(forKey: "dearAlertDialog") == nil{
            userDefaults.set(false, forKey: "dearAlertDialog")
        }
        
        if device == "iPhone 12" &&  userDefaults.bool(forKey: "dearAlertDialog") == false {
        let alert = UIAlertController(title: "Dear Aunt Chelle", message: "No matter how hard things get, or whatever it is you're going through, just always keep your head up. - From the developer of this app P.S. this is only showing up on your device", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: { [self]_ in
                userDefaults.set(true, forKey: "dearAlertDialog")
            } ))
            let when = DispatchTime.now() + 1
            DispatchQueue.main.asyncAfter(deadline: when) {
                
                    self.present(alert, animated: true, completion: nil)
            }
        }
        
        print(device)
        
       let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        
        if userDefaults.value(forKey: "appVersion") == nil || userDefaults.value(forKey: "appVersion") as? String != appVersion {
            tabBarController?.tabBar.items?[2].badgeValue = String("1")
        }
        
        if userDefaults.value(forKey: "intime") != nil {
        datePicker.date = userDefaults.value(forKey: "intime") as! Date
        }
        if userDefaults.value(forKey: "outtime") != nil {
            datePickerOutTime.date = userDefaults.value(forKey: "outtime") as! Date
        }
        
        var hoursItems: [Hours] {
            
            do {
                return try context.fetch(Hours.fetchRequest())
            }
            catch {
                print("There was an error")
            }
            
            return [Hours]()
        }
        
        userDefaults.removeObject(forKey: "ID")
        
        if userDefaults.integer(forKey: "historyEnabled") == 0 {
        tabBarController?.tabBar.items?[1].badgeValue = String(hoursItems.count)
        }
        else {
            tabBarController?.tabBar.items![1].badgeValue = nil
        }
        
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
            
        AMtoPM()
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        
        var hoursItems: [Hours] {
            
            do {
                return try context.fetch(Hours.fetchRequest())
            }
            catch {
                print("There was an error")
            }
            
            return [Hours]()
        }
        
        if userDefaults.integer(forKey: "historyEnabled") == 0 {
        tabBarController?.tabBar.items?[1].badgeValue = String(hoursItems.count)
        }
        else {
            tabBarController?.tabBar.items?[1].badgeValue = nil
        }
    }
    
    func AMtoPM() {
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
            let minutesRounded = String(round(minutesDecimal * 100) / 100.00)
            let minutesInverted = Double(minutesRounded)! * -1
            print(minutesInverted)
            //let minutesFormatted = String(minutesInverted).dropFirst(2)
            print(minutesInverted)
            let minutes2 = 1.0 - Double(round(minutesInverted * 100) / 100.00)
            let minutes3 = round(minutes2 * 100) / 100.00
            print(minutes3)
            let minutes = String(minutes3).dropFirst(2)
            print(minutes)
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
                            let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
                            
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
            
                    let today = Date()
                    let formatter1 = DateFormatter()
                        formatter1.dateFormat = "MM/dd/yyyy"
                    let dateFormatted = formatter1.string(from: today)
                    hoursToBeStored.date = dateFormatted
                    }
                    }
                }
                else {
                    
                    if userDefaults.value(forKey: "historyEnabled") as! Int == 0 {
                        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
                        
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
                    let today = Date()
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
                    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
                    
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
                
                    let today = Date()
                let formatter1 = DateFormatter()
                    formatter1.dateFormat = "MM/dd/yyyy"
                let dateFormatted = formatter1.string(from: today)
                hoursToBeStored.date = dateFormatted
                    }
                }
            }
            else {
                
                if userDefaults.integer(forKey: "historyEnabled") == 0 {
                    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
                    
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
                //hoursToBeStored.date = Date()
                let today = Date()
                let formatter1 = DateFormatter()
                formatter1.dateFormat = "MM/dd/yyyy"
                let dateFormatted = formatter1.string(from: today)
                hoursToBeStored.date = dateFormatted
                }
            }
        }
        
        print(userDefaults.integer(forKey: "historyEnabled"))
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
