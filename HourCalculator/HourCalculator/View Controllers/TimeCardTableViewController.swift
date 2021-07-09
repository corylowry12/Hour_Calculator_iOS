//
//  TimeCardTableViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 7/8/21.
//

import Foundation
import UIKit
import CoreData

class TimeCardTableViewController: UITableViewController {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let userDefaults = UserDefaults.standard
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
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
