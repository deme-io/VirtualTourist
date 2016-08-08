//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Demetrius Henry on 8/6/16.
//  Copyright © 2016 Demetrius Henry. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate {
    
    // MARK: ===== Properties =====
    
    let userDefault = NSUserDefaults.standardUserDefaults()
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: ===== View Methods =====
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.addAnnotation(_:)))
        longPressGesture.minimumPressDuration = 0.85
        mapView.addGestureRecognizer(longPressGesture)
        
        loadMapRegion()
    }
    
    
    private func saveMapRegion() {
        userDefault.setDouble(mapView.region.span.latitudeDelta, forKey: "mapViewSpanLat")
        userDefault.setDouble(mapView.region.span.longitudeDelta, forKey: "mapViewSpanLong")
        userDefault.setDouble(mapView.region.center.latitude, forKey: "mapViewCenterLat")
        userDefault.setDouble(mapView.region.center.longitude, forKey: "mapViewCenterLong")
    }
    
    private func loadMapRegion() {
        var mapRegion = MKCoordinateRegion()
        mapRegion.span.latitudeDelta = userDefault.doubleForKey("mapViewSpanLat")
        mapRegion.span.longitudeDelta = userDefault.doubleForKey("mapViewSpanLong")
        mapRegion.center.latitude = userDefault.doubleForKey("mapViewCenterLat")
        mapRegion.center.longitude = userDefault.doubleForKey("mapViewCenterLong")
        
        mapView.setRegion(mapRegion, animated: true)
    }
    
    // MARK: ===== MapView Delegate Methods =====
    
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
        saveMapRegion()
    }
    
    
    func addAnnotation(gestureRecognizer:UIGestureRecognizer){
        if gestureRecognizer.state == .Began {
            let touchPoint = gestureRecognizer.locationInView(mapView)
            let newCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            
            let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let context = delegate.dataController.managedObjectContext
            if let annotation = NSEntityDescription.insertNewObjectForEntityForName("Pin", inManagedObjectContext: context) as? Pin {
                annotation.latitude = newCoordinate.latitude
                annotation.longitude = newCoordinate.longitude
                
                CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: newCoordinate.latitude, longitude: newCoordinate.longitude), completionHandler: {(placemarks, error) -> Void in
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
                
                try! context.save()
                
                let request = NSFetchRequest(entityName: "Pin")
                print(context.countForFetchRequest(request, error: nil))
            }
            
        }
    }


}

