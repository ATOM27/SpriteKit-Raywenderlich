//
//  GameViewController.swift
//  ZombieConga
//
//  Created by Eugene  Mekhedov on 12/26/18.
//  Copyright © 2018 Eugene  Mekhedov. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let scene = MainMenuScene(size:CGSize(width: 2018, height: 1536))
        let skView = self.view as! SKView
        
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.ignoresSiblingOrder = true
        scene.scaleMode = .aspectFill
        skView.presentScene(scene)
        
        skView.ignoresSiblingOrder = true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
