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
  
  let gps: GPSTracker
  var isTracking: Bool {
    get {
      return settings.isSet(SettingName.TrackingEnabled)
    }
  }
  
  var mapTrack: TrackHistory!
  var trackPolys: [MKPolyline] = []
  var currentPoly: MKPolyline? = nil
  
  var mapDelegate: MapDelegate?
  
  var speedUnit = SpeedUnit.M_S
  var altitudeUnit = AltitudeUnit.Meter
  
  var photosObserver: CameraPhotosObserver!
  
  var regs = TokenRegs()
  
  var tapHandlers : [LabelTapHandler] = []
  required init?(coder aCoder: NSCoder) {
    gps = GPSTracker()
    super.init(coder: aCoder)
  }

  class LoggyAnnotation: NSObject, MKAnnotation {
    public var coordinate: CLLocationCoordinate2D
    public init(coordinate: CLLocationCoordinate2D) {
      self.coordinate = coordinate
    }
  }
  class WaypointAnnotation: LoggyAnnotation {
    static let identifier = "waypoint"
  }
  
  class TrackAnnotation: LoggyAnnotation {
    static let identifier = "track"
    let isStart: Bool
    public init(coordinate: CLLocationCoordinate2D, isStart: Bool) {
      self.isStart = isStart
      super.init(coordinate: coordinate)
    }
  }
  
  func updateLocationInfo(_ pt: TrackPoint, color: UIColor = UIColor.black) {
    self.locationValue.text = self.formatCoord(pt.location)
    if let ele = pt.elevation {
      self.altitudeValue.text = self.formatAltitude(ele)
    }
    if let speed = pt.speed {
      self.speedValue.text = self.formatSpeed(speed)
    }
    if let bearing = pt.bearing {
      self.bearingValue.text = self.formatBearing(bearing)
    }
    for label in infoValueLabels {
      label.textColor = color
    }
    
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()

    infoValueLabels = [ locationValue, altitudeValue, speedValue, bearingValue ]

    mapTrack = TrackHistory(gpx: gpxController.gpxData())
    
    tapHandlers.append(contentsOf: [
      LabelTapHandler(locationValue, { self.toggleUnit($0) }),
      LabelTapHandler(speedValue, { self.toggleUnit($0) }),
      LabelTapHandler(altitudeValue, { self.toggleUnit($0) }),
      LabelTapHandler(bearingValue, { self.toggleUnit($0) })
    ])
    tapHandlers.removeAll()
    
    if let alt_unit = settings.value(forKey: SettingName.AltitudeUnit) {
      altitudeUnit = AltitudeUnit.parse(alt_unit)
    }
    if let speed_unit = settings.value(forKey: SettingName.SpeedUnit) {
      speedUnit = SpeedUnit.parse(speed_unit)
    }
    
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
      
      self.mapView.setCenter(pt.location, animated: true)

      if self.isTracking && isMajor {
        self.mapTrack.add(pt.location)
      
        if let region = self.mapTrack.region() {
          self.mapView.setRegion(region, animated: true)
        }
    
        if self.mapTrack.gpx.tracks.last!.segments.last!.track.count == 1 {
          let ann = TrackAnnotation(coordinate: pt.location, isStart: true)
          self.mapView.addAnnotation(ann)
        }
        let newPoly = MKPolyline(coordinates: &self.mapTrack.coordCache, count: self.mapTrack.coordCache.count)
        if let poly = self.currentPoly {
          self.mapView.remove(poly)
        } else {
          self.trackPolys.append(newPoly)
        }
        self.mapView.add(newPoly)
        self.currentPoly = newPoly
      }
    }
    
    self.mapDelegate = MapDelegate(self)
    self.mapView.delegate = self.mapDelegate
    
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
      fatalError("mapView: Unknown overlay")
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
      if let _ = annotation as? WaypointAnnotation {
        var pin: MKPinAnnotationView!
        if let view = mapView.dequeueReusableAnnotationView(withIdentifier: WaypointAnnotation.identifier) {
          pin = view as! MKPinAnnotationView
          pin.annotation = annotation
        } else {
          pin = MKPinAnnotationView.init(annotation: annotation, reuseIdentifier: WaypointAnnotation.identifier)
        }
        pin.pinTintColor = UIColor.blue
        return pin
      }
      if let track = annotation as? TrackAnnotation {
        var pin: MKPinAnnotationView!
        if let view = mapView.dequeueReusableAnnotationView(withIdentifier: TrackAnnotation.identifier) {
          pin = view as! MKPinAnnotationView
          pin.annotation = annotation
        } else {
          pin = MKPinAnnotationView.init(annotation: annotation, reuseIdentifier: TrackAnnotation.identifier)
        }
        pin.pinTintColor = track.isStart ? UIColor.green : UIColor.red
        return pin
      }
      return nil
    }

    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
//      print("mapView changed: \(mapView.visibleMapRect)")
    }
  }
  
  func toggleUnit(_ sender: UIView) {
    if sender == speedValue {
      speedUnit = speedUnit.next()
      settings.update(value: speedUnit.rawValue, forKey:SettingName.SpeedUnit)
    }
    else if sender == altitudeValue {
      altitudeUnit = altitudeUnit.next()
      settings.update(value: altitudeUnit.rawValue, forKey: SettingName.AltitudeUnit)
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
    mapTrack.startNewSegment()
    self.currentPoly = nil
    settings.update(value: "true", forKey:SettingName.TrackingEnabled)
  }
  @IBAction func stopTracking(_ sender: Any) {
    settings.update(value: "false", forKey:SettingName.TrackingEnabled)
    if let pt = gps.currentLocation() {
      let place = TrackAnnotation(coordinate: pt.location, isStart: false)
      self.mapView.addAnnotation(place)
    }

  }
  
  @IBAction func storeWaypoint(sender: UIButton) {
    if let pt = gps.currentLocation() {
      storeWaypoint(pt)
    }
  }

  func storeWaypoint(_ pt : TrackPoint) {
    self.updateLocationInfo(pt, color: UIColor.blue)
    print("Store waypoint [location \(pt.location)] [date \(pt.timestamp)]")
    let ann = WaypointAnnotation(coordinate: pt.location)
    self.mapView.addAnnotation(ann)
  }
  
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
}

