//
//  ViewController.swift
//  Ikea
//
//  Created by Miso on 02/06/2020.
//  Copyright © 2020 Miso. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, ARSCNViewDelegate, UITextFieldDelegate {
    
    var itemsArray: [String] = []
    var metamodel: [NSMutableDictionary] = []
    var graphicalSyntax: [NSMutableDictionary] = []
    var model: [NSMutableDictionary] = [];
    var modelObjectEdited: NSMutableDictionary = [:]
    // -- MODEL SCHEME --
    // [
    //  { "name" = uuid1 : UUID,
    //    "class" = class1 : String,
    //    "ar_facet" = ar_facet1 : NSMutableDictionary,
    //    "current_version" = version1 : Int,
    //    "max_version" = 3,
    //    "attributes" = {
    //        "attribute1": attribute1 : Type1,
    //        "attribute2": attribute2 : Type2,
    //        (···)
    //     }
    //     "reference": []
    //   },
    //  { "name" = uuid2 : UUID
    //    (···)
    //   },
    //  (···)
    // ]
    // -- AR_FACET SCHEME --
    //
    // { "node" = node1 : SCNNode,
    //   "attributes_node" = attributes_node1 : SCNNode
    //  }
    
    @IBOutlet weak var planeDetected: UILabel!
    @IBOutlet weak var itemsCollectionView: UICollectionView!
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var attributesView: UIView!
    @IBOutlet weak var attributesButton: UIButton!
    
    let tableView = UITableView()
    
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
        self.attributesView.isHidden = true
        self.attributesButton.isHidden = true
        
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
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(showAttributes))
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
            
            // Search for the metamodel class
            var metamodelClass = NSMutableDictionary()
            for aMetamodelClass in self.metamodel {
                let aClassName = aMetamodelClass["name"] as! String
                if aClassName == selectedItem {
                    metamodelClass = aMetamodelClass
                }
            }
            let classAttributes = metamodelClass["attributes"] as! NSMutableArray
            
            // Create a new object in model
            let itemDic = NSMutableDictionary()
            let itemName = UUID().uuidString
            itemDic["name"] = itemName
            itemDic["class"] = selectedItem
            itemDic["current_version"] = 1
            itemDic["max_version"] = 3
            let itemAttributes = NSMutableDictionary()
            let itemTypeAttributes = NSMutableDictionary()
            let itemMaxAttributes = NSMutableDictionary()
            for aClassAttribute in classAttributes {
                let aClassAttributeDic = aClassAttribute as! NSMutableDictionary
                let aClassAttributeName = aClassAttributeDic["name"] as! NSString
                let aClassAttributeDefault = aClassAttributeDic["default"]
                let aClassAttributeMax = aClassAttributeDic["max"]
                let aClassAttributeType = aClassAttributeDic["type"]
                
                itemAttributes.setObject(aClassAttributeDefault!, forKey: aClassAttributeName)
                itemTypeAttributes.setObject(aClassAttributeType!, forKey: aClassAttributeName)
                itemMaxAttributes.setObject(aClassAttributeMax!, forKey: aClassAttributeName)
            }
            itemDic["attributes"] = itemAttributes
            itemDic["typeAttributes"] = itemTypeAttributes
            itemDic["maxAttributes"] = itemMaxAttributes
            // Create an AR facet to store its representations and nodes in AR environment
            let arFacet = NSMutableDictionary()
            itemDic["ar_facet"] = arFacet
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
            let classVersionsNames = graphicalSyntaxClass["vname"] as! NSMutableDictionary
            let sourceName = classVersionsNames["v\(currentVersion)"] as! String;
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
                
                // Update the model with the node in its AR facet
                arFacet["node"] = node
                
                // Place the object version name over the object
                
                let text = SCNText(string: sourceName, extrusionDepth: 0.1)
                text.font = UIFont.systemFont(ofSize: 1)
                text.flatness = 0.005
                let textNode = SCNNode(geometry: text)
                let fontScale: Float = 0.01
                textNode.scale = SCNVector3(fontScale, fontScale, fontScale)
                textNode.position = SCNVector3(0,0.05,0.05)
                node.addChildNode(textNode)
                
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
                    
                    let eachArFacet = eachItemDic["ar_facet"] as! NSMutableDictionary
                    let eachNode = eachArFacet["node"] as! SCNNode
                    if eachNode == oldNode {
                        itemDic = eachItemDic
                        itemFound = true
                    }
                    
                    /* Also items can be matched with its name
                    let eachItemName = eachItemDic["name"] as! String
                    if eachItemName == oldNodeName {
                        itemDic = eachItemDic
                        itemFound = true
                    }
                    */
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
                    let classVersionsNames = graphicalSyntaxClass["vname"] as! NSMutableDictionary
                    let firstSource = classVersions["v\(currentVersion)"] as! String;
                    let sourceName = classVersionsNames["v\(currentVersion)"] as! String;
                    let url = URL(string: firstSource)
                    if let scene = try? SCNScene(url: url! , options: nil) {
                        print("[VC] load \(oldNode.name!).scn successful")
                        
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
                        
                        // Update the facet
                        let arFacet = itemDic["ar_facet"] as! NSMutableDictionary
                        arFacet["node"] = newNode
                        
                        // Place the object version name over the object
                        
                        let text = SCNText(string: sourceName, extrusionDepth: 0.1)
                        text.font = UIFont.systemFont(ofSize: 1)
                        text.flatness = 0.005
                        let textNode = SCNNode(geometry: text)
                        let fontScale: Float = 0.01
                        textNode.scale = SCNVector3(fontScale, fontScale, fontScale)
                        textNode.position = SCNVector3(0,0.05,0.05)
                        newNode.addChildNode(textNode)
                        
                    } else {
                        print("[VC] error loading \(oldNode.name!).scn")
                    }
                    
                } else {
                    print("[VC] Scene raycast result not found in model", oldNodeName)
                }
                
                print("[VC] Model", model)
                
            } else {
                // If nil, the raycast did not get a model's object
                print("[VC] Scene raycast result is node named (null)")
            }
            
        }
        
    }
    
    @objc func showAttributes(sender: UISwipeGestureRecognizer) {
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
        
        // Compose and show the attributes
        let oldNode = rayCast.node
        if (oldNode.name != nil) {

            let oldNodeName = oldNode.name!
            print("[VC] Scene raycast result is node", oldNodeName)
            
            // Check if the result's node is in the view
            if self.sceneView.scene.rootNode.childNodes.contains(oldNode) {
                
                // Search for the result's object in the model, as an object or as an attributes
                var itemDic: NSMutableDictionary = [:]
                var itemFound = false
                //var arfacetDic: NSMutableDictionary = [:] ->(see next /* */ block)<-
                //var facetFound = false
                for eachItemDic in model {
                    
                    let eachArFacet = eachItemDic["ar_facet"] as! NSMutableDictionary
                    if let eachNode = eachArFacet["node"] as? SCNNode {
                        if eachNode == oldNode {
                            itemDic = eachItemDic
                            itemFound = true
                        }
                    }
                    
                    /* This is not working; it's for selecting the attributes text node
                    if let eachAttributesNode = eachArFacet["attributes_node"] as? SCNNode {
                        print("[VC] Verifiying attribute node.")
                        if eachAttributesNode == oldNode {
                            arfacetDic = eachItemDic
                            facetFound = true
                        }
                    }
                    */
                    
                    /* Also items can be matched with its name
                    let eachItemName = eachItemDic["name"] as! String
                    if eachItemName == oldNodeName {
                        itemDic = eachItemDic
                        itemFound = true
                    }
                    */
                }
                if (itemFound) {
                    print("[VC] Object node found.")
                    
                    // Get the attributes from the model
                    let itemAttributes = itemDic["attributes"] as! NSMutableDictionary
                    let itemTypeAttributes = itemDic["typeAttributes"] as! NSMutableDictionary
                    let itemMaxAttributes = itemDic["maxAttributes"] as! NSMutableDictionary
                    
                    //Get the graph syntax to get attributes that should be shown
                    var graphicalSyntaxClass = NSMutableDictionary()
                    for aGraphicalSyntaxClass in self.graphicalSyntax {
                        let className = aGraphicalSyntaxClass["name"] as! String
                        if className == selectedItem {
                            graphicalSyntaxClass = aGraphicalSyntaxClass
                        }
                    }
                    let classAttributesShow = graphicalSyntaxClass["showAttributes"] as! NSMutableDictionary
                    
                    // Place the attributes over the object
                    var string = ""
                    let allKeys = itemAttributes.allKeys
                    for aKey in allKeys {
                        //check if show is true
                        let numbool = classAttributesShow[aKey] as! NSNumber
                        if(numbool.boolValue){
                           string = string+"\(aKey): \(itemAttributes[aKey] ?? "")\n"
                        }
                    }
                    let text = SCNText(string: string, extrusionDepth: 0.1)
                    text.font = UIFont.systemFont(ofSize: 1)
                    text.flatness = 0.005
                    let textNode = SCNNode(geometry: text)
                    let fontScale: Float = 0.01
                    textNode.scale = SCNVector3(fontScale, fontScale, fontScale)
                    textNode.position = SCNVector3(0,0,0.05)
                    oldNode.addChildNode(textNode)
                    
                    // Update the facet
                    
                    
                    let arFacet = itemDic["ar_facet"] as! NSMutableDictionary
                    if let oldTextNode = arFacet["attributes_node"] {
                        (oldTextNode as! SCNNode).removeFromParentNode()
                    }
                    arFacet["attributes_node"] = textNode
                    itemDic["ar_facet"] = arFacet
                    
                    print("[VC] Shown attributes: ", string)
                    
                    // Show the edit interface; this was meant to be in the next else if statement                    
                    // Show the view to edit the attributes
                    modelObjectEdited = itemDic
                    self.attributesView.isHidden = false
                    self.attributesButton.isHidden = false
                    self.show(attributes: itemAttributes, typeAttributes: itemTypeAttributes, maxAttributes: itemMaxAttributes)
                
                } /*else if (facetFound) {
                    print("[VC] Attributes node found in facet.")
                    
                    
                    
                }*/ else {
                    print("[VC] Scene raycast result not found in model", oldNodeName)
                }
                
                print("[VC] Model", model)
                
            } else {
                // If nil, the raycast did not get a model's object
                print("[VC] Scene raycast result is node named (null)")
            }
            
        }
        
    }
    
    @IBAction func handleAttributesButton(_ sender: Any) {
        
        // Get the attributes from the model
        let itemAttributes = modelObjectEdited["attributes"] as! NSMutableDictionary
        
        // Update the model
        let textFields = NSMutableArray()
        for eachSubview in self.attributesView.subviews {
            if eachSubview is UITextField {
                textFields.add(eachSubview)
            }
        }
        var index = 0;
        let allNames = itemAttributes.allKeys
        for eachElement in textFields {
            let eachTextField = eachElement as! UITextField
            itemAttributes[allNames[index]] = eachTextField.text
            index += 1;
        }
        modelObjectEdited["attributes"] = itemAttributes
        
        // Hide the edit interface
        self.attributesView.isHidden = true
        self.attributesButton.isHidden = true
        
        // Update the graphycal syntax
        // Place the attributes over the object
        var string = ""
        let allKeys = itemAttributes.allKeys
        
        //Get the graph syntax to get attributes that should be shown
        var graphicalSyntaxClass = NSMutableDictionary()
        for aGraphicalSyntaxClass in self.graphicalSyntax {
            let className = aGraphicalSyntaxClass["name"] as! String
            if className == selectedItem {
                graphicalSyntaxClass = aGraphicalSyntaxClass
            }
        }
        let classAttributesShow = graphicalSyntaxClass["showAttributes"] as! NSMutableDictionary
        
        for aKey in allKeys {
            
            //check if show is true
            let numbool = classAttributesShow[aKey] as! NSNumber
            if(numbool.boolValue){
               string = string+"\(aKey): \(itemAttributes[aKey] ?? "")\n"
            }
        }
        let text = SCNText(string: string, extrusionDepth: 0.1)
        text.font = UIFont.systemFont(ofSize: 1)
        text.flatness = 0.005
        let textNode = SCNNode(geometry: text)
        let fontScale: Float = 0.01
        textNode.scale = SCNVector3(fontScale, fontScale, fontScale)
        textNode.position = SCNVector3(0,0,0.05)
        
        // Update the facet
        let arFacet = modelObjectEdited["ar_facet"] as! NSMutableDictionary
        if let oldTextNode = arFacet["attributes_node"] {
            (oldTextNode as! SCNNode).removeFromParentNode()
        }
        if let oldNode = arFacet["node"] {
            (oldNode as! SCNNode).addChildNode(textNode)
        }
        arFacet["attributes_node"] = textNode
        modelObjectEdited["ar_facet"] = arFacet
        
        print("[VC] Shown attributes: ", string)
        print("[VC] Model", model)
        
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
    
    func show(attributes: NSMutableDictionary, typeAttributes: NSMutableDictionary, maxAttributes: NSMutableDictionary)
    {
        // Show attributes information
        
        var lastAddedElement: UIView
        // Remove previous subviews
        for eachView in self.attributesView.subviews {
            if eachView is UIButton {
                
            } else {
                eachView.removeFromSuperview();
            }
        }
        
        // Show attribute title label
        if (attributes.count > 0) {
            let attributesTitleLabel = UILabel();
            attributesTitleLabel.translatesAutoresizingMaskIntoConstraints = false
            attributesTitleLabel.font = UIFont.systemFont(ofSize: 17.0)
            attributesTitleLabel.text = "Attributes:";
            // Add the label
            self.attributesView.addSubview(attributesTitleLabel);
            // Leading constraint
            let attributesTitleLabelLeading = NSLayoutConstraint(item: attributesTitleLabel,
                                                                 attribute: NSLayoutConstraint.Attribute.leading,
                                                                 relatedBy: NSLayoutConstraint.Relation.equal,
                                                                 toItem: self.attributesView,
                                                                 attribute: NSLayoutConstraint.Attribute.leading,
                                                                 multiplier: 1.0,
                                                                 constant: 16.0)
            // Trailing constraint
            let attributesTitleLabelTrailing = NSLayoutConstraint(item: attributesTitleLabel,
                                                                  attribute: NSLayoutConstraint.Attribute.trailing,
                                                                  relatedBy: NSLayoutConstraint.Relation.equal,
                                                                  toItem: self.attributesView,
                                                                  attribute: NSLayoutConstraint.Attribute.trailing,
                                                                  multiplier: 1.0,
                                                                  constant: 0.0)
            // Top constraint
            let attributesTitleLabelTop = NSLayoutConstraint(item: attributesTitleLabel,
                                                             attribute: NSLayoutConstraint.Attribute.top,
                                                             relatedBy: NSLayoutConstraint.Relation.equal,
                                                             toItem: self.attributesView,
                                                             attribute: NSLayoutConstraint.Attribute.top,
                                                             multiplier: 1.0,
                                                             constant: 0.0)
            // Height constraint
            let attributesTitleLabelHeight = NSLayoutConstraint(item: attributesTitleLabel,
                                                                attribute: NSLayoutConstraint.Attribute.height,
                                                                relatedBy: NSLayoutConstraint.Relation.equal,
                                                                toItem: nil,
                                                                attribute: NSLayoutConstraint.Attribute.notAnAttribute,
                                                                multiplier: 1.0,
                                                                constant: 21.0)
            // Add constraints to the Parent
            self.attributesView.addConstraint(attributesTitleLabelTrailing);
            self.attributesView.addConstraint(attributesTitleLabelLeading);
            self.attributesView.addConstraint(attributesTitleLabelTop);
            // Add height constraint to the subview, as subview owns it.
            attributesTitleLabel.addConstraint(attributesTitleLabelHeight);

            // Set this label as the last element added
            lastAddedElement = attributesTitleLabel as UIView;
            
            
            // For each attribute compose a layout with label and textField
            let allNames = attributes.allKeys
            for eachName in allNames {
                
                let eachAttribute = attributes[eachName] as! String
                let eachTypeAttribute = typeAttributes[eachName] as! String
                let eachMaxAttribute = maxAttributes[eachName] as! String
                
                // Set attribute's name label
                let attributesNameLabel = UILabel();
                attributesNameLabel.translatesAutoresizingMaskIntoConstraints = false
                attributesNameLabel.font = UIFont.systemFont(ofSize: 17.0)
                attributesNameLabel.text = eachName as? String;
                // Add the label
                self.attributesView.addSubview(attributesNameLabel);
                // Leading constraint
                let attributesNameLabelLeading = NSLayoutConstraint(item: attributesNameLabel,
                                                                    attribute: NSLayoutConstraint.Attribute.leading,
                                                                    relatedBy: NSLayoutConstraint.Relation.equal,
                                                                    toItem: self.attributesView,
                                                                    attribute: NSLayoutConstraint.Attribute.leading,
                                                                    multiplier: 1.0,
                                                                    constant: 24.0)
                // Trailing constraint
                let attributesNameLabelTrailing = NSLayoutConstraint(item: self.attributesView!,
                                                                     attribute: NSLayoutConstraint.Attribute.trailing,
                                                                     relatedBy: NSLayoutConstraint.Relation.equal,
                                                                     toItem: attributesNameLabel,
                                                                     attribute: NSLayoutConstraint.Attribute.trailing,
                                                                     multiplier: 1.0,
                                                                     constant: 24.0)
                // Top constraint
                let attributesNameLabelTop = NSLayoutConstraint(item: attributesNameLabel,
                                                                attribute: NSLayoutConstraint.Attribute.top,
                                                                relatedBy: NSLayoutConstraint.Relation.equal,
                                                                toItem: lastAddedElement,
                                                                attribute: NSLayoutConstraint.Attribute.bottom,
                                                                multiplier: 1.0,
                                                                constant: 16.0)
                // Height constraint
                let attributesNameLabelHeight = NSLayoutConstraint(item: attributesNameLabel,
                                                                   attribute: NSLayoutConstraint.Attribute.height,
                                                                   relatedBy: NSLayoutConstraint.Relation.equal,
                                                                   toItem: nil,
                                                                   attribute: NSLayoutConstraint.Attribute.notAnAttribute,
                                                                   multiplier: 1.0,
                                                                   constant: 21.0)
                // Add constraints to the Parent
                self.attributesView.addConstraint(attributesNameLabelLeading);
                self.attributesView.addConstraint(attributesNameLabelTrailing);
                self.attributesView.addConstraint(attributesNameLabelTop);
                // Add height constraint to the subview, as subview owns it.
                attributesNameLabel.addConstraint(attributesNameLabelHeight);

                // Set this label as the last element added
                lastAddedElement = attributesNameLabel as UIView;
                
                // Set attribute's textField
                
                let attributesTextField = UITextField();
                if(eachMaxAttribute != "1"){
                    print("is not unique " + eachAttribute);
                    attributesTextField.keyboardType = UIKeyboardType.emailAddress;
                    attributesTextField.addTarget(self, action: #selector(addTable(_:)), for: .touchDown)
                } else {
                    print("is unique " + eachAttribute);
                }
                if(eachTypeAttribute == "Int"){
                    //change keyboard type for integers
                    attributesTextField.keyboardType = UIKeyboardType.numberPad;
                } else if (eachTypeAttribute == "Bool") {
                    attributesTextField.keyboardType = UIKeyboardType.emailAddress;
                    attributesTextField.addTarget(self, action: #selector(changeText(_:)), for: .touchDown)
                }
                attributesTextField.delegate = self
                attributesTextField.translatesAutoresizingMaskIntoConstraints = false;
                attributesTextField.borderStyle = UITextField.BorderStyle.roundedRect;
                attributesTextField.text = eachAttribute;
                // Add the label
                self.attributesView.addSubview(attributesTextField);
                self.addConstraints(item: attributesTextField, lastAddedElement: lastAddedElement)
                lastAddedElement = attributesTextField as UIView;
                
            }
        }
    }
    @objc func addTable(_ textField: UITextField){
        let itemString = textField.text
        let itemList = itemString?.split(separator: ",")
        print(itemList!)
    }
    
    //target of Bool textField, true -> false or false -> true. Default false if another
    @objc func changeText(_ textField: UITextField){
        if(textField.text == "false"){
            textField.text = "true"
        }
        else{
            textField.text = "false"
        }
    }
    func addConstraints(item: Any, lastAddedElement: UIView){
        let attributesTextFieldLeading = NSLayoutConstraint(item: item,
                                                            attribute: NSLayoutConstraint.Attribute.leading,
                                                            relatedBy: NSLayoutConstraint.Relation.equal,
                                                            toItem: self.attributesView,
                                                            attribute: NSLayoutConstraint.Attribute.leading,
                                                            multiplier: 1.0,
                                                            constant: 24.0)
        // Trailing constraint
        let attributesTextFieldTrailing = NSLayoutConstraint(item: self.attributesView!,
                                                             attribute: NSLayoutConstraint.Attribute.trailing,
                                                             relatedBy: NSLayoutConstraint.Relation.equal,
                                                             toItem: item,
                                                             attribute: NSLayoutConstraint.Attribute.trailing,
                                                             multiplier: 1.0,
                                                             constant: 24.0)
        // Top constraint
        let attributesTextFieldTop = NSLayoutConstraint(item: item,
                                                        attribute: NSLayoutConstraint.Attribute.top,
                                                        relatedBy: NSLayoutConstraint.Relation.equal,
                                                        toItem: lastAddedElement,
                                                        attribute: NSLayoutConstraint.Attribute.bottom,
                                                        multiplier: 1.0,
                                                        constant: 8.0)
        //Add constraints to the Parent
        self.attributesView.addConstraint(attributesTextFieldTrailing);
        self.attributesView.addConstraint(attributesTextFieldLeading);
        self.attributesView.addConstraint(attributesTextFieldTop);
    }
    //when press return, hid the keyboard
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    //disable keyboard when bool type
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if(textField.keyboardType == UIKeyboardType.emailAddress){
            self.view.endEditing(true)
            return false
        }
        return true
    }
    //disable results that not fit with especific type
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool{
        
        //if nothing changes
        if (string.count == 0){
            return true
        }
        let currentText = textField.text ?? ""
        let text = (currentText as NSString).replacingCharacters(in: range, with: string)
        
        //check if is only integer or boolean, specified in keyboard type
        //numberPad -> Int
        //emailaddress -> Bool (due to func textFieldShouldBeginEditing, this won't be triggered, but there is a conditional just in case of bug)
        if (textField.keyboardType == UIKeyboardType.numberPad){
            //set of rest of characters that doesn't belong to number
            let setNoNumbers = NSCharacterSet(charactersIn: "0123456789").inverted
            //if any of the text is not a number, return false. If its full numbers, return true
            return text.rangeOfCharacter(from: setNoNumbers) == nil
        } else if (textField.keyboardType == UIKeyboardType.emailAddress){
            return text == "true" || text == "false"
        }
        return true
    }
}

extension Int {
    var degreesToRadians: Double {
        return Double(self) * .pi/180
    }
}
