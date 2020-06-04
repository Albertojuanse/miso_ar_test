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
        
        let url = URL(string: "arplugin:method?firstParam=1")
               
        UIApplication.shared.open(url!) { (result) in
            if result {
               // The URL was delivered successfully!
            }
        }
        
    }
    
}

