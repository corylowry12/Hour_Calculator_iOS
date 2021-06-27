//
//  SettingsTableViewCell.swift
//  HourCalculator
//
//  Created by Cory Lowry on 6/26/21.
//

import UIKit

class SettingsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var hourSwitch : UISwitch?
    
    @IBAction func onHourSwitchChanged(_ sender: UISwitch) {
        
        let userDefaults = UserDefaults.standard
        userDefaults.set(sender.isOn, forKey: "StoredEmptyHours")
        
        //let storedValue = userDefaults.bool(forKey: "StoredEmptyHours")
        
        print(userDefaults.bool(forKey: "StoredEmptyHours"))
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        let storedValue = UserDefaults.standard.bool(forKey: "StoredEmptyHours")

        hourSwitch?.isOn = storedValue
        
        // Configure the view for the selected state
    }
    
}
