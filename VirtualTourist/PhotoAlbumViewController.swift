//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Raphael Neuenschwander on 25.06.15.
//  Copyright (c) 2015 Raphael Neuenschwander. All rights reserved.
//

import UIKit
import CoreData



class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    
    var pin: Pin!
    
    @IBOutlet weak var photoCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var error: NSError? = nil
        
        // Fetch the data
        fetchedResultsController.performFetch(&error)
        
        if let error = error {
            println(error.localizedDescription)
        }
        
        // Set the delegate
        fetchedResultsController.delegate = self

    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        if pin.photos.isEmpty {
            FlickrClient.sharedInstance().getImagesFromFlickrBySearch(searchLongitude: pin.coordinate.longitude, searchLatitude: pin.coordinate.latitude) { photos, error in
                
                if let error = error {
                    println(error)
                
                } else {
                    
                    // map the array of dictionary to photo objects
                    var photo = photos?.map() { (dictionary: [String:AnyObject]) -> Photo in
                        let photo = Photo(dictionary: dictionary, context: self.sharedContext)
                        
                        photo.pin = self.pin
                        
                        
                        return photo
                        
                    }
                    dispatch_async(dispatch_get_main_queue()) {
                    self.photoCollectionView.reloadData()
                    }
                }
            }
        }
    }
    
    // Layout collection view
    
    override func viewDidLayoutSubviews() {
        // Lay out the collection view so that cells take up 1/3 of the width,
        // with no space in between.de
        
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)
        layout.minimumLineSpacing = 2
        layout.minimumInteritemSpacing = 2
        
        let width = floor(self.photoCollectionView.frame.size.width/3) - layout.minimumLineSpacing
        layout.itemSize = CGSize(width: width, height: width)
        
        photoCollectionView.collectionViewLayout = layout
        
    }
    
    //Shared Context
    lazy var sharedContext: NSManagedObjectContext  = {
       return CoreDataStackManager.sharedInstance().managedObjectContext!
        
    }()
    
    //MARK: Core Data
    
    
    //Configure the fetchedResultsController
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        
        
        let fetchedResultsController: NSFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsController
    }()
    
    //MARK: UICollectionViewDataSource, UICollectionViewDelegate
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        println(sectionInfo.numberOfObjects)
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = photoCollectionView.dequeueReusableCellWithReuseIdentifier("PhotoAlbumViewCell", forIndexPath: indexPath) as! PhotoAlbumCollectionViewCell
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        cell.label.text = photo.imagePath
        
        let nsurl = NSURL(string: photo.imagePath)!
        
        if let imageData = NSData(contentsOfURL: nsurl) {
            cell.photoImageView.image = UIImage(data: imageData)
            
        }
        
        return cell
        
    }
    
    
    //TODO: Add NSFetchedResultsControllerDelegate methods
    
}
    

