//: Playground - noun: a place where people can play

import UIKit
//import LoggyTools

// let gps = GPSTracker()

// gps.start()
// gps.stop()

/*
let settings = SettingsImpl()

do {
  var token = settings.observe(key: "key", onChange: { print("value \($0)") })

  settings.update(value: "key", forKey: "meh")

}
*/
let syms = [ "N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW" ]

//let syms = [ "N", "NE", "E", "SE", "S", "SW", "W", "NW" ]
let sep = (360/syms.count)

let deg = 359
syms[ (syms.count + ((deg+sep/2) / sep)) % syms.count ]

func formatDMS(deg: Double, labels: (String,String)) -> String {

  let neg = deg < 0
  let d = abs(deg)
  let dec = Int(d)
  let min = Int((d - Double(dec)) * 60)
  let sec = (d - Double(dec) - Double(min)/60)*3600
  return (neg ? labels.0 : labels.1) + String(format:" %d° %d' %f\"", dec, min, sec)
}

formatDMS(deg:1.3333, labels:("W","E"))

formatDMS(deg:-1.3333, labels:("S", "N"))

