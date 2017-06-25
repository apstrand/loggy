//
//  GPSTracker.swift
//  Loggy
//
//  Created by Peter Strand on 2017-06-19.
//  Copyright © 2017 Peter Strand. All rights reserved.
//

import Foundation
import CoreLocation

public class GPSTracker {
  
  public struct TrackPoint {
    public let location : CLLocation
  }
  
  public typealias TrackLogger = (TrackPoint) -> Void
  
  var logger : TrackLogger?
  let loc_mgr : CLLocationManager
  var pendingTracking = false
  var loc_delegate : LocDelegate! = nil
  
  public init() {
    loc_mgr = CLLocationManager()
    let delegate = LocDelegate(self)
    loc_mgr.delegate = delegate
    loc_delegate = delegate
  }
  
  func startPendingTracking() {
    if pendingTracking {
      loc_mgr.startUpdatingLocation()
    }
    
    
  }
  
  public func setTrackLogger(_ logger : @escaping TrackLogger) {
    self.logger = logger
  }
  
  public func start() {
    pendingTracking = true
    
    let status = CLLocationManager.authorizationStatus()
    print("start: gps status: \(status.rawValue)")
    
    switch status {
    case .notDetermined:
      // loc_mgr?.requestWhenInUseAuthorization()
      loc_mgr.requestAlwaysAuthorization()
      break
    case .authorizedAlways, .authorizedWhenInUse:
      startPendingTracking()
    default:
      break
    }
  }
  
  public func stop() {
    pendingTracking = false
  }
  
  public func storeWaypoint() {
    
  }
  
  class LocDelegate : NSObject, CLLocationManagerDelegate {
    let parent : GPSTracker
    init(_ gps : GPSTracker) {
      parent = gps
    }
    func locationManager(_ : CLLocationManager, didUpdateLocations locs: [CLLocation]) {
//      print("Tells the delegate that new location data is available: [\(locs)]")
      if let logger = parent.logger {
        for loc in locs {
          let tp : TrackPoint = TrackPoint(location: loc)
          logger(tp)
        }
      }
    }
    
    func locationManager(_ : CLLocationManager, didFailWithError: Error) {
      print("Tells the delegate that the location manager was unable to retrieve a location value.")
    }
    
    func locationManager(_ : CLLocationManager, didFinishDeferredUpdatesWithError: Error?) {
      print("Tells the delegate that updates will no longer be deferred.")
    }
    
    func locationManagerDidPauseLocationUpdates(_ : CLLocationManager) {
      print("Tells the delegate that location updates were paused.")
    }
    
    func locationManagerDidResumeLocationUpdates(_ _ : CLLocationManager) {
      print("Tells the delegate that the delivery of location updates has resumed.\nResponding to Heading Events")
    }
    
    func locationManager(_ : CLLocationManager, didUpdateHeading: CLHeading) {
      print("Tells the delegate that the location manager received updated heading information.")
    }
    
    func locationManagerShouldDisplayHeadingCalibration(_ : CLLocationManager) -> Bool {
      print("Asks the delegate whether the heading calibration alert should be displayed.\nResponding to Region Events")
      return false
    }
    
    func locationManager(_ : CLLocationManager, didEnterRegion: CLRegion) {
      print("Tells the delegate that the user entered the specified region.")
    }
      
    func locationManager(_ : CLLocationManager, didExitRegion: CLRegion) {
      print("Tells the delegate that the user left the specified region.")
    }
    func locationManager(_ : CLLocationManager, didDetermineState: CLRegionState, for: CLRegion) {
      print("Tells the delegate about the state of the specified region.")
    }
    func locationManager(_ : CLLocationManager, monitoringDidFailFor: CLRegion?, withError: Error) {
      print("Tells the delegate that a region monitoring error occurred.")
    }
    
    func locationManager(_ : CLLocationManager, didStartMonitoringFor: CLRegion) {
      print("Tells the delegate that a new region is being monitored.\nResponding to Ranging Events")
    }
    
    func locationManager(_ : CLLocationManager, didRangeBeacons: [CLBeacon], in: CLBeaconRegion) {
      print("Tells the delegate that one or more beacons are in range.")
    }
    
    func locationManager(_ : CLLocationManager, rangingBeaconsDidFailFor: CLBeaconRegion, withError: Error) {
      print("Tells the delegate that an error occurred while gathering ranging information for a set of beacons.\nResponding to Visit Events")
    }
    
    func locationManager(_ : CLLocationManager, didVisit: CLVisit) {
      print("Tells the delegate that a new visit-related event was received.\nResponding to Authorization Changes")
    }
  
    func locationManager(_ : CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
      
      print("didChangeAuthorization: gps status: \(status.rawValue)")
      
      switch status {
      case .authorizedAlways, .authorizedWhenInUse:
        parent.startPendingTracking()
        break
      default:
        break
      }
    }
    
  }
  
}

