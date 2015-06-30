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
    
    @IBOutlet weak var newCollection: UIBarButtonItem!
    
    var taskCounter: Int = 0
    
    // Create 3 empty arrays that will keep track of insertions, deletions, updates
    var insertedIndexPaths : [NSIndexPath]!
    var deletedIndexPaths : [NSIndexPath]!
    var updatedIndexPaths : [NSIndexPath]!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.newCollection.enabled = true
        
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
        fetchRequest.predicate = NSPredicate(format: "pin ==%@", self.pin)
        
        
        let fetchedResultsController: NSFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsController
    }()
    
    //MARK: UICollectionViewDataSource, UICollectionViewDelegate
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = photoCollectionView.dequeueReusableCellWithReuseIdentifier("PhotoAlbumViewCell", forIndexPath: indexPath) as! PhotoAlbumCollectionViewCell
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        configureCell(cell, photo: photo)
        
        return cell
        
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        // Delete an image from the album when it is selected
        let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        // The removal from the cache and document directory is done directly from the Photo NSManaged object entity, check "Photo" for details
        
        // Remove the object from the shared context, which prepare the object to be deleted from the persistent store
        sharedContext.deleteObject(photo)
        
        // Save the context with the change (ie. delete)
        CoreDataStackManager.sharedInstance().saveContext()
        
    }
    
    
    //MARK: Actions
    
    //Download a new collection of data
    @IBAction func newCollection(sender: UIBarButtonItem) {
        
        
        // Remove the object from the shared context
        for photo in fetchedResultsController.fetchedObjects as! [Photo]{
            sharedContext.deleteObject(photo)
        }
        
        // The removal from the cache and document directory is done directly from the Photo NSManaged object entity, check "Photo" for details
        
        // Delete the object from the persistent store
        CoreDataStackManager.sharedInstance().saveContext()
        
        
        // Download a new set of Data
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
            }
            dispatch_async(dispatch_get_main_queue()) {
            // Save the objects in the persistent store
            CoreDataStackManager.sharedInstance().saveContext()
            }
        }
        
    }
    
    
    
    
    //MARK: - Add NSFetchedResultsControllerDelegate methods
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        
        // We create the three empty array to handle changes in the collection view
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
    }

    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type {
            
        case .Insert:
            // Insert the corresponding new indexpath in the array
            insertedIndexPaths.append(newIndexPath!)
            
        case .Delete:
            // Insert the indexpath to delete in the array
            deletedIndexPaths.append(indexPath!)
            
        case .Update:
            // Insert the indexpath to be udpated in the array
            updatedIndexPaths.append(indexPath!)
            
        case .Move:
            break
            
        default :
            break
            
        }
        
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        // loop through the arrays and perform the changes
        
        println("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
        
        
        photoCollectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.photoCollectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.photoCollectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.photoCollectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
        
        
    }
    
    
    //MARK: Configure Cell
    
    func configureCell(cell: PhotoAlbumCollectionViewCell, photo: Photo) {
        
        cell.photoImageView.backgroundColor = UIColor.whiteColor()
        cell.photoImageView.image = UIImage(named: "Placeholder")
        
        
        // If the image has already been downloaded, display it
        if let photo = photo.photoImage {
            cell.photoImageView.image = photo
    
        }

        // Else, download it
        else {
            
            // Add a task to the task counter
            self.incrementTaskCounter(incrementTrueDecrementFalse: true)
            
            // We download the images one by one asyncronously
            let task = FlickrClient.sharedInstance().taskForImage(photo.imagePath) { data, error in
            
                if let error = error {
                    println("Error to download the image : \(error.localizedDescription)")
                    
                    //The task has been cancelled => remove a task from the task counter
                    self.incrementTaskCounter(incrementTrueDecrementFalse: false)
                }
            
                if let data = data {
                
                    let photoImage = UIImage(data: data)
                
                    //update the model, cash the image
                    
                    photo.photoImage = photoImage
                
                    // Update on the main thread later
                    dispatch_async(dispatch_get_main_queue()) {
                    cell.photoImageView.image = photoImage
                     
                    // The task completed, the image has been downloaded and displayed => remove a task from the task counter
                    self.incrementTaskCounter(incrementTrueDecrementFalse: false)
                    
                    }
                }
            
            }
            
            cell.taskToCancelIfCellIsReused = task
            
            
        }

    }
    
   
    //MARK: Helper
    
    // This function increment or decrement the taskCounter variable, and check its value. If its value equals 0 (meaning no download tasks are still active), the button is enabled, else, it is disabled.
    func incrementTaskCounter(incrementTrueDecrementFalse increment: Bool) {
        
        if increment {
            self.taskCounter++
        
        } else {
            self.taskCounter--
            
        }
        
        
        if self.taskCounter == 0 {
            self.newCollection.enabled = true
        } else {
            self.newCollection.enabled = false
        }
    }
}
    

