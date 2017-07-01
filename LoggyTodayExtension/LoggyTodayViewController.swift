//
//  TodayViewController.swift
//  LoggyTodayExtension
//
//  Created by Peter Strand on 2017-06-23.
//  Copyright © 2017 Peter Strand. All rights reserved.
//

import UIKit
import NotificationCenter
import LoggyTools

class LoggyTodayViewController: UIViewController, NCWidgetProviding {
  
  @IBOutlet weak var lastUpdatedLabel: UILabel!
  @IBOutlet weak var locationLabel: UILabel!
  @IBOutlet weak var altitudeLabel: UILabel!
  @IBOutlet weak var bearingLabel: UILabel!
  @IBOutlet weak var speedLabel: UILabel!
  
  @IBOutlet weak var waypointButton: UIButton!
  @IBOutlet weak var stopButton: UIButton!
  @IBOutlet weak var startButton: UIButton!
  
  @IBAction func waypointAction(_ sender: Any) {
    print("[W] storeWaypoint")
    extensionContext?.open(AppUrl.app(cmd:.StoreWaypoint), completionHandler: nil)
  }

  @IBAction func stopAction(_ sender: Any) {
    print("[W] stopAction")
    extensionContext?.open(AppUrl.app(cmd:.StopTracking), completionHandler: nil)
  }
  
  @IBAction func startAction(_ sender: Any) {
    print("[W] startAction")
    extensionContext?.open(AppUrl.app(cmd:.StartTracking), completionHandler: nil)
  }
  
  
  func appState() -> UserDefaults? {
    let defaults = UserDefaults(suiteName: SettingName.Suite)
    return defaults
  }
  
  func updateState(enabled : Bool) {
    let setup : ((UIButton,Bool) -> Void) = { btn,state in
      btn.isEnabled = state; btn.alpha = state ? 1.0 : 0.5
    }
    let defaults = appState()
    setup(self.startButton, !enabled)
    setup(self.stopButton, enabled)
    setup(self.waypointButton, (defaults?.bool(forKey:SettingName.AlwaysAutoWaypoint) ?? false) ? true : enabled)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()

    let defaults = appState()
    if let val = defaults?.bool(forKey: SettingName.TrackingEnabled) {
      updateState(enabled:val)
    }
    
    
//    extensionContext?.widgetLargestAvailableDisplayMode = .expanded
  }
  
  
 func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
    let expanded = activeDisplayMode == .expanded
    preferredContentSize = expanded ? CGSize(width: maxSize.width, height: 500) : maxSize
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
    // Perform any setup necessary in order to update the view.

    let defaults = appState()
    if let val = defaults?.bool(forKey: SettingName.TrackingEnabled) {
      if val != stopButton.isEnabled {
        updateState(enabled:val)
        completionHandler(.newData)
      }
    }

    completionHandler(NCUpdateResult.noData)
  }
    
}
