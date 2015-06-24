//
//  FlickrClient-Convenience.swift
//  VirtualTourist
//
//  Created by Raphael Neuenschwander on 24.06.15.
//  Copyright (c) 2015 Raphael Neuenschwander. All rights reserved.
//

import Foundation


extension FlickrClient {
    
    
    func getImagesFromFlickrBySearch (searchLongitude longitude: Double, searchLatitude latitude: Double, completionhandler : (photos: [[String:AnyObject]]?, error: String?) -> Void ) {
        
        // Set the parameters, method
        
        var parameters: [String: AnyObject] = [
            UrlKeys.Method: Method.SearchPhotos,
            UrlKeys.Bbox: createBoundingBox(latitude, longitude: longitude),
            UrlKeys.Extras: Constants.Url
        ]
        
        taskForGetMethod(parameters) { parsedData, error in
            
            if let error = error {
                completionhandler(photos: nil, error: error.localizedDescription)
                
            } else {
                
                // Retrieve the photos
                if let results = parsedData as? [String:AnyObject] {
                    if let photos = results[ResponseKeys.Photos] as? [String:AnyObject] {
                        if let photo = photos[ResponseKeys.Photo] as? [[String:AnyObject]] {
                            completionhandler(photos: photo, error: nil)
                        } else {
                            completionhandler(photos: nil, error: "Invalid key or could not cast photo to [[String:AnyObject]]")
                        }
                    } else {
                        completionhandler(photos: nil, error: "Invalid key or could not cast photos to [String:AnyObject]")
                    }
                } else {
                    completionhandler(photos: nil, error: "Could not cast parsedData to [String:AnyObject]")
                }
            }
        }
        
    }
    
    //MARK: Helper functions
    
    // Creates a bounding box string from a given latitude and longitude
    func createBoundingBox (latitude: Double, longitude: Double) -> String {
        
        let bottomLeftLongitude = longitude - Constants.SearchLenght / 2
        let bottomLeftLatitude = latitude - Constants.SearchWidth / 2
        let topRightLongitude = longitude + Constants.SearchLenght / 2
        let topRightLatitude = latitude + Constants.SearchWidth / 2
        
        return "\(bottomLeftLongitude),\(bottomLeftLatitude),\(topRightLongitude),\(topRightLatitude)"
        
    }
}