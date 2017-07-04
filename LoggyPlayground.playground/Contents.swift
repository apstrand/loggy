//: Playground - noun: a place where people can play

import UIKit
import LoggyTools

// let gps = GPSTracker()

// gps.start()
// gps.stop()


let settings = SettingsImpl()

do {
  var token = settings.observe(key: "key", onChange: { print("value \($0)") })

  settings.update(value: "key", forKey: "meh")

}
