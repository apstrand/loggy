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

class DashboardViewController: UIViewController {

  struct SettingNames {
    static let PowerSave = "power_save"
    static let AutoWaypoint = "auto_waypoint"
    static let SpeedUnit = "speed_unit"
    static let AltitudeUnit = "altitude_unit"
  }

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
  @IBOutlet weak var powerSaveToggle: UISwitch!
  @IBOutlet weak var waypointButton: UIButton!
  @IBOutlet weak var stopButton: UIButton!
  @IBOutlet weak var startButton: UIButton!
  @IBOutlet weak var mapView: MKMapView!
  
  let gps : GPSTracker
  
  struct Track {
    var min_lat : CLLocationDegrees = Double.greatestFiniteMagnitude
    var max_lat : CLLocationDegrees = -Double.greatestFiniteMagnitude
    var min_lon : CLLocationDegrees = Double.greatestFiniteMagnitude
    var max_lon : CLLocationDegrees = -Double.greatestFiniteMagnitude
    
    var coords : [CLLocationCoordinate2D] = []

    mutating func add(_ coord : CLLocationCoordinate2D) {
      min_lat = min(min_lat, coord.latitude)
      max_lat = max(min_lat, coord.latitude)
      min_lon = min(min_lon, coord.latitude)
      max_lon = max(min_lon, coord.latitude)
      coords.append(coord)
    }
    
    func region() -> MKCoordinateRegion? {
      var span : MKCoordinateSpan
      if coords.count > 1 {
        span = MKCoordinateSpan(latitudeDelta: 3*(max_lat - min_lat), longitudeDelta: 3*(max_lon - min_lon))
      } else {
        span = MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
      }
      if let last = coords.last {
        let coordReg = MKCoordinateRegion(center: last, span: span)
        return coordReg
      } else {
        return nil
      }
    }
  }
  var map_track : Track?
  var last_poly : MKPolyline?
  
  class TapHandler {
    let callback : (UIView) -> Void
    let view : UIView
    init(_ view : UIView, _ cb: @escaping (UIView) -> Void) {
      self.view = view
      self.callback = cb
      let tapGesture = UITapGestureRecognizer()
      tapGesture.numberOfTapsRequired = 1
      tapGesture.addTarget(self, action: #selector(TapHandler.tapDetected(target:)))
      view.addGestureRecognizer(tapGesture)
    }
    
    @objc func tapDetected(target: Any) {
      callback(view)
    }
  }

  var tapHandlers : [TapHandler] = []
  required init?(coder aCoder: NSCoder) {
    gps = GPSTracker()
    super.init(coder: aCoder)
  }
  
  class Logger {
    static let dateFormatter : DateFormatter = {
      let fmt = DateFormatter()
      fmt.dateFormat = "yyyyMMdd_hhmmss"
      return fmt
    }()
    let gpx_path : URL
    let gpx_filename : String
    var gpx = GPXData()
    
    init() throws {
      gpx_filename = "track-" + Logger.dateFormatter.string(from: Date()) + ".gpx"
      let dir = URL(fileURLWithPath: NSTemporaryDirectory())
      gpx_path = dir.appendingPathComponent(gpx_filename)
    }
    
    func log_point(_ loc : GPSTracker.TrackPoint) {
      gpx.tracks.append(loc)
    }
    
    func log_waypoint(_ pt : GPSTracker.TrackPoint) {
      gpx.waypoints.append(pt)
    }
    
    func finish() {
      let str = gpx.to_string()
      
      try? str.write(to: gpx_path, atomically: true, encoding: .utf8)
      
      let fm = FileManager.default
      let cloud_dir = fm.url(forUbiquityContainerIdentifier: nil)
      guard let cloud_path = cloud_dir?.appendingPathComponent("Documents").appendingPathComponent(gpx_filename)
        else {
        print("Cannot create icloud path")
        return
      }
      
      print(cloud_path)
      
      do {
        try fm.setUbiquitous(true, itemAt: gpx_path, destinationURL: cloud_path)
      } catch let err {
        print("Failed to move gpx file to icloud: \(err)")
        
      }
    }
  }
  
