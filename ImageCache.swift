//
//  ImageCache.swift
//  VirtualTourist
//
//  Created by Raphael Neuenschwander on 28.06.15.
//  Copyright (c) 2015 Raphael Neuenschwander. All rights reserved.
//

import Foundation
import UIKit

class ImageCache {
    
    private var inMemoryCache = NSCache()
    
    //MARK: - Retrieving images
    
    func imageWithIdentifier(identifier: String?) -> UIImage? {
        
        //If the identifier is nil, or empty, return nil
        if identifier == nil || identifier! == "" {
            return nil
        }
        
        let path = pathForIdentifier(identifier!)
        var data: NSData?
        
        //First try the memory cache
        if let image = inMemoryCache.objectForKey(path) as? UIImage {
            return image
        }
        
        //Next Try the hard drive
        if let data = NSData(contentsOfFile: path) {
            return UIImage(data: data)
        }
        
        return nil
        
    }
    
    
    //MARK: - Saving images
    
    func storeImage(image: UIImage? , withIdentifier identifier: String) {
    
    let path = pathForIdentifier(identifier)
        
        // If the image is nil, remove image from the cache
        if image == nil {
            inMemoryCache.removeObjectForKey(path)
            NSFileManager.defaultManager().removeItemAtPath(path, error: nil)
            return
        }
        
        // Otherwise, keep it in memory
        inMemoryCache.setObject(image!, forKey: path)
        
        // And in documents directory
        let data = UIImagePNGRepresentation(image!)
        data.writeToFile(path, atomically: true)
    }
    
    //MARK: - Delete images
    
    func deleteImage(identifier: String) {
        
        let path = pathForIdentifier(identifier)
        
        //Remove it from the cache
        inMemoryCache.removeObjectForKey(path)
        
        //Delete it from the document directory
        NSFileManager.defaultManager().removeItemAtPath(identifier, error: nil)
        
        if !NSFileManager.defaultManager().fileExistsAtPath(path) {
            println("doesn't exist anymore")
        }
        
    }
    
    // Helper
    
    func pathForIdentifier(identifier: String) -> String {
        
        let documentDirectory: NSURL = NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).first as! NSURL
        let fullPathUrl = documentDirectory.URLByAppendingPathComponent(identifier)
    
        return fullPathUrl.path!
    }
    
}



