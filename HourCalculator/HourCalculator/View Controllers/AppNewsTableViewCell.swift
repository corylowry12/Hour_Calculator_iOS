//
//  AppNewsTableViewCell.swift
//  HourCalculator
//
//  Created by Cory Lowry on 3/26/22.
//

import Foundation
import UIKit

class AppNewsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
}
