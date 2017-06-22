//
//  ViewController.swift
//  Loggy
//
//  Created by Peter Strand on 2017-06-19.
//  Copyright © 2017 Peter Strand. All rights reserved.
//

import UIKit
import MapKit

class DashboardViewController: UIViewController {

  @IBOutlet weak var locationLabel: UILabel!
  @IBOutlet weak var altitudeLabel: UILabel!
  @IBOutlet weak var speedLabel: UILabel!
  @IBOutlet weak var bearingLabel: UILabel!
  @IBOutlet weak var locationValue: UILabel!
  @IBOutlet weak var altitudeValue: UILabel!
  @IBOutlet weak var speedValue: UILabel!
  @IBOutlet weak var bearingValue: UILabel!
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var autoWaypointToggle: UISwitch!
  @IBOutlet weak var powerSaveToggle: UISwitch!
  @IBOutlet weak var startButton: UIButton!
  @IBOutlet weak var waypointButton: UIButton!
  @IBOutlet weak var stopButton: UIButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    
  }
  
  @IBAction func startTracking(sender: UIButton) {
    
  }
  @IBAction func stopTracking(sender: UIButton) {
    
  }
  @IBAction func storeWaypoint(sender: UIButton) {
    
  }
  
  @IBAction func toggleAutowaypoint(sender: UISwitch) {
    
  }
  @IBAction func togglePowerSave(sender: UISwitch) {
    
  }
  
  @IBAction func toggleUnit(sender: UILabel) {
    
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
}

