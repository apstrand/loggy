//
//  UnitHandling.swift
//  Loggy
//
//  Created by Peter Strand on 2017-06-30.
//  Copyright © 2017 Peter Strand. All rights reserved.
//

import Foundation

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
