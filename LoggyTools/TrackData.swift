//
//  TrackData.swift
//  LoggyTools
//
//  Created by Peter Strand on 2017-06-29.
//  Copyright © 2017 Peter Strand. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation
import UIKit

public struct TrackPoint {
  public let location : CLLocation
  public let timestamp : Date?
  public let name : String?
  public init(location : CLLocation, timestamp : Date? = nil, name : String? = nil) {
    self.location = location
    self.timestamp = timestamp
    self.name = name
  }
}

public struct Track {
  var min_lat : CLLocationDegrees = Double.greatestFiniteMagnitude
  var max_lat : CLLocationDegrees = -Double.greatestFiniteMagnitude
  var min_lon : CLLocationDegrees = Double.greatestFiniteMagnitude
  var max_lon : CLLocationDegrees = -Double.greatestFiniteMagnitude
  
  public var coords : [CLLocationCoordinate2D] = []
  
  public init() {
    
  }
  
  public mutating func add(_ coord : CLLocationCoordinate2D) {
    min_lat = min(min_lat, coord.latitude)
    max_lat = max(min_lat, coord.latitude)
    min_lon = min(min_lon, coord.latitude)
    max_lon = max(min_lon, coord.latitude)
    coords.append(coord)
  }
  
  public func region() -> MKCoordinateRegion? {
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

public struct TrackHistory
{
  var tracks : [Track]
  
}

