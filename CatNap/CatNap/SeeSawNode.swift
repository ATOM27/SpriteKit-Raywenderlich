//
//  SeeSawNode.swift
//  CatNap
//
//  Created by Eugene  Mekhedov on 5/21/19.
//  Copyright © 2019 Eugene  Mekhedov. All rights reserved.
//

import UIKit
import SpriteKit

class SeeSawNode: SKSpriteNode, EventListenerNode {
    func didMoveToScene() {
        guard let scene = scene else{ return }
        let seesawBase = scene.childNode(withName: "seesawBase")
        let pinJoint = SKPhysicsJointPin.joint(withBodyA: seesawBase!.physicsBody!, bodyB: physicsBody!, anchor: seesawBase!.position)
        scene.physicsWorld.add(pinJoint)
    }
}
