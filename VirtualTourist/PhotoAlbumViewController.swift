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
    
    var context: NSManagedObjectContext {
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return delegate.dataController.managedObjectContext
    }

    
    // MARK: ===== Properties =====
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var pin: Pin?
    var photosArray: [Photo] {
        var array = pin?.photos?.allObjects as! [Photo]
        array.sortInPlace({ (p1, p2) -> Bool in
            return p1.id?.compare(p2.id!) == NSComparisonResult.OrderedDescending
        })
        return array
    }
    
    // MARK: ===== View Methods =====
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = pin?.title
        
        mapView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        
        setMapRegion()
        loadPinPhotosData()
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
    
    private func loadPinPhotosData() {
        if pin != nil && photosArray.isEmpty {
            downloadPinPhotosData({ (success) in
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
    
    
    private func downloadPinPhotosData(completionHandlerForDownload: (success: Bool) -> Void) {
        guard let pin = pin else {
            return
        }
        
        FlickrAPI.sharedInstance.searchForPhotosByCoordinate(pin.coordinate, completionHandlerForSearch: { (data, errorString) in
            if (errorString != nil) {
                print(errorString)
                completionHandlerForDownload(success: false)
            } else {
                guard let data = data else {
                    completionHandlerForDownload(success: false)
                    return
                }
                
                print(data)
                
                let photos = data[FlickrAPI.FlickrResponseKeys.Photo] as! [[String:AnyObject]]
                
                for photo in photos {
                    do {
                        let request = NSFetchRequest(entityName: "Photo")
                        request.predicate = NSPredicate(format: "id = %@", photo[FlickrAPI.FlickrResponseKeys.ID] as! String)
                        
                        guard let fetchedPhotos = try self.context.executeFetchRequest(request) as? [Photo] else {
                            continue
                        }
                        
                        if photo[FlickrAPI.FlickrResponseKeys.ID] as? String == fetchedPhotos.first?.id {
                            //self.photosArray.append(fetchedPhotos.first!)
                            //print("Added Fetched Photo to array")
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
                    //self.photosArray.append(newPhoto)
                    //print("Added Downloaded Photo to array")
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
            return 0
        } else {
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
        
        guard !photosArray.isEmpty else {
            return cell
        }
        
        let photo = photosArray[indexPath.item]
        
        if photo.image != nil {
            let image = UIImage(data: photo.image!)
            cell.imageView.image = image
            return cell
        } else {
            let request = NSFetchRequest(entityName: "Photo")
            request.predicate = NSPredicate(format: "id = %@", photo.id!)
            guard let fetchedPhoto = try! self.context.executeFetchRequest(request).first as? Photo else {
                return cell
            }
            
            if fetchedPhoto.image != nil {
                photo.image = fetchedPhoto.image
                let image = UIImage(data: fetchedPhoto.image!)
                cell.imageView.image = image
                return cell
            } else {
                guard let url = fetchedPhoto.imageURL else {
                    return cell
                }
                
                guard let imageURL = NSURL(string: url) else {
                    return cell
                }
                
                FlickrAPI.sharedInstance.downloadImageFromFlickr(imageURL) { (imageData, errorString) in
                    guard errorString == nil else {
                        return
                    }
                    
                    let photoJPEG = UIImageJPEGRepresentation(UIImage(data: imageData!)!, 0.01)!
                    photo.image = photoJPEG
                    fetchedPhoto.image = photoJPEG
                    
                    let image = UIImage(data: photoJPEG)
                    dispatch_async(dispatch_get_main_queue(), {
                        cell.imageView.image = image!
                    })
                }
                return cell
            }
        }
    }
    
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let photo = photosArray[indexPath.item]
        context.deleteObject(photo)
        photo.pin = nil
        collectionView.deleteItemsAtIndexPaths([indexPath])
        try! context.save()
    }
    
    
}
