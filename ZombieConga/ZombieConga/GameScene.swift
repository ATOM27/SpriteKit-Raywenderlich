//
//  GameScene.swift
//  ZombieConga
//
//  Created by Eugene  Mekhedov on 12/26/18.
//  Copyright © 2018 Eugene  Mekhedov. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    let zombie = SKSpriteNode(imageNamed: "zombie1")
    
    var lastUpdateTime: TimeInterval = 0
    var dt: TimeInterval = 0
    let zombieMovePointsPerSec: CGFloat = 480.0
    var velocity = CGPoint.zero
    
    let playableRect: CGRect
    
    var lastTouchLocation: CGPoint?
    
    let zombieRotateRadiansPerSec:CGFloat = 4.0 * π
    
    let zombieAnimation: SKAction
    
    let catCollisionSound: SKAction = SKAction.playSoundFileNamed("hitCat.wav", waitForCompletion: false)
    let enemyCollisionSound: SKAction = SKAction.playSoundFileNamed("hitCatLady.wav", waitForCompletion: false)
    
    let catMovePointPerSecond: CGFloat = 480.0
    
    var invincible = false
    
    var lives = 5{
        didSet{
            livesLabel.text = "Lives: \(lives)"
        }
    }
    
    var catsCount = 0{
        didSet{
            catsLabel.text = "Cats: \(catsCount)"
        }
    }
    
    var gameOver = false
    
    let cameraNode = SKCameraNode()
    let cameraMovePointsPerSec: CGFloat = 200.0
    var cameraRect: CGRect{
        let x = cameraNode.position.x - size.width / 2 + (size.width - playableRect.width)/2
        let y = cameraNode.position.y - size.height / 2 + (size.height - playableRect.height) / 2
        return CGRect(x: x, y: y, width: playableRect.width, height: playableRect.height)
    }
    
    let livesLabel = SKLabelNode(fontNamed: "Glimstick")
    let catsLabel = SKLabelNode(fontNamed: "Glimstick")
    
    override init(size: CGSize) {
        let maxAspectRatio: CGFloat = 16.0/9.0
        let playableHeight = size.width / maxAspectRatio
        let playableMargin = (size.height - playableHeight) / 2
        playableRect = CGRect(x: 0, y: playableMargin, width: size.width, height: playableHeight)
        var textures: [SKTexture] = []
        for i in 1...4{
            textures.append(SKTexture(imageNamed: "zombie\(i)"))
        }
        textures.append(textures[2])
        textures.append(textures[1])

        zombieAnimation = SKAction.animate(with: textures, timePerFrame: 0.1)
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        
        playBackgroundMusic(filename: "backgroundMusic.mp3")
        
        backgroundColor = SKColor.black
//        let background = SKSpriteNode(imageNamed: "background1")
//        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
//        background.zPosition = -1
//        let mySize = background.size
//        print("Size: \(mySize)")
//        addChild(background)
        
        for i in 0...1 {
            let background = backgroundNode()
            background.anchorPoint = CGPoint.zero
            background.position = CGPoint(x: CGFloat(i) * background.size.width, y: 0)
            background.name = "background"
            addChild(background)
        }
        
        zombie.position = CGPoint(x: 400, y: 400)
        zombie.zPosition = 100

        addChild(zombie)
        //zombie.run(SKAction.repeatForever(zombieAnimation))
        
        run(SKAction.repeatForever(SKAction.sequence([SKAction.run { [weak self] in
            self?.spawnEnemy()
            },
                                                      SKAction.wait(forDuration: 1.2)])))
        
        run(SKAction.repeatForever(SKAction.sequence([SKAction.run {[weak self] in
            self?.spawnCat()
            },
                                                      SKAction.wait(forDuration: 1.0)])))
        
        //debugDrawPlayableArea()
        addChild(cameraNode)
        camera = cameraNode
        cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        
        //lives label
        livesLabel.text = "Lives: \(lives)"
        livesLabel.fontColor = SKColor.black
        livesLabel.fontSize = 100
        livesLabel.zPosition = 150
        livesLabel.position = CGPoint(x: -playableRect.size.width / 2 + CGFloat(20),
                                      y: -playableRect.size.height / 2 + CGFloat(20))
        livesLabel.horizontalAlignmentMode = .left
        livesLabel.verticalAlignmentMode = .bottom
        cameraNode.addChild(livesLabel)
        
        //cats label
        catsLabel.text = "Cats: \(catsCount)"
        catsLabel.fontColor = SKColor.black
        catsLabel.fontSize = 100
        catsLabel.zPosition = 150
        catsLabel.position = CGPoint(x: playableRect.size.width / 2 + CGFloat(0),
                                     y: -playableRect.size.height / 2 + CGFloat(20))
        catsLabel.horizontalAlignmentMode = .right
        catsLabel.verticalAlignmentMode = .bottom
        cameraNode.addChild(catsLabel)
        
    }
    
    override func update(_ currentTime: TimeInterval) {

//        if lastTouchLocation != nil{
//            let offset = lastTouchLocation! - zombie.position
//            if offset.length() <= (CGFloat(dt) * zombieMovePointsPerSec){
//                velocity = CGPoint.zero
//                stopZombieAnimation()
//            }
//        }
        
        move(sprite: zombie, velocity: velocity)
        rotate(sprite: zombie, direction: velocity, rotateRadiansPerSec: zombieRotateRadiansPerSec)
        
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0 }
        lastUpdateTime = currentTime
        //print("\(dt*1000) milliseconds since last update")
        
        boundsCheckZombie()
        //checkCollisions()
        moveTrain()
        moveCamera()
        
        if lives <= 0 && !gameOver{
            gameOver = true
            print("You lose!")
            backgroundMusicPlayer.stop()
            let gameOverScene = GameOverScene(size: size, won: false)
            gameOverScene.scaleMode = scaleMode
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            view?.presentScene(gameOverScene, transition: reveal)
        }
        
        //cameraNode.position = zombie.position
    }
    
    override func didEvaluateActions() {
        checkCollisions()
    }
    
    func move(sprite: SKSpriteNode, velocity: CGPoint){
        let amountToMove = velocity * CGFloat(dt)
        //print("Amount to move: \(amountToMove)")
        sprite.position += amountToMove
    }
    
    func moveZombieToward(location: CGPoint){
        let offset = location - zombie.position
        let direction = offset.normalized()
        velocity = direction * zombieMovePointsPerSec
        startZombieAnimation()
        //print("Velocity: \(velocity)")
    }
    
    func backgroundNode() -> SKSpriteNode{
        let backgroundNode = SKSpriteNode()
        backgroundNode.anchorPoint = CGPoint.zero
        backgroundNode.name = "background"
        
        let background1 = SKSpriteNode(imageNamed: "background1")
        background1.anchorPoint = CGPoint.zero
        background1.position = CGPoint(x: 0, y: 0)
        backgroundNode.addChild(background1)
        
        let background2 = SKSpriteNode(imageNamed: "background2")
        background2.anchorPoint = CGPoint.zero
        background2.position = CGPoint(x: background1.size.width, y: 0)
        backgroundNode.addChild(background2)
        
        backgroundNode.size = CGSize(width: background1.size.width + background2.size.width,
                                     height: background1.size.height)
        backgroundNode.zPosition = -1
        return backgroundNode
    }
    
    func boundsCheckZombie(){
        let bottomLeft = CGPoint(x: cameraRect.minX, y: cameraRect.minY)
        let topRight = CGPoint(x: cameraRect.maxX, y: cameraRect.maxY)
        
        if zombie.position.x <= bottomLeft.x{
            zombie.position.x = bottomLeft.x
            velocity.x = abs(velocity.x)
        }
        
        if zombie.position.x >= topRight.x{
            zombie.position.x = topRight.x
            velocity.x = -velocity.x
        }
        
        if zombie.position.y <= bottomLeft.y{
            zombie.position.y = bottomLeft.y
            velocity.y = -velocity.y
        }
        
        if zombie.position.y >= topRight.y{
            zombie.position.y = topRight.y
            velocity.y = -velocity.y
        }
    }
    
    func debugDrawPlayableArea(){
        let shape = SKShapeNode()
        let path = CGMutablePath()
        path.addRect(playableRect)
        shape.path = path
        shape.strokeColor = SKColor.red
        shape.lineWidth = 4.0
        addChild(shape)
    }
    
    func rotate(sprite: SKSpriteNode, direction: CGPoint, rotateRadiansPerSec: CGFloat){
        
        let shortest = shortesAngleBetween(angle1: sprite.zRotation, angle2: direction.angle)
        let amountToRotate = min(CGFloat(dt) * rotateRadiansPerSec, abs(shortest))
        sprite.zRotation += amountToRotate * shortest.sign()
    }
    
    func spawnEnemy(){
        let enemy = SKSpriteNode(imageNamed: "enemy")
        enemy.name = "enemy"
        enemy.position = CGPoint(x: cameraRect.maxX + enemy.size.width / 2,
                                 y: CGFloat.random(min: cameraRect.minY + enemy.size.height / 2,
                                                   max: cameraRect.maxY - enemy.size.height / 2))
        enemy.zPosition = 50
        addChild(enemy)

        let actionMove = SKAction.moveTo(x: cameraRect.minX - enemy.size.width / 2, duration: 2.0)
        let actionRemove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([actionMove, actionRemove])
        enemy.run(sequence)
//        let actionMidMove = SKAction.moveBy(
//            x: -size.width/2-enemy.size.width/2,
//            y: -playableRect.height/2 + enemy.size.height/2,
//            duration: 1.0)
//        let actionMove = SKAction.moveBy(
//            x: -size.width/2-enemy.size.width/2,
//            y: playableRect.height/2 - enemy.size.height/2,
//            duration: 1.0)
//
//        let reverseMid = actionMidMove.reversed()
//        let reverseMove = actionMove.reversed()
//        let wait = SKAction.wait(forDuration: 0.25)
//        let logMessage = SKAction.run {
//            print("Reqched bottom!")
//        }
//        let halfSequence = SKAction.sequence([actionMidMove, logMessage, wait, actionMove])
//        let sequence = SKAction.sequence([halfSequence, halfSequence.reversed()])
//        let repeatAction = SKAction.repeatForever(sequence)
//        enemy.run(repeatAction)
    }
    
    func spawnCat(){
        let cat = SKSpriteNode(imageNamed: "cat")
        cat.name = "cat"
        cat.position = CGPoint(x: CGFloat.random(min: cameraRect.minX, max: cameraRect.maxX),
                               y: CGFloat.random(min: cameraRect.minY, max: cameraRect.maxY))
        cat.setScale(0)
        cat.zPosition = 50
        addChild(cat)
        
        let appear = SKAction.scale(to: 1.0, duration: 0.5)
        
        cat.zRotation = -π / 16.0
        let leftWiggle = SKAction.rotate(byAngle: π/8, duration: 0.5)
        let rightWiggle = leftWiggle.reversed()
        let fullWiggle = SKAction.sequence([leftWiggle, rightWiggle])
        
        let scaleUp = SKAction.scale(by: 1.2, duration: 0.25)
        let scaleDown = scaleUp.reversed()
        let fullScale = SKAction.sequence([scaleUp, scaleDown, scaleUp, scaleDown])
        let group = SKAction.group([fullScale, fullWiggle])
        let groupWait = SKAction.repeat(group, count: 10)
        
        let disappear = SKAction.scale(to: 0, duration: 0.5)
        let removeFromParent = SKAction.removeFromParent()
        let sequance = SKAction.sequence([appear, groupWait, disappear, removeFromParent])
        cat.run(sequance)
    }
    
    func zombieHit(cat: SKSpriteNode){
        cat.name = "train"
        cat.removeAllActions()
        
        let scaleAction = SKAction.scale(to: 1.0, duration: 0.2)
        let rotateAction = SKAction.rotate(toAngle: 0, duration: 0.2)
        let greenCat = SKAction.colorize(with: SKColor.green, colorBlendFactor: 1.0, duration: 0.2)
        let groupAction = SKAction.group([scaleAction, rotateAction, greenCat])
        cat.run(groupAction)
        
        run(catCollisionSound)
        
        catsCount += 1
    }
    
    func zombieHit(enemy: SKSpriteNode){
        invincible = true
        
        let blinkTimes = 10.0
        let duration = 3.0
        
        let fadeOff = SKAction.fadeAlpha(to: 0, duration: duration / blinkTimes)
        let fadeOn = SKAction.fadeAlpha(to: 1, duration: duration / blinkTimes)
        
        let sequance = SKAction.sequence([fadeOff, fadeOn])
        zombie.run(
            SKAction.sequence([
                SKAction.repeat(sequance, count: Int(duration / (duration / blinkTimes))),
                SKAction.run { [weak self] in
                    self?.invincible = false
                }]))
        
        run(enemyCollisionSound)
        loseCats()
        lives -= 1
    }
    
    func checkCollisions(){
        var hitCats: [SKSpriteNode] = []
        enumerateChildNodes(withName: "cat") { (node, _) in
            let cat = node as! SKSpriteNode
            if cat.frame.intersects(self.zombie.frame){
                hitCats.append(cat)
            }
        }
        
        for cat in hitCats{
            zombieHit(cat: cat)
        }
        
        if invincible{
            return
        }
        
        var hitEnemies: [SKSpriteNode] = []
        enumerateChildNodes(withName: "enemy") { (node, _) in
            let enemy = node as! SKSpriteNode
            if node.frame.insetBy(dx: 20, dy: 20).intersects(self.zombie.frame){
                hitEnemies.append(enemy)
            }
        }
        
        for enemy in hitEnemies{
            zombieHit(enemy: enemy)
        }
    }
    
    func startZombieAnimation(){
        if zombie.action(forKey: "animation") == nil{
            zombie.run(SKAction.repeatForever(zombieAnimation), withKey: "animation")
        }
    }
    
    func stopZombieAnimation(){
        zombie.removeAction(forKey: "animation")
    }
    
    
    
    func moveTrain(){
        var targetPosition = zombie.position
        var trainCount = 0
        
        enumerateChildNodes(withName: "train") { (node, stop) in
            trainCount += 1
            if !node.hasActions(){
                let actionDuration = 0.3
                let offset = targetPosition - node.position
                let direction = offset.normalized()
                let amountToMovePerSec = direction * self.catMovePointPerSecond
                let amountToMove = amountToMovePerSec * CGFloat(actionDuration)
                let moveAction = SKAction.moveBy(x: amountToMove.x, y: amountToMove.y, duration: actionDuration)
                node.run(moveAction)
            }
            targetPosition = node.position
        }
        
        if trainCount >= 15 && !gameOver{
            gameOver = true
            print("You win!")
            backgroundMusicPlayer.stop()
            let gameOverScene = GameOverScene(size: size, won: true)
            gameOverScene.scaleMode = scaleMode
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            view?.presentScene(gameOverScene, transition: reveal)
        }
    }
    
    func moveCamera(){
        let backgroundVelocity = CGPoint(x: cameraMovePointsPerSec, y: 0)
        let amountToMove = backgroundVelocity * CGFloat(dt)
        cameraNode.position += amountToMove
        
        enumerateChildNodes(withName: "background") { (node, _) in
            let background = node as! SKSpriteNode
            if background.position.x + background.size.width < self.cameraRect.origin.x{
                background.position = CGPoint(x: background.position.x + background.size.width * 2, y: background.position.y)
            }
        }
    }
    
    func loseCats(){
        var loseCount = 0
        enumerateChildNodes(withName: "train") { (node, stop) in
            var randomSpot = node.position
            randomSpot.x += CGFloat.random(min: -100, max: 100)
            randomSpot.y += CGFloat.random(min: -100, max: 100)
            
            node.name = ""
            node.run(
                SKAction.sequence([
                    SKAction.group([
                        SKAction.rotate(toAngle: π * 4, duration: 1.0),
                        SKAction.move(to: randomSpot, duration: 1.0),
                        SKAction.scale(to: 0, duration: 1.0)
                        ]),
                    SKAction.removeFromParent()
                ]))
            loseCount += 1
            if loseCount >= 2{
                stop[0] = true
            }
        }
        
        if loseCount >= 2{
            catsCount = catsCount - loseCount >= 0 ? catsCount - loseCount : 0
        }
    }
    
    //MARK: - Touches
    
    func sceneTouched(touchLocation: CGPoint){
        lastTouchLocation = touchLocation
        moveZombieToward(location: touchLocation)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else{
            return
        }
        let touchLocation = touch.location(in: self)
        sceneTouched(touchLocation: touchLocation)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else{
            return
        }
        let touchLocation = touch.location(in: self)
        sceneTouched(touchLocation: touchLocation)
    }
}
