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
    
    var context: NSManagedObjectContext {
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return delegate.dataController.managedObjectContext
    }
    
    let userDefault = NSUserDefaults.standardUserDefaults()
    
    @IBOutlet weak var mapView: MKMapView!
    
    
    
    
    // MARK: ===== View Methods =====
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.addAnnotation(_:)))
        longPressGesture.minimumPressDuration = 0.85
        mapView.addGestureRecognizer(longPressGesture)
        
        
        if userDefault.boolForKey("appHasBeenLaunchedBefore") {
            loadMapRegion()
        } else {
            setDefaultMapRegion()
            userDefault.setBool(true, forKey: "appHasBeenLaunchedBefore")
            saveMapRegion()
        }        
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        loadMapPins()
    }
    
    
    // MARK: ===== Map Data Methods =====
    
    private func setDefaultMapRegion() {
        var mapRegion = MKCoordinateRegion()
        mapRegion.center = CLLocationCoordinate2D(latitude: 39.8282, longitude: -98.5795)
        mapRegion.span = MKCoordinateSpan(latitudeDelta: 70, longitudeDelta: 70)
        mapView.setRegion(mapRegion, animated: true)
    }
    
    
    private func loadMapPins() {
        let request = NSFetchRequest(entityName: "Pin")
        
        do {
            if let pins = try context.executeFetchRequest(request) as? [Pin] {
                mapView.addAnnotations(pins)
            }
        } catch {
            print(error)
        }
    }
    
    
    
    // MARK: ===== Map Region Persist Methods =====
    
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
        if let annotation = annotation as? Pin {
            let identifier = "pin"
            var view: MKPinAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
                as? MKPinAnnotationView {
                dequeuedView.annotation = annotation
                view = dequeuedView
            } else {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
                view.canShowCallout = true
                view.animatesDrop = true
            }
            return view
        }
        return nil
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
    
    
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        performSegueWithIdentifier("Photo Album Segue", sender: view)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "Photo Album Segue" {
            if let photoAlbumVC = segue.destinationViewController.childViewControllers[0] as? PhotoAlbumViewController {
                photoAlbumVC.pin = sender?.annotation as? Pin
            }
        }
    }
    
    
    func addAnnotation(gestureRecognizer:UIGestureRecognizer){
        if gestureRecognizer.state == .Ended {
            let touchPoint = gestureRecognizer.locationInView(mapView)
            let newCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            
            if let annotation = NSEntityDescription.insertNewObjectForEntityForName("Pin", inManagedObjectContext: context) as? Pin {
                annotation.latitude = newCoordinate.latitude
                annotation.longitude = newCoordinate.longitude
                
                CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: newCoordinate.latitude, longitude: newCoordinate.longitude), completionHandler: {(placemarks, error) -> Void in
                    if error != nil {
                        print("Reverse geocoder failed with error" + error!.localizedDescription)
                        return
                    }
                    
                    if let placemark = placemarks?[0] {
                        if placemark.name != "" {
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
                        
                        if self.context.hasChanges {
                            try! self.context.save()
                            print("Context Saved")
                        }
                    }
                })
                let request = NSFetchRequest(entityName: "Pin")
                print(context.countForFetchRequest(request, error: nil))
            }
        }
    }
    
    
}

