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
  
  let MinLatSpan: CLLocationDegrees = 0.02
  let MinLonSpan: CLLocationDegrees = 0.02
  
  var min_lat: CLLocationDegrees = 0
  var max_lat: CLLocationDegrees = 0
  var min_lon: CLLocationDegrees = 0
  var max_lon: CLLocationDegrees = 0
  
  public var gpx: GPXData
  public var coordCache: [CLLocationCoordinate2D] = []
  
  public init(gpx: GPXData) {
    self.gpx = gpx
  }
  
  public mutating func startNewSegment() {
    coordCache.removeAll()
    min_lat = Double.greatestFiniteMagnitude
    max_lat = -Double.greatestFiniteMagnitude
    min_lon = Double.greatestFiniteMagnitude
    max_lon = -Double.greatestFiniteMagnitude

    if gpx.tracks.count == 0 {
      gpx.tracks.append(GPXData.Track())
    }
    gpx.tracks.last!.segments.append(GPXData.TrackSeg())
  }

  public mutating func add(_ coord : CLLocationCoordinate2D) {
    min_lat = min(min_lat, coord.latitude)
    max_lat = max(min_lat, coord.latitude)
    min_lon = min(min_lon, coord.longitude)
    max_lon = max(min_lon, coord.longitude)

    gpx.tracks.last!.segments.last!.track.append(TrackPoint(location:coord))
    coordCache.append(coord)
  }
  
  public func region() -> MKCoordinateRegion? {
    var span : MKCoordinateSpan
    let coords = gpx.withCurrentTrack({ return $0 })
    if coords.count > 1 {
      span = MKCoordinateSpan(latitudeDelta: max(MinLatSpan, 3*(max_lat - min_lat)), longitudeDelta: max(MinLonSpan, 3*(max_lon - min_lon)))
    } else {
      span = MKCoordinateSpan(latitudeDelta: MinLatSpan, longitudeDelta: MinLonSpan)
    }
    if let last = coords.last {
      let coordReg = MKCoordinateRegion(center: last.location, span: span)
      return coordReg
    } else {
      return nil
    }
  }
}


