//
//  GameScene.swift
//  CatNap
//
//  Created by Eugene  Mekhedov on 3/5/19.
//  Copyright © 2019 Eugene  Mekhedov. All rights reserved.
//

import SpriteKit
import GameplayKit

protocol EventListenerNode {
    func didMoveToScene()
}

protocol InteractiveNode{
    func interact()
}

struct PhysicsCategory{
    static let None:    UInt32 = 0
    static let Cat:     UInt32 = 0b1     //1
    static let Block:   UInt32 = 0b10    //2
    static let Bed:     UInt32 = 0b100   //4
    static let Edge:    UInt32 = 0b1000  //8
    static let Label:   UInt32 = 0b10000 //16
    static let Spring:  UInt32 = 0b100000 //32
    static let Hook:    UInt32 = 0b1000000 // 64
}

class GameScene: SKScene {
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    
    var catNode: CatNode!
    var bedNode: BedNode!
    
    var playable = true
    
    var currentLevel: Int = 0
    var hookBaseNode: HookBaseNode?
    
    class func level(levelNum: Int) -> GameScene?{
        let scene = GameScene(fileNamed: "Level\(levelNum)")!
        scene.currentLevel = levelNum
        scene.scaleMode = .aspectFill
        return scene
    }
    
    override func didMove(to view: SKView) {
        self.isPaused = true
        self.isPaused = false
        
        let maxAspectRatio: CGFloat = 16.0 / 9.0
        let maxAspectRatioHeight = size.width / maxAspectRatio
        let playableMargin: CGFloat = (size.height - maxAspectRatioHeight) / 2
        
        let playableRect = CGRect(x: 0, y: playableMargin, width: size.width, height: size.height - playableMargin * 2)
        physicsBody = SKPhysicsBody(edgeLoopFrom: playableRect)
        physicsWorld.contactDelegate = self
        physicsBody?.categoryBitMask = PhysicsCategory.Edge
        
        enumerateChildNodes(withName: "//*") { (node, _) in
            if let eventListenerNode = node as? EventListenerNode{
                eventListenerNode.didMoveToScene()
            }
        }
        
        bedNode = (childNode(withName: "bed") as! BedNode)
        catNode = (childNode(withName: "//cat_body") as! CatNode)
        hookBaseNode = (childNode(withName: "hookBase") as? HookBaseNode)
        SKTAudio.sharedInstance().playBackgroundMusic("backgroundMusic.mp3")        
    }
    
    override func didSimulatePhysics() {
        if playable && hookBaseNode?.isHooked != true{
            if abs(catNode.parent!.zRotation) > CGFloat(25).degreesToRadians(){
                lose()
            }
        }
    }
    
    func inGameMessage(text: String){
        let message = MessageNode(message: text)
        message.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(message)
    }
    
    @objc func newGame(){
        view!.presentScene(GameScene.level(levelNum: currentLevel))
    }
    
    func lose(){
//        if currentLevel > 1 {
//            currentLevel -= 1
//        }
        playable = false
        SKTAudio.sharedInstance().pauseBackgroundMusic()
        SKTAudio.sharedInstance().playSoundEffect("lose.mp3")
        
        inGameMessage(text: "Try again...")
        perform(#selector(newGame), with: nil, afterDelay: 5)
        catNode.wakeUp()
    }
    
    func win(){
        if currentLevel < 6 {
            currentLevel += 1
        }
        playable = false
        
        SKTAudio.sharedInstance().pauseBackgroundMusic()
        SKTAudio.sharedInstance().playSoundEffect("win.mp3")
        
        inGameMessage(text: "Nice job!")
        
        perform(#selector(GameScene.newGame), with: nil, afterDelay: 3)
        
        catNode.curlAt(scenePoint: bedNode.position)
    }
}

extension GameScene: SKPhysicsContactDelegate{
    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask == PhysicsCategory.Label | PhysicsCategory.Edge{
            let labelNode = contact.bodyA.categoryBitMask == PhysicsCategory.Label ? contact.bodyA.node : contact.bodyB.node
            (labelNode as! MessageNode).didBounce()
        }
        if !playable {
            return
        }
        
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        if collision == PhysicsCategory.Cat | PhysicsCategory.Bed{
            print("SUCCESS")
            win()
        }else if collision == PhysicsCategory.Cat | PhysicsCategory.Edge{
            print("FAIL")
            lose()
        }else if collision == PhysicsCategory.Cat | PhysicsCategory.Hook && hookBaseNode?.isHooked == false{
            hookBaseNode?.hookCat(catPhysicsBody: catNode.parent!.physicsBody!)
        }
    }
}
