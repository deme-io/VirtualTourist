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
    var totalPhotos = 0
    
    
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
            
            downloadPinImages(pin)
            }
        
    }
    
    
    private func downloadPinImages(pin: Pin) {
        FlickrAPI.sharedInstance.searchForPhotosByCoordinate(pin.coordinate, completionHandlerForSearch: { (data, errorString) in
            if (errorString != nil) {
                print(errorString)
            } else {
                guard let data = data else {
                    return
                }
                
                self.totalPhotos = Int(data["total"] as! String)!
                print("Download func total: \(self.totalPhotos)")
                
                let photos = data[FlickrAPI.FlickrResponseKeys.Photo] as! [[String:AnyObject]]
                for photo in photos  {
                    let request = NSFetchRequest(entityName: "Photo")
                    request.predicate = NSPredicate(format: "id = %@", photo[FlickrAPI.FlickrResponseKeys.ID] as! String)
                    
                    do {
                        if let fetchedPhoto = try self.context.executeFetchRequest(request) as? [Photo] {
                            if photo[FlickrAPI.FlickrResponseKeys.ID] as? String == fetchedPhoto.first?.id {
                                return
                            }
                        }
                    } catch {
                        print(error)
                    }
                    
                    if let newPhoto = NSEntityDescription.insertNewObjectForEntityForName("Photo", inManagedObjectContext: self.context) as? Photo {
                        newPhoto.pin = self.pin
                        newPhoto.imageURL = photo[FlickrAPI.FlickrResponseKeys.MediumURL] as? String
                        newPhoto.id = photo[FlickrAPI.FlickrResponseKeys.ID] as? String
                        
                        let request = NSFetchRequest(entityName: "Photo")
                        print("\(self.context.countForFetchRequest(request, error: nil)) photos have been downloaded")
                    }
                    
                    
                }
                
                if self.context.hasChanges {
                    try! self.context.save()
                }
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
        return (pin?.photos?.allObjects.count)!
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let identifier = "cell"
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath) as! CustomCollectionViewCell
        
        guard ((pin?.photos?.allObjects[indexPath.row]) != nil) else {
            return cell
        }
        
        guard let photo = pin?.photos?.allObjects[indexPath.row] as? Photo else {
            return cell
        }
        
        guard let url = photo.imageURL else {
            return cell
        }
        guard let imageURL = NSURL(string: url) else {
            return cell
        }
        
        FlickrAPI.sharedInstance.downloadImageFromFlickr(imageURL) { (image, errorString) in
            guard errorString == nil else {
                return
            }
            
            dispatch_async(dispatch_get_main_queue(), { 
                cell.imageView.image = image
            })
        }
        
//        photo.image = NSData(contentsOfURL: imageURL)
//        
//        if photo.image != nil {
//            cell.imageView.image = UIImage(data: photo.image!)
//        } else {
//            let url = NSURL(string: photo.imageURL!)
//            let data = NSData(contentsOfURL: url!)
//            photo.image = data
//            cell.imageView.image = UIImage(data: data!)
//        }
        
        return cell
    }
    
}
