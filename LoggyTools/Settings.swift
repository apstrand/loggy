//
//  Settings.swift
//  Loggy
//
//  Created by Peter Strand on 2017-07-02.
//  Copyright © 2017 Peter Strand. All rights reserved.
//

import Foundation


public protocol SettingsReader {
  func value(forKey key: String) -> String?
  func isSet(_ key: String) -> Bool
  func observe(key: String, onChange callback: @escaping (String) -> Void) -> Token
}

public protocol SettingsWriter {
  func update(value: String, forKey: String)
}

public protocol SettingsDefaults {
  static var defaults: [String : String] { get }
  static func setup()
  static var userDefaults: UserDefaults { get }
}

open class SettingsImpl<Settings : SettingsDefaults>: SettingsReader, SettingsWriter {
  private var listenerId = 0
  var listeners: [String: [(Int, (String) -> Void)]] = [:]
  
  public init() {
    Settings.setup()
  }
  
  public func isSet(_ key: String) -> Bool {
    return value(forKey: key) == "true"
  }
  
  public func value(forKey key: String) -> String? {
    let defaults = Settings.userDefaults
    return defaults.string(forKey: key) ?? Settings.defaults[key]
  }
  
  public func update(value: String, forKey key: String) {
    let defaults = Settings.userDefaults
    defaults.set(value, forKey: key)
    if let cs = listeners[key] {
      for (_,cb) in cs {
        cb(value)
      }
    }
  }
  
  
  public func observe(key: String, onChange callback: @escaping (String) -> Void) -> Token {
    listenerId += 1
    if let _ = listeners[key] {
      listeners[key]!.append((listenerId, callback))
    } else {
      listeners[key] = [(listenerId, callback)]
    }
    if let val = value(forKey: key) ?? Settings.defaults[key] {
      callback(val)
    }
    let removeId = listenerId
    return TokenImpl {
      outer: for (key,vs) in self.listeners {
        for ix in 0..<vs.count {
          let id = vs[ix].0
          if id == removeId {
            self.listeners[key]!.remove(at: ix)
            print("removed listener \(removeId) for \(key)")
            break outer
          }
        }
      }
    }
  }
  
}
