//
//  ViewController.swift
//  AR host app test
//
//  Created by MISO on 03/06/2020.
//  Copyright © 2020 MISO. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }

    @IBAction func handleButtonAR(_ sender: Any) {
        
        print("[HOST] The host app will ask the resource arplugin:resourcePath?firstParam=1.")
        if let appURL = URL(string: "arplugin:resourcePath?firstParam=1") {
            UIApplication.shared.open(appURL) { success in
                if success {
                    print("[HOST] The URL was delivered successfully.")
                } else {
                    print("[HOST] The URL failed to open.")
                }
            }
        } else {
            print("[HOST] Invalid URL specified.")
        }
        
    }
    
}

