//
//  GPXData.swift
//  Loggy
//
//  Created by Peter Strand on 2017-06-24.
//  Copyright © 2017 Peter Strand. All rights reserved.
//

import Foundation
import CoreLocation

public struct TrackPoint {
  public let location : CLLocationCoordinate2D
  public let timestamp : Date
  public let elevation : Double?
  public let speed : Double?
  public let bearing : Double?
  public let name : String?
  public init(location: CLLocationCoordinate2D, timestamp: Date,
              name: String? = nil, elevation: Double? = nil,
              speed: Double? = nil, bearing: Double? = nil)
  {
    self.location = location
    self.timestamp = timestamp
    self.name = name
    self.elevation = elevation
    self.speed = speed
    self.bearing = bearing
  }
}

/*
public protocol GPXDelegate {
  func waypointUpdate(waypoint: GPXData.Waypoint)
  func segmentUpdate(segment: GPXData.TrackSeg)
  func trackUpdate(track: GPXData.Track)
}
 */

public class GPXData {
  
  // see http://www.topografix.com/gpx.asp
  public class Track {
    public typealias Id = Int
    public var id: Id
    public var name: String?
    public var segments: [TrackSeg] = []
    public init(id: Int) {
      self.id = id
    }
  }
  public class TrackSeg {
    public typealias Id = Int
    public var id: Id
    public var name: String?
    public var track: [TrackPoint] = []
    public init(id: Int) {
      self.id = id
    }
  }
  public class Waypoint {
    public typealias Id = Int
    public var id: Id
    public var point: TrackPoint
    public init(point: TrackPoint, id: Int) {
      self.point = point
      self.id = id
    }
  }
  private var nextId = 1
  public var tracks: [Track] = []
  public var waypoints: [Waypoint] = []
  
  public func genId() -> Int {
    nextId += 1
    return nextId
  }
  
  public init() { }
    
  public func withCurrentTrack<T>(_ fn: ((inout [TrackPoint]) -> T)) -> T {
    return fn(&tracks.last!.segments.last!.track)
  }
  
  public func to_string() -> String {
    var str = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
    str += "<gpx xmlns=\"http://www.topografix.com/GPX/1/0\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.topografix.com/GPX/1/0 http://www.topografix.com/GPX/1/0/gpx.xsd\" version=\"1.0\" creator=\"se.nena.loggy\">\n"
    
    for track in tracks {
      str += " <trk>\n"
      if let name = track.name {
        str += "  <name>\(name)</name>\n"
      }
      for seg in track.segments {
        str += "  <trkseg>\n"
        for pt in seg.track {
          let lat = pt.location.latitude
          let lon = pt.location.longitude
          str += "   <trkpt lat=\"\(lat)\" lon=\"\(lon)\">"
          addTrackPointMetadata(&str, pt)
          str += "</trkpt>\n"
        }
        str += "  </trkseg>\n"
      }
    str += " </trk>\n"
    }
    for waypoint in waypoints {
      let lat = waypoint.point.location.latitude
      let lon = waypoint.point.location.longitude
      str += " <wpt lat=\"\(lat)\" lon=\"\(lon)\">"
      addTrackPointMetadata(&str, waypoint.point)
      str += "</wpt>\n"
    }
    str += "</gpx>\n"
    return str
  }
  
  public static func parse(contentsOf url: URL) -> GPXData? {
    
    let inst = GPXData()

    do {
      let data = try Data(contentsOf: url)
      let parser = XMLParser(data: data)
      let delegate = ParserDelegate(inst)
      parser.delegate = delegate

      parser.parse()
      return inst
    } catch let err {
      print("Parse error: \(err)")
      return nil
    }
  }

  class ParserDelegate : NSObject, XMLParserDelegate {
    var gpx : GPXData
    var last_location : CLLocationCoordinate2D?
    let iso8601 = ISO8601DateFormatter()
    var name_stack : [String?] = []
    var last_time : Date?
    var last_ele : Double?
    var last_speed : Double?
    var last_course : Double?
    var last_cdata : String = ""
    init(_ gpx : GPXData) {
      self.gpx = gpx
    }
    deinit {
      
    }
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String])
    {
      last_cdata.removeAll()
      switch elementName {
      case "gpx":
        break
      case "wpt":
        fallthrough
      case "trkpt":
        name_stack.append(nil)
        let lat = Double(attributeDict["lat"] ?? "0.0")!
        let lon = Double(attributeDict["lon"] ?? "0.0")!
        last_location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        break
      case "trk":
        name_stack.append(nil)
        gpx.tracks.append(Track(id:gpx.genId()))
        break
      case "trkseg":
        gpx.tracks.last!.segments.append(TrackSeg(id:gpx.genId()))
        break
      case "name":
        break
      case "ele":
        break
      case "desc":
        break
      case "time":
        break
      default:
        print("GPXData: XML: Unhandled start tag \"\(elementName)\"")
      }
    }
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?)
    {
      switch elementName {
      case "gpx":
        break
      case "wpt":
        if let loc = last_location {
          gpx.waypoints.append(Waypoint(point: TrackPoint(location: loc, timestamp: last_time!, name: name_stack.removeLast(), elevation: last_ele, speed: last_speed, bearing: last_course), id: gpx.genId()))
          last_ele = nil
          last_time = nil
          last_speed = nil
          last_course = nil
        }
        last_location = nil
        break
      case "trk":
        gpx.tracks.last?.name = name_stack.removeLast()
        break
      case "trkseg":
        break
      case "trkpt":
        if let loc = last_location {
          gpx.tracks.last?.segments.last?.track.append(TrackPoint(location: loc, timestamp: last_time!, name: name_stack.removeLast(), elevation: last_ele, speed: last_speed, bearing: last_course))
          last_ele = nil
          last_time = nil
          last_speed = nil
          last_course = nil
        }
        last_location = nil
        break
      case "name":
        let ix = name_stack.count
        name_stack[ix-1] = last_cdata
        last_cdata = ""
        break
      case "ele":
        last_ele = Double(last_cdata)
        last_cdata = ""
        break
      case "speed":
        last_speed = Double(last_cdata)
        last_cdata = ""
        break
      case "course":
        last_course = Double(last_cdata)
        last_cdata = ""
        break
      case "desc":
        break
      case "time":
        last_time = iso8601.date(from: last_cdata)
        last_cdata = ""
        break
      default:
        print("GPXData: XML: Unhandled end tag \"\(elementName)\"")
      }
    }
    func parser(_ parser: XMLParser, foundCharacters string: String) {
      last_cdata.append(string)
    }
    func parserDidEndDocument(_ parser: XMLParser) {
    }
  }
  
  func addTrackPointMetadata(_ str: inout String, _ tp : TrackPoint) {
    str += "\n    <time>" + timefmt(tp.timestamp) + "</time>"
    if let name = tp.name {
      str += "\n    <name>" + name + "</name>"
    }
    if let ele = tp.elevation {
      str += "\n    <ele>\(ele)</ele>"
    }
    if let speed = tp.speed {
      str += "\n    <speed>\(speed)</speed>"
    }
    if let bearing = tp.bearing {
      str += "\n    <course>\(bearing)</course>"
    }
  }
  
  static let dateFormatter = ISO8601DateFormatter()
  public func timefmt(_ date: Date) -> String {
    return GPXData.dateFormatter.string(from: date)
  }
}
