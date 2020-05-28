//
//  ViewController.swift
//  AR Drawing
//
//  Created by MISO on 27/05/2020.
//  Copyright © 2020 MISO. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var buttonDraw: UIButton!
    let configuration = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.debugOptions = [
            ARSCNDebugOptions.showFeaturePoints,
            ARSCNDebugOptions.showWorldOrigin];
        self.sceneView.showsStatistics = true;
        self.sceneView.session.run(configuration)
        self.sceneView.delegate = self;
    }
    
    func renderer(_ renderer: SCNSceneRenderer,
                  willRenderScene scene: SCNScene,
                  atTime time: TimeInterval) {
        guard let pointOfView = sceneView.pointOfView else {return}
        let pov_transform = pointOfView.transform
        let orientation = SCNVector3(
            -pov_transform.m31,
            -pov_transform.m32,
            -pov_transform.m33)
        let location = SCNVector3(
            pov_transform.m41,
            pov_transform.m42,
            pov_transform.m43)
        let frontOfCamera = orientation + location;
        
        DispatchQueue.main.async {
            if self.buttonDraw.isHighlighted {
                let sphereNode = SCNNode(geometry: SCNSphere(radius: 0.02))
                sphereNode.position = frontOfCamera;
                self.sceneView.scene.rootNode.addChildNode(sphereNode)
                sphereNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
            } else {
                self.sceneView.scene.rootNode.enumerateChildNodes {
                    (node, _) in
                    if node.name == "pointer" {
                        node.removeFromParentNode()
                    }
                }
                
                let pointer = SCNNode(geometry: SCNSphere(radius: 0.01))
                pointer.name = "pointer"
                pointer.position = frontOfCamera;
                self.sceneView.scene.rootNode.addChildNode(pointer)
                pointer.geometry?.firstMaterial?.diffuse.contents = UIColor.red
            }
        }
    }
    
}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x,
                          left.y + right.y,
                          left.z + right.z)
}
