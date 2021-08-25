//
//  GalleryCollectionViewCell.swift
//  HourCalculator
//
//  Created by Cory Lowry on 8/23/21.
//

import UIKit

class GalleryCollectionViewCell : UICollectionViewCell {
    
    @IBOutlet weak var galleryImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var holder_view: UIView!
    @IBOutlet weak var checkMark: UIImageView!
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        galleryImage.frame.origin.x = 0
        holder_view.frame.origin.x = 0
        super.prepareForReuse()
    }
}
