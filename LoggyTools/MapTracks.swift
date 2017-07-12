//
//  MapTrack.swift
//  Loggy
//
//  Created by Peter Strand on 2017-07-12.
//  Copyright © 2017 Peter Strand. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

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
  let MaxLatSpan: CLLocationDegrees = 2
  let MaxLonSpan: CLLocationDegrees = 2
  
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
    assert(isTracking)
    
    if self.isTracking && isMajor {
      self.add(pt.location)
      
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
    
    
    if let region = self.region() {
      self.mapView.setRegion(region, animated: true)
    } else {
      self.mapView.setCenter(pt.location, animated: true)
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
    var span: MKCoordinateSpan
    if coordCache.count > 1 {
      span = MKCoordinateSpan(
        latitudeDelta: min(MaxLatSpan, max(MinLatSpan, 3*(max_lat - min_lat))),
        longitudeDelta: min(MaxLonSpan, max(MinLonSpan, 3*(max_lon - min_lon))))
    } else {
      span = MKCoordinateSpan(latitudeDelta: MinLatSpan, longitudeDelta: MinLonSpan)
    }
    if let last = coordCache.last {
      let coordReg = MKCoordinateRegion(center: last, span: span)
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
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
      if !parent.isTracking {
        parent.mapView.setCenter(userLocation.coordinate, animated: true)
      }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
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


