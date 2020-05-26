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
        
        /* Box or sphere (or SCNSphere); random
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
         */
        /* Capsule
        node.geometry = SCNCapsule(capRadius: 0.1, height: 0.3)
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        node.geometry?.firstMaterial?.specular.contents = UIColor.white
        node.position = SCNVector3(0, 0, -0.3)
         */
        /* Cone or cilinder (or SCNCylinder)
        node.geometry = SCNCone(topRadius: 0.1, bottomRadius: 0.3, height: 0.3)
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        node.geometry?.firstMaterial?.specular.contents = UIColor.white
        node.position = SCNVector3(0, 0, -0.3)
         */
        /* Tube
        node.geometry = SCNTube(
            innerRadius: 0.2,
            outerRadius: 0.3,
            height: 0.5)
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        node.geometry?.firstMaterial?.specular.contents = UIColor.white
        node.position = SCNVector3(0, 0, -0.3)
         */
        /* Torus
        node.geometry = SCNTorus(ringRadius: 0.3, pipeRadius: 0.1)
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        node.geometry?.firstMaterial?.specular.contents = UIColor.white
        node.position = SCNVector3(0, 0, -0.3)
         */
        /* Plane
        node.geometry = SCNPlane(width: 0.2, height: 0.2)
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        node.geometry?.firstMaterial?.specular.contents = UIColor.white
        node.position = SCNVector3(0, 0, -0.3)
         */
        /* Pyramid
        node.geometry = SCNPyramid(width: 0.1, height: 0.1, length: 0.1)
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        node.geometry?.firstMaterial?.specular.contents = UIColor.white
        node.position = SCNVector3(0, 0, -0.3)
         */
        /* Bezier
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 0.2))
        path.addLine(to: CGPoint(x: 0.2, y: 0.3))
        path.addLine(to: CGPoint(x: 0.4, y: 0.2))
        path.addLine(to: CGPoint(x: 0.4, y: 0))
        let shape = SCNShape(path: path, extrusionDepth: 0.2)
        node.geometry = shape;
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        node.geometry?.firstMaterial?.specular.contents = UIColor.white
        node.position = SCNVector3(0, 0, -0.3)
         */
        
        /* Relative positions
        node.geometry = SCNPyramid(width: 0.1, height: 0.1, length: 0.1)
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        node.geometry?.firstMaterial?.specular.contents = UIColor.white
        node.position = SCNVector3(0, 0, -0.3)
        
        let relative_node = SCNNode(geometry: SCNCylinder(
            radius: 0.05,
            height: 0.05)
        )
        relative_node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        relative_node.geometry?.firstMaterial?.specular.contents = UIColor.white
        relative_node.position = SCNVector3(0.1, 0.1, 0)
        node.addChildNode(relative_node)
         */
        
        /* Rotations
        node.geometry = SCNPyramid(width: 0.1, height: 0.1, length: 0.1)
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        node.geometry?.firstMaterial?.specular.contents = UIColor.white
        node.position = SCNVector3(0, 0, -0.3)
        node.eulerAngles = SCNVector3(Float.pi/2.0,0,0)
         */
        
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

