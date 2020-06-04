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
    
    let configuration = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView.debugOptions = [
            ARSCNDebugOptions.showWorldOrigin,
            ARSCNDebugOptions.showFeaturePoints
        ]
        self.sceneView.session.run(configuration)
        
    }

    @IBAction func handleBackButton(_ sender: Any) {
        
    }
    
}

