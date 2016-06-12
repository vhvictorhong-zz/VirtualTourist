//
//  Selection.swift
//  VirtualTourist
//
//  Created by Victor Hong on 3/17/16.
//  Copyright © 2016 Victor Hong. All rights reserved.
//

import Foundation


class Selection {
    
    var selectedPin: Pin?
    var selectedImage: String?
    
    class func sharedInstance() -> Selection {
        
        struct Singleton {
            static let sharedInstance = Selection()
        }
        
        return Singleton.sharedInstance
        
    }
}