//
//  BedNode.swift
//  CatNap
//
//  Created by Eugene Mekhedov on 3/20/19.
//  Copyright © 2019 Eugene  Mekhedov. All rights reserved.
//

import SpriteKit

class BedNode: SKSpriteNode, EventListenerNode{
    func didMoveToScene() {
        let bodySize = CGSize(width: 40.0, height: 30.0)
        physicsBody = SKPhysicsBody(rectangleOf: bodySize)
        physicsBody?.isDynamic = false
        physicsBody!.categoryBitMask = PhysicsCategory.Bed
        physicsBody!.collisionBitMask = PhysicsCategory.None
    }
}
