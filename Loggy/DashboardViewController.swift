//
//  ViewController.swift
//  Loggy
//
//  Created by Peter Strand on 2017-06-19.
//  Copyright © 2017 Peter Strand. All rights reserved.
//

import UIKit
import MapKit
import LoggyTools
import Photos

class DashboardViewController: UIViewController {

  enum Failure: Error {
    case msg(String)
  }
  
  @IBOutlet weak var locationLabel: UILabel!
  @IBOutlet weak var altitudeLabel: UILabel!
  @IBOutlet weak var speedLabel: UILabel!
  @IBOutlet weak var bearingLabel: UILabel!
  @IBOutlet weak var locationValue: UILabel!
  @IBOutlet weak var altitudeValue: UILabel!
  @IBOutlet weak var speedValue: UILabel!
  @IBOutlet weak var bearingValue: UILabel!
  @IBOutlet weak var autoWaypointToggle: UISwitch!
  @IBOutlet weak var alwaysAutoWaypointToggle: UISwitch!
  @IBOutlet weak var powerSaveToggle: UISwitch!
  @IBOutlet weak var waypointButton: UIButton!
  @IBOutlet weak var stopButton: UIButton!
  @IBOutlet weak var startButton: UIButton!
  @IBOutlet weak var mapView: MKMapView!
  
  let gps : GPSTracker
  
  var map_track : Track?
  var last_poly : MKPolyline?
  
  var mapDelegate : MapDelegate?
  
  var speedUnit = SpeedUnit.M_S
  var altitudeUnit = AltitudeUnit.Meter
  
  var photosObserver : CameraPhotosObserver!
  var logger : FileLogger?
  
  var tapHandlers : [LabelTapHandler] = []
  required init?(coder aCoder: NSCoder) {
    gps = GPSTracker()
    super.init(coder: aCoder)
  }
  
  
  func updateLocationInfo(_ pt: TrackPoint) {
    self.locationValue.text = self.formatCoord(pt.location.coordinate)
    self.altitudeValue.text = self.formatAltitude(pt.location.altitude)
    self.speedValue.text = self.formatSpeed(pt.location.speed)
    self.bearingValue.text = self.formatBearing(pt.location.course)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tapHandlers.append(contentsOf: [
      LabelTapHandler(locationValue, { self.toggleUnit($0) }),
      LabelTapHandler(speedValue, { self.toggleUnit($0) }),
      LabelTapHandler(altitudeValue, { self.toggleUnit($0) }),
      LabelTapHandler(bearingValue, { self.toggleUnit($0) })
    ])
    tapHandlers.removeAll()
    
    let defaults = UserDefaults.standard
    powerSaveToggle.isOn = defaults.bool(forKey: SettingNames.PowerSave)
    autoWaypointToggle.isOn = defaults.bool(forKey: SettingNames.AutoWaypoint)
    alwaysAutoWaypointToggle.isOn = defaults.bool(forKey: SettingNames.AlwaysAutoWaypoint)
    if let alt_unit = defaults.string(forKey: SettingNames.AltitudeUnit) {
      altitudeUnit = AltitudeUnit.parse(alt_unit)
    }
    if let speed_unit = defaults.string(forKey: SettingNames.SpeedUnit) {
      speedUnit = SpeedUnit.parse(speed_unit)
    }
    
    gps.monitorState { is_tracking in
      self.startButton.isEnabled = !is_tracking
      self.stopButton.isEnabled = is_tracking
      self.waypointButton.isEnabled = self.alwaysAutoWaypointToggle.isOn || is_tracking
      self.startButton.alpha = self.startButton.isEnabled ? 1.0 : 0.5
      self.stopButton.alpha = self.stopButton.isEnabled ? 1.0 : 0.5
      self.waypointButton.alpha = self.waypointButton.isEnabled ? 1.0 : 0.5
      

      if is_tracking {
        self.locationValue.text = ""
        self.altitudeValue.text = ""
        self.speedValue.text = ""
        self.bearingValue.text = ""
      } else {
        self.locationValue.text = "- -"
        self.altitudeValue.text = "- -"
        self.speedValue.text = "- -"
        self.bearingValue.text = "- -"
      }
    }
    gps.setTrackLogger{ pt in
      self.logger?.log_point(pt)
      self.updateLocationInfo(pt)
      
      self.mapView.setCenter(pt.location.coordinate, animated: true)
      
      if self.map_track == nil {
        return
      }
      
      self.map_track!.add(pt.location.coordinate)
      
      if let region = self.map_track!.region() {
        self.mapView.setRegion(region, animated: true)
      }
    
      if self.map_track!.coords.count == 1 {
        let place = MKPlacemark.init(coordinate: pt.location.coordinate)
        self.mapView.addAnnotation(place)
      }
      if let poly = self.last_poly {
          self.mapView.remove(poly)
      }
      self.last_poly = MKPolyline(coordinates: &self.map_track!.coords, count: self.map_track!.coords.count)
      self.mapView.add(self.last_poly!)
    }
    
    self.mapView.showsUserLocation = true
    
    self.mapDelegate = MapDelegate(self)
    self.mapView.delegate = self.mapDelegate
    
    self.photosObserver = CameraPhotosObserver({ loc, date in
      if self.autoWaypointToggle.isOn && (self.gps.isTracking() || self.alwaysAutoWaypointToggle.isOn) {
        if let date = date {
          self.storeWaypoint(TrackPoint(location:loc, timestamp:date))
        } else {
          print("No date in photo!")
        }
      }
    })
  }
  
