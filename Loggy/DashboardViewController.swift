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
  @IBOutlet weak var waypointButton: UIButton!
  @IBOutlet weak var stopButton: UIButton!
  @IBOutlet weak var startButton: UIButton!
  @IBOutlet weak var mapView: MKMapView!
  
  var infoValueLabels : [UILabel] = []
  
  var settings: SettingsRW!
  var gpxController: GPXBacking!
  var units: UnitController!

  let gps: GPSTracker
  var isTracking: Bool {
    get {
      return settings.isSet(SettingName.TrackingEnabled)
    }
  }
  
  var mapTracks: MapTracks!
  
  
  var photosObserver: CameraPhotosObserver!
  
  var regs = TokenRegs()
  
  var tapHandlers : [LabelTapHandler] = []
  required init?(coder aCoder: NSCoder) {
    gps = GPSTracker()
    super.init(coder: aCoder)
  }
  
  func updateLocationInfo(_ pt: TrackPoint, color: UIColor = UIColor.black) {
    self.locationValue.text = self.units.location.format((pt.location.latitude, pt.location.longitude))
    if let ele = pt.elevation {
      self.altitudeValue.text = self.units.altitude.format(ele)
    }
    if let speed = pt.speed {
      self.speedValue.text = self.units.speed.format(speed)
    }
    if let bearing = pt.bearing {
      self.bearingValue.text = self.units.bearing.format(bearing)
    }
    for label in infoValueLabels {
      label.textColor = color
    }
    
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()

    infoValueLabels = [ locationValue, altitudeValue, speedValue, bearingValue ]

    mapTracks = MapTracks(mapView, gpxController.gpxData(), gps)
    
    tapHandlers.append(contentsOf: [
      LabelTapHandler(locationValue, { self.toggleUnit($0) }),
      LabelTapHandler(speedValue, { self.toggleUnit($0) }),
      LabelTapHandler(altitudeValue, { self.toggleUnit($0) }),
      LabelTapHandler(bearingValue, { self.toggleUnit($0) })
    ])
    tapHandlers.removeAll()
    
    regs += settings.observe(key: SettingName.PowerSave, onChange: { value in
      self.updateGpsState(isTracking: self.isTracking, powerSave: (value == "true"))
    })
    regs += settings.observe(key: SettingName.TrackingEnabled) { value in
      if value == "true" {
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
      
      self.updateInterfaceState(isTracking: value == "true")
    }
    
    updateGpsState(isTracking: isTracking,
                   powerSave: settings.isSet(SettingName.PowerSave))

    gps.setTrackLogger{ pt, isMajor in

      if isMajor {
        self.updateLocationInfo(pt)
      }
      
      self.mapTracks.handleNewLocation(point:pt, isMajor:isMajor)
    }
    
    self.photosObserver = CameraPhotosObserver({ loc, date in
      if self.settings.isSet(SettingName.AutoWaypoint) &&
        (self.isTracking ||
          self.settings.isSet(SettingName.AlwaysAutoWaypoint)) {
        if let date = date {
          self.storeWaypoint(TrackPoint(location:loc.coordinate, timestamp:date))
        } else {
          print("No date in photo!")
        }
      }
    })
  }
  
  func updateInterfaceState(isTracking: Bool) {
    self.startButton.isEnabled = !isTracking
    self.stopButton.isEnabled = isTracking
    
    let alwaysAutoWaypoint = settings.isSet(SettingName.AlwaysAutoWaypoint)

    self.waypointButton.isEnabled = alwaysAutoWaypoint || isTracking
    self.startButton.alpha = self.startButton.isEnabled ? 1.0 : 0.5
    self.stopButton.alpha = self.stopButton.isEnabled ? 1.0 : 0.5
    self.waypointButton.alpha = self.waypointButton.isEnabled ? 1.0 : 0.5
  }
  
  func updateGpsState(isTracking: Bool, powerSave: Bool) {
    if !powerSave || isTracking {
      gps.start()
    } else {
      gps.stop()
    }
  }
  
  
  func toggleUnit(_ sender: UIView) {
    if sender == speedValue {
      settings.update(value: units.speed.next().rawValue, forKey:SettingName.SpeedUnit)
    }
    else if sender == altitudeValue {
      settings.update(value: units.altitude.next().rawValue, forKey: SettingName.AltitudeUnit)
    }
    else if sender == locationValue {
      settings.update(value: units.location.next().rawValue, forKey: SettingName.LocationUnit)
    }
    else if sender == bearingValue {
      settings.update(value: units.bearing.next().rawValue, forKey: SettingName.BearingUnit)
    }
  }
  
  
  @IBAction func startTracking(_ sender: Any) {
    mapTracks.startNewSegment()
    settings.update(value: "true", forKey:SettingName.TrackingEnabled)
  }

  @IBAction func stopTracking(_ sender: Any) {
    settings.update(value: "false", forKey:SettingName.TrackingEnabled)
    mapTracks.endSegment(gps.currentLocation())
  }
  
  @IBAction func storeWaypoint(sender: UIButton) {
    if let pt = gps.currentLocation() {
      storeWaypoint(pt)
    }
  }

  func storeWaypoint(_ pt : TrackPoint) {
    self.updateLocationInfo(pt, color: UIColor.blue)
    print("Store waypoint [location \(pt.location)] [date \(pt.timestamp)]")
    mapTracks.storeWaypoint(location: pt)
  }
  
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
}

