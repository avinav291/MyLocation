//
//  LocationCell.swift
//  MyLocations
//
//  Created by Avinav Goel on 22/02/16.
//  Copyright © 2016 Avinav Goel. All rights reserved.
//

import UIKit

class LocationCell: UITableViewCell {

  @IBOutlet weak var descriptionLabel: UILabel!
  @IBOutlet weak var addressLabel: UILabel!
  @IBOutlet weak var photoImageView: UIImageView!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    backgroundColor = UIColor.black()
    descriptionLabel.textColor = UIColor.white()
    descriptionLabel.highlightedTextColor = descriptionLabel.textColor
    addressLabel.textColor = UIColor(white: 1.0, alpha: 0.4)
    addressLabel.highlightedTextColor = addressLabel.textColor
    
    let selectionView = UIView(frame: CGRect.zero)
    selectionView.backgroundColor = UIColor(white: 1.0, alpha: 0.2)
    selectedBackgroundView = selectionView
    
    photoImageView.layer.cornerRadius = photoImageView.bounds.size.width / 2
    photoImageView.clipsToBounds = true
    separatorInset = UIEdgeInsets(top: 0, left: 82, bottom: 0, right: 0)
  }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

  func configureForLocation(location: Location) {
    if location.locationDescription.isEmpty {
      descriptionLabel.text = "(No Description)"
    } else {
      descriptionLabel.text = location.locationDescription
    }
    
    if let placemark = location.placemark {
      var text = ""
      text.addText(placemark.subThoroughfare)
      text.addText(placemark.thoroughfare, withSeparator: " ")
      text.addText(placemark.locality, withSeparator: ", ")
      addressLabel.text = text
    } else {
      addressLabel.text = String(format: "Lat: %.8f, Long: %.8f", location.latitude, location.longitude)
    }
    
    photoImageView.image = imageForLocation(location)    
  }
  
  func imageForLocation(location: Location) -> UIImage {
    if location.hasPhoto, let image = location.photoImage {
      return image.resizedImageWithBounds(CGSize(width: 52, height: 52))
    }
    return UIImage(named: "No Photo")!
  }
}
