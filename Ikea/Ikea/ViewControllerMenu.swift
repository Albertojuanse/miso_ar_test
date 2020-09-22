//
//  ViewControllerMenu.swift
//  Ikea
//
//  Created by MISO on 25/06/2020.
//  Copyright © 2020 Miso. All rights reserved.
//

import UIKit
import ARKit

class ViewControllerMenu: UIViewController, UITableViewDelegate, UITableViewDataSource  {
    //https://www.ioscreator.com/tutorials/prototype-cells-table-view-ios-tutorial
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.modelsArray.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "headCell", for: indexPath)
            
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "modelCell", for: indexPath)
        cell.textLabel?.text = self.modelsArray[indexPath.row - 1]
        
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(indexPath.row != 0) {
            let model = self.modelsArray[indexPath.row - 1]
            self.loadMetamodels(model: model)
        }
    }
    
    var itemsArray: [String] = []
    var metamodel: [NSMutableDictionary] = []
    var graphicalSyntax: [NSMutableDictionary] = []
    var cellToMetamodel: NSMutableDictionary = [:]
    var cellToGraph: NSMutableDictionary = [:]
    var timer: Timer?
    var fireTimer: Bool = false
    var updateTimer: Timer?
    var second = 0
    var modelsArray: [String] = []
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var load: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        load.setTitle("Choose a model", for: .normal)
        self.loadTypeModels()
        self.tableView.dataSource = self
        self.tableView.delegate = self
    }
    
    @objc func timeWaiting(){
        if(self.fireTimer) {
            second+=1
            if(second >= 2 && self.fireTimer == true){
                self.fireTimer = false
                second = 0
                load.setTitle("Load", for: .normal)
            }
        }
    }
    func loadTypeModels() {
        let url = URL(string: "https://github.com/Albertojuanse/miso_ar_test/blob/master/Ikea/External/model.json?raw=true")
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
                        let files = jsonResult["files"] as! NSMutableArray
                        for anElement in files {
                            // Get from the JSON each class
                            let aFile = anElement as! NSMutableDictionary
                            
                            // Save the name in itemsArray
                            let key = aFile["name"] as! String
                            
                            let metamodelString = aFile["ontological"] as! String
                            let graphicModelString = aFile["graphic"] as! String
                            
                            self.modelsArray.append(key)
                            self.cellToGraph.setValue(graphicModelString, forKey: key)
                            self.cellToMetamodel.setValue(metamodelString, forKey: key)
                        }
                    } catch let e{
                        print(e)
                    }
                }
            }
        }
        task.resume()
        updateTimer = Timer.scheduledTimer(timeInterval:1, target:self, selector:#selector(update), userInfo: nil, repeats: true)
    }
    @objc func update(){
        self.tableView.reloadData()
    }
    func loadMetamodels(model: String) {
        
        
        // Load the metamodel
        let url = URL(string: self.cellToMetamodel.value(forKey: model) as! String)
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
                        
                        self.itemsArray.removeAll()
                        self.metamodel.removeAll()
                        self.graphicalSyntax.removeAll()
                        
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
                            let classReferences = aClass["references"] as! NSMutableArray
                            let references = NSMutableArray()
                            for anReference in classReferences {
                                let eachReference = anReference as! NSMutableDictionary
                                references.add(eachReference)
                            }
                            metamodelClass["references"] = references
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
        let graphic_url = URL(string: self.cellToGraph.value(forKey: model) as! String)
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
                            
                            // Define a class for the metamodel and save it
                            let className = aClass["name"] as! String
                            let classVersions = aClass["versions"] as! NSMutableDictionary
                            let classVersionsName = aClass["vname"] as! NSMutableDictionary
                            let classShowAttributes = aClass["showAttributes"] as! NSMutableArray
                            let classConstraints = aClass["constraints"] as! NSMutableDictionary
                            
                            let graphicalSyntaxClass = NSMutableDictionary()
                            graphicalSyntaxClass["name"] = className
                            graphicalSyntaxClass["versions"] = classVersions
                            graphicalSyntaxClass["vname"] = classVersionsName
                            graphicalSyntaxClass["showAttributes"] = classShowAttributes
                            graphicalSyntaxClass["constraints"] = classConstraints
                            self.graphicalSyntax.append(graphicalSyntaxClass)
                            
                        }
                        
                    } catch let e{
                        print(e)
                    }
                }
            }
        }
        print("[VCM] graphic_Task resume")
        graphic_task.resume()
        load.setTitle("Wait", for: .normal)
        self.fireTimer = true
        timer = Timer.scheduledTimer(timeInterval:1, target:self, selector:#selector(timeWaiting), userInfo: nil, repeats: true)
    }
    
    @IBAction func handleLoadButton(_ sender: Any) {
        if(load.titleLabel?.text == "Load"){
            self.performSegue(withIdentifier: "fromLoadToARView", sender: sender)
        }
        
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
