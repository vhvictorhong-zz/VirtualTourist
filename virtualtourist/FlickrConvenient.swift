//
//  FlickrConvenient.swift
//  VirtualTourist
//
//  Created by Victor Hong on 3/17/16.
//  Copyright © 2016 Victor Hong. All rights reserved.
//

import Foundation
import CoreData

extension FlickrClient {
    
    func downloadPhotosForPin(pin: Pin, completionHandler: (success: Bool, error: NSError?) -> Void) {
        
        var randomPageNumber: Int = 1
        
        if let numberPages = pin.pageNumber?.integerValue {
            if numberPages > 0 {
                let pageLimit = min(numberPages, 20)
                randomPageNumber = Int(arc4random_uniform(UInt32(pageLimit))) + 1
            }
        }
        
        let parameters: [String: AnyObject] = [
            URLKeys.Method: Methods.Search,
            URLKeys.APIKey: Constants.APIKey,
            URLKeys.Format: URLValues.JSONFormat,
            URLKeys.NoJSONCallback: 1,
            URLKeys.Latitude: pin.latitude,
            URLKeys.Longitude: pin.longitude,
            URLKeys.Extras: URLValues.URLMediumPhoto,
            URLKeys.Page: randomPageNumber,
            URLKeys.PerPage: 15
        ]
        
        taskForGETMethodWithParameters(parameters, completionHandler: {
            results, error in
            
            if let error = error {
                completionHandler(success: false, error: error)
            } else {
                
                if let photoDictionary = results.valueForKey(JSONResponseKeys.Photos) as? [String: AnyObject],
                    photosArray = photoDictionary[JSONResponseKeys.Photo] as? [[String: AnyObject]],
                    numberOfPhotoPages = photoDictionary[JSONResponseKeys.Pages] as? Int {
                    
                        pin.pageNumber = numberOfPhotoPages
                        
                        self.numberOfPhotoDownloaded = photosArray.count
                        
                        for photoDictionary in photosArray {
                            
                            guard let photoURLString = photoDictionary[URLValues.URLMediumPhoto] as? String
                                else {
                                    print("error, photoDictionary")
                                continue
                            }
                            
                            let newPhoto = Photo(imageURL: photoURLString, pin: pin, context: self.sharedContext)
        
                            self.downloadPhotoImage(newPhoto, completionHandler: {
                                success, error in
                                
                                NSNotificationCenter.defaultCenter().postNotificationName("downloadPhototoImage.done", object: nil)
                                
                                dispatch_async(dispatch_get_main_queue(), {
                                    CoreDataStackManager.sharedInstance().saveContext()
                                })
                            })
                        }
                        completionHandler(success: true, error: nil)
                } else {
                    completionHandler(success: false, error: NSError(domain: "downloadPhotosForPin", code: 0, userInfo: nil))
                }
            }
        })
    }
    
    func downloadPhotoImage(photo: Photo, completionHandler: (success: Bool, error: NSError?) -> Void) {
        
        let imageURLString = photo.imageURL
        
        taskForGetMethod(imageURLString, completionHandler: {
            result, error in
            
            if let error = error {
                print("Error from downloading images \(error.localizedDescription)")
                photo.filePathError = "error"
                completionHandler(success: false, error: error)
            } else {
                if let result = result {
                    let fileName = (imageURLString as NSString).lastPathComponent
                    let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
                    let pathArray = [dirPath, fileName]
                    let fileURL = NSURL.fileURLWithPathComponents(pathArray)!
                    
                    NSFileManager.defaultManager().createFileAtPath(fileURL.path!, contents: result, attributes: nil)
                    
                    photo.filePathError = fileURL.path
                    
                    completionHandler(success: true, error: nil)
                }
            }
        })
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
}