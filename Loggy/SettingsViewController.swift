//
//  SettingsViewController.swift
//  Loggy
//
//  Created by Peter Strand on 2017-07-02.
//  Copyright © 2017 Peter Strand. All rights reserved.
//

import Foundation
import UIKit
import LoggyTools

class SettingsViewController: UIViewController {

  @IBOutlet weak var autoWaypointToggle: UISwitch!
  @IBOutlet weak var alwaysAutoWaypointToggle: UISwitch!
  @IBOutlet weak var powerSaveToggle: UISwitch!
  
  var settings: SettingsRW!

  required init?(coder aCoder: NSCoder) {
    super.init(coder: aCoder)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
  
    powerSaveToggle.isOn = settings.isSet(SettingName.PowerSave)
    autoWaypointToggle.isOn = settings.isSet(SettingName.AutoWaypoint)
    alwaysAutoWaypointToggle.isOn = settings.isSet(SettingName.AlwaysAutoWaypoint)

  
  }
  
  @IBAction func toggleAlwaysAutowaypoint(sender: UISwitch) {
    settings.update(value: sender.isOn ? "true" : "false", forKey: SettingName.AlwaysAutoWaypoint)
  }
  
  @IBAction func toggleAutowaypoint(sender: UISwitch) {
    settings.update(value: sender.isOn ? "true" : "false", forKey: SettingName.AutoWaypoint)
  }
  
  @IBAction func togglePowerSave(sender: UISwitch) {
    settings.update(value: sender.isOn ? "true" : "false", forKey: SettingName.PowerSave)
  }

  
}
