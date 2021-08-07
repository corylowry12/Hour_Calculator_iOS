//
//  TimeCardInfoTableViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 8/6/21.
//

import Foundation
import UIKit
import CoreData

class TimeCardInfoTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
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
            print("sort mode: \(userDefaults.integer(forKey: "timeCardsSort"))")
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
        //print(timeCard.count)
        tableView.delegate = self
        tableView.dataSource = self
        
        textField.delegate = self
        
        //let timecardinfo = TimeCardInfo(context: context)
        //print(timecardinfo.id_number)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if userDefaults.string(forKey: "name") == nil || userDefaults.string(forKey: "name")?.trimmingCharacters(in: .whitespaces) == "" {
            textField.text = "Unknown"
            self.navigationItem.title = "Time Card Info"
        }
        else {
            textField.text = userDefaults.string(forKey: "name")
            self.navigationItem.title = userDefaults.string(forKey: "name")
        }
        
        totalHoursLabel.text = "Total Hours: \(userDefaults.string(forKey: "total") ?? "Unknown")"
        weekOfLabel.text = "Week Of: \(userDefaults.string(forKey: "week") ?? "Unknown")"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("count: \(timeCard.count)")
        return timeCard.count
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
        
        if sender.text != "" || sender.text != nil {
        timeCards[userDefaults.integer(forKey: "index")].name = sender.text
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        }
        else if sender.text?.trimmingCharacters(in: .whitespaces) == ""{
            timeCards[userDefaults.integer(forKey: "index")].name = "Unknown"
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
        }
    }
    @IBAction func textFieldValueChanged(_ sender: UITextField) {
        
        if sender.text != "" || sender.text != nil {
        timeCards[userDefaults.integer(forKey: "index")].name = sender.text
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        }
        else if sender.text?.trimmingCharacters(in: .whitespaces) == ""{
            timeCards[userDefaults.integer(forKey: "index")].name = "Unknown"
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
            return false
    }
}
