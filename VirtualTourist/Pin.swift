//
//  Pin.swift
//  VirtualTourist
//
//  Created by Raphael Neuenschwander on 23.06.15.
//  Copyright (c) 2015 Raphael Neuenschwander. All rights reserved.
//

import UIKit

import CoreData

@objc(Pin)

class Pin: NSManagedObject {
    
    struct Keys {
        static let Longitude = "longitude"
        static let Latitude = "latitude"
    }
    
    @NSManaged var longitude: NSNumber
    @NSManaged var latitude: NSNumber
    @NSManaged var photos: [Photo]
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        longitude = dictionary[Pin.Keys.Longitude] as! Double
        latitude = dictionary[Pin.Keys.Latitude] as! Double
        
    }
    
    
}


