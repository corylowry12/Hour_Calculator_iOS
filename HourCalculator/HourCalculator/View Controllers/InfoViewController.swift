//
//  InfoViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 6/25/21.
//

import UIKit
import GoogleMobileAds
import CoreData
import MediaPlayer
import Instabug

class InfoViewController: UIViewController {
    
    private let notificationCenter = NotificationCenter.default
    
    @IBOutlet weak var amountOfHoursStoredLabel: UILabel!
    
    @IBOutlet weak var totalHoursStoredLabel: UILabel!
    
    let things = DispatchQueue.self
    
    var total : Double = 0.0
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var hourItems: [Hours] {
        
        do {
            
            return try context.fetch(Hours.fetchRequest())
            
        } catch {
            
            print("Couldn't fetch data")
            
        }
        
        return [Hours]()
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        BugReporting.enabled = true
        
        if hourItems.count >= 5 {
            DispatchQueue.main.async {
                self.amountOfHoursStoredLabel.text = "Number of hours stored: \( UserDefaults.standard.string(forKey: "hourNum") ?? "")"
                
                self.totalHoursStoredLabel.text = "Total Hours: \( UserDefaults.standard.string(forKey: "TotalHours") ?? "")"
                let alert = UIAlertController(title: nil, message: "Please Wait...", preferredStyle: .alert)
                alert.view.tintColor = UIColor.black
                let loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50)) as UIActivityIndicatorView
                loadingIndicator.hidesWhenStopped = true
                loadingIndicator.startAnimating()
                alert.view.addSubview(loadingIndicator)
                self.present(alert, animated: true, completion: self.calculate)
                
            }
        }
        else {
            calculate()
        }
    }
    @IBAction func doneButtonTapped(_ sender: Any) {
        
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func calculate() {
        //print("test")
        let hoursCount = String(hourItems.count)
        var rounded = 0.0
        
        self.amountOfHoursStoredLabel.text = "Number of hours stored: \(hoursCount)"
        
        let count = hourItems.count - 1
        
        total = 0.0
        do {
            if hourItems.count > 0 {
                for n in 0...count {
                    total += Double(hourItems[n].totalHours!)!
                    rounded = round(total * 100) / 100.00
                    self.totalHoursStoredLabel.text = "Total Hours: \(rounded)"
                }
            }
            else {
                self.totalHoursStoredLabel.text = "Total Hours: 0"
            }
            if hourItems.count >= 5 {
                
                let defaults = UserDefaults.standard
                defaults.set("\(hourItems.count)", forKey: "hourNum")
                let defaults2 = UserDefaults.standard
                defaults2.set("\(rounded)", forKey: "TotalHours")
                self.dismiss(animated: true, completion: nil)
            }
        }
        catch {
            let alert = UIAlertController(title: "There was an error", message: "Please try again or try deleting hours", preferredStyle: .alert)
            alert.view.tintColor = UIColor.black
            alert.addAction(UIAlertAction(title: "OK", style: .destructive, handler: nil))
            self.dismiss(animated: true, completion: nil)
            self.present(alert, animated: true, completion: nil)
        }
    }
}
