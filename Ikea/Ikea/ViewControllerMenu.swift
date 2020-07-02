//
//  ViewControllerMenu.swift
//  Ikea
//
//  Created by MISO on 25/06/2020.
//  Copyright © 2020 Miso. All rights reserved.
//

import UIKit
import ARKit

class ViewControllerMenu: UIViewController  {
    
    var itemsArray: [String] = []
    var metamodel: [NSMutableDictionary] = []
    var graphicalSyntax: [NSMutableDictionary] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadMetamodels()
    }
    
    func loadMetamodels() {
        
        // Load the metamodel
        let url = URL(string: "https://github.com/Albertojuanse/miso_ar_test/blob/master/Ikea/External/ontological_metamodel.json?raw=true")
        if (url != nil) {
            print("[VCM] URL object exists: ", url!)
        }
        let session = URLSession.shared
        let task = session.dataTask(with: url!) { (data, response, error) -> Void in
            if error != nil {
                print(error!)
            } else {
                if let data = data {
                    do {

                        print("[VCM] Task running")
                        
                        let jsonResult = try JSONSerialization.jsonObject(
                            with: data,
                            options: JSONSerialization.ReadingOptions.mutableContainers
                        ) as! NSMutableDictionary
                        
                        let classes = jsonResult["classes"] as! NSMutableArray
                        for anElement in classes {
                            
                            // Get from the JSON each class
                            let aClass = anElement as! NSMutableDictionary
                            
                            // Save the name in itemsArray
                            let className = aClass["name"] as! String
                            self.itemsArray.append(className)
                            
                            // Define a class for the metamodel and save it
                            let classAttributes = aClass["attributes"] as! NSMutableArray
                            let metamodelClass = NSMutableDictionary()
                            metamodelClass["name"] = className
                            let attributes = NSMutableArray()
                            for anAttribute in classAttributes {
                                let eachAttribute = anAttribute as! NSMutableDictionary
                                attributes.add(eachAttribute)
                            }
                            metamodelClass["attributes"] = attributes
                            self.metamodel.append(metamodelClass)
                            
                        }
                        
                    } catch let e{
                        print(e)
                    }
                }
            }
        }
        print("[VCM] Task resume")
        task.resume()
        
        // Load the graphic syntax
        let graphic_url = URL(string: "https://github.com/Albertojuanse/miso_ar_test/blob/master/Ikea/External/graphic_model.json?raw=true")
        if (graphic_url != nil) {
            print("[VCM] graphic_URL object exists: ", graphic_url!)
        }
        let graphic_session = URLSession.shared
        let graphic_task = graphic_session.dataTask(with: graphic_url!) { (data, response, error) -> Void in
            if error != nil {
                print(error!)
            } else {
                if let data = data {
                    do {

                        print("[VCM] graphic_Task running")
                        
                        let jsonResult = try JSONSerialization.jsonObject(
                            with: data,
                            options: JSONSerialization.ReadingOptions.mutableContainers
                        ) as! NSMutableDictionary
                        
                        let classes = jsonResult["classes"] as! NSMutableArray
                        for anElement in classes {
                            
                            // Get from the JSON each class
                            let aClass = anElement as! NSMutableDictionary
                            
                            // Sav the name in itemsArray
                            let className = aClass["name"] as! String
                            self.itemsArray.append(className)
                            
                            // Define a class for the metamodel and save it
                            let classVersions = aClass["versions"] as! NSMutableDictionary
                            let classConstraints = aClass["constraints"] as! NSMutableDictionary
                            
                            let graphicalSyntaxClass = NSMutableDictionary()
                            graphicalSyntaxClass["name"] = className
                            graphicalSyntaxClass["versions"] = classVersions
                            graphicalSyntaxClass["constraints"] = classConstraints
                            self.metamodel.append(graphicalSyntaxClass)
                            
                        }
                        
                    } catch let e{
                        print(e)
                    }
                }
            }
        }
        print("[VCM] graphic_Task resume")
        graphic_task.resume()
        
    }
    
    @IBAction func handleLoadButton(_ sender: Any) {
        self.performSegue(withIdentifier: "fromLoadToARView", sender: sender)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "fromLoadToARView") {
            let viewController: ViewController = segue.destination as! ViewController
            viewController.graphicalSyntax = self.graphicalSyntax
            viewController.itemsArray = self.itemsArray
            viewController.metamodel = self.metamodel
        }
    }
}