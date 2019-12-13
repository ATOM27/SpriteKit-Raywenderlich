//
//  Firebug.swift
//  PestControl
//
//  Created by Eugene  Mekhedov on 7/24/19.
//  Copyright © 2019 Razeware LLC. All rights reserved.
//

import SpriteKit

class Firebug: Bug {

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override init() {
    super.init()
    name = "Firebug"
    color = .red
    colorBlendFactor = 0.8
    physicsBody?.categoryBitMask = PhysicsCategory.Firebug
  }
}