  var logger : Logger?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tapHandlers.append(contentsOf: [
      TapHandler(locationValue, { self.toggleUnit($0) }),
      TapHandler(speedValue, { self.toggleUnit($0) }),
      TapHandler(altitudeValue, { self.toggleUnit($0) }),
      TapHandler(bearingValue, { self.toggleUnit($0) })
    ])
    
    let defaults = UserDefaults.standard
    powerSaveToggle.isOn = defaults.bool(forKey: SettingNames.PowerSave)
    autoWaypointToggle.isOn = defaults.bool(forKey: SettingNames.AutoWaypoint)
    if let alt_unit = defaults.string(forKey: SettingNames.AltitudeUnit) {
      altitudeUnit = AltitudeUnit.parse(alt_unit)
    }
    if let speed_unit = defaults.string(forKey: SettingNames.SpeedUnit) {
      speedUnit = SpeedUnit.parse(speed_unit)
    }
    
    gps.monitorState { is_tracking in
      self.startButton.isEnabled = !is_tracking
      self.stopButton.isEnabled = is_tracking
      self.waypointButton.isEnabled = is_tracking
      self.startButton.alpha = !is_tracking ? 1.0 : 0.5
      self.stopButton.alpha = is_tracking ? 1.0 : 0.5
      self.waypointButton.alpha = is_tracking ? 1.0 : 0.5
      

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
      self.locationValue.text = self.formatCoord(pt.location.coordinate)
      self.altitudeValue.text = self.formatAltitude(pt.location.altitude)
      self.speedValue.text = self.formatSpeed(pt.location.speed)
      self.bearingValue.text = self.formatBearing(pt.location.course)
      
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
  }
  
  class MapDelegate : NSObject, MKMapViewDelegate {
    let parent : DashboardViewController
    init(_ p : DashboardViewController) {
      parent = p
    }
    public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
      if overlay is MKPolyline {
        // draw the track
        let polyLine = overlay
        let polyLineRenderer = MKPolylineRenderer(overlay: polyLine)
        polyLineRenderer.strokeColor = UIColor.black
        polyLineRenderer.lineWidth = 2.0
        
        return polyLineRenderer
      }
      assert(false)
    }

  }
  var mapDelegate : MapDelegate?
  
  enum SpeedUnit : String {
    case M_S = "m_per_s"
    case KM_H = "km_per_h"
    case M_H = "miles_per_h"
    static func parse(_ str : String) -> SpeedUnit {
      switch str {
        case "m_per_s":
          return .M_S
        case "km_per_h":
          return .KM_H
        case "miles_per_h":
          return .M_H
        default:
          return .M_S
      }
    }
    func next() -> SpeedUnit {
      switch self {
      case .M_S:
        return .KM_H
      case .KM_H:
        return .M_H
      case .M_H:
        return .M_S
      }
    }
    func format(_ value : Double) -> String {
      switch self {
      case .M_S:
        return String(format: "%.1f m/s", value)
      case .KM_H:
        return String(format: "%.1f km/h", value * 3600 / 1000)
      case .M_H:
        return String(format: "%.1f mph", value * 3600 / 1609.34)
      }
    }
  }
  enum AltitudeUnit : String {
    case Meter = "m"
    case Feet = "ft"
    static func parse(_ str : String) -> AltitudeUnit {
      switch str {
        case "m":
          return .Meter
        case "ft":
          return .Feet
      default:
        return .Meter
      }
    }
    func next() -> AltitudeUnit {
      switch self {
        case .Meter:
          return .Feet
        case .Feet:
          return .Meter
      }
    }
  }
  var speedUnit = SpeedUnit.M_S
  var altitudeUnit = AltitudeUnit.Meter
  
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
    if let pt = gps.storeWaypoint() {
      let place = MKPlacemark.init(coordinate: pt.location.coordinate)
      self.mapView.addAnnotation(place)
    }
  }
  
  @IBAction func toggleTracking(sender: UISwitch) {
    if sender.isOn {
      try? logger = Logger()
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

