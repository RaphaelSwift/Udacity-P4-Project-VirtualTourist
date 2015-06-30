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

class MapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    
    //MARK: - Class properties and attributes
    
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var tapAndHoldGestureRecognizer: UIGestureRecognizer? = nil
    
    // Create an instance of MKpointAnnotation, which only purpose it to be dragged on the map until dropped
    var temporaryAnnotationPoint = MKPointAnnotation()
    
    // Create an instance of our MapRegion class
    let mapRegion = MapRegion()
    
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
        
        
        // Set the delegate
        fetchedResultController.delegate = self
        
        // retrieve the pins from Core Data
        var error: NSError? = nil
        
        fetchedResultController.performFetch(&error)
        
        if let error = error {
            println(error.localizedDescription)
        }
        
        self.mapView.addAnnotations(self.fetchedResultController.fetchedObjects)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        self.activityIndicator.stopAnimating()
        
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
    
    lazy var fetchedResultController: NSFetchedResultsController = {
       
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        
        let fetchedResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultController
        
    }()

    
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
            
            let dictionary: [String:AnyObject] = [
                Pin.Keys.Latitude: locationCoordinate.latitude,
                Pin.Keys.Longitude: locationCoordinate.longitude
            ]
            
            let pin = Pin(dictionary: dictionary, context: self.sharedContext)
            
            CoreDataStackManager.sharedInstance().saveContext()

        }
    }
    
    //MARK: - MKMapViewDelegate methods
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        
        self.activityIndicator.startAnimating()
        
        let fetched = self.fetchedResultController.fetchedObjects as! [Pin]
        for pin in fetched {
            if pin.coordinate.latitude == view.annotation.coordinate.latitude && pin.coordinate.longitude == view.annotation.coordinate.longitude {
                
                
                // Once the corresponding pin is found, show the photoalbum and pass the data (pin)
                let controller = storyboard?.instantiateViewControllerWithIdentifier("PhotoAlbumViewController") as! PhotoAlbumViewController
                
                // Pass the corresponding pin to the controller
                controller.pin = pin
                
                // Check if a photo album already exist for this pin
                if !pin.photos.isEmpty {
                    
                    // If it does, segue to the album controller
                    self.navigationController?.pushViewController(controller, animated: true)
                }
                
                // Otherwise, get the images paths from flickr, using the pin coordinates
                else {
                    
                    FlickrClient.sharedInstance().getImagesFromFlickrBySearch(searchLongitude: pin.coordinate.longitude, searchLatitude: pin.coordinate.latitude) { photos, error in
                        
                        if let error = error {
                            println(error)
                            
                        } else {
                            
                            // Check if images were found for the given location.
                            if photos?.count == 0 {
                                
                                dispatch_async(dispatch_get_main_queue()) {
                                self.activityIndicator.stopAnimating()
                                self.displayLabelNoPhotoFound()
                                }
                                
                            } else {
                        
                                // map the array of dictionary to photo objects
                                var photo = photos?.map() { (dictionary: [String:AnyObject]) -> Photo in
                                    let photo = Photo(dictionary: dictionary, context: self.sharedContext)
                                    
                                    photo.pin = pin
                                
                                    return photo
                                }
                         
                                // Save the context
                                CoreDataStackManager.sharedInstance().saveContext()
                                
                                // Segue to the PhotoAlbum
                        
                                dispatch_async(dispatch_get_main_queue()) {
                                self.navigationController?.pushViewController(controller, animated: true)
                                }
                            }
                        }
                    }
                }
                // Deselect the annotation
                mapView.deselectAnnotation(pin, animated: true)
            }
        }
       
    }
    
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        /* Try to dequeue an existing pin view first */
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier("PhotoPin") as? MKPinAnnotationView
        
        /* If an existing pin view was not available, create one. */
        
        if pinView == nil {
            
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "PhotoPin")
            
        } else {
            
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    // Each time the region changes, save it
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        mapRegion.saveRegion(mapView.region)
    }
    
    
    //MARK: - NSFetchedResultsControllerDelegate methods

    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type {
            
        case .Insert:
            self.mapView.addAnnotation(anObject as! Pin)
            
        case .Delete:
            self.mapView.removeAnnotation(anObject as! Pin)
            
        case .Update:
            return
            
        default:
            return
        }
    }
    
    
    //MARK : UI
    
    
    func displayLabelNoPhotoFound() {
        
        self.label.alpha = 1.0
        
        UIView.animateWithDuration(1.0, delay: 2.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {self.label.alpha = 0.0}, completion: nil)
        
    }

}

