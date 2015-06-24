//
//  FlickrClient-Constants.swift
//  VirtualTourist
//
//  Created by Raphael Neuenschwander on 24.06.15.
//  Copyright (c) 2015 Raphael Neuenschwander. All rights reserved.
//

import Foundation


extension FlickrClient {
    
    struct Constants {
        static let ApiKey = "42f337b6fe1871f88aab183b2549900c"
        static let BaseUrl = "https://api.flickr.com/services/rest/"
        static let Format = "json"
        static let NoJsonCallBack = "1"
        static let SearchWidth = 1.0 // 1 degree latitude
        static let SearchLenght = 1.0 // 1 degree longitude
        static let Url = "url_m"
        

        
    }
    
    struct Method {
        static let SearchPhotos = "flickr.photos.search"
        
    }
    
    struct UrlKeys {
        static let ApiKey = "api_key"
        static let Format = "format"
        static let NoJsonCallBack = "nojsoncallback"
        static let Bbox = "bbox"
        static let Method = "method"
        static let Extras = "extras"
    }
    
    struct ResponseKeys {
        static let Photos = "photos"
        static let Photo = "photo"
    }
    
}