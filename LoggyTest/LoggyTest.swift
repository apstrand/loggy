//
//  LoggyTest.swift
//  LoggyTest
//
//  Created by Peter Strand on 2017-07-01.
//  Copyright © 2017 Peter Strand. All rights reserved.
//

import XCTest


class LoggyTest: XCTestCase {
  
  let path = Bundle.init(for: LoggyTest.self).resourceURL!
  
  override func setUp() {
    super.setUp()
  }
  
  override func tearDown() {
    super.tearDown()
  }

  func testLoadGpx() {
    let gpx = GPXData(contentsOf: path.appendingPathComponent("short_track_wpt.gpx"))
    XCTAssertEqual(3, gpx.waypoints.count)
    XCTAssertEqual("Scot's run waterfall", gpx.waypoints[0].name)
    XCTAssertEqual(2, gpx.tracks.count)
    XCTAssertEqual(11, gpx.tracks[0].segments[0].track.count)
  }
  /*
  func testSaveGpx() {
    
  }

  func testGpxRoundtrip() {
    
  }
  */
}
