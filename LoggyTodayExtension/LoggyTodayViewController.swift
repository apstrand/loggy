//
//  TodayViewController.swift
//  LoggyTodayExtension
//
//  Created by Peter Strand on 2017-06-23.
//  Copyright © 2017 Peter Strand. All rights reserved.
//

import UIKit
import NotificationCenter

class LoggyTodayViewController: UIViewController, NCWidgetProviding {
  
  @IBOutlet weak var info_row1: UILabel!
  @IBOutlet weak var info_row2_1: UILabel!
  @IBOutlet weak var info_row2_2: UILabel!
  
  @IBAction func storeWaypoint(_ sender: UIButton) {
    print("[W] storeWaypoint")
    if let url = URL(string:"loggy://action?storeWaypoint") {
      extensionContext?.open(url, completionHandler: nil)
    }
  }
  
  @IBOutlet weak var statusSwitch: UISwitch!
  
  @IBAction func toggleStatus(_ sender: UISwitch) {
    print("[W] toggleStatus: \(sender.isOn)")
    guard let url = URL(string:"loggy://tracking?" + (sender.isOn ? "on" : "off")) else { return }
    extensionContext?.open(url, completionHandler: nil)
  }
  
  func appState() -> UserDefaults? {
    let defaults = UserDefaults(suiteName: "group.se.nena.loggy")
    return defaults
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let defaults = appState()
    if let val = defaults?.bool(forKey: "tracking.enabled") {
      self.statusSwitch.isOn = val
    }
    self.info_row1.text = defaults?.string(forKey: "info.row1")
    self.info_row2_1.text = defaults?.string(forKey: "info.row2_1")
    self.info_row2_2.text = defaults?.string(forKey: "info.row2_2")
    
//    extensionContext?.widgetLargestAvailableDisplayMode = .expanded
  }
  
  
 func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
    let expanded = activeDisplayMode == .expanded
    preferredContentSize = expanded ? CGSize(width: maxSize.width, height: 200) : maxSize
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
    
    // If an error is encountered, use NCUpdateResult.Failed
    // If there's no update required, use NCUpdateResult.NoData
    // If there's an update, use NCUpdateResult.NewData
    
    completionHandler(NCUpdateResult.newData)
  }
    
}
