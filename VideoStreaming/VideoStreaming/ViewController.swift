//
//  ViewController.swift
//  VideoStreaming
//
//  Created by MISO on 26/1/22.
//

import UIKit
import AVKit
import AVFoundation

class ViewController: UIViewController {

    @IBAction func playVideo(_ sender: AnyObject) {
        guard let url = URL(string: "https://post-its-server.herokuapp.com/getMaterial.mp4") else {
            return
        }
        let player = AVPlayer(url: url)
        
        let controller = AVPlayerViewController()
        controller.player = player
        
        present(controller, animated: true) {
            player.play()
        }
    }
}

