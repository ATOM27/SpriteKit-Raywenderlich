//
//  GameScene.swift
//  DropCharge
//
//  Created by Eugene  Mekhedov on 9/23/19.
//  Copyright © 2019 Eugene  Mekhedov. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion

enum GameStatus: Int{
    case waitingForTap
    case waitingForBomb
    case playing
    case gameOver
}

enum PlayerStatus: Int{
    case idle
    case jump
    case fall
    case lava
    case dead
}

struct PhysicsCategory{
    static let None: UInt32                 = 0
    static let Player: UInt32               = 0b1       // 1
    static let PlatformNormal: UInt32       = 0b10      // 2
    static let PlatformBreakable: UInt32    = 0b100     // 4
    static let CoinNormal: UInt32           = 0b1000    // 8
    static let CoinSpecial: UInt32          = 0b10000   // 16
    static let Edges: UInt32                = 0b100000  // 32
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var bgNode: SKNode!
    var fgNode: SKNode!
    var backgroundOverlayTemplate: SKNode!
    var backgroundOverlayHeight: CGFloat!
    var player: SKSpriteNode!
    
    let motionManager = CMMotionManager()
    var xAcceleration = CGFloat(0)
    
    var platform5Across: SKSpriteNode!
    var coinArrow: SKSpriteNode!
    var platformDiagonal: SKSpriteNode!
    var breakDiagonal: SKSpriteNode!
    var coinDiagonal: SKSpriteNode!
    var coinSDiagonal: SKSpriteNode!
    var coinCross: SKSpriteNode!
    var coinSCross: SKSpriteNode!
    var platformArrow: SKSpriteNode!
    var breakArrow: SKSpriteNode!
    var coinSArrow: SKSpriteNode!
    var coin5Across: SKSpriteNode!
    var coinS5Across: SKSpriteNode!
    var break5Across: SKSpriteNode!

    var lastOverlayPosition = CGPoint.zero
    var lastOverlayHeight: CGFloat = 0.0
    var levelPositionY: CGFloat = 0.0
    
    var gameState = GameStatus.waitingForTap
    var playerState = PlayerStatus.idle
    
    let cameraNode = SKCameraNode()
    
    var lava: SKSpriteNode!
    
     var lastUpdateTimeInterval: TimeInterval = 0
    var deltaTime: TimeInterval = 0
    
    var lives = 3
    
    override func didMove(to view: SKView) {
        setupNodes()
        setupLavel()
        let scale = SKAction.scale(to: 1.0, duration: 0.5)
        fgNode.childNode(withName: "Ready")!.run(scale)
        setupPlayer()
        setupCoreMotion()
        physicsWorld.contactDelegate = self
        camera?.position = CGPoint(x: size.width / 2, y: size.height / 2)
    }
    
    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTimeInterval > 0{
            deltaTime = currentTime - lastUpdateTimeInterval
        }else{
            deltaTime = 0
        }
        lastUpdateTimeInterval = currentTime
        
        if isPaused{
            return
        }
        
        if gameState == .playing{
            updateCamera()
            updateLevel()
            updatePlayer()
            updateLava(deltaTime)
            updateCollisionLava()
        }
        
