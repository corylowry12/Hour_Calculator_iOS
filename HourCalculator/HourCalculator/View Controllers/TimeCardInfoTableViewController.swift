//
//  TimeCardInfoTableViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 8/6/21.
//

import Foundation
import UIKit
import CoreData
import GoogleMobileAds

class TimeCardInfoTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    lazy var bannerView: GADBannerView! = GADBannerView(adSize: kGADAdSizeBanner)
    
    @IBOutlet weak var totalHoursLabel: UILabel!
    @IBOutlet weak var weekOfLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    let userDefaults = UserDefaults.standard
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var timeCards: [TimeCards] {
        
        do {
            var sort = NSSortDescriptor(key: #keyPath(TimeCards.week), ascending: false)
            let fetchrequest = NSFetchRequest<TimeCards>(entityName: "TimeCards")
            if userDefaults.integer(forKey: "timeCardsSort") == 0 {
                sort = NSSortDescriptor(key: #keyPath(TimeCards.week), ascending: false)
            }
            else if userDefaults.integer(forKey: "timeCardsSort") == 1 {
                sort = NSSortDescriptor(key: #keyPath(TimeCards.week), ascending: true)
            }
            else if userDefaults.integer(forKey: "timeCardsSort") == 2 {
                sort = NSSortDescriptor(key: #keyPath(TimeCards.total), ascending: true)
            }
            else if userDefaults.integer(forKey: "timeCardsSort") == 3 {
                sort = NSSortDescriptor(key: #keyPath(TimeCards.total), ascending: false)
            }
            else if userDefaults.integer(forKey: "timeCardsSort") == 4 {
                sort = NSSortDescriptor(key: #keyPath(TimeCards.name), ascending: true)
            }
            else if userDefaults.integer(forKey: "timeCardsSort") == 5 {
                sort = NSSortDescriptor(key: #keyPath(TimeCards.name), ascending: false)
            }
            fetchrequest.sortDescriptors = [sort]
            return try context.fetch(fetchrequest)
            
        } catch {
            
            print("Couldn't fetch data")
            
        }
        
        return [TimeCards]()
        
    }
    
    var timeCard: [TimeCardInfo] {
        
        do {
            let fetchrequest = NSFetchRequest<TimeCardInfo>(entityName: "TimeCardInfo")
            let predicate = userDefaults.value(forKey: "id")
            fetchrequest.predicate = NSPredicate(format: "id_number == %@", predicate as! CVarArg)
            let sort = NSSortDescriptor(key: #keyPath(TimeCardInfo.date), ascending: false)
            fetchrequest.sortDescriptors = [sort]
            
            return try context.fetch(fetchrequest)
            
        } catch {
            
            print("Couldn't fetch data")
            
        }
        
        return [TimeCardInfo]()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        textField.delegate = self
        
        addBannerViewToView(bannerView)
        
        bannerView.adUnitID = "ca-app-pub-4546055219731501/2396708566"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if userDefaults.string(forKey: "name") == nil || userDefaults.string(forKey: "name")?.trimmingCharacters(in: .whitespaces) == "" ||  userDefaults.string(forKey: "name") == "Unknown" {
            textField.text = "Unknown"
            self.navigationItem.title = "Time Card Info"
        }
        else {
            textField.text = userDefaults.string(forKey: "name")
            self.navigationItem.title = userDefaults.string(forKey: "name")
        }
        let total = round(Double(userDefaults.string(forKey: "total")!)! * 100.0) / 100.0
        totalHoursLabel.text = "Total Hours: \(total)"
        if timeCards[userDefaults.value(forKey: "index") as! Int].numberBeingExported == 1 {
            weekOfLabel.text = "Day Of: \(userDefaults.string(forKey: "week") ?? "Unknown")"
        }
        else {
            weekOfLabel.text = "Week Of: \(userDefaults.string(forKey: "week") ?? "Unknown")"
        }
        
        textField.clearButtonMode = .always
        textField.autocapitalizationType = .words
        textField.autocorrectionType = .no
        
        if userDefaults.integer(forKey: "accent") == 0 {
            textField.backgroundColor = UIColor(rgb: 0x26A69A)
        }
        else if userDefaults.integer(forKey: "accent") == 1 {
            textField.backgroundColor = UIColor(rgb: 0x7841c4)
        }
        else if userDefaults.integer(forKey: "accent") == 2 {
            textField.backgroundColor = UIColor(rgb: 0x347deb)
            
        }
        else if userDefaults.integer(forKey: "accent") == 3 {
            textField.backgroundColor = UIColor(rgb: 0xfc783a)
        }
        else if userDefaults.integer(forKey: "accent") == 4 {
            textField.backgroundColor = UIColor(rgb: 0xc41d1d)
        }
        textField.tintColor = UIColor.systemGray2
        view.backgroundColor = tableView.backgroundColor
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return timeCard.count
    }
    
    private var finishedLoadingInitialTableCells = false
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        DispatchQueue.main.async { [self] in
            
            var lastInitialDisplayableCell = false
            
            //change flag as soon as last displayable cell is being loaded (which will mean table has initially loaded)
            if timeCards.count > 0 && !finishedLoadingInitialTableCells {
                if let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows,
                   let lastIndexPath = indexPathsForVisibleRows.last, lastIndexPath.row == indexPath.row {
                    lastInitialDisplayableCell = true
                }
            }
            
            if !finishedLoadingInitialTableCells {
                
                if lastInitialDisplayableCell {
                    finishedLoadingInitialTableCells = true
                }
                
                //animates the cell as it is being displayed for the first time
                cell.transform = CGAffineTransform(translationX: 0, y: tableView.rowHeight/2)
                cell.alpha = 0
                
                UIView.animate(withDuration: 1.0, delay: 0.0, options: [.transitionCrossDissolve], animations: {
                    cell.transform = CGAffineTransform(translationX: 0, y: 0)
                    cell.alpha = 1
                }, completion: nil)
            }
        }
    }
    
    @IBAction func textFieldClose(_ sender: UITextField) {
        if sender.text != "" && sender.text != nil {
            timeCards[userDefaults.integer(forKey: "index")].name = sender.text?.trimmingCharacters(in: .whitespaces)
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
        }
        else if sender.text?.trimmingCharacters(in: .whitespaces) == ""{
            timeCards[userDefaults.integer(forKey: "index")].name = nil
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
        }
        
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let hourItems = timeCard[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "timeCardCell", for: indexPath) as! TimeCardInfoTableViewCell
        //DispatchQueue.main.async {
        let inTime = hourItems.intime
        let outTime = hourItems.outtime
        let totalHours = hourItems.total_hours
        let date = hourItems.date!
        
        
        cell.inTimeLabel.text = "In Time: \(inTime ?? "Unknown")"
        cell.outTimeLabel.text = "Out Time: \(outTime ?? "Unknown")"
        cell.totalHoursLabel.text = "Total Hours: \(totalHours ?? "Unknown")"
        cell.dateLabel.text = "Date: \(date)"
        //}
        return cell
    }
    @IBAction func textFieldTextChanged(_ sender: UITextField) {
        
        if sender.text != "" && sender.text != nil {
            timeCards[userDefaults.integer(forKey: "index")].name = sender.text
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
        }
        else if sender.text?.trimmingCharacters(in: .whitespaces) == ""{
            timeCards[userDefaults.integer(forKey: "index")].name = nil
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
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
