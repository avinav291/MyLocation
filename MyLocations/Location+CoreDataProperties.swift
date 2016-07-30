//
//  Location+CoreDataProperties.swift
//  MyLocations
//
//  Created by Avinav Goel on 22/02/16.
//  Copyright © 2016 Avinav Goel. All rights reserved.
//
//

import Foundation
import CoreData
import CoreLocation

extension Location {

    @NSManaged var category: String
    @NSManaged var date: NSDate
    @NSManaged var latitude: Double
    @NSManaged var locationDescription: String
    @NSManaged var longitude: Double
    @NSManaged var placemark: CLPlacemark?
    @NSManaged var photoID: NSNumber?

}
