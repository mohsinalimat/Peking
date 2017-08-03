//
//  PKAlbumViewCell.swift
//  Peking
//
//  Created by Meniny on 2015/11/14.
//  Copyright © 2015 Meniny. All rights reserved.
//

import UIKit
import Photos

final class PKAlbumViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    var image: UIImage? {
        didSet {
            self.imageView.image = image
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.isSelected = false
    }
    
    override var isSelected : Bool {
        didSet {
            self.layer.borderColor = isSelected ? PekingAppearance.appearance.tintColor.cgColor : UIColor.clear.cgColor
            self.layer.borderWidth = isSelected ? 2 : 0
        }
    }
}
