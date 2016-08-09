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
    
    
    
    // MARK: ===== View Methods =====
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = pin?.title
        
        mapView.delegate = self
        collectionView.delegate = self
        
        if let pin = pin {
            var mapRegion = MKCoordinateRegion()
            mapRegion.center = pin.coordinate
            mapRegion.span.latitudeDelta = 0.005
            mapRegion.span.longitudeDelta = 0.005
            
            mapView.setRegion(mapRegion, animated: true)
            mapView.addAnnotation(pin)
            
            FlickrAPI.sharedInstance.searchForPhotosByCoordinate(pin.coordinate, completionHandlerForSearch: { (data, errorString) in
                if (errorString != nil) {
                    print(errorString)
                } else {
                    guard let data = data else {
                        return
                    }
                    let photos = data[FlickrAPI.FlickrResponseKeys.Photo] as! [[String:AnyObject]]
                    for photo in photos  {
                        if let newPhoto = NSEntityDescription.insertNewObjectForEntityForName("Photo", inManagedObjectContext: self.context) as? Photo {
                            newPhoto.pin = self.pin
                            newPhoto.imageURL = photo[FlickrAPI.FlickrResponseKeys.MediumURL] as? String
                            newPhoto.id = photo[FlickrAPI.FlickrResponseKeys.ID] as? NSNumber
                            
                            guard let url = newPhoto.imageURL else {
                                return
                            }
                            guard let imageURL = NSURL(string: url) else {
                                return
                            }
                            newPhoto.image = NSData(contentsOfURL: imageURL)
                            
                            let request = NSFetchRequest(entityName: "Photo")
                            print("There are: \(self.context.countForFetchRequest(request, error: nil)) photos in Care Data")
                        }
                    }
                    
                    if self.context.hasChanges {
                        try! self.context.save()
                        print("Context Saved")
                    }
                }
            })
        }
        
    }
    
    
    // MARK: ===== IBAction Methods =====
    
    @IBAction func newCollectionButtonPressed(sender: AnyObject) {
    }

    @IBAction func doneButtonPressed(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    // MARK: ===== Collection View Delegate Methods =====
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let request = NSFetchRequest(entityName: "Photo")
        print(context.countForFetchRequest(request, error: nil))
        return context.countForFetchRequest(request, error: nil)
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let identifier = "cell"
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath) as! CustomCollectionViewCell
        
        return cell
    }

}
