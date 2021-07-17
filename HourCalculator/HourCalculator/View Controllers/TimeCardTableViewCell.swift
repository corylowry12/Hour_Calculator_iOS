//
//  TimeCardTableViewCell.swift
//  HourCalculator
//
//  Created by Cory Lowry on 7/8/21.
//

import Foundation
import UIKit

class TimeCardTableViewCell : UITableViewCell {
    
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var inTimeLabel: UILabel!
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
}
