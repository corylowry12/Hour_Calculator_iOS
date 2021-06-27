//
//  TableViewCell.swift
//  HourCalculator
//
//  Created by Cory Lowry on 6/24/21.
//

import UIKit

class TableViewCell: UITableViewCell {

    @IBOutlet weak var inTimeLabel: UILabel!
    
    @IBOutlet weak var outTimeLabel: UILabel!
    
    @IBOutlet weak var totalHoursLabel: UILabel!
    
    @IBOutlet weak var dateLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
