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
  @IBOutlet weak var powerSaveToggle: UISwitch!
  
  var settings: SettingsRW!
  var appState: AppFileState!

  required init?(coder aCoder: NSCoder) {
    super.init(coder: aCoder)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
  
    powerSaveToggle.isOn = settings.isSet(SettingName.PowerSave)
    autoWaypointToggle.isOn = settings.isSet(SettingName.AutoWaypoint)

  
  }

  @IBAction func clearTracksAction(_ sender: Any) {
    appState.clearAndBumpAutoSave()
  }

  @IBAction func openSettingsAction(_ sender: Any) {
    let app = UIApplication.shared
    if let url = URL(string:UIApplicationOpenSettingsURLString) {
      if app.canOpenURL(url) {
        app.open(url, options: [:], completionHandler: { result in return } )
      }
    }
  }

  @IBAction func toggleAutowaypoint(sender: UISwitch) {
    settings.update(value: sender.isOn ? "true" : "false", forKey: SettingName.AutoWaypoint)
  }
  
  @IBAction func togglePowerSave(sender: UISwitch) {
    settings.update(value: sender.isOn ? "true" : "false", forKey: SettingName.PowerSave)
  }

  
}
