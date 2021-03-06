//
//  Photo.swift
//  VirtualTourist
//
//  Created by Raphael Neuenschwander on 23.06.15.
//  Copyright (c) 2015 Raphael Neuenschwander. All rights reserved.
//

import UIKit
import CoreData

@objc(Photo)

class Photo: NSManagedObject {
    
    struct Keys {
        static let ImagePath = "url_m"
    }
    
    @NSManaged var imagePath: String 
    @NSManaged var pin : Pin?
    

    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary:[String:AnyObject], context: NSManagedObjectContext) {
        
        //Core Data
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        //Dictionary
        imagePath = dictionary[Photo.Keys.ImagePath] as! String
        
    }
    
    // When the context is saved, we want to check if the object has been deleted, if it has effectively been, we want to remove it from the cache and document directory as well
    override func didSave() {
        
        if self.deleted {
        
            FlickrClient.Caches.imageCache.deleteImage(imagePath)
        }
    }
    
    
    
    // Retrieves the image if existing, else saves it
    var photoImage: UIImage? {
        
        get {
            return FlickrClient.Caches.imageCache.imageWithIdentifier(imagePath)
        }
        
        set {
            FlickrClient.Caches.imageCache.storeImage(newValue, withIdentifier: imagePath)
        }
    }
}
