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
    var photosArray = [Photo]()
    
    
    // MARK: ===== View Methods =====
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = pin?.title
        
        mapView.delegate = self
        collectionView.delegate = self
        
        if let pin = pin {
            var mapRegion = MKCoordinateRegion()
            mapRegion.center = pin.coordinate
            mapRegion.span.latitudeDelta = 0.004
            mapRegion.span.longitudeDelta = 0.004
            
            mapView.setRegion(mapRegion, animated: true)
            mapView.addAnnotation(pin)
            
            getPinImagesData(pin, completionHandlerForDownload: { (success) in
                if success == true {
                    print("Photos array count: \(self.photosArray.count)")
                    dispatch_async(dispatch_get_main_queue(), {
                        self.collectionView.reloadData()
                    })
                    
                }
            })
        }
        
    }
    
    
    private func getPinImagesData(pin: Pin, completionHandlerForDownload: (success: Bool) -> Void) {
        FlickrAPI.sharedInstance.searchForPhotosByCoordinate(pin.coordinate, completionHandlerForSearch: { (data, errorString) in
            if (errorString != nil) {
                print(errorString)
                completionHandlerForDownload(success: false)
            } else {
                guard let data = data else {
                    completionHandlerForDownload(success: false)
                    return
                }
                
                let photos = data[FlickrAPI.FlickrResponseKeys.Photo] as! [[String:AnyObject]]
                
                for photo in photos {
                    do {
                        let request = NSFetchRequest(entityName: "Photo")
                        request.predicate = NSPredicate(format: "id = %@", photo[FlickrAPI.FlickrResponseKeys.ID] as! String)
                        
                        guard let fetchedPhotos = try self.context.executeFetchRequest(request) as? [Photo] else {
                            continue
                        }
                        
                        if photo[FlickrAPI.FlickrResponseKeys.ID] as? String == fetchedPhotos.first?.id {
                            self.photosArray.append(fetchedPhotos.first!)
                            print("Added Fetched Photo to array")
                            continue
                        }
                    } catch {
                        print(error)
                    }
                    
                    
                    guard let newPhoto = NSEntityDescription.insertNewObjectForEntityForName("Photo", inManagedObjectContext: self.context) as? Photo else {
                        return
                    }
                    
                    newPhoto.pin = self.pin
                    newPhoto.imageURL = photo[FlickrAPI.FlickrResponseKeys.MediumURL] as? String
                    newPhoto.id = photo[FlickrAPI.FlickrResponseKeys.ID] as? String
                    self.photosArray.append(newPhoto)
                    print("Added Downloaded Photo to array")
                }
                
                if self.context.hasChanges {
                    try! self.context.save()
                }
                
                let newRequest = NSFetchRequest(entityName: "Photo")
                newRequest.predicate = NSPredicate(format: "pin.latitude = %@", pin.latitude!)
                print("\(self.context.countForFetchRequest(newRequest, error: nil)) photos have been downloaded for this pin")
                
                completionHandlerForDownload(success: true)
            }
        })
        
    }
    
    
    // MARK: ===== IBAction Methods =====
    
    @IBAction func newCollectionButtonPressed(sender: AnyObject) {
    }

    @IBAction func doneButtonPressed(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    // MARK: ===== Collection View Delegate Methods =====
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photosArray.count
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let identifier = "cell"
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath) as! CustomCollectionViewCell
        
//        guard !photosArray.isEmpty else {
//            return cell
//        }
//        
//        let photo = photosArray[indexPath.row]
//        
//        guard let url = photo.imageURL else {
//            return cell
//        }
//        
//        guard let imageURL = NSURL(string: url) else {
//            return cell
//        }
//        
//        guard photo.image != nil else {
//            FlickrAPI.sharedInstance.downloadImageFromFlickr(imageURL) { (imageData, errorString) in
//                guard errorString == nil else {
//                    return
//                }
//                
//                photo.image = imageData
//                
//                let image = UIImage(data: imageData!)
//                
//                dispatch_async(dispatch_get_main_queue(), {
//                    cell.imageView.image = image!
//                })
//            }
//            return cell
//        }
//        
//        if photo.image != nil {
//            cell.imageView.image = UIImage(data: photo.image!)
//        }
        
        return cell
    }
    
//    func collectionView(collectionView: UICollectionView, shouldDeselectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
//        <#code#>
//    }
    
}
