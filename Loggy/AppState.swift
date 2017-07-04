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
}

protocol SettingsRW: SettingsReader, SettingsWriter { }

struct LoggySettings: SettingsDefaults {
  public static var defaults: [String: String] {
    get {
      return [ SettingName.PowerSave: "false" ]
    }
  }
  static func setup() {
    userDefaults.set("false", forKey: SettingName.TrackingEnabled)
  }
  static let userDefaults = {
    return UserDefaults(suiteName: SettingName.Suite) ?? UserDefaults.standard
  }()
}

class AppState: SettingsImpl<LoggySettings>, GPXBacking, SettingsRW {

  
  var gpxInst = GPXData()
  
  
  func gpxData() -> GPXData {
    return gpxInst
  }
  
}

