//
//  AppDelegate.swift
//  Loggy
//
//  Created by Peter Strand on 2017-06-19.
//  Copyright © 2017 Peter Strand. All rights reserved.
//

import UIKit

@UIApplicationMain
class LoggyAppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  var appState = AppState()
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    
    if let vc = window?.rootViewController {
      if let tab = vc as? UITabBarController {
        if let vcs = tab.viewControllers {
          for vc in vcs {
            if let vc = vc as? DashboardViewController {
              vc.settings = appState
              vc.gpxController = appState
              vc.units = appState
            }
            if let vc = vc as? TrackViewController {
              vc.gpxController = appState
              vc.units = appState
            }
            if let vc = vc as? SettingsViewController {
              vc.settings = appState
            }
            
          }
        }
      }
    }
    appState.didFinishLaunching()

    return true
  }

  func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
    print("open with url: \(url) options \(options)")
    return true
  }

  
  func applicationWillResignActive(_ application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
  }

  func applicationDidEnterBackground(_ application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    appState.didEnterBackground()
  }

  func applicationWillEnterForeground(_ application: UIApplication) {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }

  func applicationWillTerminate(_ application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }


}

