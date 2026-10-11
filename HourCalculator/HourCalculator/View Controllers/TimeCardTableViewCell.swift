//
//  TimeCardTableViewCell.swift
//  HourCalculator
//
//  Created by Cory Lowry on 7/8/21.
//

import Foundation
import UIKit

class TimeCardTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var inTimeLabel: UILabel!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        thumbnailImageView?.layer.cornerRadius = 8
        thumbnailImageView?.layer.masksToBounds = true
        thumbnailImageView?.layer.borderWidth = 0.5
        thumbnailImageView?.layer.borderColor = UIColor.separator.cgColor
        thumbnailImageView?.contentMode = .scaleAspectFill
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView?.image = nil
        thumbnailImageView?.isHidden = true
    }
}
