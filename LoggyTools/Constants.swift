//
//  Settings.swift
//  Loggy
//
//  Created by Peter Strand on 2017-06-30.
//  Copyright © 2017 Peter Strand. All rights reserved.
//

import Foundation

public struct SettingName {
  public static let Suite = "group.se.nena.loggy"
  public static let PowerSave = "power_save"
  public static let AutoWaypoint = "auto_waypoint"
  public static let AlwaysAutoWaypoint = "always_auto_waypoint"
  public static let SpeedUnit = "speed_unit"
  public static let AltitudeUnit = "altitude_unit"
  public static let TrackingEnabled = "tracking_enabled"
}


public enum AppCommand : String {
  case StartTracking = "action?startTracking"
  case StopTracking = "action?stopTracking"
  case StoreWaypoint = "action?storeWaypoint"
}

public struct AppUrl {
  public static let AppUrl = "loggy://"
  public static func app(cmd : AppCommand) -> URL {
    guard let url = URL(string:AppUrl + cmd.rawValue)
      else {  fatalError("Failed to create appurl for command: \"\(cmd)\"") }
    return url
  }
}

