//
//  TimeCardInfoTableViewCell.swift
//  HourCalculator
//
//  Created by Cory Lowry on 8/6/21.
//

import Foundation
import UIKit

class TimeCardInfoTableViewCell : UITableViewCell {
    
    @IBOutlet weak var inTimeLabel: UILabel!
    @IBOutlet weak var outTimeLabel: UILabel!
    @IBOutlet weak var totalHoursLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
}
