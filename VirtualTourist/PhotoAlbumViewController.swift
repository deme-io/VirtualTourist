//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Demetrius Henry on 8/7/16.
//  Copyright © 2016 Demetrius Henry. All rights reserved.
//

import UIKit
import MapKit

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate {

    
    // MARK: ===== Properties =====
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var pin: Pin?
    
    
    
    // MARK: ===== View Methods =====
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = pin?.title
        
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
                    //print("Data from search: \(data)")
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

}
