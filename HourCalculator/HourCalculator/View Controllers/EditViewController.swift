//
//  EditViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 6/25/21.
//

import UIKit
import CoreData
import Instabug

class EditViewController: UIViewController {
    
    
    @IBOutlet weak var datePickerInTime: UIDatePicker!
    @IBOutlet weak var datePickerOutTime: UIDatePicker!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet var saveButton: UIButton!
    
    @IBOutlet var DatePicker: UIDatePicker!
    @IBOutlet weak var dateLabel: UILabel!
    var data : Int!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    let userDefaults = UserDefaults.standard
    
    var didUpdateInTime: Bool = true
    var didUpdateOutTime: Bool = true
    var didUpdateDate: Bool = true
    
    var hourItems: [Hours] {
        
        do {
            var sort = NSSortDescriptor(key: #keyPath(Hours.date), ascending: false)
            let fetchrequest = NSFetchRequest<Hours>(entityName: "Hours")
            if userDefaults.integer(forKey: "historySort") == 0 {
                sort = NSSortDescriptor(key: #keyPath(Hours.date), ascending: false)
            }
            else if userDefaults.integer(forKey: "historySort") == 1 {
                sort = NSSortDescriptor(key: #keyPath(Hours.date), ascending: true)
            }
            else if userDefaults.integer(forKey: "historySort") == 2 {
                sort = NSSortDescriptor(key: #keyPath(Hours.totalHours), ascending: true)
            }
            else if userDefaults.integer(forKey: "historySort") == 3 {
                sort = NSSortDescriptor(key: #keyPath(Hours.totalHours), ascending: false)
            }
            fetchrequest.sortDescriptors = [sort]
            return try context.fetch(fetchrequest)
            
        } catch {
            
            print("Couldn't fetch data")
            
        }
        
        return [Hours]()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        //DatePicker.sizeToFit()
        //DatePicker.clipsToBounds = true
        
        BugReporting.enabled = true
        
        if userDefaults.integer(forKey: "accent") == 0 {
            saveButton.backgroundColor = UIColor(rgb: 0x26A69A)
        }
        else if userDefaults.integer(forKey: "accent") == 1 {
            saveButton.backgroundColor = UIColor(rgb: 0x7841c4)
        }
        else if userDefaults.integer(forKey: "accent") == 2 {
            saveButton.backgroundColor = UIColor(rgb: 0x347deb)
        }
        else if userDefaults.integer(forKey: "accent") == 3 {
            saveButton.backgroundColor = UIColor(rgb: 0xfc783a)
        }
        else if userDefaults.integer(forKey: "accent") == 4 {
            saveButton.backgroundColor = UIColor(rgb: 0xc41d1d)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //let id = Hours(context: context).objectID
        //print(id)
        
        let os = ProcessInfo().operatingSystemVersion
        
        switch (os.majorVersion, os.minorVersion, os.patchVersion) {
        case (let x, _, _) where x < 14: do {
            DatePicker.isHidden = true
        }
        default: do {
            DatePicker.isHidden = false
        }
        }
        
        DatePicker.maximumDate = Date()
        
        let defaults = UserDefaults.standard
        
        data = Int(defaults.string(forKey: "ID")!)!
        
        //print(data)
        
        let hourItemStored = hourItems[data].inTime
        let hourItemStored2 = hourItems[data].outTime
        let dateTaken = hourItems[data].date
        //print("date2 \(dateTaken)")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        let dateFormatterForDateTaken = DateFormatter()
        dateFormatterForDateTaken.dateFormat = "MM/dd/yyyy"
        let date = dateFormatter.date(from: hourItemStored!)
        let dateOut = dateFormatter.date(from: hourItemStored2!)
        let dateEntered = dateFormatterForDateTaken.date(from: dateTaken!)
        
        do {
            datePickerInTime.date = date!
            datePickerOutTime.date = dateOut!
            
            if dateEntered == nil {
                print("there was an error")
                self.dismiss(animated: true, completion: nil)
                let alert = UIAlertController(title: "Error", message: "There was an error. Please try again or delete the hour you're trying to edit and re-enter it", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil ))
                self.present(alert, animated: true, completion: nil)
            }
            else {
                DatePicker.date = dateEntered!
            }
            
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver("Update")
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    }
    
    var inHour : Int = 0
    var inMinute : Int = 0
    
    @IBAction func dateChanged(_ sender: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        let date = dateFormatter.string(from: sender.date)
        if date == hourItems[data].date {
            didUpdateDate = true
        }
        else {
        didUpdateDate = false
        }
    }
    @IBAction func inTimeValueChanged(_ sender: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        let inTimeDate = dateFormatter.string(from: sender.date)
        if inTimeDate == hourItems[data].inTime {
            didUpdateInTime = true
        }
        else {
        didUpdateInTime = false
        }
        let date = datePickerInTime.date
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        
        inHour = components.hour!
        inMinute = components.minute!
        
    }
    
    var outHour : Int = 0
    var outMinute : Int = 0
    
    @IBAction func outTimeValueChanged(_ sender: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        let outTimeDate = dateFormatter.string(from: sender.date)
        if outTimeDate == hourItems[data].outTime {
            didUpdateOutTime = true
        }
        else {
        didUpdateOutTime = false
        }
        let outDate = datePickerOutTime.date
        let componentsOut = Calendar.current.dateComponents([.hour, .minute], from: outDate)
        outHour = componentsOut.hour!
        outMinute = componentsOut.minute!
    }
    @IBAction func saveButtonClicked(_ sender: Any) {
        
        if didUpdateDate == false || didUpdateOutTime == false || didUpdateDate == false {
        //save()
            let date = datePickerInTime.date
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            
            inHour = components.hour!
            inMinute = components.minute!
            
            let outDate = datePickerOutTime.date
            let componentsOut = Calendar.current.dateComponents([.hour, .minute], from: outDate)
            
            outHour = componentsOut.hour!
            outMinute = componentsOut.minute!
            
            //let minutesDifference = outMinute - inMinute
            let hoursDifference = outHour - inHour
            
            if hoursDifference < 0 && (12...24).contains(inHour) && (0...12).contains(outHour){
                    self.PMtoAM()
            }
            else {
                    self.save()
                
            }
        }
        else {
            dateLabel.text = "Can Not Save, No Values Were Changed"
        }
    }
    
    @IBAction func cancelButtonClicked(_ sender: Any) {
        if didUpdateInTime == false ||
            didUpdateOutTime == false ||
            didUpdateDate == false {
            let alert = UIAlertController(title: "Pending Changes", message: "You are trying to leave with pending changes. Would you like to save?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {_ in
                self.save()
                self.dismiss(animated: true, completion: nil)
                let notificationName = NSNotification.Name("Update")
                NotificationCenter.default.post(name: notificationName, object: nil)
            } ))
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { _ in
                self.dismiss(animated: true, completion: nil)
            }))
            
            self.present(alert, animated: true, completion: nil)
        } else {
            let userDefaults = UserDefaults.standard
            userDefaults.removeObject(forKey: "ID")
            self.dismiss(animated: true, completion: nil)
            let notificationName = NSNotification.Name("Update")
            NotificationCenter.default.post(name: notificationName, object: nil)
        }
    }
    
    @IBAction func deleteButtonTapped(_ sender: Any) {
        
        let hourToDelete = self.hourItems[data]
        
        let alert = UIAlertController(title: "Delete?", message: "Would you like to delete this hour?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {_ in
            self.context.delete(hourToDelete)
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
            //deleteButton.title = "\(hourToDelete)"
            let alert = UIAlertController(title: nil, message: "Entry Deleted   ✓", preferredStyle: .alert)
            alert.view.tintColor = UIColor.black
            self.present(alert, animated: true, completion: nil)
            let notificationName = NSNotification.Name("Update")
            NotificationCenter.default.post(name: notificationName, object: nil)
            let when = DispatchTime.now() + 1
            DispatchQueue.main.asyncAfter(deadline: when) {
                alert.dismiss(animated: true, completion: {
                    self.dismiss(animated: true, completion: nil)
                })
            }
        } ))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { _ in
                                        let alert = UIAlertController(title: nil, message: "Entry Not Deleted", preferredStyle: .alert)
                                        alert.view.tintColor = UIColor.black
                                        self.present(alert, animated: true, completion: nil)
                                        let notificationName = NSNotification.Name("Update")
                                        NotificationCenter.default.post(name: notificationName, object: nil)
                                        let when = DispatchTime.now() + 1
                                        DispatchQueue.main.asyncAfter(deadline: when) {
                                            alert.dismiss(animated: true, completion: {
                                                self.dismiss(animated: true, completion: nil)
                                            })
                                        }                                          }))
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func PMtoAM() {
        let date = datePickerInTime.date
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        
        inHour = components.hour!
        inMinute = components.minute!
        
        let outDate = datePickerOutTime.date
        let componentsOut = Calendar.current.dateComponents([.hour, .minute], from: outDate)
        
        outHour = componentsOut.hour!
        outMinute = componentsOut.minute!
        
        let minutesDifference = outMinute - inMinute
        let hoursDifference = outHour - inHour + 24
        
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
                
                let dateFormatterForDateTaken = DateFormatter()
                dateFormatterForDateTaken.dateFormat = "MM/dd/yyyy"
                let dateEntered = dateFormatterForDateTaken.string(from: DatePicker.date)
                
                let inTime = inTimeDate
                let outTime = outTimeDate
                
                hoursToBeStored.inTime = inTime
                hoursToBeStored.outTime = outTime
                hoursToBeStored.totalHours = "\(hours).\(minutes)"
                hoursToBeStored.date = dateEntered
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
            
            let dateFormatterForDateTaken = DateFormatter()
            dateFormatterForDateTaken.dateFormat = "MM/dd/yyyy"
            let dateEntered = dateFormatterForDateTaken.string(from: DatePicker.date)
            
            let inTime = inTimeDate
            let outTime = outTimeDate
            
            hoursToBeStored.inTime = inTime
            hoursToBeStored.outTime = outTime
            hoursToBeStored.totalHours = "\(hoursDifference).\(minutesFormatted)"
            
            hoursToBeStored.date = dateEntered
        }
        didUpdateInTime = true
        didUpdateOutTime = true
        didUpdateDate = true
    }
    
    func save() {
        
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
                
                //let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
                
                let hoursToBeStored = hourItems[data]
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "hh:mm a"
                let inTimeDate = dateFormatter.string(from: datePickerInTime.date)
                let outTimeDate = dateFormatter.string(from: datePickerOutTime.date)
                
                let dateFormatterForDateTaken = DateFormatter()
                dateFormatterForDateTaken.dateFormat = "MM/dd/yyyy"
                let dateEntered = dateFormatterForDateTaken.string(from: DatePicker.date)
                
                let inTime = inTimeDate
                let outTime = outTimeDate
                
                hoursToBeStored.inTime = inTime
                hoursToBeStored.outTime = outTime
                hoursToBeStored.totalHours = "\(hours).\(minutes)"
                hoursToBeStored.date = dateEntered
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
            
            let dateFormatterForDateTaken = DateFormatter()
            dateFormatterForDateTaken.dateFormat = "MM/dd/yyyy"
            let dateEntered = dateFormatterForDateTaken.string(from: DatePicker.date)
            
            let inTime = inTimeDate
            let outTime = outTimeDate
            
            hoursToBeStored.inTime = inTime
            hoursToBeStored.outTime = outTime
            hoursToBeStored.totalHours = "\(hoursDifference).\(minutesFormatted)"
            
            hoursToBeStored.date = dateEntered
        }
        didUpdateInTime = true
        didUpdateOutTime = true
        didUpdateDate = true
        //(UIApplication.shared.delegate as! AppDelegate).saveContext()
    }
}

