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

public class LogTracks {

  public typealias TrackLogger = (GPXData.Track?, GPXData.TrackSeg?, TrackPoint?) -> Void
  public typealias WaypointLogger = (GPXData.Waypoint) -> Void

  var trackLoggers : [(Int,Filter,TrackLogger)] = []
  var waypointLoggers : [(Int,Filter,WaypointLogger)] = []
  var loggerId = 0

  
  public var gpx: GPXData
  public var isTracking: Bool = false
  
  public init(_ gpx: GPXData) {
    self.gpx = gpx
    
  }
  
  public func handleNewLocation(point pt: TrackPoint, isMajor: Bool) {
    
    if self.isTracking && isMajor {
      
      if isMajor {
        gpx.tracks.last!.segments.last!.track.append(TrackPoint(location:pt.location, timestamp: pt.timestamp))
      }
      
      let track = gpx.tracks.last!
      let seg = track.segments.last!
      for logger in trackLoggers {
        if !isMajor || logger.1.majorPoints {
          logger.2(track, seg, pt)
        }
      }
    }
  }
  
  public func startNewSegment() {

    if gpx.tracks.count == 0 {
      gpx.tracks.append(GPXData.Track(id:gpx.genId()))
    }
    gpx.tracks.last!.segments.append(GPXData.TrackSeg(id:gpx.genId()))
    isTracking = true
  }
  
  public func endSegment(_ pt: TrackPoint?) {
    isTracking = false
  }
  
  public func storeWaypoint(location pt: TrackPoint) {
    let waypoint = GPXData.Waypoint(point: pt, id: gpx.genId())
    
      for logger in self.waypointLoggers {
        logger.2(waypoint)
      }

  }
  
  public struct Filter {
    let fullHistory: Bool
    let majorPoints: Bool
    public init(fullHistory: Bool = false, majorPoints: Bool = false) {
      self.fullHistory = fullHistory
      self.majorPoints = majorPoints
    }
  }
  public func observeTrackData(_ filter: Filter, _ logger : @escaping TrackLogger) -> Token
  {
    loggerId += 1
    let removeId = loggerId
    self.trackLoggers.append((removeId,filter,logger))
    
    if filter.fullHistory {
      for track in gpx.tracks {
        for seg in track.segments {
          logger(track, seg, nil)
        }
      }
    }
    
    return TokenImpl {
      for ix in self.trackLoggers.indices {
        if self.trackLoggers[ix].0 == removeId {
          self.trackLoggers.remove(at: ix)
          break
        }
      }
    }
  }

  public func observeWaypoints(_ filter: Filter, _ logger : @escaping WaypointLogger) -> Token
  {
    loggerId += 1
    let removeId = loggerId
    self.waypointLoggers.append((removeId,filter,logger))

    if filter.fullHistory {
      for waypoint in gpx.waypoints {
        logger(waypoint)
      }
    }
    
    return TokenImpl {
      for ix in self.waypointLoggers.indices {
        if self.waypointLoggers[ix].0 == removeId {
          self.waypointLoggers.remove(at: ix)
          break
        }
      }
    }
  }

  public func load(from other: GPXData) {
    self.gpx.tracks = other.tracks
    self.gpx.waypoints = other.waypoints
    refreshObservers()
  }
  
  func refreshObservers() {
    for logger in trackLoggers {
      if logger.1.fullHistory {
        // clear all
        logger.2(nil, nil, nil)
      }
    }
    for track in self.gpx.tracks {
      for seg in track.segments {
        for logger in trackLoggers {
          if logger.1.fullHistory {
            logger.2(track, seg, nil)
          }
        }
      }
    }
    for waypoint in self.gpx.waypoints {
      for logger in waypointLoggers {
        if logger.1.fullHistory {
          logger.2(waypoint)
        }
      }
    }
  }
}

public class MapTracks {
  
  public class LoggyAnnotation: NSObject, MKAnnotation {
    public var coordinate: CLLocationCoordinate2D
    public init(coordinate: CLLocationCoordinate2D) {
      self.coordinate = coordinate
    }
  }
  
  public class WaypointAnnotation: LoggyAnnotation {
    static let identifier = "waypoint"
  }
  
  public class TrackAnnotation: LoggyAnnotation {
    static let identifier = "track"
    let isStart: Bool
    public init(coordinate: CLLocationCoordinate2D, isStart: Bool) {
      self.isStart = isStart
      super.init(coordinate: coordinate)
    }
  }

