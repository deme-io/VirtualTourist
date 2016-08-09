//
//  Pin.swift
//  VirtualTourist
//
//  Created by Demetrius Henry on 8/9/16.
//  Copyright © 2016 Demetrius Henry. All rights reserved.
//

import Foundation
import CoreData
import MapKit


class Pin: NSManagedObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(Double(latitude!), Double(longitude!))
    }

}
