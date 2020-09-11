//
//  ViewController.swift
//  Ikea
//
//  Created by Miso on 02/06/2020.
//  Copyright © 2020 Miso. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, ARSCNViewDelegate, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    
    var itemsArray: [String] = []
    var metamodel: [NSMutableDictionary] = []
    var graphicalSyntax: [NSMutableDictionary] = []
    var model: [NSMutableDictionary] = [];
    var modelObjectEdited: NSMutableDictionary = [:]
    var objectsInitialPos: NSMutableDictionary = [:]
    var objectsBoundingBox: NSMutableDictionary = [:]
    var objectsList: NSMutableDictionary = [:]
    var objectsIdName: NSMutableDictionary = [:]
    var nodeToDelete: SCNNode? = nil
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
    
    //@IBOutlet weak var planeDetected: UILabel!
    @IBOutlet weak var itemsCollectionView: UICollectionView!
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var attributesView: UIScrollView!
    @IBOutlet weak var attributesButton: UIButton!
    @IBOutlet weak var trashButton: UIButton!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var contentView: UIView!
    
    
    let tableView = UITableView()
    
    let auxView = UIView()
    
    var addButton = UIButton()
    
    let configuration = ARWorldTrackingConfiguration()
    
    var selectedItem: String?
    
    var newItem: String?
    
    var currentTextField = UITextField()
    
    var finalText: String?
    
    var panZinit = CGFloat()
    
    var panLocation = SCNVector3()
    
    var dataSource = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ARKit scene view initialization
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        self.configuration.planeDetection = [.horizontal, .vertical]
        self.sceneView.session.run(configuration)
        self.sceneView.delegate = self
        self.sceneView.autoenablesDefaultLighting = true
        
        // Layout
        self.itemsCollectionView.dataSource = self
        self.itemsCollectionView.delegate = self
        self.attributesView.isHidden = true
        self.contentView.isHidden = true
        self.attributesButton.isHidden = true
        self.trashButton.isHidden = true
        
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
        
        // Pan gesture is used to move the object
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(move))
        panGestureRecognizer.require(toFail: swipeGestureRecognizer)
        self.sceneView.addGestureRecognizer(panGestureRecognizer)
    }
    
    // Gestures do 2 types of raycasting
    // - World raycasting, based on ARRaycastQuery supported by ARKit to find world surfaces, etc.
    // - Scene raycasting, based on SCNHitTest supported by SceneKit to find virtual nodes.
    
    @objc func tapped(sender: UITapGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let tapLocation = sender.location(in: sceneView)
        let editcontrol = UIAlertController(title: "Edit", message: "Write the new name", preferredStyle: .alert)
        //action of the modal. User writes the word, table and data update
        let editalertaction = UIAlertAction(title: "Done", style: .default) { (action) in
            guard let textfield = editcontrol.textFields?.first else { return }
            let text = textfield.text
            //use the content of textfield to update dataSource and tableView
            if (text != nil) {
                if(text?.count == 0){
                    self.configurePos(tapLocation: tapLocation, sceneView: sceneView)
                } else {
                    self.newItem = text
                    self.configurePos(tapLocation: tapLocation, sceneView: sceneView)
                }
            } else {
                self.configurePos(tapLocation: tapLocation, sceneView: sceneView)
            }
        }
        //open editable textfield
        editcontrol.addTextField()
        editcontrol.addAction(editalertaction)
        self.present(editcontrol, animated: true)
        
    }
    
    func configurePos(tapLocation: CGPoint, sceneView: ARSCNView) {
        // Get from the scene the tapped position
        
        
        var graphicalSyntaxClass = NSMutableDictionary()
        for aGraphicalSyntaxClass in self.graphicalSyntax {
            let className = aGraphicalSyntaxClass["name"] as! String
            if className == selectedItem {
                graphicalSyntaxClass = aGraphicalSyntaxClass
            }
        }
        let classConstraints = graphicalSyntaxClass["constraints"] as! NSMutableDictionary
        let plane = classConstraints["planes"] as! String
        
        // Configure the world raycast query and create it
        let estimatedPlane: ARRaycastQuery.Target = .estimatedPlane
        var alignment: ARRaycastQuery.TargetAlignment = .any
        if(plane == "horizontal"){
            alignment = .horizontal
        } else if plane == "vertical" {
            alignment = .vertical
        }
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
            let classReferences = metamodelClass["references"] as! NSMutableArray
            
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
            let itemMinAttributes = NSMutableDictionary()
            for aClassAttribute in classAttributes {
                let aClassAttributeDic = aClassAttribute as! NSMutableDictionary
                let aClassAttributeName = aClassAttributeDic["name"] as! NSString
                let aClassAttributeDefault = aClassAttributeDic["default"]
                let aClassAttributeMax = aClassAttributeDic["max"]
                let aClassAttributeMin = aClassAttributeDic["min"]
                let aClassAttributeType = aClassAttributeDic["type"]
                
                itemAttributes.setObject(aClassAttributeDefault!, forKey: aClassAttributeName)
                itemTypeAttributes.setObject(aClassAttributeType!, forKey: aClassAttributeName)
                itemMaxAttributes.setObject(aClassAttributeMax!, forKey: aClassAttributeName)
                itemMinAttributes.setObject(aClassAttributeMin!, forKey: aClassAttributeName)
            }
            itemDic["attributes"] = itemAttributes
            itemDic["typeAttributes"] = itemTypeAttributes
            itemDic["maxAttributes"] = itemMaxAttributes
            itemDic["minAttributes"] = itemMinAttributes
            
            let itemReferences = NSMutableDictionary()
            let itemTargetReferences = NSMutableDictionary()
            let itemMaxReferences = NSMutableDictionary()
            let itemMinReferences = NSMutableDictionary()
            for aClassReference in classReferences {
                let aClassReferenceDic = aClassReference as! NSMutableDictionary
                let aClassReferenceName = aClassReferenceDic["name"] as! NSString
                let aClassReferenceMax = aClassReferenceDic["max"]
                let aClassReferenceMin = aClassReferenceDic["min"]
                let aClassReferenceTarget = aClassReferenceDic["target"]
                
                itemReferences.setObject(aClassReferenceName, forKey: aClassReferenceName)
                itemTargetReferences.setObject(aClassReferenceTarget!, forKey: aClassReferenceName)
                itemMaxReferences.setObject(aClassReferenceMax!, forKey: aClassReferenceName)
                itemMinReferences.setObject(aClassReferenceMin!, forKey: aClassReferenceName)
            }
            itemDic["references"] = itemReferences
            itemDic["targetReferences"] = itemTargetReferences
            itemDic["maxReferences"] = itemMaxReferences
            itemDic["minReferences"] = itemMinReferences
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
                node.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: node, options: nil))
                let classConstraints = graphicalSyntaxClass["constraints"] as! NSMutableDictionary
                let overlapping = classConstraints["overlapping"] as! String
                if checkOverLapping(node: node) || overlapping == "true" {
                    self.sceneView.scene.rootNode.addChildNode(node)
                    
                    // Update the model with the node in its AR facet
                    arFacet["node"] = node
                    print(node.boundingBox)
                    let box :NSMutableDictionary = [:]
                    box.setValue(node.boundingBox.min, forKey: "min")
                    box.setValue(node.boundingBox.max, forKey: "max")
                    self.objectsBoundingBox.setValue(box, forKey: node.name!)
                    // Place the object version name over the object
                    
                    let text = SCNText(string: self.newItem, extrusionDepth: 0.1)
                    text.font = UIFont.systemFont(ofSize: 1)
                    text.flatness = 0.005
                    let textNode = SCNNode(geometry: text)
                    let fontScale: Float = 0.01
                    textNode.scale = SCNVector3(fontScale, fontScale, fontScale)
                    textNode.position = SCNVector3(0,0.05,0.05)
                    node.addChildNode(textNode)
                    
                    let posDict :NSMutableDictionary = [:]
                    posDict.setValue(node.position.x, forKey: "x")
                    posDict.setValue(node.position.y, forKey: "y")
                    posDict.setValue(node.position.z, forKey: "z")
                    self.objectsInitialPos.setValue(posDict, forKey: node.name!)
                    self.objectsList.setValue(self.selectedItem, forKey: self.newItem!)
                    self.objectsIdName.setValue(self.newItem, forKey: node.name!)
                } else {
                    model.popLast()
                    wrongAttrAlert(message: "The object is overlapping. Try another place")
                }
                
                
            } else {
                print("[VC] Error loading \(selectedItem).scn")
            }
            
            print("[VC] Model", model)
        }
    }
    
    func checkOverLapping(node: SCNNode) -> Bool{
        if(self.objectsInitialPos.count < 1) {return true}
        let keys = self.objectsInitialPos.allKeys
        for key in keys {
            let box = self.objectsBoundingBox.value(forKey: key as! String) as! NSMutableDictionary
            let min = box.value(forKey: "min") as! SCNVector3
            let max = box.value(forKey: "max") as! SCNVector3
            let originPos = self.objectsInitialPos.value(forKey: key as! String) as! NSMutableDictionary
            
            //get max and min from current node
            let xmax = node.boundingBox.max.x + node.position.x
            let xmin = node.boundingBox.min.x + node.position.x
            let ymax = node.boundingBox.max.y + node.position.y
            let ymin = node.boundingBox.min.y + node.position.y
            let zmax = node.boundingBox.max.z + node.position.z
            let zmin = node.boundingBox.min.z + node.position.z
            
            //get max and min from previous existing node
            let originxmax = max.x + (originPos.value(forKey: "x") as! Float)
            let originxmin = min.x + (originPos.value(forKey: "x") as! Float)
            let originymax = max.y + (originPos.value(forKey: "y") as! Float)
            let originymin = min.y + (originPos.value(forKey: "y") as! Float)
            let originzmax = max.z + (originPos.value(forKey: "z") as! Float)
            let originzmin = min.z + (originPos.value(forKey: "z") as! Float)
            
            //overlapping if x y and z (max or min) is between max and min of existing node
            if(((xmax < originxmax && xmax > originxmin) || (xmin < originxmax && xmin > originxmin)) && ((ymax < originymax && ymax > originymin) || (ymin < originymax && xmin > originymin)) && ((zmax < originzmax && zmax > originzmin) || (zmin < originzmax && zmin > originzmin))){
                
                return false
            }
        }
        return true;
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
                
                // LEA: "save" the node for potential deletion
                nodeToDelete = oldNode
                
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
                    let classAttributesShow = graphicalSyntaxClass["showAttributes"] as! NSMutableArray
                    
                    // Place the attributes over the object
                    var string = ""
                    let allKeys = itemAttributes.allKeys
                    for aKey in allKeys {
                        
                        //check if is in the list
                        if(classAttributesShow.contains(aKey)){
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
                    self.contentView.isHidden = false
                    self.attributesButton.isHidden = false
                    self.trashButton.isHidden = false
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
        let itemTypeAttributes = modelObjectEdited["typeAttributes"] as! NSMutableDictionary
        let itemMaxAttributes = modelObjectEdited["maxAttributes"] as! NSMutableDictionary
        let itemMinAttributes = modelObjectEdited["minAttributes"] as! NSMutableDictionary
        let allNames = itemAttributes.allKeys
        // Update the model
        let textFields = NSMutableArray()
        var i = 0;
        for eachSubview in self.attributesView.subviews {
            if eachSubview is UITextField {
                let name = allNames[i]
                let messagename = name as! String
                let type = itemTypeAttributes[name] as! String
                let aux = eachSubview as! UITextField
                let min = itemMinAttributes[name] as! String
                let max = itemMaxAttributes[name] as! String
                if(min != "0" && aux.text!.isEmpty){
                    wrongAttrAlert(message: "Attribute " + messagename + " must have at least " + min + ". Correct it")
                    return
                }
                if(max != "1"){
                    let itemList = aux.text?.split(separator: " ")
                    if(itemList!.count < Int(min)!){
                        wrongAttrAlert(message: "Attribute " + messagename + " must have at least " + min + ". Correct it")
                        return
                    } else if(max != "-1" && itemList!.count > Int(max)!){
                        wrongAttrAlert(message: "Attribute " + messagename + " must have less than " + max + ". Correct it")
                        return
                    } else if (type == "Int"){
                        for item in itemList! {
                            if(Int(item) == nil){
                                wrongAttrAlert(message: "Attribute " + messagename + " is integer. Correct it")
                                return
                            }
                        }
                    } else if (type == "Bool"){
                        for item in itemList! {
                            if(item != "true" || item != "false"){
                                wrongAttrAlert(message: "Attribute " + messagename + " must be 'true' or 'false'. Correct it")
                                return
                            }
                        }
                    }
                } else {
                    if(type == "Int"){
                        if(Int(aux.text!) == nil){
                            wrongAttrAlert(message: "Attribute " + messagename + " is integer. Correct it")
                            return
                        }
                    } else if (type == "Bool"){
                        if(aux.text != "true" || aux.text != "false"){
                            wrongAttrAlert(message: "Attribute " + messagename + " must be 'true' or 'false'. Correct it")
                            return
                        }
                    }

                }
                i+=1
                textFields.add(eachSubview)
            }
        }
        var index = 0;
        
        for eachElement in textFields {
            let eachTextField = eachElement as! UITextField
            itemAttributes[allNames[index]] = eachTextField.text
            index += 1;
        }
        modelObjectEdited["attributes"] = itemAttributes
        
        // Hide the edit interface
        self.attributesView.isHidden = true
        self.attributesButton.isHidden = true
        self.trashButton.isHidden = true
        
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
        let classAttributesShow = graphicalSyntaxClass["showAttributes"] as! NSMutableArray
        
        for aKey in allKeys {
            
            //check if is in the list
            if(classAttributesShow.contains(aKey)){
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
            
            
            //Get the graph syntax to get min and max measure that should be shown
            var graphicalSyntaxClass = NSMutableDictionary()
            for aGraphicalSyntaxClass in self.graphicalSyntax {
                let className = aGraphicalSyntaxClass["name"] as! String
                if className == selectedItem {
                    graphicalSyntaxClass = aGraphicalSyntaxClass
                }
            }
            let classConstraints = graphicalSyntaxClass["constraints"] as! NSMutableDictionary
            let max = classConstraints["sizeMax"] as! String
            let min = classConstraints["sizeMin"] as! String
            if(sender.scale > 1){
                sender.scale = 1.01
            } else if(sender.scale < 1){
                sender.scale = 0.99
            }
            
            let pinchAction = SCNAction.scale(by: sender.scale, duration: 0)
            
            if(node.scale.x < (max as NSString).floatValue){
                if(node.scale.x > (min as NSString).floatValue){
                    node.runAction(pinchAction)
                } else {
                    if(sender.scale > 1){
                        node.runAction(pinchAction)
                    }
                }
                
            } else {
                if(sender.scale < 1){
                    node.runAction(pinchAction)
                }
            }
            sender.scale = 1.0
        }
    }
    
    //https://medium.com/@literalpie/dragging-objects-in-scenekit-and-arkit-3568212a90e5
    @objc func move(sender : UIPanGestureRecognizer){
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
        let oldNode = rayCast.node
        if (oldNode.name != nil) {
            let oldNodeName = oldNode.name!
            print("[VC] Scene raycast result is node", oldNodeName)
            print(oldNode.worldPosition)
            // Check if the result's node is in the view
            if self.sceneView.scene.rootNode.childNodes.contains(oldNode){
                var itemDic: NSMutableDictionary = [:]
                var itemFound = false
                for eachItemDic in model {
                    let eachArFacet = eachItemDic["ar_facet"] as! NSMutableDictionary
                    if let eachNode = eachArFacet["node"] as? SCNNode {
                        if eachNode == oldNode {
                            itemDic = eachItemDic
                            itemFound = true
                        }
                    }
                }
                if itemFound {
                    //panGesture has 2 states: began(start of pan) and changed(change position)
                    switch sender.state {
                    case .began:
                        //init z position
                        panZinit = CGFloat(sceneView.projectPoint(oldNode.worldPosition).z)
                        //pan init location
                        panLocation = rayCast.worldCoordinates
                    case .changed:
                        var originPos : NSMutableDictionary = [:]
                        originPos = self.objectsInitialPos.value(forKey: oldNodeName) as! NSMutableDictionary
                        let xinit = originPos.value(forKey: "x") as! CGFloat
                        let yinit = originPos.value(forKey: "y") as! CGFloat
                        let zinit = originPos.value(forKey: "z") as! CGFloat
                        //Get the graph syntax to get x and y max distance to original position
                        var graphicalSyntaxClass = NSMutableDictionary()
                        for aGraphicalSyntaxClass in self.graphicalSyntax {
                            let className = aGraphicalSyntaxClass["name"] as! String
                            if className == selectedItem {
                                graphicalSyntaxClass = aGraphicalSyntaxClass
                            }
                        }
                        let classConstraints = graphicalSyntaxClass["constraints"] as! NSMutableDictionary
                        let xmax = classConstraints["xToOriginPos"] as! String
                        let format = NumberFormatter()
                        format.decimalSeparator = "."
                        let xformat = format.number(from: xmax)
                        let ymax = classConstraints["yToOriginPos"] as! String
                        let yformat = format.number(from: ymax)
                        let zmax = classConstraints["zToOriginPos"] as! String
                        let zformat = format.number(from: zmax)
                        let touchPos = sceneView.unprojectPoint(SCNVector3(tapLocation.x, tapLocation.y, panZinit))
                        let move = SCNVector3(touchPos.x - panLocation.x, touchPos.y - panLocation.y, touchPos.z - panLocation.z)
                        
                        //don't move if x and/or y are over limits
                        if((xinit - CGFloat(oldNode.worldPosition.x + move.x)) < CGFloat(truncating: xformat!) && (yinit - CGFloat(oldNode.worldPosition.y + move.y)) < CGFloat(truncating: yformat!) && (zinit - CGFloat(oldNode.worldPosition.z + move.z)) < CGFloat(truncating: zformat!) && (xinit - CGFloat(oldNode.worldPosition.x + move.x)) > -CGFloat(truncating: xformat!) && (yinit - CGFloat(oldNode.worldPosition.y + move.y)) > -CGFloat(truncating: yformat!) && (zinit - CGFloat(oldNode.worldPosition.z + move.z)) > -CGFloat(truncating: zformat!)){
                            oldNode.localTranslate(by: move)
                            panLocation = touchPos
                        }
                    default:
                        break
                    }
                }
            }
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
        /*DispatchQueue.main.async {
            self.planeDetected.isHidden = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.planeDetected.isHidden = true
            }
        }*/
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
        
        // Remove previous subviews
        for eachView in self.attributesView.subviews {
            if eachView is UIButton || eachView is UIStackView ||  eachView == contentView {
                
            } else {
                eachView.removeFromSuperview();
            }
        }
        
        for eachView in self.contentView.subviews {
            if eachView is UIButton || eachView is UIStackView {
                
            } else {
                eachView.removeFromSuperview();
            }
        }
        
        for eachView in self.stackView.subviews {
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
            self.stackView.addArrangedSubview(attributesTitleLabel)
            
            
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
                self.stackView.addArrangedSubview(attributesNameLabel)
                
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
                self.stackView.addArrangedSubview(attributesTextField)
            }
            
        }
    }
    //MARK: - One-to-many Attributes
    //It opens the tableview to manages attributes one-to-many
    @objc func addTable(_ textField: UITextField){
        let itemString = textField.text
        let itemList = itemString?.split(separator: " ")
        
        
        auxView.frame = self.view.frame
        if(!auxView.isDescendant(of: self.view)){
            self.view.addSubview(auxView)
        }
        auxView.isHidden = false;
        auxView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        let tap = UITapGestureRecognizer(target: self, action: #selector(returnTable))
        auxView.addGestureRecognizer(tap);
        
        tableView.frame = CGRect(x: textField.frame.origin.x, y: 200, width: textField.frame.width, height: 200)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        dataSource = []
        for item in itemList! {
            dataSource.append(String(item))
        }
        if(!tableView.isDescendant(of: self.view)){
            self.view.addSubview(tableView)
        }
        currentTextField = textField
        tableView.isHidden = false;
        addButton = UIButton(frame: CGRect(x: textField.frame.origin.x, y: 150, width: 150, height: 50))
        addButton.setTitle("Add", for: .normal)
        addButton.backgroundColor = .black
        addButton.addTarget(self, action: #selector(addRow), for: .touchUpInside)
        if(!addButton.isDescendant(of: auxView)){
            auxView.addSubview(addButton)
        }
        addButton.isHidden = false;
    }
    
    //exit tableview ans updates textview
    @objc func returnTable(){
        finalText = ""
        var i = 0
        for item in dataSource {
            i+=1
            finalText! += item
            if(i<dataSource.count){
                finalText! += " "
            }
        }
        currentTextField.text = finalText
        addButton.isHidden = true;
        auxView.isHidden = true;
        tableView.isHidden = true
    }
    
    //adds row when pressing add button. new by default
    @objc func addRow(){
        dataSource.append("new")
        tableView.reloadData()
    }
    
    //number of rows in the iterable section. It must be equal to datasource. If not, exception
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    //fills the table with datasource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = dataSource[indexPath.row]
        return cell
    }
    
    //when swipe to left, appears 2 buttons, delete and edit
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        //remove data associate with the row of the table and remove the table
        let actiondelete = UIContextualAction(style: .destructive, title: "Delete") { (_, _, _) in
            //IMPORTANT remove data from datasource. Error if not
            self.dataSource.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        
        //update data and table row with an alertAction
        let actionedit = UIContextualAction(style: .normal, title: "Edit") { (_, _, _) in
            //build modal
            let editcontrol = UIAlertController(title: "Edit", message: "Write the new name", preferredStyle: .alert)
            //action of the modal. User writes the word, table and data update
            let editalertaction = UIAlertAction(title: "Done", style: .default) { (action) in
                guard let textfield = editcontrol.textFields?.first else { return }
                let text = textfield.text
                //use the content of textfield to update dataSource and tableView
                if (text != nil) {
                    if(text?.count == 0){
                        return
                    } else {
                        self.dataSource[indexPath.row] = text ?? "null"
                        tableView.reloadRows(at: [indexPath], with: .automatic)
                    }
                } else {
                    return
                }
            }
            //open editable textfield
            editcontrol.addTextField()
            editcontrol.addAction(editalertaction)
            self.present(editcontrol, animated: true)
        }
        return UISwipeActionsConfiguration(actions: [actiondelete, actionedit])
    }
    
    func wrongAttrAlert(message: String){
        let alertcontrol = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let alertaction = UIAlertAction(title: "OK", style: .default)
        alertcontrol.addAction(alertaction)
        self.present(alertcontrol, animated: true)
    }
    //MARK: - Adjust textfield to types
    //target of Bool textField, true -> false or false -> true. Default false if another
    @objc func changeText(_ textField: UITextField){
        if(textField.text == "false"){
            textField.text = "true"
        }
        else{
            textField.text = "false"
        }
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
    
    // MARK: - PERSISTENCE
    // https://www.appcoda.com/arkit-persistence/
    
    // Gives the document directory path for writing and reading the world map data
    var worldMapURL: URL = {
        do {
            return try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("worldMapURL")
        } catch {
            fatalError("Error getting world map URL from document directory.")
        }
    }()
    
    // archiver method to save the ARWorldMap object
    func archive(worldMap: ARWorldMap) throws {
        let data = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
        try data.write(to: self.worldMapURL, options: [.atomic])
    }
    
    
    @IBAction func resetBarButtonItemDidTouch(_ sender: UIBarButtonItem) {
        resetTrackingConfiguration()
    }
    
    @IBAction func saveBarButtonItemDidTouch(_ sender: UIBarButtonItem) {
        sceneView.session.getCurrentWorldMap { (worldMap, error) in
            guard let worldMap = worldMap else {
                print("Error getting current world map.")
                return
            }
            
            do {
                try self.archive(worldMap: worldMap)
                DispatchQueue.main.async {
                    print("World map is saved.")
                }
            } catch {
                fatalError("Error saving world map: \(error.localizedDescription)")
            }
        }
    }
    @IBAction func loadBarButtonItemDidTouch(_ sender: UIBarButtonItem) {
        guard let worldMapData = retrieveWorldMapData(from: worldMapURL),
            let worldMap = unarchive(worldMapData: worldMapData) else { return }
        resetTrackingConfiguration(with: worldMap)
    }
    
    func resetTrackingConfiguration(with worldMap: ARWorldMap? = nil) {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        
        let options: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
        if let worldMap = worldMap {
            configuration.initialWorldMap = worldMap
            print("Found saved world map.")
        } else {
            print("Move camera around to map your surrounding space.")
        }
        
        sceneView.debugOptions = [.showFeaturePoints]
        sceneView.session.run(configuration, options: options)
    }
    
    func retrieveWorldMapData(from url: URL) -> Data? {
        do {
            return try Data(contentsOf: self.worldMapURL)
        } catch {
            print("Error retrieving world map data.")
            return nil
        }
    }
    
    func unarchive(worldMapData data: Data) -> ARWorldMap? {
        
        let unarchievedObject = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data)
        
        let worldMap = unarchievedObject
        
        return worldMap
    }
    
    // MARK: - DELETE NODE
    @IBAction func handleDeletion(_ sender: Any) {
        NSLog("delete tapped")
        
        // Hide the edit interface
        self.attributesView.isHidden = true
        self.attributesButton.isHidden = true
        self.trashButton.isHidden = true
        
        nodeToDelete?.removeFromParentNode()
        self.objectsInitialPos.removeObject(forKey: nodeToDelete?.name)
        self.objectsBoundingBox.removeObject(forKey: nodeToDelete?.name)
    }
    
    
    
}

extension Int {
    var degreesToRadians: Double {
        return Double(self) * .pi/180
    }
}
