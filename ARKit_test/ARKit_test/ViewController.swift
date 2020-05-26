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
        self.sceneView.automaticallyUpdatesLighting = true;
    }

    @IBAction func handleTapAdd(_ sender: Any) {
        let node = SCNNode()
        node.geometry = SCNBox(width: 0.1,
                               height: 0.1,
                               length: 0.1,
                               chamferRadius: 0)
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        node.geometry?.firstMaterial?.specular.contents = UIColor.white
        let x = randomNumbers(firstNum: -0.3, secondNum: 0.3)
        let y = randomNumbers(firstNum: -0.3, secondNum: 0.3)
        let z = randomNumbers(firstNum: -0.3, secondNum: 0.3)
        node.position = SCNVector3(x, y, z)
        self.sceneView.scene.rootNode.addChildNode(node)
    }
    
    @IBAction func handleTapReset(_ sender: Any) {
        self.resetSession()
    }
    
    func resetSession() {
        self.sceneView.session.pause()
        self.sceneView.scene.rootNode.enumerateChildNodes{
            (node, _) in
            node.removeFromParentNode()
        }
        self.sceneView.session.run(configuration,
                                   options: [
                                    .resetTracking,
                                    .removeExistingAnchors
                                    ])
    }
    
    func randomNumbers(firstNum: CGFloat, secondNum: CGFloat) -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) +
        min(firstNum, secondNum)
    }
    
}

