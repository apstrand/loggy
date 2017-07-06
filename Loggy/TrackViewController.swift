//
//  TrackViewController.swift
//  Loggy
//
//  Created by Peter Strand on 2017-07-02.
//  Copyright © 2017 Peter Strand. All rights reserved.
//

import Foundation
import UIKit
import LoggyTools
import CoreLocation

class TrackViewController: UIViewController,
        UITableViewDataSource, UITableViewDelegate,
        GPXDelegate
{

  var gpsController: GPSController!
  var units: UnitController!
  
  required init?(coder aCoder: NSCoder) {
    super.init(coder: aCoder)
  }
  
  func waypointUpdate(waypoint: GPXData.Waypoint) {
    
  }
  
  func segmentUpdate(segment: GPXData.TrackSeg) {

  }
  
  func trackUpdate(track: GPXData.Track) {
    
  }
  
  enum RowType: String {
    case Track = "track"
    case Waypoint = "waypoint"
    case SegmentStart = "segment-start"
    case SegmentEnd = "segment-end"
  }
  struct RowData {
    let id: Int
    let type: RowType
    let location: String
    let date: Date
    let name: String?
    let extra: String? = nil
  }
  var rows: [RowData] = []
  
  let dateFormatter : DateFormatter = {
    let fmt = DateFormatter()
    fmt.dateStyle = .medium
    fmt.timeStyle = .medium
    return fmt
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  func refresh() {
    rows.removeAll()
    
    let gpx = gpsController.gpxData()

    for waypoint in gpx.waypoints {
      let pt = waypoint.point
      let loc = String(format: "%.3f %.3f", pt.location.latitude, pt.location.longitude)
      rows.append(RowData(id: waypoint.id, type: .Waypoint, location: loc, date: pt.timestamp, name: pt.name))
    }
    
    for track in gpx.tracks {
      let segs = track.segments.count
      if segs > 0 {
        let tps = track.segments[0].track.count
        if tps > 0 {
          let pt = track.segments.first!.track.first!
          let loc = String(format: "%.3f %.3f", pt.location.latitude, pt.location.longitude)
          rows.append(RowData(id: track.id, type: .Track, location: loc, date: pt.timestamp, name: pt.name))
          
        }
      }
//      let extra = NSString(format: "[segments %d]", segs)
    }

  }
  
  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if (section == 0) {
      return rows.count
    }
    return 0
  }

  public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if let view = tableView.dequeueReusableCell(withIdentifier: RowType.Track.rawValue) {
      
      return view
    } else {
      let view = UITableViewCell(style: .default, reuseIdentifier: RowType.Track.rawValue)
      return view
    }
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  

}
