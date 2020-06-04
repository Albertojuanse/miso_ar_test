//
//  ViewController.swift
//  AR host app test
//
//  Created by MISO on 03/06/2020.
//  Copyright © 2020 MISO. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var textParam1: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }

    @IBAction func handleButtonAR(_ sender: Any) {
        
        let param1 = self.textParam1.text!
        let url = "arplugin:resourcePath?firstParam=\(param1)"
        print("[HOST] The host app will ask the resource \(url).")
        
        if let appURL = URL(string: url) {
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

