//
//  ViewController.swift
//  AR planets
//
//  Created by MISO on 30/05/2020.
//  Copyright © 2020 MISO. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet weak var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView.debugOptions = [
            ARSCNDebugOptions.showWorldOrigin,
            ARSCNDebugOptions.showFeaturePoints
        ];
        self.sceneView.session.run(configuration);
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let sun = SCNNode(geometry: SCNSphere(radius: 0.35))
        let earthParent = SCNNode()
        
        sun.geometry?.firstMaterial?.diffuse.contents = SKTexture(imageNamed: "sun.jpg");
        sun.position = SCNVector3(0,0,-1)
        earthParent.position = SCNVector3(0,0,-1)
        
        self.sceneView.scene.rootNode.addChildNode(sun)
        self.sceneView.scene.rootNode.addChildNode(earthParent)
        
        let earth = planet(geometry: SCNSphere(radius: 0.2),
                           diffuse: SKTexture(imageNamed: "earth.jpg"),
                           position: SCNVector3(1.2 ,0 , 0))
        
        let sunAction = Rotation(time: 8)
        let earthParentRotation = Rotation(time: 14)
        let earthRotation = Rotation(time: 8)
        
        earth.runAction(earthRotation)
        earthParent.runAction(earthParentRotation)
        sun.addChildNode(earth)
        sun.runAction(sunAction)
        earthParent.addChildNode(earth)
        
    }
    
    func planet(geometry: SCNGeometry, diffuse: SKTexture, position: SCNVector3) -> SCNNode {
        let planet = SCNNode(geometry: geometry)
        planet.geometry?.firstMaterial?.diffuse.contents = diffuse
        planet.position = position
        return planet
        
    }
    
    func Rotation(time: TimeInterval) -> SCNAction {
        let Rotation = SCNAction.rotateBy(x: 0, y: CGFloat(360.degreesToRadians), z: 0, duration: time)
        let foreverRotation = SCNAction.repeatForever(Rotation)
        return foreverRotation
    }
    
}

extension Int {
    
    var degreesToRadians: Double { return Double(self) * .pi/180}
}
