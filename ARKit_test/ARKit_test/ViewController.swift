//
//  ViewController.swift
//  ARKit_test
//
//  Created by MISO on 24/05/2020.
//  Copyright © 2020 MISO. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet weak var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.sceneView.debugOptions = [
            ARSCNDebugOptions.showFeaturePoints,
            ARSCNDebugOptions.showWorldOrigin
        ]
        self.sceneView.session.run(configuration)
    }

    @IBAction func handleTapAdd(_ sender: Any) {
        let node = SCNNode()
        node.geometry = SCNBox(width: 0.1,
                               height: 0.1,
                               length: 0.1,
                               chamferRadius: 0)
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        node.position = SCNVector3(0, 0, 0)
        self.sceneView.scene.rootNode.addChildNode(node)
    }
    
}

