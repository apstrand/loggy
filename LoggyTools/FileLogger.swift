//
//  FileLogger.swift
//  LoggyTools
//
//  Created by Peter Strand on 2017-06-29.
//  Copyright © 2017 Peter Strand. All rights reserved.
//

import Foundation

public class FileLogger {
  static let dateFormatter : DateFormatter = {
    let fmt = DateFormatter()
    fmt.dateFormat = "yyyyMMdd_hhmmss"
    return fmt
  }()
  let gpx_path : URL
  let gpx_filename : String
  var gpx = GPXData()
  
  public init() throws {
    gpx_filename = "track-" + FileLogger.dateFormatter.string(from: Date()) + ".gpx"
    let dir = URL(fileURLWithPath: NSTemporaryDirectory())
    gpx_path = dir.appendingPathComponent(gpx_filename)
  }
  
  public func log_point(_ loc : TrackPoint) {
    gpx.withCurrentTrack({ ts in ts.append(loc) })
  }
  
  public func log_waypoint(_ pt : TrackPoint) {
    gpx.waypoints.append(pt)
  }
  
  public func finish() {
    let str = gpx.to_string()
    
    try? str.write(to: gpx_path, atomically: true, encoding: .utf8)
    
    let fm = FileManager.default
    let cloud_dir = fm.url(forUbiquityContainerIdentifier: nil)
    guard let cloud_path = cloud_dir?.appendingPathComponent("Documents").appendingPathComponent(gpx_filename)
      else {
        print("Cannot create icloud path")
        return
    }
    
    print(cloud_path)
    
    do {
      try fm.setUbiquitous(true, itemAt: gpx_path, destinationURL: cloud_path)
    } catch let err {
      print("Failed to move gpx file to icloud: \(err)")
      
    }
  }
}
