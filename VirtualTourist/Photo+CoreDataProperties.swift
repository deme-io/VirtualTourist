//
//  Photo+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Demetrius Henry on 8/9/16.
//  Copyright © 2016 Demetrius Henry. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Photo {

    @NSManaged var id: NSNumber?
    @NSManaged var image: NSData?
    @NSManaged var imageURL: String?
    @NSManaged var pin: Pin?

}
