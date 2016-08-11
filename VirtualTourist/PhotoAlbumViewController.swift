//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Demetrius Henry on 8/7/16.
//  Copyright © 2016 Demetrius Henry. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    
    // MARK: ===== Properties =====
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var collectionLabel: UILabel!
    
    var pin: Pin?
    var photosArray: [Photo] {
        var array = pin?.photos?.allObjects as! [Photo]
        array.sortInPlace({ (p1, p2) -> Bool in
            return p1.id?.compare(p2.id!) == NSComparisonResult.OrderedDescending
        })
        return array
    }
    
    var context: NSManagedObjectContext {
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return delegate.dataController.managedObjectContext
    }
    
    let firstGroup = dispatch_group_create()
    var pageNumber = 1
    var totalPages = 1
    
    // MARK: ===== View Methods =====
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = pin?.title
        
        mapView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        
        setMapRegion()
        loadPinPhotosData(pageNumber)
        
        collectionLabel.hidden = true
    }
    
    
    private func setMapRegion() {
        if let pin = pin {
            var mapRegion = MKCoordinateRegion()
            mapRegion.center = pin.coordinate
            mapRegion.span.latitudeDelta = 0.004
            mapRegion.span.longitudeDelta = 0.004
            
            mapView.setRegion(mapRegion, animated: true)
            mapView.addAnnotation(pin)
        }
    }
    
    private func loadPinPhotosData(pageNumber: Int) {
        if pin != nil && photosArray.isEmpty {
            newCollectionButton.enabled = false
            downloadPinPhotosData(pageNumber, completionHandlerForDownload: { (success) in
                if success == true {
                    print("Photos array count: \(self.photosArray.count)")
                    dispatch_async(dispatch_get_main_queue(), {
                        self.collectionView.reloadData()
                    })
                }
            })
        } else {
            collectionView.reloadData()
        }
    }
    
    
    private func downloadPinPhotosData(pageNumber: Int,completionHandlerForDownload: (success: Bool) -> Void) {
        guard let pin = pin else {
            return
        }
        
        FlickrAPI.sharedInstance.searchForPhotosByCoordinate(pin.coordinate, pageNumber: pageNumber, completionHandlerForSearch: { (data, errorString) in
            if (errorString != nil) {
                print(errorString)
                completionHandlerForDownload(success: false)
            } else {
                guard let data = data else {
                    completionHandlerForDownload(success: false)
                    return
                }
                
                print(data)
                self.totalPages = Int(data["pages"] as! NSNumber)
                
                let photos = data[FlickrAPI.FlickrResponseKeys.Photo] as! [[String:AnyObject]]
                
                for photo in photos {
                    do {
                        let request = NSFetchRequest(entityName: "Photo")
                        request.predicate = NSPredicate(format: "id = %@", photo[FlickrAPI.FlickrResponseKeys.ID] as! String)
                        
                        guard let fetchedPhotos = try self.context.executeFetchRequest(request) as? [Photo] else {
                            continue
                        }
                        
                        if photo[FlickrAPI.FlickrResponseKeys.ID] as? String == fetchedPhotos.first?.id {
                            continue
                        }
                    } catch {
                        print(error)
                    }
                    
                    
                    guard let newPhoto = NSEntityDescription.insertNewObjectForEntityForName("Photo", inManagedObjectContext: self.context) as? Photo else {
                        continue
                    }
                    
                    newPhoto.pin = self.pin
                    newPhoto.imageURL = photo[FlickrAPI.FlickrResponseKeys.MediumURL] as? String
                    newPhoto.id = photo[FlickrAPI.FlickrResponseKeys.ID] as? String
                }
                
                if self.context.hasChanges {
                    try! self.context.save()
                }
                
                completionHandlerForDownload(success: true)
            }
        })
        
    }
    
    
    // MARK: ===== IBAction Methods =====
    
    @IBAction func newCollectionButtonPressed(sender: AnyObject) {
        for photo in photosArray {
            context.deleteObject(photo)
            photo.pin = nil
        }
        
        if pageNumber < totalPages {
            pageNumber = pageNumber + 1
        } else {
            pageNumber = 1
        }
        
        loadPinPhotosData(pageNumber)
        try! context.save()
    }

    @IBAction func doneButtonPressed(sender: AnyObject) {
        if self.context.hasChanges {
            try! self.context.save()
        }
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    // MARK: ===== Collection View Delegate Methods =====
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if photosArray.isEmpty {
            collectionLabel.hidden = false
            return 0
        } else {
            collectionLabel.hidden = true
            return photosArray.count
        }
        
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let identifier = "cell"
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath) as! CustomCollectionViewCell
                
        cell.imageView.image = UIImage(named: "placeholder.png")
        
        if let image = fetchPhotoForIndexPath(indexPath) {
            cell.imageView.image = image
        } else {
            downloadCellImage(indexPath, complettionHandlerForDownload: { (image) in
                dispatch_sync(dispatch_get_main_queue(), { 
                    cell.imageView.image = image
                })
            })
        }
        return cell
    }
    
    
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let photo = photosArray[indexPath.item]
        context.deleteObject(photo)
        photo.pin = nil
        collectionView.deleteItemsAtIndexPaths([indexPath])
        try! context.save()
    }
    
    
    // MARK: ===== Helper Methods =====
    
    private func fetchPhotoForIndexPath(indexPath: NSIndexPath) -> UIImage? {
        guard !photosArray.isEmpty else {
            return nil
        }
        
        let photo = photosArray[indexPath.item]
        
        if photo.image != nil {
            return UIImage(data: photo.image!)
        } else {
            let request = NSFetchRequest(entityName: "Photo")
            request.predicate = NSPredicate(format: "id = %@", photo.id!)
            guard let fetchedPhoto = try! self.context.executeFetchRequest(request).first as? Photo else {
                return nil
            }
            
            if fetchedPhoto.image != nil {
                photo.image = fetchedPhoto.image
                return UIImage(data: fetchedPhoto.image!)
            } else {
                return nil
            }
        }
    }
    
    
    private func downloadCellImage(indexPath: NSIndexPath, complettionHandlerForDownload: (image: UIImage?) -> Void) {
        newCollectionButton.enabled = false
        collectionView.allowsSelection = false
        var image: UIImage?
        
        let photo = photosArray[indexPath.item]
        guard let url = photo.imageURL else {
            complettionHandlerForDownload(image: nil)
            return
        }
        
        guard let imageURL = NSURL(string: url) else {
            complettionHandlerForDownload(image: nil)
            return
        }
        
        dispatch_group_enter(firstGroup)
        
        FlickrAPI.sharedInstance.downloadImageFromFlickr(imageURL) { (imageData, errorString) in
            guard errorString == nil else {
                return
            }
            
            let photoJPEG = UIImageJPEGRepresentation(UIImage(data: imageData!)!, 0.01)!
            photo.image = photoJPEG
            image = UIImage(data: photoJPEG)
            complettionHandlerForDownload(image: image)
            
            dispatch_group_leave(self.firstGroup)
        }
        dispatch_group_notify(firstGroup, dispatch_get_main_queue()) {
            self.newCollectionButton.enabled = true
            self.collectionView.allowsSelection = true
        }
        
    }
    
}
