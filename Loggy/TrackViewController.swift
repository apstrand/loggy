//
//  TrackViewController.swift
//  Loggy
//
//  Created by Peter Strand on 2017-07-02.
//  Copyright © 2017 Peter Strand. All rights reserved.
//

import Foundation
import UIKit

class TrackViewController: UITableViewController {

  var gpxController: GPXBacking!
  
  required init?(coder aCoder: NSCoder) {
    super.init(coder: aCoder)
  }
 
  @IBAction func edgePanLeftAction(_ sender: Any) {
  }
}
