//
//  Pin.swift
//  VirtualTourist
//
//  Created by Demetrius Henry on 8/6/16.
//  Copyright © 2016 Demetrius Henry. All rights reserved.
//

import Foundation
import CoreData
import MapKit

class Pin: NSManagedObject, MKAnnotation {

// Insert code here to add functionality to your managed object subclass
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(Double(latitude!), Double(longitude!))
    }
    

}