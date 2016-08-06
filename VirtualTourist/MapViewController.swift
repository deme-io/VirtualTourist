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
    
    // MARK: ===== Properties =====
    let userDefault = NSUserDefaults.standardUserDefaults()
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: ===== View Methods =====
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        var mapRegion = MKCoordinateRegion()
        mapRegion.span.latitudeDelta = userDefault.doubleForKey("mapViewSpanLat")
        mapRegion.span.longitudeDelta = userDefault.doubleForKey("mapViewSpanLong")
        mapRegion.center.latitude = userDefault.doubleForKey("mapViewCenterLat")
        mapRegion.center.longitude = userDefault.doubleForKey("mapViewCenterLong")
        
        mapView.setRegion(mapRegion, animated: true)
        
        let uilgr = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.addAnnotation(_:)))
        uilgr.minimumPressDuration = 2.0
        mapView.addGestureRecognizer(uilgr)
    }
    
    // MARK: ===== Map Delegate Methods =====
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "pin"
        var view: MKPinAnnotationView
        if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
            as? MKPinAnnotationView {
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.canShowCallout = true
            view.animatesDrop = true
        }
        return view
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        userDefault.setDouble(mapView.region.span.latitudeDelta, forKey: "mapViewSpanLat")
        userDefault.setDouble(mapView.region.span.longitudeDelta, forKey: "mapViewSpanLong")
        userDefault.setDouble(mapView.region.center.latitude, forKey: "mapViewCenterLat")
        userDefault.setDouble(mapView.region.center.longitude, forKey: "mapViewCenterLong")
    }
    
    
    func addAnnotation(gestureRecognizer:UIGestureRecognizer){
        if gestureRecognizer.state == UIGestureRecognizerState.Began {
            let touchPoint = gestureRecognizer.locationInView(mapView)
            let newCoordinates = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            let annotation = MKPointAnnotation()
            
            annotation.coordinate = newCoordinates
            
            CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: newCoordinates.latitude, longitude: newCoordinates.longitude), completionHandler: {(placemarks, error) -> Void in
                if error != nil {
                    print("Reverse geocoder failed with error" + error!.localizedDescription)
                    return
                }
                
                if let placemark = placemarks?[0] {
                    annotation.title = placemark.name
                    dispatch_async(dispatch_get_main_queue(), {
                        self.mapView.addAnnotation(annotation)
                        self.mapView.selectAnnotation(annotation, animated: true)
                    })
                } else {
                    annotation.title = "Unknown Place"
                    dispatch_async(dispatch_get_main_queue(), {
                        self.mapView.addAnnotation(annotation)
                        self.mapView.selectAnnotation(annotation, animated: true)
                    })
                }
            })
        }
    }


}

