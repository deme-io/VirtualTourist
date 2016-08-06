//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Demetrius Henry on 8/6/16.
//  Copyright © 2016 Demetrius Henry. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {
    
    let userDefault = NSUserDefaults.standardUserDefaults()
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        var mapRegion = MKCoordinateRegion()
        mapRegion.span.latitudeDelta = userDefault.doubleForKey("mapViewSpanLat")
        mapRegion.span.longitudeDelta = userDefault.doubleForKey("mapViewSpanLong")
        mapRegion.center.latitude = userDefault.doubleForKey("mapViewCenterLat")
        mapRegion.center.longitude = userDefault.doubleForKey("mapViewCenterLong")
        
        mapView.setRegion(mapRegion, animated: true)
    }
    
    
   
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        userDefault.setDouble(mapView.region.span.latitudeDelta, forKey: "mapViewSpanLat")
        userDefault.setDouble(mapView.region.span.longitudeDelta, forKey: "mapViewSpanLong")
        userDefault.setDouble(mapView.region.center.latitude, forKey: "mapViewCenterLat")
        userDefault.setDouble(mapView.region.center.longitude, forKey: "mapViewCenterLong")
    }


}

