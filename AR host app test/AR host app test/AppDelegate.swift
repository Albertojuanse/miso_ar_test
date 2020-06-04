//
//  AppDelegate.swift
//  AR host app test
//
//  Created by MISO on 03/06/2020.
//  Copyright © 2020 MISO. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        NSLog("[HOST] The plug-in app did finish launching.")
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        NSLog("[HOST] The host app did become active.")
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        NSLog("[HOST] The host app will resign active.")
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        NSLog("[HOST] The host app did enter background.")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        NSLog("[HOST] The host app will enter foreground.")
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        NSLog("[HOST] The host app will terminate.")
    }
    
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

