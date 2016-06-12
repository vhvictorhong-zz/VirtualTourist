//
//  PhotoAlbumCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Victor Hong on 3/25/16.
//  Copyright © 2016 Victor Hong. All rights reserved.
//

import UIKit

class PhotoAlbumCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = UIColor.blueColor()
    }
    
}