  let MinLatSpan: CLLocationDegrees = 0.02
  let MinLonSpan: CLLocationDegrees = 0.02
  
  var min_lat: CLLocationDegrees = 0
  var max_lat: CLLocationDegrees = 0
  var min_lon: CLLocationDegrees = 0
  var max_lon: CLLocationDegrees = 0

  var trackPolys: [MKPolyline] = []
  var currentPoly: MKPolyline? = nil
  
  var mapView: MKMapView
  var mapDelegate: MapDelegate?
  
  public var gpx: GPXData
  public var coordCache: [CLLocationCoordinate2D] = []
  public var isTracking: Bool = false
  public var isStartingSegment: Bool = false
  
  public init(_ mapView: MKMapView, _ gpx: GPXData) {
    self.mapView = mapView
    self.gpx = gpx
    self.mapDelegate = MapDelegate(self)
    self.mapView.delegate = self.mapDelegate

  }
  
  public func handleNewLocation(point pt: TrackPoint, isMajor: Bool) {
    self.mapView.setCenter(pt.location, animated: true)
    
    if self.isTracking && isMajor {
      self.add(pt.location)
      
      if let region = self.region() {
        self.mapView.setRegion(region, animated: true)
      }
      
      if self.isStartingSegment {
        let ann = TrackAnnotation(coordinate: pt.location, isStart: true)
        self.mapView.addAnnotation(ann)
        self.isStartingSegment = false
      }
      let newPoly = MKPolyline(coordinates: &self.coordCache, count: self.coordCache.count)
      if let poly = self.currentPoly {
        self.mapView.remove(poly)
      } else {
        self.trackPolys.append(newPoly)
      }
      self.mapView.add(newPoly)
      self.currentPoly = newPoly
    }

  }
  
  public func startNewSegment() {
    currentPoly = nil
    coordCache.removeAll()
    min_lat = Double.greatestFiniteMagnitude
    max_lat = -Double.greatestFiniteMagnitude
    min_lon = Double.greatestFiniteMagnitude
    max_lon = -Double.greatestFiniteMagnitude

    isTracking = true
    isStartingSegment = true
  }

  public func endSegment(_ pt: TrackPoint?) {
    isTracking = false
    if let pt = pt {
      let place = TrackAnnotation(coordinate: pt.location, isStart: false)
      self.mapView.addAnnotation(place)
    }  
  }
  
  public func storeWaypoint(_ waypoint: GPXData.Waypoint) {
    let ann = WaypointAnnotation(coordinate: waypoint.point.location)
    self.mapView.addAnnotation(ann)
  }
  
  public func add(_ coord : CLLocationCoordinate2D) {
    min_lat = min(min_lat, coord.latitude)
    max_lat = max(min_lat, coord.latitude)
    min_lon = min(min_lon, coord.longitude)
    max_lon = max(min_lon, coord.longitude)

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

  class MapDelegate : NSObject, MKMapViewDelegate {
    let parent : MapTracks
    init(_ p : MapTracks) {
      parent = p
    }
    public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
      if overlay is MKPolyline {
        let polyLine = overlay
        let polyLineRenderer = MKPolylineRenderer(overlay: polyLine)
        polyLineRenderer.strokeColor = UIColor.black
        polyLineRenderer.lineWidth = 2.0
        
        return polyLineRenderer
      }
      fatalError("mapView: Unknown overlay")
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
      if let _ = annotation as? WaypointAnnotation {
        var pin: MKPinAnnotationView!
        if let view = mapView.dequeueReusableAnnotationView(withIdentifier: WaypointAnnotation.identifier) {
          pin = view as! MKPinAnnotationView
          pin.annotation = annotation
        } else {
          pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: WaypointAnnotation.identifier)
        }
        pin.pinTintColor = UIColor.blue
        return pin
      }
      if let track = annotation as? TrackAnnotation {
        var pin: MKPinAnnotationView!
        if let view = mapView.dequeueReusableAnnotationView(withIdentifier: TrackAnnotation.identifier) {
          pin = view as! MKPinAnnotationView
          pin.annotation = annotation
        } else {
          pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: TrackAnnotation.identifier)
        }
        pin.pinTintColor = track.isStart ? UIColor.green : UIColor.red
        return pin
      }
      return nil
    }
    
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
      //      print("mapView changed: \(mapView.visibleMapRect)")
    }
  }

}

