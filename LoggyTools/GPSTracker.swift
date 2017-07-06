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

  public typealias TrackLogger = (TrackPoint, Bool) -> Void
  public typealias WaypointLogger = (TrackPoint) -> Void
  public typealias StateMonitor = (Bool) -> Void

  var loggers : [(Int,TrackLogger)] = []
  var waypointLoggers : [(Int,WaypointLogger)] = []
  var loggerId = 0
  let loc_mgr : CLLocationManager
  var pendingTracking = false
  var pendingOneshotTracking : [((TrackPoint) -> Void)] = []
  var loc_delegate : LocDelegate! = nil
  private var isActive = false
  var state_callback : StateMonitor?
  
  struct Config {
    var timeThreshold: Double
    var distThreshold: Double
    func isSignificant(_ pt1: TrackPoint, _ pt2: TrackPoint) -> Bool {
      var time_diff = Double.greatestFiniteMagnitude
      let tm1 = pt1.timestamp
      let tm2 = pt2.timestamp
      time_diff = tm1.timeIntervalSince(tm2)
      let dist_diff = GPSTracker.greatCircleDist(pt1.location, pt2.location)
      return dist_diff > distThreshold || time_diff > timeThreshold
    }
  }
  var config : Config = Config(timeThreshold: 10, distThreshold: 1)
  var last_point : TrackPoint?
  var last_minor_point : TrackPoint?
  
  public init() {
    loc_mgr = CLLocationManager()
    let delegate = LocDelegate(self)
    loc_mgr.delegate = delegate
    loc_delegate = delegate
  }

  public func monitorState(callback : @escaping StateMonitor) {
    self.state_callback = callback
    self.state_callback?(isActive)
  }
  
  func startPendingTracking() {
    if pendingTracking || pendingOneshotTracking.count > 0{
      loc_mgr.startUpdatingLocation()
      isActive = true
      self.state_callback?(isActive)
    }
  }
  
  public func addTrackLogger(_ logger : @escaping TrackLogger) -> Token {
    loggerId += 1
    let removeId = loggerId
    self.loggers.append((removeId,logger))
    return TokenImpl {
      for ix in self.loggers.indices {
        if self.loggers[ix].0 == removeId {
          self.loggers.remove(at: ix)
          break
        }
      }
    }
  }
  public func addWaypointLogger(_ logger : @escaping WaypointLogger) -> Token {
    loggerId += 1
    let removeId = loggerId
    self.waypointLoggers.append((removeId,logger))
    return TokenImpl {
      for ix in self.waypointLoggers.indices {
        if self.waypointLoggers[ix].0 == removeId {
          self.waypointLoggers.remove(at: ix)
          break
        }
      }
    }
  }
  
  public func storeWaypoint() {
    self.withCurrentLocation { pt in
      self.storeWaypoint(location:pt)
    }
  }
  public func storeWaypoint(location pt: TrackPoint) {
    for logger in self.waypointLoggers {
      logger.1(pt)
    }
  }

  public func start() {
    pendingTracking = true
    
    internalStart()
  }
  
  private func internalStart() {
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
    internalStop()
  }
  
  fileprivate func internalStop() {
    loc_mgr.stopUpdatingLocation()
    isActive = false
    self.state_callback?(isActive)
  }
  
  public func currentLocation() -> TrackPoint? {
    if let pt = last_minor_point, isActive {
      return pt
    } else {
      return nil
    }
  }
  
  public func withCurrentLocation(callback: @escaping (TrackPoint) -> Void) {
    if let pt = last_minor_point, isActive {
      callback(pt)
    } else {
      pendingOneshotTracking.append(callback)
      internalStart()
    }
  }
  
  public func isGpsActive() -> Bool {
    return isActive
  }
  
  func handleNewLocation(_ tp : TrackPoint) {
    last_minor_point = tp
    let significant = last_point == nil || config.isSignificant(last_point!, tp)
    for (_,logger) in loggers {
      logger(tp, significant)
    }
    last_point = tp
  }
  
  class LocDelegate : NSObject, CLLocationManagerDelegate {
    let parent : GPSTracker
    init(_ gps : GPSTracker) {
      parent = gps
    }
    func locationManager(_ : CLLocationManager, didUpdateLocations locs: [CLLocation]) {
//      print("Tells the delegate that new location data is available: [\(locs)]")
      var last_pt : TrackPoint?
      for loc in locs {
        let pt = TrackPoint(location: loc.coordinate, timestamp: loc.timestamp)
        parent.handleNewLocation(pt)
        last_pt = pt
      }
      if parent.pendingOneshotTracking.count > 0 {
        if let pt = last_pt {
          for cb in parent.pendingOneshotTracking {
            cb(pt)
          }
          parent.pendingOneshotTracking.removeAll()
        }
        if !parent.pendingTracking {
          parent.internalStop()
        }
      }
    }
    
    func locationManager(_ : CLLocationManager, didFailWithError error: Error) {
      print("Tells the delegate that the location manager was unable to retrieve a location value.\n\(error)")
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
  
  
  public static func greatCircleDist(_ loc1: CLLocationCoordinate2D, _ loc2: CLLocationCoordinate2D) -> Double {
    // Equirectangular approximation
    // see: http://www.movable-type.co.uk/scripts/latlong.html
    let lat1 = loc1.latitude
    let lon1 = loc1.longitude
    let lat2 = loc2.latitude
    let lon2 = loc2.longitude
    let R = 6371000.0
    
    let x = (lon2-lon1) * cos((lat1+lat2)/2);
    let y = (lat2-lat1);
    let d = sqrt(x*x + y*y) * R;
    return d
  }
}

