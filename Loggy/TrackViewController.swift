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

class TrackDataCell: UITableViewCell {
  
  @IBOutlet weak var track: UILabel!
  @IBOutlet weak var info: UILabel!
  @IBOutlet weak var status: UILabel!
}

class WaypointCell: UITableViewCell {
  
  @IBOutlet weak var waypoint: UILabel!
  @IBOutlet weak var info: UILabel!
}

class TrackViewController: UIViewController,
        UITableViewDataSource, UITableViewDelegate
{

  var logTracks: LogTracks!
  var units: UnitController!
  
  var regs = TokenRegs()
  
  @IBOutlet weak var tableView: UITableView!

  @IBOutlet weak var exportButton: UIButton!
  @IBOutlet weak var selectButton: UIButton!
  required init?(coder aCoder: NSCoder) {
    super.init(coder: aCoder)
  }
  
  enum RowType: String {
    case Track = "track"
    case Waypoint = "waypoint"
    case Segment = "segment"
    case SegmentStart = "segment-start"
    case SegmentEnd = "segment-end"
  }
  struct RowData {
    let id: Int
    let type: RowType
    let location: String
    let date: Date
    let name: String?
    let extra: String?
  }
  var tableViewLoaded = false
  var rows: [RowData] = []
  
  let dateFormatter : DateFormatter = {
    let fmt = DateFormatter()
    fmt.dateStyle = .medium
    fmt.timeStyle = .medium
    return fmt
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    
    regs += logTracks.observeTrackData(LogTracks.Filter(trackingOnly: true, fullHistory:true)) { track, seg, point in
      if track == nil {
        print("TrackView: reload all")
        self.rows.removeAll()
        self.tableView.reloadData()
      } else if let seg = seg {
        if let row = self.segmentToRowData(seg) {
          self.rows.append(row)
        }
      } else if let pt = point {
        // update segment with new size
      }
      var ix = self.rows.endIndex
      ix = self.rows.index(before: ix)
      while ix >= self.rows.startIndex {
        if self.rows[ix].type == .Segment {
//          self.rows[ix].extra =
          return
        }
        ix = self.rows.index(before: ix)
      }
    }
    regs += logTracks.observeWaypoints(LogTracks.Filter(trackingOnly: false, fullHistory:true)) { waypoint in
      self.rows.append(self.waypointToRowData(waypoint))
      if self.tableViewLoaded {
        self.tableView.insertRows(at: [IndexPath(row: self.rows.count-1, section: 0)], with: .automatic)
      }
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if let paths = tableView.indexPathsForSelectedRows {
      for path in paths {
        tableView.deselectRow(at: path, animated: false)
      }
    }
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    tableView.flashScrollIndicators()
  }
  @IBAction func selectAction(_ sender: Any) {
  }
  
  @IBAction func exportAction(_ sender: Any) {
  }

  func waypointToRowData(_ waypoint: GPXData.Waypoint) -> RowData {
    let pt = waypoint.point
    let loc = String(format: "%.3f %.3f", pt.location.latitude, pt.location.longitude)
    return RowData(id: waypoint.id, type: .Waypoint, location: loc, date: pt.timestamp, name: pt.name, extra: "WPT")
  }
  
  func segmentToRowData(_ seg: GPXData.TrackSeg) -> RowData? {
    if let pt = seg.track.first {
      let loc = String(format: "%.3f %.3f", pt.location.latitude, pt.location.longitude)
      return RowData(id: seg.id, type: .Segment, location: loc, date: pt.timestamp, name: pt.name, extra: "\(seg.track.count)")
    }
    return nil
  }

  
  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    tableViewLoaded = true
    if (section == 0) {
      return rows.count
    }
    return 0
  }

  public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let rowData = rows[indexPath.row]
    
    switch rowData.type {
    case .Waypoint:
      if let view = tableView.dequeueReusableCell(withIdentifier: rowData.type.rawValue) as? WaypointCell {
        view.waypoint.text = rowData.location
        view.info.text = dateFormatter.string(for:rowData.date)
        return view
      }
      break
    case .Segment:
      if let view = tableView.dequeueReusableCell(withIdentifier: rowData.type.rawValue) as? TrackDataCell {
        view.track.text = "Track"
        view.info.text = dateFormatter.string(for:rowData.date)
        view.status.text = rowData.extra
        return view
      }
      break
    default:
      break
    }
    let view = UITableViewCell(style: .default, reuseIdentifier: "fallback")
    view.textLabel?.text = "Unknown type: " + rowData.type.rawValue
    return view
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  

}
