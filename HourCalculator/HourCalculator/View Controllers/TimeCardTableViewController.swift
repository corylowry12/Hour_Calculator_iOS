//
//  TimeCardTableViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 7/8/21.
//

import Foundation
import UIKit
import CoreData
import Instabug

class TimeCardTableViewController: UITableViewController {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let userDefaults = UserDefaults.standard
    
    var undo : Int = 0
    
    var timeCards: [TimeCards] {
        
        do {
            let sort = NSSortDescriptor(key: #keyPath(TimeCards.week), ascending: false)
            let fetchrequest = NSFetchRequest<TimeCards>(entityName: "TimeCards")
            fetchrequest.sortDescriptors = [sort]
            return try context.fetch(fetchrequest)
            
        } catch {
            
            print("Couldn't fetch data")
            
        }
        
        return [TimeCards]()
        
    }
    
    override var canBecomeFirstResponder: Bool {
        get {
            return true
        }
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        print(undo)
        if motion == .motionShake {
            print(undo)
            if undo == 1 {
                BugReporting.dismiss()
                print("Why are you shaking me?")
                let alert = UIAlertController(title: "Undo", message: "Would you like to undo time card deletion?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [self]_ in
                    (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.rollback()
                    
                    UIView.transition(with: self.tableView, duration: 0.25, options: .transitionCrossDissolve, animations: {self.tableView.reloadData()}, completion: nil)
                    
                    noHoursStoredBackground()
                    
                    undo = 0
                    
                }))
                alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            else {
                BugReporting.enabled = true
                Instabug.show()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
        noHoursStoredBackground()
        BugReporting.enabled = false
        self.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        undo = 0
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    }
    
    func noHoursStoredBackground() {
        if timeCards.count == 0 {
            let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: accessibilityFrame.size.width, height: accessibilityFrame.size.height))
            messageLabel.text = "There are currently entries stored"
            messageLabel.textColor = .black
            messageLabel.numberOfLines = 0;
            messageLabel.textAlignment = .center;
            messageLabel.font = UIFont.systemFont(ofSize: 16.0, weight: UIFont.Weight.medium)
            messageLabel.sizeToFit()
            
            tableView.backgroundView = messageLabel;
            tableView.separatorStyle = .none;
        }
        else {
            tableView.backgroundView = nil
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            let hourToDelete = self.timeCards[indexPath.row]
            self.context.delete(hourToDelete)
            
            self.tableView.deleteRows(at: [indexPath], with: .fade)
            noHoursStoredBackground()
            undo = 1
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //performSegue(withIdentifier: "viewMore", sender: nil)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return timeCards.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let timeCards = timeCards[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "timeCard", for: indexPath) as! TimeCardTableViewCell
        
        let round = round(timeCards.total * 100) / 100.00
        let inTime = timeCards.week
        let total = round
        
        cell.inTimeLabel.text = "Week Of: \(inTime ?? "Unknown")"
        cell.totalLabel.text = "Total Hours: \(total)"
        
        return cell
    }
}
