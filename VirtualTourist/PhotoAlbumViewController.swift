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

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var pin: Pin?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        title = pin?.title
        
        if let pin = pin {
            var mapRegion = MKCoordinateRegion()
            mapRegion.center = pin.coordinate
            mapRegion.span.latitudeDelta = 0.06
            mapRegion.span.longitudeDelta = 0.06
            
            mapView.setRegion(mapRegion, animated: true)
            mapView.addAnnotation(pin)
        }
        
        
        
    }
    
    @IBAction func newCollectionButtonPressed(sender: AnyObject) {
    }

    @IBAction func doneButtonPressed(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
