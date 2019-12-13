//
//  Bug.swift
//  PestControl
//
//  Created by Eugene  Mekhedov on 7/23/19.
//  Copyright © 2019 Razeware LLC. All rights reserved.
//

import SpriteKit

enum BugSettings{
  static let bugDistance: CGFloat = 16
}

class Bug: SKSpriteNode {
  
  var animations: [SKAction] = []
  
  override func encode(with aCoder: NSCoder) {
    aCoder.encode(animations, forKey: "Bug.animations")
    super.encode(with: aCoder)
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    animations = aDecoder.decodeObject(forKey: "Bug.animations") as! [SKAction]
  }

  init() {
    let texture = SKTexture(imageNamed: "bug_ft1")
    super.init(texture: texture, color: .white, size: texture.size())
    physicsBody = SKPhysicsBody(circleOfRadius: size.width / 2)
    physicsBody?.allowsRotation = false
    physicsBody?.restitution = 0.5
    
    createAnimations(character: "bug")
    
    physicsBody?.categoryBitMask = PhysicsCategory.Bug
  }
  
  @objc func moveBug(){
    let randomX = CGFloat(Int.random(min: -1, max: 1))
    let randomY = CGFloat(Int.random(min: -1, max: 1))
    
    let vector = CGVector(dx: randomX * BugSettings.bugDistance,
                          dy: randomY * BugSettings.bugDistance)
    
    let moveBy = SKAction.move(by: vector, duration: 1)
    let moveAgain = SKAction.perform(#selector(moveBug), onTarget: self)
    
    let direction = animationDirection(for: vector)
    
    if direction == .left{
      xScale = abs(xScale)
    }else if direction == .right{
      xScale = -abs(xScale)
    }
    
    run(animations[direction.rawValue], withKey: "animation")
    run(SKAction.sequence([moveBy, moveAgain]))
  }
  
  func die(){
    removeAllActions()
    texture = SKTexture(imageNamed: "bug_lt1")
    yScale = -1
    physicsBody = nil
    run(SKAction.sequence([
      SKAction.fadeOut(withDuration: 3),
      SKAction.removeFromParent()
      ]))
  }
  
}

extension Bug: Animatable {}