        for child in fgNode.children{
            if convert(child.position, from: fgNode).y < self.cameraNode.position.y - self.view!.frame.height * 2{
                child.removeFromParent()
            }
        }
    }
    
    //MARK: - Help methods
    
    func setupNodes(){
        let worldNode = childNode(withName: "World")!
        bgNode = worldNode.childNode(withName: "Background")!
        backgroundOverlayTemplate = (bgNode.childNode(withName: "Overlay")!.copy() as! SKNode)
        backgroundOverlayHeight = backgroundOverlayTemplate.calculateAccumulatedFrame().height
        fgNode = worldNode.childNode(withName: "Foreground")!
        player = (fgNode.childNode(withName: "Player") as! SKSpriteNode)
        fgNode.childNode(withName: "Bomb")?.run(SKAction.hide())
        
        platform5Across = loadForegroundOverlayTemplate("Platform5Across")
        coinArrow = loadForegroundOverlayTemplate("CoinArrow")
        platformDiagonal = loadForegroundOverlayTemplate("PlatformDiagonal")
        breakDiagonal = loadForegroundOverlayTemplate("BreakDiagonal")
        coinDiagonal = loadForegroundOverlayTemplate("CoinDiagonal")
        coinSDiagonal = loadForegroundOverlayTemplate("CoinSDiagonal")
        coinCross = loadForegroundOverlayTemplate("CoinCross")
        coinSCross = loadForegroundOverlayTemplate("CoinSCross")
        platformArrow = loadForegroundOverlayTemplate("PlatformArrow")
        breakArrow = loadForegroundOverlayTemplate("BreakArrow")
        coinSArrow = loadForegroundOverlayTemplate("CoinSArrow")
        coin5Across = loadForegroundOverlayTemplate("Coin5Across")
        coinS5Across = loadForegroundOverlayTemplate("CoinS5Across")
        break5Across = loadForegroundOverlayTemplate("Break5Across")
        
        addChild(cameraNode)
        camera = cameraNode
        
        lava = (fgNode.childNode(withName: "Lava") as! SKSpriteNode)
    }
    
    func setupLavel(){
        //place initial platform
        let initialPlatform = platform5Across.copy() as! SKSpriteNode
        var overlayPosition = player.position
        overlayPosition.y = player.position.y - ((player.size.height * 0.5) +
        (initialPlatform.size.height * 0.20))
        initialPlatform.position = overlayPosition
        fgNode.addChild(initialPlatform)
        lastOverlayPosition = overlayPosition
        lastOverlayHeight = initialPlatform.size.height / 2.0
        levelPositionY = bgNode.childNode(withName: "Overlay")!.position.y + backgroundOverlayHeight
        while lastOverlayPosition.y < levelPositionY{
            addRandomForegroundOverlay()
        }
    }
    
    func setupPlayer(){
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width * 0.3)
        player.physicsBody?.isDynamic = false
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.categoryBitMask = PhysicsCategory.Player
        player.physicsBody?.collisionBitMask = 0
    }
    
    func setPlayerVelocity(_ amount: CGFloat){
        let gain: CGFloat = 2.5
        player.physicsBody!.velocity.dy = max(player.physicsBody!.velocity.dy, amount * gain)
    }
    
    func jumpPlayer(){
        setPlayerVelocity(650)
    }
    
    func boostPlayer(){
        setPlayerVelocity(1200)
    }
    
    func superBoostPlayer(){
        setPlayerVelocity(1700)
    }
    
    func setupCoreMotion(){
        motionManager.accelerometerUpdateInterval = 0.2
        let queue = OperationQueue()
        motionManager.startAccelerometerUpdates(to: queue) { (accelerometerData, error) in
            guard let accelerometerData = accelerometerData else{
                return
            }
            
            let acceleration = accelerometerData.acceleration
            self.xAcceleration = (CGFloat(acceleration.x) * 0.75) + (self.xAcceleration * 0.25)
        }
    }
    
    func sceneCropAmount() -> CGFloat{
        guard let view = self.view else{
            return 0
        }
        let scale = view.bounds.size.height / self.size.height
        let scaledWidth = self.size.width * scale
        let scaledOverlap = scaledWidth - view.bounds.size.width
        return scaledOverlap / scale
    }
    
    func updatePlayer(){
        player.physicsBody?.velocity.dx = xAcceleration * 2000.0
        // Wrap player around edges of screen
        var playerPosition = convert(player.position, from: fgNode)
        let leftLimit = (sceneCropAmount() / 2) - (player.size.width / 2)
        let rightLimit = size.width - sceneCropAmount() / 2 + player.size.width / 2
        if playerPosition.x < leftLimit{
            playerPosition = convert(CGPoint(x: rightLimit, y: 0.0), to: fgNode)
            player.position.x = playerPosition.x
        }else if playerPosition.x > rightLimit{
            playerPosition = convert(CGPoint(x: leftLimit, y: 0.0), to: fgNode)
            player.position.x = playerPosition.x
        }
        //Check player state
        if player.physicsBody!.velocity.dy < CGFloat(0) && playerState != .fall{
            playerState = .fall
            print("Falling")
        }else if player.physicsBody!.velocity.dy > CGFloat(0) && playerState != .jump{
            playerState = .jump
            print("Jumping")
        }
    }
    
    func updateCamera(){
        let cameraTarget = convert(player.position, from: fgNode)
        var targetPositionY = cameraTarget.y - (size.height * 0.10)
        
        let lavaPos = convert(lava.position, from: fgNode)
        targetPositionY = max(targetPositionY, lavaPos.y)
        
        let diff = targetPositionY - camera!.position.y
        
        let cameraLagFactor = CGFloat(0.2)
        let lagDiff = diff * cameraLagFactor
        let newCameraPostionY = camera!.position.y + lagDiff
        
        camera?.position.y = newCameraPostionY
    }
    
    func updateLava(_ dt: TimeInterval){
        let bottomOfScreenY = camera!.position.y - (size.height / 2)
        let bottomOfScreenYFg = convert(CGPoint(x: 0, y: bottomOfScreenY), to: fgNode).y
        
        let lavaVelocityY = CGFloat(120)
        let lavaStep = lavaVelocityY * CGFloat(dt)
        var newLavaPositionY = lava.position.y + lavaStep
        
        newLavaPositionY = max(newLavaPositionY, (bottomOfScreenYFg - 125.0))
        lava.position.y = newLavaPositionY
    }
    
    func updateCollisionLava(){
        if player.position.y < lava.position.y + 90{
            playerState = .lava
            print("Lava")
            boostPlayer()
            lives -= 1
            if lives <= 0{
                gameOver()
            }
        }
    }
    
    func updateLevel(){
        let cameraPos = camera!.position
        if cameraPos.y > levelPositionY - (size.height * 0.55){
            createBackgroundOverlay()
            while lastOverlayPosition.y < levelPositionY {
                addRandomForegroundOverlay()
            }
        }
    }
    
    func gameOver(){
        gameState = .gameOver
        playerState = .dead
        
        physicsWorld.contactDelegate = nil
        player.physicsBody?.isDynamic = false
        
        let moveUp = SKAction.moveBy(x: 0.0, y: size.height / 2.0, duration: 0.5)
        moveUp.timingMode = .easeOut
        let moveDown = SKAction.moveBy(x: 0.0, y: -(size.height * 1.5), duration: 1.0)
        moveDown.timingMode = .easeIn
        player.run(SKAction.sequence([moveUp, moveDown]))
        
        let gameOverSprite = SKSpriteNode(imageNamed: "GameOver")
        gameOverSprite.position = camera!.position
        gameOverSprite.zPosition = 10
        addChild(gameOverSprite)
    }
    
    //MARK: - Particles
    
    func explosion(intensity: CGFloat) -> SKEmitterNode{
        let emitter = SKEmitterNode()
        let particleTexture = SKTexture(imageNamed: "spark")
        emitter.zPosition = 2
        emitter.particleTexture = particleTexture
        emitter.particleBirthRate = 4000 * intensity
        emitter.numParticlesToEmit = Int(400 * intensity)
        emitter.particleLifetime = 2.0
        emitter.emissionAngle = CGFloat(90).degreesToRadians()
        emitter.emissionAngleRange = CGFloat(360).degreesToRadians()
        emitter.particleSpeed = 600 * intensity
        emitter.particleSpeedRange = 1000 * intensity
        emitter.particleAlpha = 1.0
        emitter.particleAlphaRange = 0.25
        emitter.particleScale = 1.2
        emitter.particleScaleRange = 2.0
        emitter.particleScaleSpeed = -1.5
        emitter.particleColorBlendFactor = 1
        emitter.particleBlendMode = SKBlendMode.add
        emitter.run(SKAction.removeFromParentAfterDelay(2.0))
        
        let sequence = SKKeyframeSequence(capacity: 5)
        sequence.addKeyframeValue(SKColor.white, time: 0)
        sequence.addKeyframeValue(SKColor.yellow, time: 0.10)
        sequence.addKeyframeValue(SKColor.orange, time: 0.15)
        sequence.addKeyframeValue(SKColor.red, time: 0.75)
        sequence.addKeyframeValue(SKColor.black, time: 0.95)
        emitter.particleColorSequence = sequence
        
        return emitter
    }
    //MARK: - Overlay nodes
    
    func loadForegroundOverlayTemplate(_ fileName: String) -> SKSpriteNode{
        let overlayScene = SKScene(fileNamed: fileName)!
        let overlayTemplate = overlayScene.childNode(withName: "Overlay")
        return overlayTemplate as! SKSpriteNode
    }
    
    func createForegroundOverlay(_ overlayTemplate: SKSpriteNode, flipX: Bool){
        let foregroundOverlay = overlayTemplate.copy() as! SKSpriteNode
        lastOverlayPosition.y = lastOverlayPosition.y + (lastOverlayHeight + (foregroundOverlay.size.height / 2))
        lastOverlayHeight = foregroundOverlay.size.height / 2
        foregroundOverlay.position = lastOverlayPosition
        if flipX == true{
            foregroundOverlay.xScale = -1
        }
        fgNode.addChild(foregroundOverlay)
    }
    
    func createBackgroundOverlay(){
        let backgroundOverlay = backgroundOverlayTemplate.copy() as! SKNode
        backgroundOverlay.position = CGPoint(x: 0.0, y: levelPositionY)
        bgNode.addChild(backgroundOverlay)
        levelPositionY += backgroundOverlayHeight
    }
    
    func addRandomForegroundOverlay(){
        let overlaySprite: SKSpriteNode!
        let platformPercentage = 60
        if Int.random(min: 1, max: 100) <= platformPercentage{
            let regularPlatformPercentage = 75
            if Int.random(min: 1, max: 100) <= regularPlatformPercentage{
                overlaySprite = [platform5Across, platformArrow, platformDiagonal].randomElement()!
            }else{
                overlaySprite = [breakDiagonal, break5Across, breakArrow].randomElement()
            }
        }else{
            let regularCoinsPercentage = 75
            if Int.random(min: 1, max: 100) <= regularCoinsPercentage{
                overlaySprite = [coin5Across, coinCross, coinDiagonal].randomElement()!
            }else{
                overlaySprite = [coinS5Across, coinSCross, coinSDiagonal].randomElement()!
            }
        }
        createForegroundOverlay(overlaySprite, flipX: false)
    }
    
    //MARK: - Events
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameState == .waitingForTap{
            bombDrop()
        }else if gameState == .gameOver{
            let newScene = GameScene(fileNamed: "GameScene")
            newScene!.scaleMode = .aspectFill
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            self.view?.presentScene(newScene!, transition: reveal)
        }
    }
    
    func bombDrop(){
        gameState = .waitingForBomb
        // Scale out title & ready label.
        let scale = SKAction.scale(to: 0, duration: 0.4)
        fgNode.childNode(withName: "Title")!.run(scale)
        fgNode.childNode(withName: "Ready")!.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.2),
            scale
        ]))
        
        //Bounce bomb
        let scaleUp = SKAction.scale(to: 1.25, duration: 0.25)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.25)
        let sequence = SKAction.sequence([ scaleUp, scaleDown])
        let repeatSeq = SKAction.repeatForever(sequence)
        fgNode.childNode(withName: "Bomb")!.run(SKAction.unhide())
        fgNode.childNode(withName: "Bomb")!.run(repeatSeq)
        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.run(startGame)
        ]))
    }
    
    func startGame(){
        let bomb = fgNode.childNode(withName: "Bomb")!
        let bombBlast = explosion(intensity: 2.0)
        bombBlast.position = bomb.position
        fgNode.addChild(bombBlast)
        bomb.removeFromParent()
        gameState = .playing
        player.physicsBody!.isDynamic = true
        superBoostPlayer()
    }
    
    //MARK: - SKPhysicsContactDelegate
    
    func didBegin(_ contact: SKPhysicsContact) {
        let other = contact.bodyA.categoryBitMask == PhysicsCategory.Player ? contact.bodyB : contact.bodyA
        
        switch other.categoryBitMask {
        case PhysicsCategory.CoinNormal:
            if let coin = other.node as? SKSpriteNode{
                coin.removeFromParent()
                jumpPlayer()
            }
        case PhysicsCategory.PlatformNormal:
            if let _ = other.node as? SKSpriteNode{
                if player.physicsBody!.velocity.dy < 0{
                    jumpPlayer()
                }
            }
        case PhysicsCategory.CoinSpecial:
            if let coinSpec = other.node as? SKSpriteNode{
                coinSpec.removeFromParent()
                boostPlayer()
            }
        case PhysicsCategory.PlatformBreakable:
            if let breakablePlatform = other.node as? SKSpriteNode{
                if player.physicsBody!.velocity.dy < 0{
                    jumpPlayer()
                    breakablePlatform.removeFromParent()
                }
            }
        default:
            break
        }
    }
}
