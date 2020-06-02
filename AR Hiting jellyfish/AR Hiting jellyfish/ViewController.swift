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
        self.buttonPlay.isEnabled = false
    }
    
    func addNode() {
        /*
        let node = SCNNode(geometry: SCNBox(width: 0.2,
                                            height: 0.2,
                                            length: 0.2,
                                            chamferRadius: 0.0))
        node.position = SCNVector3(0,0,-1)
        self.sceneView.scene.rootNode.addChildNode(node)
         */
        let jellyfishScene = SCNScene(named: "Jellyfish.scn")
        let jellyfishNode = jellyfishScene?.rootNode.childNode(
            withName:"Jellyfish",
            recursively: false)
        jellyfishNode?.position = SCNVector3(0,0,-1)
        self.sceneView.scene.rootNode.addChildNode(jellyfishNode!)
    }
    
    @objc func handleTap(sender: UIGestureRecognizer) {
        let sceneViewTappedOn = sender.view as! SCNView
        let touchCoordinates = sender.location(in: sceneViewTappedOn)
        let hitTest = sceneViewTappedOn.hitTest(touchCoordinates)
        if hitTest.isEmpty {
            
        } else {
            let results = hitTest.first!
            let node = results.node
            if node.animationKeys.isEmpty {
                self.animateNode(node: node)
            }
        }
    }
    
    func animateNode(node: SCNNode) {
        let spin = CABasicAnimation(keyPath: "position")
        spin.fromValue = node.presentation.position
        spin.toValue = SCNVector3(node.presentation.position.x - 0.2,
                                  node.presentation.position.y - 0.2,
                                  node.presentation.position.z - 0.2)
        spin.duration = 0.15
        spin.autoreverses = true
        spin.repeatCount = 5
        node.addAnimation(spin, forKey: "position")
    }
    
}

