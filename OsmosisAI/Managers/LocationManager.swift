//  Copyright © 2018 OsmosisAI, Inc. All rights reserved.

/*
 CONFIDENTIALITY NOTICE:
 This Software and all associated source files are confidential
 and intended only for use by individual or entity to which addressed
 and may contain information that is privileged, confidential and exempt from disclosure under applicable law.
 If you are not the intended recipient, be aware that any use, dissemination or disclosure,
 distribution or copying of communication or attachments is strictly prohibited.
 */

import Foundation
import CoreLocation

protocol LocationManagerDelegate: class {
  func locationManagerDidUpdateLocation(_ locationManager: LocationManager, location: CLLocation)
  func locationManagerDidUpdateHeading(_ locationManager: LocationManager, heading: CLLocationDirection, accuracy: CLLocationDirection)
}

///Handles retrieving the location and heading from CoreLocation
///Does not contain anything related to ARKit or advanced location
public class LocationManager: NSObject, CLLocationManagerDelegate {
  
  // MARK: - Properties
  
  public static let shared = LocationManager()
  
  weak var delegate: LocationManagerDelegate?
  
  private var locationManager: CLLocationManager?
  
  var currentLocation: CLLocation?  
  private(set) public var heading: CLLocationDirection?
  private(set) public var headingAccuracy: CLLocationDegrees?
  
  
  // MARK: - Object Lifecycle
  
  override init() {
    super.init()
    
    self.locationManager = CLLocationManager()
    self.locationManager!.desiredAccuracy = kCLLocationAccuracyBestForNavigation
    self.locationManager!.distanceFilter = kCLDistanceFilterNone
    self.locationManager!.headingFilter = kCLHeadingFilterNone
    self.locationManager!.pausesLocationUpdatesAutomatically = false
    self.locationManager!.delegate = self
    self.locationManager!.startUpdatingHeading()
    self.locationManager!.startUpdatingLocation()
    
    self.locationManager!.requestWhenInUseAuthorization()
    
    self.currentLocation = self.locationManager!.location
  }
  
  
  // MARK: - Private Methods
  
  func requestAuthorization() {
    if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways ||
      CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse {
      return
    }
    
    if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.denied ||
      CLLocationManager.authorizationStatus() == CLAuthorizationStatus.restricted {
      return
    }
    
    locationManager?.requestWhenInUseAuthorization()
  }
  
  
  // MARK: - Public Methods
  
  func startUpdatingLocation() {
    locationManager?.startUpdatingLocation()
  }
  
  func stopUpdatingLocation() {
    locationManager?.stopUpdatingLocation()
  }
  
  
  // MARK: - CLLocationManagerDelegate
  
  public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    
  }
  
  public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    for location in locations {
      delegate?.locationManagerDidUpdateLocation(self, location: location)
    }
    
    currentLocation = manager.location
  }
  
  public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
    if newHeading.headingAccuracy >= 0 {
      heading = newHeading.trueHeading
    } else {
      heading = newHeading.magneticHeading
    }
    
    headingAccuracy = newHeading.headingAccuracy
    
    delegate?.locationManagerDidUpdateHeading(self, heading: heading!, accuracy: newHeading.headingAccuracy)
  }
  
  public func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
    return true
  }
}

