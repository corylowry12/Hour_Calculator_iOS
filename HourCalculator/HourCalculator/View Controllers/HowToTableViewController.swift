//
//  HowToTableViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 7/4/21.
//

import UIKit
import Instabug

class HowToTableViewController: UITableViewController {
    
    @IBOutlet weak var howToEnterTimeLabel: UILabel!
    @IBOutlet weak var howToDeleteHoursLabel: UILabel!
    @IBOutlet weak var howToViewTotalLabel: UILabel!
    @IBOutlet weak var howToUndoHourDeletionLabel: UILabel!
    @IBOutlet weak var howToStoreHoursInTimeCards: UILabel!
    @IBOutlet weak var howToReportABugLabel: UILabel!
    
    let userDefaults = UserDefaults.standard
    override func viewDidLoad() {
        super.viewDidLoad()
        
       
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        BugReporting.enabled = true
        
        if userDefaults.integer(forKey: "accent") == 0 {
            howToEnterTimeLabel.textColor = UIColor(rgb: 0x26A69A)
            howToDeleteHoursLabel.textColor = UIColor(rgb: 0x26A69A)
            howToViewTotalLabel.textColor = UIColor(rgb: 0x26A69A)
            howToUndoHourDeletionLabel.textColor = UIColor(rgb: 0x26A69A)
            howToStoreHoursInTimeCards.textColor = UIColor(rgb: 0x26A69A)
            howToReportABugLabel.textColor = UIColor(rgb: 0x26A69A)
        }
        else if userDefaults.integer(forKey: "accent") == 1 {
            howToEnterTimeLabel.textColor =
                UIColor(rgb: 0x7841c4)
            howToDeleteHoursLabel.textColor = UIColor(rgb: 0x7841c4)
            howToViewTotalLabel.textColor = UIColor(rgb: 0x7841c4)
            howToUndoHourDeletionLabel.textColor = UIColor(rgb: 0x7841c4)
            howToStoreHoursInTimeCards.textColor = UIColor(rgb: 0x7841c4)
            howToReportABugLabel.textColor = UIColor(rgb: 0x7841c4)
        }
        else if userDefaults.integer(forKey: "accent") == 2 {
            howToEnterTimeLabel.textColor =
                UIColor(rgb: 0x347deb)
            howToDeleteHoursLabel.textColor = UIColor(rgb: 0x347deb)
            howToViewTotalLabel.textColor = UIColor(rgb: 0x347deb)
            howToUndoHourDeletionLabel.textColor = UIColor(rgb: 0x347deb)
            howToStoreHoursInTimeCards.textColor = UIColor(rgb: 0x347deb)
            howToReportABugLabel.textColor = UIColor(rgb: 0x347deb)
        }
        else if userDefaults.integer(forKey: "accent") == 3 {
            howToEnterTimeLabel.textColor =
                UIColor(rgb: 0xfc783a)
            howToDeleteHoursLabel.textColor = UIColor(rgb: 0xfc783a)
            howToViewTotalLabel.textColor = UIColor(rgb: 0xfc783a)
            howToUndoHourDeletionLabel.textColor = UIColor(rgb: 0xfc783a)
            howToStoreHoursInTimeCards.textColor = UIColor(rgb: 0xfc783a)
            howToReportABugLabel.textColor = UIColor(rgb: 0xfc783a)
        }
        else if userDefaults.integer(forKey: "accent") == 4 {
            howToEnterTimeLabel.textColor = UIColor(rgb: 0xc41d1d)
            howToDeleteHoursLabel.textColor = UIColor(rgb: 0xc41d1d)
            howToViewTotalLabel.textColor = UIColor(rgb: 0xc41d1d)
            howToUndoHourDeletionLabel.textColor = UIColor(rgb: 0xc41d1d)
            howToStoreHoursInTimeCards.textColor = UIColor(rgb: 0xc41d1d)
            howToReportABugLabel.textColor = UIColor(rgb: 0xc41d1d)
        }
    }
    
    @objc func tapFunction(sender: UITapGestureRecognizer) {
        print("tap working")
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath == [0, 0] {
            let index = IndexPath(row: NSNotFound, section: 1)
            tableView.scrollToRow(at: index, at: .top, animated: true)
        }
        else if indexPath == [0, 1] {
            let index = IndexPath(row: NSNotFound, section: 2)
            tableView.scrollToRow(at: index, at: .top, animated: true)
        }
        else if indexPath == [0, 2] {
            let index = IndexPath(row: NSNotFound, section: 3)
            tableView.scrollToRow(at: index, at: .top, animated: true)
        }
        else if indexPath == [0, 3] {
            let index = IndexPath(row: NSNotFound, section: 4)
            tableView.scrollToRow(at: index, at: .top, animated: true)
        }
        else if indexPath == [0, 4] {
            let index = IndexPath(row: NSNotFound, section: 5)
            tableView.scrollToRow(at: index, at: .top, animated: true)
        }
        else if indexPath == [0, 5] {
            let index = IndexPath(row: NSNotFound, section: 6)
            tableView.scrollToRow(at: index, at: .top, animated: true)
        }
    }
}
