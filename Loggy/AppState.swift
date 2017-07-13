//
//  AppState.swift
//  Loggy
//
//  Created by Peter Strand on 2017-07-02.
//  Copyright © 2017 Peter Strand. All rights reserved.
//

import Foundation
import LoggyTools

protocol GPSController {
  func gpxData() -> GPXData
  func gps() -> GPSTracker
}

protocol AppFileState {
  func clearAndBumpAutoSave()
  func load(path: URL) throws
  func save(path: URL) throws
}

protocol UnitController {
  var speed : SpeedUnit! { get }
  var altitude : AltitudeUnit! { get }
  var location : LocationUnit! { get }
  var bearing : BearingUnit! { get }
}


protocol SettingsRW: SettingsReader, SettingsWriter { }

struct LoggySettings: SettingsDefaults {
  public static var defaults: [String: String] {
    get {
      return [
        SettingName.AltitudeUnit: AltitudeUnit.Meter.rawValue,
        SettingName.SpeedUnit: SpeedUnit.KM_H.rawValue,
        SettingName.LocationUnit: LocationUnit.DMS.rawValue,
        SettingName.BearingUnit: BearingUnit.Deg.rawValue,
        SettingName.AutoSaveGen: "0",
        SettingName.PowerSave: "false"
      ]
    }
  }
  static func setup() {
    userDefaults.set("false", forKey: SettingName.TrackingEnabled)
  }
  static let userDefaults = {
    return UserDefaults(suiteName: SettingName.Suite) ?? UserDefaults.standard
  }()
}

class AppState: SettingsImpl<LoggySettings>, UnitController, SettingsRW, AppFileState {

  var gpxInst = GPXData()
  let gpsModule = GPSTracker()

  var logTracks : LogTracks!
  
  var location : LocationUnit!
  var speed : SpeedUnit!
  var altitude : AltitudeUnit!
  var bearing : BearingUnit!
  
  var photosObserver: CameraPhotosObserver!

  var regs = TokenRegs()
  var gpsRegs = TokenRegs()
  
  public override init() {
    super.init()

    regs += self.observe(key: SettingName.AltitudeUnit) {
      self.altitude = AltitudeUnit.parseUnit($0)
    }
    regs += self.observe(key: SettingName.SpeedUnit) {
      self.speed = SpeedUnit.parseUnit($0)
    }
    regs += self.observe(key: SettingName.BearingUnit) {
      self.bearing = BearingUnit.parseUnit($0)
    }
    regs += self.observe(key: SettingName.LocationUnit) {
      self.location = LocationUnit.parseUnit($0)
    }
    
    regs += self.observe(key: SettingName.TrackingEnabled) { value in
      if (value == "true") {
        self.gpsRegs += self.gpsModule.requestLocationTracking()
      } else {
        self.gpsRegs.release()
      }
    }
    
    self.logTracks = LogTracks(gpxData())
    regs += self.gps().addTrackPointLogger { pt, isMajor in
      self.logTracks.handleNewLocation(point: pt, isMajor: isMajor)
      
      self.pingAutoSave(self.gpxData())
    }
    
    regs += self.observe(key: SettingName.AutoWaypoint) { value in
      if value == "true" {
        self.photosObserver = CameraPhotosObserver({ loc, date in
          print("Found photo at \(loc) taken on \(date?.description ?? "-")")
          if self.isSet(SettingName.AutoWaypoint) {
            if let date = date {
              self.logTracks.storeWaypoint(location: TrackPoint(location:loc.coordinate, timestamp:date))
            } else {
              print("No date in photo!")
            }
          }
        })
      } else {
        self.photosObserver = nil
      }
    }

  }

  func persistURL() -> URL {
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true);
    if paths.count > 0 {
      if let str = self.value(forKey: SettingName.AutoSaveGen), let gen = Int(str) {
        return URL(fileURLWithPath:paths[0], isDirectory:true).appendingPathComponent("persist-\(gen).gpx", isDirectory:false)
      }
    }
    fatalError("Cannot find documents directory!")
  }

  func clearAndBumpAutoSave() {
    var next = 0
    if let seq = value(forKey: SettingName.AutoSaveGen) {
      if let seqno = Int(seq) {
        next = seqno+1
      }
    }
    update(value: "\(next)", forKey: SettingName.AutoSaveGen)

    let gpx = GPXData()
    self.logTracks.load(from: gpx)

    autoSave()
  }

  func didFinishLaunching() {
    load(path: persistURL())
  }
  
  func didEnterBackground() {
    save(path: persistURL())
  }
  
  func autoSave() {
    save(path: persistURL())
  }
  
  private var pendingAutoSave = false
  private var lastAutoSaveState = 0
  func pingAutoSave(_ gpx: GPXData) {
    let check = gpx.genId()
    if check != lastAutoSaveState+1 && !self.pendingAutoSave {
      print("autosave [\(check) vs \(lastAutoSaveState+1)]")
      self.pendingAutoSave = true
      DispatchQueue.global(qos: .background).asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(2)) {
        self.autoSave()
        DispatchQueue.main.async {
          self.pendingAutoSave = false
        }
      }
    }
    lastAutoSaveState = check
  }
}

extension AppState: GPSController
{
  func gpxData() -> GPXData {
    return gpxInst
  }
  func gps() -> GPSTracker {
    return gpsModule
  }
  
  func load(path: URL) {
    DispatchQueue.global(qos: .background).async {
      if let gpx = GPXData.parse(contentsOf: path) {
        DispatchQueue.main.async {
          self.logTracks.load(from: gpx)
        }
      }
    }
  }
  
  func save(path: URL) {
    let str = gpxInst.to_string()
//    print("\nSaving:\n"+str)
    DispatchQueue.global(qos: .background).async {
      do {
        try str.write(to: path, atomically: true, encoding: .utf8)
      } catch let err {
        print("Failed to save state \(err)")
      }
    }
  }
  
}