  class MapDelegate : NSObject, MKMapViewDelegate {
    let parent : DashboardViewController
    init(_ p : DashboardViewController) {
      parent = p
    }
    public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
      if overlay is MKPolyline {
        let polyLine = overlay
        let polyLineRenderer = MKPolylineRenderer(overlay: polyLine)
        polyLineRenderer.strokeColor = UIColor.black
        polyLineRenderer.lineWidth = 2.0
        
        return polyLineRenderer
      }
      assert(false)
    }

  }
  
  func toggleUnit(_ sender: UIView) {
    if sender == speedValue {
      speedUnit = speedUnit.next()
      UserDefaults.standard.set(speedUnit.rawValue, forKey:SettingNames.SpeedUnit)
    }
    else if sender == altitudeValue {
      altitudeUnit = altitudeUnit.next()
      UserDefaults.standard.setValue(altitudeUnit.rawValue, forKey: SettingNames.AltitudeUnit)
    }
  }
  
  func formatCoord(_ coord : CLLocationCoordinate2D) -> String {
    return "\(coord.latitude) \(coord.longitude)"
  }
  func formatAltitude(_ altitude : CLLocationDistance) -> String {
    return "\(altitude)"
  }
  func formatSpeed(_ speed : CLLocationSpeed) -> String {
    return speedUnit.format(speed)
  }
  func formatBearing(_ bearing : CLLocationDegrees) -> String {
    return "\(bearing)"
  }
  
  @IBAction func startTracking(_ sender: Any) {
    map_track = Track()
    gps.start()
  }
  @IBAction func stopTracking(_ sender: Any) {
    gps.stop()
    map_track = nil
  }
  
  @IBAction func storeWaypoint(sender: UIButton) {
    if let pt = gps.currentLocation() {
      storeWaypoint(pt)
    }
  }

  func storeWaypoint(_ pt : TrackPoint) {
    if !gps.isTracking() {
      self.updateLocationInfo(pt)
    }
    print("Store waypoint [location \(pt.location)] [date \(pt.timestamp)]")
    let place = MKPlacemark.init(coordinate: pt.location.coordinate)
    self.mapView.addAnnotation(place)
  }
  
  @IBAction func toggleTracking(sender: UISwitch) {
    if sender.isOn {
      try? logger = FileLogger()
      gps.start()
    } else {
      gps.stop()
      logger?.finish()
    }
  }
  
  @IBAction func toggleAutowaypoint(sender: UISwitch) {
    
    
  }
  
  @IBAction func togglePowerSave(sender: UISwitch) {
    
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
}

