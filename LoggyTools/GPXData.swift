//
//  GPXData.swift
//  Loggy
//
//  Created by Peter Strand on 2017-06-24.
//  Copyright © 2017 Peter Strand. All rights reserved.
//

import Foundation

public struct GPXData {
  
  public init() { }

  public var tracks : [GPSTracker.TrackPoint] = []
  public var waypoints : [GPSTracker.TrackPoint] = []
 
  public func to_string() -> String {
    var str = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
    str += "<gpx xmlns=\"http://www.topografix.com/GPX/1/0\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.topografix.com/GPX/1/0 http://www.topografix.com/GPX/1/0/gpx.xsd\" version=\"1.0\" creator=\"se.nnea.loggy\">\n"
    
    str += " <trk>\n"
    str += "  <name>Track</name>\n"
    str += "  <trkseg>\n"
    for track in tracks {
      let lat = track.location.coordinate.latitude
      let lon = track.location.coordinate.longitude
      str += "   <trkpt lat=\"\(lat)\" lon=\"\(lon)\"></trkpt>\n"
    }
    str += "  </trkseg>\n"
    str += " </trk>\n"
    for waypoint in waypoints {
      let lat = waypoint.location.coordinate.latitude
      let lon = waypoint.location.coordinate.longitude
      str += " <wpt lat=\"\(lat)\" lon=\"\(lon)\"></wpt>\n"
    }
    str += "</gpx>\n"
    return str
  }
}
