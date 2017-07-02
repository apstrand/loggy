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

public struct TrackHistory {
  
  var min_lat : CLLocationDegrees = Double.greatestFiniteMagnitude
  var max_lat : CLLocationDegrees = -Double.greatestFiniteMagnitude
  var min_lon : CLLocationDegrees = Double.greatestFiniteMagnitude
  var max_lon : CLLocationDegrees = -Double.greatestFiniteMagnitude
  
  public var gpx = GPXData()
  public var coordCache: [CLLocationCoordinate2D] = []
  
  public init() {
    
  }
  
  public mutating func startNewTrack() {
    coordCache.removeAll()
    gpx.tracks.append(GPXData.Track())
  }

  public mutating func add(_ coord : CLLocationCoordinate2D) {
    min_lat = min(min_lat, coord.latitude)
    max_lat = max(min_lat, coord.latitude)
    min_lon = min(min_lon, coord.longitude)
    max_lon = max(min_lon, coord.longitude)

    var coords = gpx.tracks.last?.segments.last?.track
    coords?.append(TrackPoint(location:coord))
    coordCache.append(coord)
  }
  
  public func region() -> MKCoordinateRegion? {
    var span : MKCoordinateSpan
    let coords = gpx.withCurrentTrack({ return $0 })
    if coords.count > 1 {
      span = MKCoordinateSpan(latitudeDelta: 3*(max_lat - min_lat), longitudeDelta: 3*(max_lon - min_lon))
    } else {
      span = MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
    }
    if let last = coords.last {
      let coordReg = MKCoordinateRegion(center: last.location, span: span)
      return coordReg
    } else {
      return nil
    }
  }
}


