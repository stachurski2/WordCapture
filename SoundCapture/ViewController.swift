//
//  ViewController.swift
//  SoundCapture
//
//  Created by Stanisaw Sobczyk on 08/06/2020.
//  Copyright © 2020 Stanisaw Sobczyk. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
     @IBOutlet var speechTextView: NSTextView!
    
    var audioManager: AudioManaging = AudioManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    
    @IBAction
    func click(_ :Any) {
        if audioManager.isListening == false {
            audioManager.catchStream()
            audioManager.stringCompletion = { word in
                DispatchQueue.main.async {
                      self.speechTextView.string = word
                }
              
            }
        }
    }


}

