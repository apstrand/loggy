//
//  UnitHandling.swift
//  Loggy
//
//  Created by Peter Strand on 2017-06-30.
//  Copyright © 2017 Peter Strand. All rights reserved.
//

import Foundation

protocol Unit {
  static func parseUnit(_ str: String) -> Self
//  static func parseValue(_ str: String) -> ValueType
  associatedtype ValueType
  func format(_ value : ValueType, separator: String) -> String
  func next() -> Self
}

public enum BearingUnit : String {
  case Deg = "deg"
  case Sym = "sym"
  // case SymFine = "symfine"
  public static func parseUnit(_ str: String) -> BearingUnit {
    switch str {
    case Deg.rawValue:
      return .Deg
    case Sym.rawValue:
      return .Sym
    default:
      return .Deg
    }
  }
  public typealias ValueType = Double
  public func format(_ value : ValueType) -> String {
    switch self {
    case .Deg:
      return String(format:"%.0f°", value)
    case .Sym:
      let syms = [ "N", "NE", "E", "SE", "S", "SW", "W", "NW" ]
      let sep = (360/syms.count)
      return syms[ (syms.count + ((Int(value)+sep/2) / sep)) % syms.count ]
/*
    case .SymFine:
      let syms = [ "N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW" ]
      let sep = (360/syms.count)
      return syms[ (syms.count + ((Int(value)+sep/2) / sep)) % syms.count ]
 */
    }
  }
  public func next() -> BearingUnit {
    switch self {
    case .Deg:
      return .Sym
    case .Sym:
      return .Deg
    }
  }
}

public enum SpeedUnit : String, Unit {
  case M_S = "m_per_s"
  case KM_H = "km_per_h"
  case M_H = "miles_per_h"
  typealias ValueType = Double
  public static func parseUnit(_ str : String) -> SpeedUnit {
    switch str {
    case M_S.rawValue:
      return .M_S
    case KM_H.rawValue:
      return .KM_H
    case M_H.rawValue:
      return .M_H
    default:
      return .M_S
    }
  }
  public func next() -> SpeedUnit {
    switch self {
    case .M_S:
      return .KM_H
    case .KM_H:
      return .M_H
    case .M_H:
      return .M_S
    }
  }
  public func format(_ value : Double, separator: String = " ") -> String {
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

public enum AltitudeUnit : String, Unit {

  case Meter = "m"
  case Feet = "ft"
  public static func parseUnit(_ str : String) -> AltitudeUnit {
    switch str {
    case Meter.rawValue:
      return .Meter
    case Feet.rawValue:
      return .Feet
    default:
      return .Meter
    }
  }
  public typealias ValueType = Double
  public func format(_ value : ValueType, separator: String = " ") -> String {
    switch self {
    case .Meter:
      return String(format:"%.0f m", value)
    case .Feet:
      return String(format:"%.0f ft", value*3.28084)
    }
  }
  public func next() -> AltitudeUnit {
    switch self {
    case .Meter:
      return .Feet
    case .Feet:
      return .Meter
    }
  }
}

public enum LocationUnit : String, Unit {
  case Decimal = "dec"
  case DMS = "dms"
  
  public typealias ValueType = (Double,Double)

  public static func parseUnit(_ str: String) -> LocationUnit {
    switch str {
    case Decimal.rawValue:
      return Decimal
    case DMS.rawValue:
      return DMS
    default:
      return Decimal
    }
  }
  
  func formatDMS(deg: Double, labels: (String,String)) -> String {
    let neg = deg < 0
    let d = abs(deg)
    let dec = Int(d)
    let min = Int((d - Double(dec)) * 60)
    let sec = (d - Double(dec) - Double(min)/60)*3600
    return (neg ? labels.0 : labels.1) + String(format:" %d° %d' %.2f\"", dec, min, sec)
  }
  
  public func format(_ value : ValueType, separator: String = " ") -> String {
    switch self {
    case .Decimal:
      return String(format:"%f %f", value.0, value.1)
    case .DMS:
      let lat = formatDMS(deg:value.0, labels:("W","E"))
      let lon = formatDMS(deg:value.1, labels:("S","N"))
      return lat + separator + lon
    }
  }
  public func next() -> LocationUnit {
    switch self {
    case .Decimal:
      return .DMS
    case .DMS:
      return .Decimal
    }
  }
}

