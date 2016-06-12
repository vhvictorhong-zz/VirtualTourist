//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Victor Hong on 3/17/16.
//  Copyright © 2016 Victor Hong. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class FlickrClient: NSObject {
    
    var numberOfPhotoDownloaded = 0
    
    var session: NSURLSession
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    func taskForGETMethodWithParameters(parameters: [String : AnyObject], completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
        
        let urlString = Constants.BaseURL + FlickrClient.escapedParameters(parameters)
        let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
        
        let task = session.dataTaskWithRequest(request) {
            data, response, downloadError in
            
            if let error = downloadError {
                let newError = FlickrClient.errorForResponse(data, response: response, error: error)
                completionHandler(result: nil, error: newError)
            } else {
                FlickrClient.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
            }
        }
        
        task.resume()
    }
    
    func taskForGetMethod(base: String, completionHandler: (result: NSData?, error: NSError?) -> Void) {
        
        let request = NSMutableURLRequest(URL: NSURL(string: base)!)
        
        let task = session.dataTaskWithRequest(request) {
            data, response, downloadError in
            
            if let error = downloadError {
                let newError = FlickrClient.errorForResponse(data, response: response, error: error)
                completionHandler(result: nil, error: newError)
            } else {
                completionHandler(result: data, error: nil)
            }
        }
        
        task.resume()
        
    }
    
    class func escapedParameters(parameters: [String: AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            if(!key.isEmpty) {
                let stringValue = "\(value)"
                
                let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
                
                urlVars += [key + "=" + "\(escapedValue!)"]
            }
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
        
    }
    
    class func errorForResponse(data: NSData?, response: NSURLResponse?, error: NSError) -> NSError {
        
        if let parsedResult = (try? NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)) as? [String: AnyObject] {
            
            if let status = parsedResult[JSONResponseKeys.Status] as? String, message = parsedResult[JSONResponseKeys.Message] as? String {
                
                if status == JSONResponseValues.Fail {
                    
                    let userInfo = [NSLocalizedDescriptionKey: message]
                    
                    return NSError(domain: "Virtual Tourist Error", code: 1, userInfo: userInfo)
                }
            }
        }
        
        return error
        
    }
    
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
        
        var parsingError: NSError?
        var parsedResult: AnyObject?
        
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        } catch let error as NSError {
            parsingError = error
            parsedResult = nil
            print("Parse error - \(parsingError!.localizedDescription)")
            return
        }
        
        if let error = parsingError {
            completionHandler(result: nil, error: error)
        } else {
            completionHandler(result: parsedResult, error: nil)
        }
        
    }
    
    class func sharedInstance() -> FlickrClient {
        
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        
        return Singleton.sharedInstance
        
    }
}
