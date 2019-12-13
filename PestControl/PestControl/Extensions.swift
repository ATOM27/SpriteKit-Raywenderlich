//
//  Extensions.swift
//  PestControl
//
//  Created by Eugene  Mekhedov on 7/23/19.
//  Copyright © 2019 Razeware LLC. All rights reserved.
//

import SpriteKit

extension SKTexture {
  convenience init(pixelImageNamed: String) {
    self.init(imageNamed: pixelImageNamed)
    self.filteringMode = .nearest
  }
}
