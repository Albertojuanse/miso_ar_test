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
    var graphicalSyntaxSources: NSMutableDictionary = [:]
    
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
                            
                            let aClass = anElement as! NSMutableDictionary
                            
                            let name = aClass["name"] as! String
                            self.itemsArray.append(name)
                            
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
                        
                        self.graphicalSyntaxSources = jsonResult["classes"] as! NSMutableDictionary
                        
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
            viewController.graphicalSyntaxSources = self.graphicalSyntaxSources
            viewController.itemsArray = self.itemsArray
        }
    }
}
