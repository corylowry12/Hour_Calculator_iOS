//
//  InfoViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 6/25/21.
//

import UIKit
import GoogleMobileAds
import CoreData

class InfoViewController: UIViewController {
    
    @IBOutlet weak var amountOfHoursStoredLabel: UILabel!
    
    @IBOutlet weak var totalHoursStoredLabel: UILabel!
    
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
        
       let hoursCount = String(hourItems.count)
        
        amountOfHoursStoredLabel.text = "Number of hours stored: \(hoursCount)"
        
        let count = hourItems.count - 1
        
        total = 0.0
        
        if hourItems.count > 0 {
        for n in 0...count {
            total += Double(hourItems[n].totalHours!)!
            let rounded = round(total * 100) / 100.00
            totalHoursStoredLabel.text = "Total Hours: \(rounded)"
        }
        }
        else {
            totalHoursStoredLabel.text = "Total Hours: 0"
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        let count = hourItems.count - 1
        
        total = 0.0
        
        if hourItems.count > 0 {
        for n in 0...count {
            total += Double(hourItems[n].totalHours!)!
            let rounded = round(total * 100) / 100.00
            totalHoursStoredLabel.text = "Total Hours: \(rounded)"
        }
        }
        else {
            totalHoursStoredLabel.text = "Total Hours: 0"
        }
    }
    @IBAction func doneButtonTapped(_ sender: Any) {
        
        self.dismiss(animated: true, completion: nil)
    }
}
