//
//  LocationModel.swift
//  VirtualTourist
//
//  Created by Victor Hong on 3/30/16.
//  Copyright © 2016 Victor Hong. All rights reserved.
//

import Foundation
import CoreData

@objc(LocationModel)
class LocationModel: NSManagedObject {
    
    struct Keys {
        static let Latitude = "latitude"
        static let Longitude = "longitude"
        static let LatitudeDelta = "latitudeDelta"
        static let LongitudeDelta = "longitudeDelta"
    }
    
    @NSManaged var latitude: NSNumber?
    @NSManaged var longitude: NSNumber?
    @NSManaged var latitudeDelta: NSNumber?
    @NSManaged var longitudeDelta: NSNumber?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("LocationModel", inManagedObjectContext: context)
        
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        latitude = dictionary[Keys.Latitude] as? NSNumber
        longitude = dictionary[Keys.Longitude] as? NSNumber
        latitudeDelta = dictionary[Keys.LatitudeDelta] as? NSNumber
        longitudeDelta = dictionary[Keys.LongitudeDelta] as? NSNumber
        
    }
    
}
