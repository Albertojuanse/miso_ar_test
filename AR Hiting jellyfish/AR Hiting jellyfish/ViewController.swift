//
//  ViewController.swift
//  AR Hiting jellyfish
//
//  Created by MISO on 02/06/2020.
//  Copyright © 2020 MISO. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var buttonPlay: UIButton!
    @IBOutlet weak var buttonReset: UIButton!
    
    let configuration = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.debugOptions = [
            ARSCNDebugOptions.showWorldOrigin,
            ARSCNDebugOptions.showFeaturePoints
        ]
        self.sceneView.session.run(configuration)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                          action: #selector(handleTap))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
    }

    @IBAction func handleButtonReset(_ sender: Any) {
        
    }
    
    @IBAction func handlePlayButton(_ sender: Any) {
        self.addNode()
    }
    
    func addNode() {
        let node = SCNNode(geometry: SCNBox(width: 0.2,
                                            height: 0.2,
                                            length: 0.2,
                                            chamferRadius: 0.0))
        node.position = SCNVector3(0,0,-1)
        self.sceneView.scene.rootNode.addChildNode(node)
    }
    
    @objc func handleTap(sender: UIGestureRecognizer) {
        let sceneViewTappedOn = sender.view as! SCNView
        let touchCoordinates = sender.location(in: sceneViewTappedOn)
        let hitTest = sceneViewTappedOn.hitTest(touchCoordinates)
        if hitTest.isEmpty {
            
        } else {
            let results = hitTest.first!
            let geometry = results.node.geometry
        }
    }
    
}

