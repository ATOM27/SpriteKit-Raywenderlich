//
//  MainMenuScene.swift
//  ZombieConga
//
//  Created by Eugene  Mekhedov on 2/1/19.
//  Copyright © 2019 Eugene  Mekhedov. All rights reserved.
//

import Foundation
import SpriteKit

class MainMenuScene: SKScene{
    
    override func didMove(to view: SKView) {
        let background = SKSpriteNode.init(imageNamed: "MainMenu")
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(background)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        sceneTapped()
    }
    
    func sceneTapped(){
        let gameScene = GameScene(size: size)
        gameScene.scaleMode = scaleMode
        let transition = SKTransition.doorway(withDuration: 1.5)
        view?.presentScene(gameScene, transition: transition)
    }
}
