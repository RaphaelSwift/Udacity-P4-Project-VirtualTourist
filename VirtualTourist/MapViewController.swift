//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Raphael Neuenschwander on 22.06.15.
//  Copyright (c) 2015 Raphael Neuenschwander. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate {
    
    
    //MARK: - Class properties and attributes
    
    
    @IBOutlet weak var mapView: MKMapView!
    
    var tapAndHoldGestureRecognizer: UIGestureRecognizer? = nil
    
    // Create an instance of MKpointAnnotation, which only purpose it to be dragged on the map until dropped
    var temporaryAnnotationPoint = MKPointAnnotation()
    
    // Create an instance of our MapRegion class
    let mapRegion = MapRegion()
    
    // Create an empty array of pins
    
    var pins = [Pin]()
    
    
    // Convenience lazy context var, for easy access to the shared Managed Object Context
    
    lazy var sharedContext: NSManagedObjectContext = {
       return CoreDataStackManager.sharedInstance().managedObjectContext!
    }()
    
    //MARK: - Lifecyle

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Set the map region to the last region displayed by the user
        if let lastRegionDisplayed = mapRegion.restoreRegion() {
            self.mapView.region = lastRegionDisplayed
        }
        
        tapAndHoldGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "handleLongPressure:")
        mapView.addGestureRecognizer(tapAndHoldGestureRecognizer!)
        
        // retrieve the pins from Core Data
        pins = fetchAllPins()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        
        mapView.addAnnotations(convertPinsToAnnotations(self.pins))
    }
    
    //MARK: Helpers functions 
    
    //Convert an array of pins to an array of MKAnnotation
    
    func convertPinsToAnnotations(pins: [Pin]) -> [MKPointAnnotation] {
        
        let annotations = pins.map {
            pin -> MKPointAnnotation in
            
            let annotationPoint = MKPointAnnotation()
            annotationPoint.coordinate = CLLocationCoordinate2DMake(pin.latitude as! Double, pin.longitude as! Double)
            
            return annotationPoint
        }
        
        return annotations
    }
    
    //MARK: Core Data
    
    func fetchAllPins() -> [Pin] {
        
        var error: NSError? = nil
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        let results = sharedContext.executeFetchRequest(fetchRequest, error: &error)
        
        if let error = error {
            print(error.localizedDescription)
        }
        
        return results as? [Pin] ?? [Pin]()
    }
    
    //MARK: - Gestures Recognizer
    
    func handleLongPressure(recognizer: UILongPressGestureRecognizer) {
        
        // Here we get the CGPoint for the touch and convert it to latitude and longitude coordinates to display on the map
        var locationCoordinate: CLLocationCoordinate2D {
            let point = recognizer.locationInView(self.mapView)
            let locCoord = self.mapView.convertPoint(point, toCoordinateFromView: self.mapView)
            
            return locCoord
        }
        
        if recognizer.state == .Began {
            temporaryAnnotationPoint.coordinate = locationCoordinate
            self.mapView.addAnnotation(temporaryAnnotationPoint)
        }
        
        if recognizer.state == .Changed {
            temporaryAnnotationPoint.coordinate = locationCoordinate
            self.mapView.addAnnotation(temporaryAnnotationPoint)
        }
        
        // When the user lifts the finger, it delete the temporary pin and creates the permanent pin and saves it to Core Data
        if recognizer.state == .Ended {

            self.mapView.removeAnnotation(temporaryAnnotationPoint)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = locationCoordinate
            
            let dictionary: [String:AnyObject] = [
                Pin.Keys.Latitude: annotation.coordinate.latitude,
                Pin.Keys.Longitude: annotation.coordinate.longitude
            ]
            
            let pin = Pin(dictionary: dictionary, context: self.sharedContext)
            
            self.mapView.addAnnotation(annotation)
            
            CoreDataStackManager.sharedInstance().saveContext()

        }
    }
    
    
    //MARK: - MKMapViewDelegate methods
    
    
    // Each time the region changes, save it
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        mapRegion.saveRegion(mapView.region)
    }
    


}

