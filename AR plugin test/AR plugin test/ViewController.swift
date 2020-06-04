//
//  ViewController.swift
//  AR plugin test
//
//  Created by MISO on 03/06/2020.
//  Copyright © 2020 MISO. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var buttonBack: UIButton!
    @IBOutlet weak var labelParam1: UILabel!
    
    let configuration = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView.debugOptions = [
            ARSCNDebugOptions.showWorldOrigin,
            ARSCNDebugOptions.showFeaturePoints
        ]
        self.sceneView.session.run(configuration)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        print("[PLUG-IN] AppDelegate provided param1: \(appDelegate.param1).")
        self.labelParam1.text = appDelegate.param1
    }

    @IBAction func handleBackButton(_ sender: Any) {
        
        let param1 = self.labelParam1.text!
        let url = "arhost:resourcePath?firstParam=\(param1)"
        print("[PLUG-IN] The host app will ask the resource \(url).")
        
        if let appURL = URL(string: url) {
            UIApplication.shared.open(appURL) { success in
                if success {
                    print("[PLUG-IN] The URL was delivered successfully.")
                } else {
                    print("[PLUG-IN] The URL failed to open.")
                }
            }
        } else {
            print("[PLUG-IN] Invalid URL specified.")
        }
        
    }
    
}

