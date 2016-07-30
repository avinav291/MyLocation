//
//  CurrentLocationViewController.swift
//  MyLocations
//
//  Created by Avinav Goel on 22/02/16.
//  Copyright © 2016 Avinav Goel. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData
import QuartzCore
import AudioToolbox

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate {
  @IBOutlet weak var messageLabel: UILabel!
  @IBOutlet weak var latitudeLabel: UILabel!
  @IBOutlet weak var longitudeLabel: UILabel!
  @IBOutlet weak var addressLabel: UILabel!
  @IBOutlet weak var tagButton: UIButton!
  @IBOutlet weak var getButton: UIButton!
  @IBOutlet weak var latitudeTextLabel: UILabel!
  @IBOutlet weak var longitudeTextLabel: UILabel!
  @IBOutlet weak var containerView: UIView!
  
  let locationManager = CLLocationManager()
  var location: CLLocation?
  var updatingLocation = false
  var lastLocationError: NSError?

  let geocoder = CLGeocoder()
  var placemark: CLPlacemark?
  var performingReverseGeocoding = false
  var lastGeocodingError: NSError?
  
  var timer: Timer?

  var managedObjectContext: NSManagedObjectContext!

  var logoVisible = false
  
  lazy var logoButton: UIButton = {
    let button = UIButton(type: .custom)
    button.setBackgroundImage(UIImage(named: "Logo"), for: .normal)
    button.sizeToFit()
    button.addTarget(self, action: Selector("getLocation"), for: .touchUpInside)
    button.center.x = self.view.bounds.midX
    button.center.y = 220
    return button
  }()
  
  var soundID: SystemSoundID = 0
  
  @IBAction func getLocation() {
    let authStatus = CLLocationManager.authorizationStatus()
    
    if authStatus == .notDetermined {
      locationManager.requestWhenInUseAuthorization()
      return
    }
    
    if authStatus == .denied || authStatus == .restricted {
      showLocationServicesDeniedAlert()
      return
    }
    
    if logoVisible {
      hideLogoView()
    }
    
    if updatingLocation {
      stopLocationManager()
    } else {
      location = nil
      lastLocationError = nil
      placemark = nil
      lastGeocodingError = nil
      startLocationManager()
    }

    updateLabels()
    configureGetButton()
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    updateLabels()
    configureGetButton()
    loadSoundEffect("Sound.caf")
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  func showLocationServicesDeniedAlert() {
    let alert = UIAlertController(title: "Location Services Disabled",
      message: "Please enable location services for this app in Settings.",
      preferredStyle: .alert)

    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
    alert.addAction(okAction)
    
    present(alert, animated: true, completion: nil)
  }
  
  func startLocationManager() {
    if CLLocationManager.locationServicesEnabled() {
      locationManager.delegate = self
      locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
      locationManager.startUpdatingLocation()
      updatingLocation = true

      timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(CurrentLocationViewController.didTimeOut), userInfo: nil, repeats: false)
    }
  }
  
  func stopLocationManager() {
    if updatingLocation {
      locationManager.stopUpdatingLocation()
      locationManager.delegate = nil
      updatingLocation = false

      if let timer = timer {
        timer.invalidate()
      }
    }
  }

  func didTimeOut() {
    print("*** Time out")
    
    if location == nil {
      stopLocationManager()

      lastLocationError = NSError(domain: "MyLocationsErrorDomain", code: 1, userInfo: nil)
      
      updateLabels()
      configureGetButton()
    }
  }
  
  func updateLabels() {
    if let location = location {
      latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
      longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
      tagButton.isHidden = false
      messageLabel.text = ""
      
      if let placemark = placemark {
        addressLabel.text = stringFromPlacemark(placemark)
      } else if performingReverseGeocoding {
        addressLabel.text = "Searching for Address..."
      } else if lastGeocodingError != nil {
        addressLabel.text = "Error Finding Address"
      } else {
        addressLabel.text = "No Address Found"
      }
      
      latitudeTextLabel.isHidden = false
      longitudeTextLabel.isHidden = false
    } else {
      latitudeLabel.text = ""
      longitudeLabel.text = ""
      addressLabel.text = ""
      tagButton.isHidden = true
      
      let statusMessage: String
      if let error = lastLocationError {
        if error.domain == kCLErrorDomain && error.code == CLError.denied.rawValue {
          statusMessage = "Location Services Disabled"
        } else {
          statusMessage = "Error Getting Location"
        }
      } else if !CLLocationManager.locationServicesEnabled() {
        statusMessage = "Location Services Disabled"
      } else if updatingLocation {
        statusMessage = "Searching..."
      } else {
        statusMessage = ""
        showLogoView()
      }
      
      messageLabel.text = statusMessage
      latitudeTextLabel.isHidden = true
      longitudeTextLabel.isHidden = true
    }
  }
  
  func stringFromPlacemark(placemark: CLPlacemark) -> String {
    var line1 = ""
    line1.addText(placemark.subThoroughfare)
    line1.addText(placemark.thoroughfare, withSeparator: " ")
    
    var line2 = ""
    line2.addText(placemark.locality)
    line2.addText(placemark.administrativeArea, withSeparator: " ")
    line2.addText(placemark.postalCode, withSeparator: " ")
    
    line1.addText(line2, withSeparator: "\n")
    return line1
  }
  
  func configureGetButton() {
    let spinnerTag = 1000
    
    if updatingLocation {
      getButton.setTitle("Stop", for: .normal)
      
      if view.viewWithTag(spinnerTag) == nil {
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .white)
        spinner.center = messageLabel.center
        spinner.center.y += spinner.bounds.size.height/2 + 15
        spinner.startAnimating()
        spinner.tag = spinnerTag
        containerView.addSubview(spinner)
      }
    } else {
      getButton.setTitle("Get My Location", for: .normal)
      
      if let spinner = view.viewWithTag(spinnerTag) {
        spinner.removeFromSuperview()
      }
    }
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "TagLocation" {
      let navigationController = segue.destinationViewController as! UINavigationController
      let controller = navigationController.topViewController as! LocationDetailsViewController
      
      controller.coordinate = location!.coordinate
      controller.placemark = placemark
      controller.managedObjectContext = managedObjectContext
    }
  }
  
  // MARK: - CLLocationManagerDelegate
  
  func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
    print("didFailWithError \(error)")
    
    if error.code == CLError.locationUnknown.rawValue {
      return
    }
    
    lastLocationError = error
    
    stopLocationManager()
    updateLabels()
    configureGetButton()
  }

  func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    let newLocation = locations.last!
    print("didUpdateLocations \(newLocation)")
    
    if newLocation.timestamp.timeIntervalSinceNow < -5 {
      return
    }
    
    if newLocation.horizontalAccuracy < 0 {
      return
    }

    var distance = CLLocationDistance(DBL_MAX)
    if let location = location {
      distance = newLocation.distance(from: location)
    }
    
    if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy {

      lastLocationError = nil
      location = newLocation
      updateLabels()
      
      if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy {
        print("*** We're done!")
        stopLocationManager()
        configureGetButton()
        
        if distance > 0 {
          performingReverseGeocoding = false
        }
      }
      
      if !performingReverseGeocoding {
        print("*** Going to geocode")
        
        performingReverseGeocoding = true
        
        geocoder.reverseGeocodeLocation(newLocation, completionHandler: {
          placemarks, error in
          
          //print("*** Found placemarks: \(placemarks), error: \(error)")
          
          self.lastGeocodingError = error
          if error == nil, let p = placemarks where !p.isEmpty {
            if self.placemark == nil {
              print("FIRST TIME!")
              self.playSoundEffect()
            }
            self.placemark = p.last!
          } else {
            self.placemark = nil
          }
          
          self.performingReverseGeocoding = false
          self.updateLabels()
        })
      }
    } else if distance < 1.0 {
      let timeInterval = newLocation.timestamp.timeIntervalSinceDate(location!.timestamp)
      if timeInterval > 10 {
        print("*** Force done!")
        stopLocationManager()
        updateLabels()
        configureGetButton()
      }
    }
  }
  
  // MARK: - Logo View
  
  func showLogoView() {
    if !logoVisible {
      logoVisible = true
      containerView.isHidden = true
      view.addSubview(logoButton)
    }
  }
  
  func hideLogoView() {
    if !logoVisible { return }
    
    logoVisible = false
    containerView.isHidden = false
    containerView.center.x = view.bounds.size.width * 2
    containerView.center.y = 40 + containerView.bounds.size.height / 2
    
    let centerX = view.bounds.midX
    
    let panelMover = CABasicAnimation(keyPath: "position")
    panelMover.isRemovedOnCompletion = false
    panelMover.fillMode = kCAFillModeForwards
    panelMover.duration = 0.6
    panelMover.fromValue = NSValue(CGPoint: containerView.center)
    panelMover.toValue = NSValue(CGPoint: CGPoint(x: centerX, y: containerView.center.y))
    panelMover.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
    panelMover.delegate = self
    containerView.layer.add(panelMover, forKey: "panelMover")
    
    let logoMover = CABasicAnimation(keyPath: "position")
    logoMover.isRemovedOnCompletion = false
    logoMover.fillMode = kCAFillModeForwards
    logoMover.duration = 0.5
    logoMover.fromValue = NSValue(CGPoint: logoButton.center)
    logoMover.toValue = NSValue(CGPoint:CGPoint(x: -centerX, y: logoButton.center.y))
    logoMover.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
    logoButton.layer.add(logoMover, forKey: "logoMover")
    
    let logoRotator = CABasicAnimation(keyPath: "transform.rotation.z")
    logoRotator.isRemovedOnCompletion = false
    logoRotator.fillMode = kCAFillModeForwards
    logoRotator.duration = 0.5
    logoRotator.fromValue = 0.0
    logoRotator.toValue = -2 * M_PI
    logoRotator.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
    logoButton.layer.add(logoRotator, forKey: "logoRotator")
  }
  
  override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
    containerView.layer.removeAllAnimations()
    containerView.center.x = view.bounds.size.width / 2
    containerView.center.y = 40 + containerView.bounds.size.height / 2
    
    logoButton.layer.removeAllAnimations()
    logoButton.removeFromSuperview()
  }
  
  // MARK: - Sound Effect
  
  func loadSoundEffect(name: String) {
    if let path = Bundle.main.pathForResource(name, ofType: nil) {
      let fileURL = NSURL.fileURL(withPath: path, isDirectory: false)
      let error = AudioServicesCreateSystemSoundID(fileURL, &soundID)
      if error != kAudioServicesNoError {
        print("Error code \(error) loading sound at path: \(path)")
      }
    }
  }
  
  func unloadSoundEffect() {
    AudioServicesDisposeSystemSoundID(soundID)
    soundID = 0
  }
  
  func playSoundEffect() {
    AudioServicesPlaySystemSound(soundID)
  }
}
