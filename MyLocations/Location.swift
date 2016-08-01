//
//  Location.swift
//  MyLocations
//
//  Created by Avinav Goel on 13/04/16.
//  Copyright © 2016 Avinav Goel. All rights reserved.
//

import Foundation
import CoreData
import MapKit

class Location: NSManagedObject, MKAnnotation {

  var coordinate: CLLocationCoordinate2D {
    return CLLocationCoordinate2DMake(latitude, longitude)
  }
  
  var title: String? {
    if locationDescription.isEmpty {
      return "(No Description)"
    } else {
      return locationDescription
    }
  }
  
  var subtitle: String? {
    return category
  }
  
  var hasPhoto: Bool {
    return photoID != nil
  }

  var photoPath: String {
    assert(photoID != nil, "No photo ID set")
    let filename = "Photo-\(photoID!.integerValue).jpg"
    return (applicationDocumentsDirectory as NSString).stringByAppendingPathComponent(filename)
  }
  
  var photoImage: UIImage? {
    return UIImage(contentsOfFile: photoPath)
  }
  
  class func nextPhotoID() -> Int {
    let userDefaults = NSUserDefaults.standardUserDefaults()
    let currentID = userDefaults.integerForKey("PhotoID")
    userDefaults.setInteger(currentID + 1, forKey: "PhotoID")
    userDefaults.synchronize()
    return currentID
  }
  
  func removePhotoFile() {
    if hasPhoto {
      let path = photoPath
      let fileManager = NSFileManager.defaultManager()
      if fileManager.fileExistsAtPath(path) {
        do {
          try fileManager.removeItemAtPath(path)
        } catch {
          print("Error removing file: \(error)")
        }
      }
    }
  }
}
