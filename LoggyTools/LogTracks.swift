//
//  LogTracks.swift
//  Loggy
//
//  Created by Peter Strand on 2017-07-12.
//  Copyright © 2017 Peter Strand. All rights reserved.
//

import Foundation
import CoreLocation


public class LogTracks {
  
  public typealias LocationLogger = (TrackPoint, Bool) -> Void
  public typealias TrackLogger = (GPXData.Track?, GPXData.TrackSeg?, TrackPoint?) -> Void
  public typealias WaypointLogger = (GPXData.Waypoint) -> Void
  
  var trackLoggers : [(Int,Filter,TrackLogger)] = []
  var waypointLoggers : [(Int,Filter,WaypointLogger)] = []
  var loggerId = 0
  var regs = TokenRegs()
  
  public var gpx: GPXData
  public var isTracking: Bool = false
  
  public init(_ gpx: GPXData) {
    self.gpx = gpx
   
  }
  
  public func handleNewLocation(point pt: TrackPoint, isMajor: Bool) {
    if isTracking {
      self.gpx.tracks.last!.segments.last!.track.append(TrackPoint(location:pt.location, timestamp: pt.timestamp))
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
    let trackingOnly: Bool
    public init(trackingOnly: Bool, fullHistory: Bool = false, majorPoints: Bool = false) {
      self.fullHistory = fullHistory
      self.trackingOnly = trackingOnly
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

