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
        NSLog("[HOST] The host app did finish launching.")
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
    
    func application(_ application: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:] ) -> Bool {
        
        // Determine who sent the URL.
        let sendingAppID = options[.sourceApplication]
        print("[HOST] This app was awoken using an URL sent by = \(sendingAppID ?? "Unknown")")
        
        // Process the URL.
        guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
            let resourcePath = components.path,
            let params = components.queryItems else {
                print("[HOST] This URL scheme was invalid.")
                return false
        }
        print("[HOST] The URL asks the resource: \(resourcePath).")
        
        if let firstParam = params.first(where: { $0.name == "firstParam" })?.value {
            print("[HOST] param1 in URL is \(firstParam).")
            return true
        } else {
            print("[HOST] FirstParam was missing.")
            return false
        }
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

