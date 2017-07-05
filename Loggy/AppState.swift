//
//  AppState.swift
//  Loggy
//
//  Created by Peter Strand on 2017-07-02.
//  Copyright © 2017 Peter Strand. All rights reserved.
//

import Foundation
import LoggyTools

protocol GPXBacking {
  func gpxData() -> GPXData
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

class AppState: SettingsImpl<LoggySettings>, UnitController, SettingsRW {

  var gpxInst = GPXData()

  var location : LocationUnit!
  var speed : SpeedUnit!
  var altitude : AltitudeUnit!
  var bearing : BearingUnit!
  
  
  var regs = TokenRegs()

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
  }

  var persistURL : URL = {
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true);
    if paths.count > 0 {
      return URL(fileURLWithPath:paths[0], isDirectory:true).appendingPathComponent("persist.gpx", isDirectory:false)
    }
    fatalError("Cannot find documents directory!")
  }()
  
  func didFinishLaunching() {
    load(path: persistURL)
  }
  
  func didEnterBackground() {
    save(path: persistURL)
  }
  
  func autoSave() {
    save(path: persistURL)
  }
}

extension AppState: GPXBacking
{
  func gpxData() -> GPXData {
    return gpxInst
  }
  
  func load(path: URL) {
    DispatchQueue.global(qos: .background).async {
      if let gpx = GPXData.parse(contentsOf: path) {
        DispatchQueue.main.async {
          self.gpxInst.assign(from: gpx)
        }
      }
    }
  }
  
  func save(path: URL) {
    let str = gpxInst.to_string()
    print("\nSaving:\n"+str)
    DispatchQueue.global(qos: .background).async {
      do {
        try str.write(to: path, atomically: true, encoding: .utf8)
      } catch let err {
        print("Failed to save state \(err)")
      }
    }
  }
  
}
