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
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var autoWaypointToggle: UISwitch!
  @IBOutlet weak var powerSaveToggle: UISwitch!
  @IBOutlet weak var trackingToggle: UISwitch!
  @IBOutlet weak var waypointButton: UIButton!
  
  
  let gps : GPSTracker
  
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
    trackingToggle.isOn = false
    powerSaveToggle.isOn = defaults.bool(forKey: SettingNames.PowerSave)
    autoWaypointToggle.isOn = defaults.bool(forKey: SettingNames.AutoWaypoint)
    
    gps.setTrackLogger({ pt in self.logger?.log_point(pt) } )
  }
  
  func toggleUnit(_ sender: UIView) {
    
  }
  
  @IBAction func storeWaypoint(sender: UIButton) {
    gps.storeWaypoint()
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

