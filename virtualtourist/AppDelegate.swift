//
//  AppDelegate.swift
//  VirtualTourist
//
//  Created by Victor Hong on 3/17/16.
//  Copyright © 2016 Victor Hong. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    lazy var sharedContext = {
        CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        return true
        
    }

    func applicationWillResignActive(application: UIApplication) {

        saveContext()
    }

    func applicationDidEnterBackground(application: UIApplication) {
        
        saveContext()
        
    }

    func applicationWillTerminate(application: UIApplication) {

        saveContext()
        
    }

    func saveContext() {
        dispatch_async(dispatch_get_main_queue()) {
            _ = try? self.sharedContext.save()
        }
    }
    
}

