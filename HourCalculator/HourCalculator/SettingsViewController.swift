//
//  SettingsViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 6/24/21.
//

import UIKit

class SettingsViewController: UITableViewController {
    
    let userDefaults = UserDefaults.standard
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        
        tableView.tableFooterView = UIView()
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        self.performSegue(withIdentifier: "theme", sender: self)
        self.performSegue(withIdentifier: "patch", sender: self)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier:
             "hourCell", for: indexPath) as! SettingsTableViewCell
        
        cell.tag = indexPath.row
        
        
        
        print("\(userDefaults.bool(forKey: "StoredEmptyHour"))")
        
        return cell
    }
}
