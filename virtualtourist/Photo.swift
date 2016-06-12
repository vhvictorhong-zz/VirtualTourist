//
//  Photo.swift
//  VirtualTourist
//
//  Created by Victor Hong on 3/17/16.
//  Copyright © 2016 Victor Hong. All rights reserved.
//

import Foundation
import UIKit
import CoreData

@objc(Photo)
class Photo: NSManagedObject {
    
    @NSManaged var imageURL: String
    @NSManaged var filePathError: String?
    @NSManaged var pin: Pin?
    @NSManaged var didFetchImage: Bool
    
    private let noPhotoAvailable = UIImage(named: "noPhotoAvailable")
    var fetchInProgress = false
    
    var localURL: NSURL {
        let url = NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).first
        
        return (url?.URLByAppendingPathComponent(imageURL))!
        
    }
    
    var imageData: UIImage? {
        
        if let filePathError = filePathError {
            
            if filePathError == "error" {
                return noPhotoAvailable
            }
            
            let fileName = (filePathError as NSString).lastPathComponent
            let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
            let pathArray = [dirPath, fileName]
            let fileURL = NSURL.fileURLWithPathComponents(pathArray)!
            
            return UIImage(contentsOfFile: fileURL.path!)
        }
        
        return nil
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(imageURL: String, pin: Pin, context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        self.imageURL = imageURL
        self.pin = pin
        didFetchImage = false
        
    }
    
    func fetchImageData(completionHandler: (fetchComplete: Bool) -> Void) {
        
        if didFetchImage == false && fetchInProgress == false {
            fetchInProgress = true
            
            if let url = NSURL(string: imageURL) {
                NSURLSession.sharedSession().dataTaskWithURL(url) {
                    data, response, error in
                    
                    if self.managedObjectContext != nil {
                        if error != nil {
                            NSFileManager.defaultManager().createFileAtPath(self.localURL.path!, contents: NSData(data: UIImagePNGRepresentation(self.noPhotoAvailable!)!), attributes: nil)
                        } else {
                            NSFileManager.defaultManager().createFileAtPath(self.localURL.path!, contents: data, attributes: nil)
                        }
                        self.didFetchImage = true
                        completionHandler(fetchComplete: true)
                    } else {
                        completionHandler(fetchComplete: false)
                    }
                    self.fetchInProgress = false
                }
                .resume()
            }
        }
    }
    
    override func prepareForDeletion() {
        super.prepareForDeletion()
        
        if NSFileManager.defaultManager().fileExistsAtPath(localURL.path!) {
            do {
                try NSFileManager.defaultManager().removeItemAtURL(localURL)
            } catch {
                NSLog("Couldn't remove image: \(imageURL)")
            }
        }
        
    }
}