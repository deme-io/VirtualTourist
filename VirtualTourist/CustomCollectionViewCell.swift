//
//  CustomCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Demetrius Henry on 8/9/16.
//  Copyright © 2016 Demetrius Henry. All rights reserved.
//

import UIKit

class CustomCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
    
    
}
