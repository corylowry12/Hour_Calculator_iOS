//
//  EditViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 6/25/21.
//

import UIKit

class EditViewController: UIViewController {
    
    
    @IBOutlet weak var datePickerInTime: UIDatePicker!
    @IBOutlet weak var datePickerOutTime: UIDatePicker!
    
    @IBOutlet weak var dateLabel: UILabel!
    var data : Int!
    
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
        
        let defaults = UserDefaults.standard
        
        data = Int(defaults.string(forKey: "ID")!)!
        
        let hourItemStored = hourItems[data].inTime
        let hourItemStored2 = hourItems[data].outTime
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        let date = dateFormatter.date(from: hourItemStored!)
        let dateOut = dateFormatter.date(from: hourItemStored2!)
        
        datePickerInTime.date = date!
        datePickerOutTime.date = dateOut!
        
    }
    
    var inHour : Int = 0
    var inMinute : Int = 0
    
    @IBAction func inTimeValueChanged(_ sender: Any) {
        
        let date = datePickerInTime.date
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        
        inHour = components.hour!
        inMinute = components.minute!
        
    }
    
    var outHour : Int = 0
    var outMinute : Int = 0
    
    @IBAction func outTimeValueChanged(_ sender: Any) {
        
        let outDate = datePickerOutTime.date
        let componentsOut = Calendar.current.dateComponents([.hour, .minute], from: outDate)
        outHour = componentsOut.hour!
        outMinute = componentsOut.minute!
    }
    @IBAction func saveButtonClicked(_ sender: Any) {
        
        let date = datePickerInTime.date
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
                
                //let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
                
                let hoursToBeStored = hourItems[data]
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "hh:mm a"
                let inTimeDate = dateFormatter.string(from: datePickerInTime.date)
                let outTimeDate = dateFormatter.string(from: datePickerOutTime.date)
                
                let inTime = inTimeDate
                let outTime = outTimeDate
                
                hoursToBeStored.inTime = inTime
                hoursToBeStored.outTime = outTime
                hoursToBeStored.totalHours = "\(hours).\(minutes)"
                hoursToBeStored.date = hourItems[data].date
            }
        }
            else {
                let minutesDecimal : Double = Double(minutesDifference) / 60.00
                let minutesRounded = round(minutesDecimal * 100) / 100.00
                let minutesFormatted = String(minutesRounded).dropFirst(2)
            
                dateLabel.text = "Total Hours: \(hoursDifference).\(minutesFormatted)"
                
                let hoursToBeStored = hourItems[data]
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "hh:mm a"
                let inTimeDate = dateFormatter.string(from: datePickerInTime.date)
                let outTimeDate = dateFormatter.string(from: datePickerOutTime.date)
                
                let inTime = inTimeDate
                let outTime = outTimeDate
                
                hoursToBeStored.inTime = inTime
                hoursToBeStored.outTime = outTime
                hoursToBeStored.totalHours = "\(hoursDifference).\(minutesFormatted)"
              
                hoursToBeStored.date = hourItems[data].date
            }
        
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
        
    }
        
        
    @IBAction func cancelButtonClicked(_ sender: Any) {
        
        self.dismiss(animated: true, completion: nil)
        let notificationName = NSNotification.Name("Update")
        NotificationCenter.default.post(name: notificationName, object: nil)
    }
}

