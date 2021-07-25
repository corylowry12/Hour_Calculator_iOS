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

class TimeCardTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var sortButton: UIButton!
    
    @IBOutlet var tableView: UITableView!
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let userDefaults = UserDefaults.standard
    
    var undo : Int = 0
    
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
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
        noHoursStoredBackground()
        BugReporting.enabled = false
        self.becomeFirstResponder()
        
        if timeCards.count == 0 {
            sortButton.isHidden = true
            
    
        }
        else {
            sortButton.isHidden = false
            sortButton.alpha = 0
            
            UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseInOut], animations: {
                self.sortButton.alpha = 1.0
            }, completion: {_ in
              
            })
        }
        
        if userDefaults.integer(forKey: "accent") == 0 {
            sortButton.backgroundColor = UIColor(rgb: 0x26A69A)
        }
        else if userDefaults.integer(forKey: "accent") == 1 {
            sortButton.backgroundColor = UIColor(rgb: 0x7841c4)
        
        }
        else if userDefaults.integer(forKey: "accent") == 2 {
            sortButton.backgroundColor = UIColor(rgb: 0x347deb)
        }
        else if userDefaults.integer(forKey: "accent") == 3 {
            sortButton.backgroundColor = UIColor(rgb: 0xfc783a)
        }
        else if userDefaults.integer(forKey: "accent") == 4 {
            sortButton.backgroundColor = UIColor(rgb: 0xc41d1d)
        }
    
        if userDefaults.integer(forKey: "timeCardsSort") == 0 {
            sortButton.setTitle("Sort: Date Descending", for: .normal)
        }
        else if userDefaults.integer(forKey: "timeCardsSort") == 1 {
            sortButton.setTitle("Sort: Date Ascending", for: .normal)
        }
        else if userDefaults.integer(forKey: "timeCardsSort") == 2 {
            sortButton.setTitle("Sort: Total Hours Ascending", for: .normal)
        }
        else if userDefaults.integer(forKey: "timeCardsSort") == 3 {
            sortButton.setTitle("Sort: Total Hours Descending", for: .normal)
        }
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
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    private var finishedLoadingInitialTableCells = false

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {

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

            UIView.animate(withDuration: 0.5, delay: 0.05*Double(indexPath.row), options: [.curveEaseInOut], animations: {
                cell.transform = CGAffineTransform(translationX: 0, y: 0)
                cell.alpha = 1
            }, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            let hourToDelete = self.timeCards[indexPath.row]
            self.context.delete(hourToDelete)
            
            self.tableView.deleteRows(at: [indexPath], with: .fade)
            noHoursStoredBackground()
            undo = 1
            if timeCards.count == 0 {
                sortButton.alpha = 1
                UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseInOut], animations: {
                    self.sortButton.alpha = 0
                }, completion: {_ in
                    self.sortButton.isHidden = true
                })
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return timeCards.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let timeCards = timeCards[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "timeCard", for: indexPath) as! TimeCardTableViewCell
        
        let round = round(timeCards.total * 100) / 100.00
        let inTime = timeCards.week
        let total = round
        
        cell.inTimeLabel.text = "Week Of: \(inTime ?? "Unknown")"
        cell.totalLabel.text = "Total Hours: \(total)"
        
        return cell
    }
    
    @IBAction func sortButton(_ sender: UIButton) {
        UIButton.animate(withDuration: 0.05,
                         animations: {
                            sender.transform = CGAffineTransform(scaleX: 0.975, y: 0.96)
                         },
                         completion: { finish in
                            UIButton.animate(withDuration: 0.05, animations: {
                                sender.transform = CGAffineTransform.identity
                            })
                         })
        if userDefaults.integer(forKey: "timeCardsSort") == 0 {
            sender.setTitle("Sort: Date Ascending", for: .normal)
            userDefaults.set(1, forKey: "timeCardsSort")
        }
        else if userDefaults.integer(forKey: "timeCardsSort") == 1 {
            sender.setTitle("Sort: Total Hours Ascending", for: .normal)
            userDefaults.set(2, forKey: "timeCardsSort")
        }
        else if userDefaults.integer(forKey: "timeCardsSort") == 2 {
            sender.setTitle("Sort: Total Hours Descending", for: .normal)
            userDefaults.set(3, forKey: "timeCardsSort")
        }
        else if userDefaults.integer(forKey: "timeCardsSort") == 3 {
            sender.setTitle("Sort: Date Descending", for: .normal)
            userDefaults.set(0, forKey: "timeCardsSort")
        }
        
        UIView.transition(with: tableView,
                                  duration: 0.35,
                                  options: .transitionCrossDissolve,
                                  animations: { () -> Void in
                                    self.tableView.reloadData()
                                  },
                                  completion: nil);
    }
}
