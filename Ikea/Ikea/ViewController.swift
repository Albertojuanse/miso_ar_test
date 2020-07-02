//
//  ViewController.swift
//  Ikea
//
//  Created by Miso on 02/06/2020.
//  Copyright © 2020 Miso. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, ARSCNViewDelegate {
    
    var itemsArray: [String] = []
    var metamodel: [NSMutableDictionary] = []
    var graphicalSyntax: [NSMutableDictionary] = []
    var model: [NSMutableDictionary] = [];
    // -- MODEL SCHEME --
    // [
    //  { "name" = uuid1 : UUID
    //    "class" = class1 : String
    //    "current_version" = version1 : Int
    //    "max_version" = 3
    //   },
    //  { "name" = uuid2 : UUID
    //    (···)
    //   },
    //  (···)
    // ]
    
    @IBOutlet weak var planeDetected: UILabel!
    @IBOutlet weak var itemsCollectionView: UICollectionView!
    @IBOutlet weak var sceneView: ARSCNView!
    
    let configuration = ARWorldTrackingConfiguration()
    
    var selectedItem: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ARKit scene view initialization
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        self.configuration.planeDetection = .horizontal
        self.sceneView.session.run(configuration)
        self.sceneView.delegate = self
        self.sceneView.autoenablesDefaultLighting = true
        
        // Layout
        self.itemsCollectionView.dataSource = self
        self.itemsCollectionView.delegate = self
        
        // Gesture recognizers
        self.registerGestureRecognizers()
        
    }
    
    func registerGestureRecognizers() {
        // Tap gesture is used to add objects
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        // Pinch gesture is used to resize the object
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinch))
        self.sceneView.addGestureRecognizer(pinchGestureRecognizer)
        
        // Long press gesture is used to rotate the object
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(rotate))
        longPressGestureRecognizer.minimumPressDuration = 0.1
        self.sceneView.addGestureRecognizer(longPressGestureRecognizer)
        
        // Swipe gesture is used to change the graphic syntax version
        let swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
        self.sceneView.addGestureRecognizer(swipeGestureRecognizer)
    }
    
    // Gestures do 2 types of raycasting
    // - World raycasting, based on ARRaycastQuery supported by ARKit to find world surfaces, etc.
    // - Scene raycasting, based on SCNHitTest supported by SceneKit to find virtual nodes.
    
    @objc func tapped(sender: UITapGestureRecognizer) {
        // Get from the scene the tapped position
        let sceneView = sender.view as! ARSCNView
        let tapLocation = sender.location(in: sceneView)
        
        // Configure the world raycast query and create it
        let estimatedPlane: ARRaycastQuery.Target = .estimatedPlane
        let alignment: ARRaycastQuery.TargetAlignment = .any
        let rayCastQuery = sceneView.raycastQuery(from: tapLocation,
                                                  allowing: estimatedPlane,
                                                  alignment: alignment)
        // TODO: Check if sceneView.session.currentFrame.raycastQuery() does the same. Alberto J. 2020/06/29
        
        // Get results preventing nil responses
        if let nonOptRayCastQuery: ARRaycastQuery = rayCastQuery {

            let worldResult: [ARRaycastResult] = sceneView.session.raycast(nonOptRayCastQuery)

            guard let rayCast: ARRaycastResult = worldResult.first
            else {
                print("[VC] World raycast over", tapLocation, "did not get any result.")
                return
            }

            self.addItem(rayCast: rayCast)
            
        }
    }
    
    func addItem(rayCast: ARRaycastResult) {
        // User wants to add an object of class selectedItem
        if let selectedItem = self.selectedItem {
            
            // Create a new object in model
            let itemDic = NSMutableDictionary()
            let itemName = UUID().uuidString
            itemDic["name"] = itemName
            itemDic["class"] = selectedItem
            itemDic["current_version"] = 1
            itemDic["max_version"] = 3
            model.append(itemDic)
            
            // Search for its graphical syntax
            var graphicalSyntaxClass = NSMutableDictionary()
            for aGraphicalSyntaxClass in self.graphicalSyntax {
                let className = aGraphicalSyntaxClass["name"] as! String
                if className == selectedItem {
                    graphicalSyntaxClass = aGraphicalSyntaxClass
                }
            }
            // Get the version's sources and load the graphical syntax
            let classVersions = graphicalSyntaxClass["versions"] as! NSMutableDictionary
            let currentVersion = 1
            let firstSource = classVersions["v\(currentVersion)"] as! String;
            let url = URL(string: firstSource)
            if let scene = try? SCNScene(url: url! , options: nil) {
                
                print("[VC] Load \(selectedItem).scn successful.")
                
                // Get the .scn's node called 'selectedItem', since each .scn can have got several nodes
                let node = (scene.rootNode.childNode(withName: selectedItem, recursively: false))!
                node.name = itemName
                let transform = rayCast.worldTransform
                let thirdColumn = transform.columns.3
                node.position = SCNVector3(thirdColumn.x, thirdColumn.y,thirdColumn.z)
                if selectedItem == "table" {
                    self.centerPivot(for: node)
                }
                self.sceneView.scene.rootNode.addChildNode(node)
                
            } else {
                print("[VC] Error loading \(selectedItem).scn")
            }
            
            print("[VC] Model", model)
        }
    }
    
    @objc func swiped(sender: UISwipeGestureRecognizer) {
        // Get from the scene the tapped position
        let sceneView = sender.view as! ARSCNView
        let tapLocation = sender.location(in: sceneView)
        
        // Get results of a SceneKit hit testing
        let sceneResult: [SCNHitTestResult] = sceneView.hitTest(tapLocation,
                                                                options: [SCNHitTestOption.firstFoundOnly: true])

        guard let rayCast: SCNHitTestResult = sceneResult.first
        else {
            print("[VC] Scene raycast over", tapLocation, "did not get any result.")
            return
        }
        
        // Change a graphical model by other
        let oldNode = rayCast.node
        if (oldNode.name != nil) {

            let oldNodeName = oldNode.name!
            print("[VC] Scene raycast result is node", oldNodeName)
            
            // Check if the result's node is in the view
            if self.sceneView.scene.rootNode.childNodes.contains(oldNode) {
                
                // Search for the result's object
                var itemDic: NSMutableDictionary = [:]
                var itemFound = false
                for eachItemDic in model {
                    let eachItemName = eachItemDic["name"] as! String
                    if eachItemName == oldNodeName {
                        itemDic = eachItemDic
                        itemFound = true
                    }
                }
                if (itemFound) {
                    
                    // Update the model
                    var currentVersion = itemDic["current_version"] as! Int
                    let maxVersion = itemDic["max_version"] as! Int
                    if currentVersion < maxVersion {
                        currentVersion += 1
                    } else {
                        currentVersion = 1
                    }
                    itemDic["current_version"] = currentVersion
                    let selectedItem = itemDic["class"] as! String
                    let itemName = itemDic["name"] as! String
                    
                    // Search for its graphical syntax
                    var graphicalSyntaxClass = NSMutableDictionary()
                    for aGraphicalSyntaxClass in self.graphicalSyntax {
                        let className = aGraphicalSyntaxClass["name"] as! String
                        if className == selectedItem {
                            graphicalSyntaxClass = aGraphicalSyntaxClass
                        }
                    }
                    
                    // Get the version's sources and change its graphical syntax in scene
                    let classVersions = graphicalSyntaxClass["versions"] as! NSMutableDictionary
                    let firstSource = classVersions["v\(currentVersion)"] as! String;
                    let url = URL(string: firstSource)
                    if let scene = try? SCNScene(url: url! , options: nil) {
                        print("load \(oldNode.name!).scn successful")
                        
                        let oldPosition = oldNode.position
                        let oldScale = oldNode.scale
                        oldNode.removeFromParentNode()
                        
                        let newNode = (scene.rootNode.childNode(withName: selectedItem, recursively: false))!
                        newNode.name = itemName
                        newNode.position = oldPosition
                        newNode.scale = oldScale
                        if selectedItem == "table" {
                            self.centerPivot(for: newNode)
                        }
                        
                        self.sceneView.scene.rootNode.addChildNode(newNode)
                        
                    } else {
                        print("error loading \(oldNode.name!).scn")
                    }
                    
                } else {
                    print("[VC] Scene raycast result not found in model", oldNodeName)
                }
                
            } else {
                // If nil, the raycast did not get a model's object
                print("[VC] Scene raycast result is node named (null)")
            }
            
        }
        
    }
    
    @objc func pinch (sender: UIPinchGestureRecognizer) {
        // TODO: Change to raycast. Alberto J. 2020/06/29
        let sceneView = sender.view as! ARSCNView
        let pinchLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(pinchLocation)
        if !hitTest.isEmpty {
            let results = hitTest.first!
            let node = results.node
            let pinchAction = SCNAction.scale(by: sender.scale, duration: 0)
            node.runAction(pinchAction)
            sender.scale = 1.0
        }
    }
    @objc func rotate(sender : UILongPressGestureRecognizer) {
        // TODO: Change to raycast. Alberto J. 2020/06/29
        let sceneView = sender.view as! ARSCNView
        let holdLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(holdLocation)
        if !hitTest.isEmpty {
            let results = hitTest.first!
            if sender.state == .began {
                let rotation = SCNAction.rotateBy(x: 0, y: CGFloat(360.degreesToRadians), z: 0, duration: 1)
                let forever = SCNAction.repeatForever(rotation)
                results.node.runAction(forever)
                print("holding")
            } else if sender.state == .ended {
                print("release finger")
                results.node.removeAllActions()
            }
        }
        
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.itemsArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "item", for: indexPath) as! itemCell
        cell.itemLable.text = self.itemsArray[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        self.selectedItem = self.itemsArray[indexPath.row]
        cell?.backgroundColor = UIColor.green
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = UIColor.orange
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else {return}
        DispatchQueue.main.async {
            self.planeDetected.isHidden = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.planeDetected.isHidden = true
            }
        }
    }
    
    func centerPivot(for node: SCNNode) {
        let min = node.boundingBox.min
        let max = node.boundingBox.max
        node.pivot = SCNMatrix4MakeTranslation(
            min.x + (max.x - min.x)/2,
            min.y + (max.y - min.y)/2,
            min.z + (max.z - min.z)/2
        )
    }

}

extension Int {
    var degreesToRadians: Double {
        return Double(self) * .pi/180
    }
}
