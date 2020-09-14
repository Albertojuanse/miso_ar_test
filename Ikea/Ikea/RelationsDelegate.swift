//
//  RelationsDelegate.swift
//  Ikea
//
//  Created by MISO on 14/09/2020.
//  Copyright © 2020 Miso. All rights reserved.
//

import UIKit

class RelationsDelegate: NSObject, UITableViewDelegate, UITableViewDataSource {
    
    var dataSource = [String]()
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = dataSource[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        
    }
}
