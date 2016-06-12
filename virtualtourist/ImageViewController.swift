//
//  ImageViewController.swift
//  VirtualTourist
//
//  Created by Victor Hong on 3/17/16.
//  Copyright © 2016 Victor Hong. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController {

    
    @IBOutlet weak var imageView: UIImageView!

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let imageURL = NSURL(string: Selection.sharedInstance().selectedImage!)
        let imageData = NSData(contentsOfURL: imageURL!)
        if (imageData != nil) {
            self.imageView.image = UIImage(data: imageData!)
        } else {
            self.imageView.image = UIImage(named: "noPhotoAvailable")
        }
    }
}
