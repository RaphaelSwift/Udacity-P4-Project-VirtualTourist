//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Raphael Neuenschwander on 24.06.15.
//  Copyright (c) 2015 Raphael Neuenschwander. All rights reserved.
//

import Foundation

class FlickrClient: NSObject {
    
    // Shared Session
    var session: NSURLSession
    
    override init () {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    // GET Method
    
    func taskForGetMethod (parameters: [String: AnyObject], completionHandler:(result: AnyObject! ,error: NSError?) -> Void ) -> NSURLSessionDataTask {
        
        // Set the parameters
        var mutableParameters = parameters
        
        mutableParameters[UrlKeys.ApiKey] = Constants.ApiKey
        mutableParameters[UrlKeys.Format] = Constants.Format
        mutableParameters[UrlKeys.NoJsonCallBack] = Constants.NoJsonCallBack
        
        // Build the URL
        
        let urlString = Constants.BaseUrl + escapedParameters(mutableParameters)
        let url = NSURL(string: urlString)!
        
        let request = NSURLRequest(URL: url)
        
        // Make the request
        let task = session.dataTaskWithRequest(request) { data, response, error in
            
            if let error = error {
                completionHandler(result: nil, error: error)
                
            } else {
                
                var error: NSError? = nil
                
                // Parse the data
                if let parsedData: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &error) {
                    
                    if let error = error {
                        completionHandler(result: nil, error: error)
                    
                    } else {
                        completionHandler(result: parsedData, error: nil)
                    }
                }
            }
        }
        
        // Start the request
        task.resume()
        return task
    }
    
    
    // Task Method to download an image from a given string url
    
    func taskForImage (imagePath: String, completionHandler: (imageData: NSData?, error: NSError?) -> Void ) -> NSURLSessionTask {
        
        let url = NSURL(string: imagePath)!
        
        let request = NSURLRequest(URL: url)
        
        //Make the request
        let task = session.dataTaskWithRequest(request) { data, response, error in
            
            if let error = error {
                completionHandler(imageData: nil, error: error)
                
            } else {
                completionHandler(imageData: data, error: nil)
            }
            
        }
        
        task.resume()
        return task
    }
    
    
    
    //MARK: - Helpers
    
    // Helper function, given a dictionary of parameters, convert to a string for a URL
    func escapedParameters(parameters: [String:AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key,value) in parameters {
            
            let valueString = "\(value)"
            
            let escapedValue = valueString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            urlVars.append("\(key)=\(escapedValue!)")
            
        }
     
        return (!urlVars.isEmpty ? "?" : "") + join("&" , urlVars)
    }
    
    
    //MARK: - SharedInstance
    
    class func sharedInstance() -> FlickrClient {
        
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
    
        return Singleton.sharedInstance
    }
    
    //MARK: - Shared Cache
    
    struct Caches {
        static let imageCache = ImageCache()
    }
    
}
