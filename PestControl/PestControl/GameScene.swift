/**
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import SpriteKit

class GameScene: SKScene {
  
  var background: SKTileMapNode!
  var player = Player()
  var bugsNode = SKNode()
  var obstaclesTileMap: SKTileMapNode?
  var firebugCount: Int = 0
  var bugSprayTileMap: SKTileMapNode?
  var hud = HUD()
  var timeLimit: Int = 120
  var elapsedTime: Int = 0
  var startTime: Int?
  var currentLevel: Int = 1
  var gameState: GameState = .initial {
    didSet {
      hud.updateGameState(from: oldValue, to: gameState)
    }
  }
  
  //MARK: - Life cycle
  
  override func encode(with aCoder: NSCoder) {
    aCoder.encode(firebugCount, forKey: "Scene.firebugCount")
    aCoder.encode(elapsedTime, forKey: "Scene.elapsedTime")
    aCoder.encode(gameState.rawValue, forKey: "Scene.gameState")
    aCoder.encode(currentLevel, forKey: "Scene.currentLevel")
    super.encode(with: aCoder)
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    background = (childNode(withName: "background") as! SKTileMapNode)
    obstaclesTileMap = (childNode(withName: "obstacles") as? SKTileMapNode)
    if let timeLimit = userData?.object(forKey: "timeLimit") as? Int{
      self.timeLimit = timeLimit
    }
    
    let savedGameState = aDecoder.decodeInteger(forKey: "Scene.gameState")
    if let gameState = GameState(rawValue: savedGameState),
      gameState == .pause {
      self.gameState = gameState
      firebugCount = aDecoder.decodeInteger(
        forKey: "Scene.firebugCount")
      elapsedTime = aDecoder.decodeInteger(
        forKey: "Scene.elapsedTime")
      currentLevel = aDecoder.decodeInteger(
        forKey: "Scene.currentLevel")
      // 2
      player = childNode(withName: "Player") as! Player
      hud = camera!.childNode(withName: "HUD") as! HUD
      bugsNode = childNode(withName: "Bugs")!
      bugSprayTileMap = childNode(withName: "Bugspray") as? SKTileMapNode
    }
    addObservers()
  }
  
  override func didMove(to view: SKView) {
    if gameState == .initial{
      addChild(player)
      setupWorldPhysics()
      createBugs()
      setupObstaclesPhysics()
    if firebugCount > 0{
      createBugSpray(quantity:  firebugCount + 10)
    }
      setupHud()
    gameState = .start
    }
    setupCamera()
  }
  
  override func update(_ currentTime: TimeInterval) {
    if gameState != .play  {
      isPaused = true
      return
    }
    
    if !player.hasBugspray{
      updateBugspray()
    }
    advanceBreakableTile(locatedAt: player.position)
    updateHud(currentTime: currentTime)
    checkEndGame()
  }
  
  //MARK: - Setup
  
  func setupCamera(){
    guard let camera = camera, let view = view else { return }
    
    let zeroDistance = SKRange(lowerLimit: -100, upperLimit: 100)
    let playerConstraint = SKConstraint.distance(zeroDistance, to: player)
    
    let xInset = min(view.bounds.width/2 * camera.xScale,
                     background.frame.width/2)
    let yInset = min(view.bounds.height/2 * camera.yScale,
                     background.frame.height/2)
    
    let constraintRect = background.frame.insetBy(dx: xInset, dy: yInset)
    
    let xRange = SKRange(lowerLimit: constraintRect.minX,
                         upperLimit: constraintRect.maxX)
    let yRange = SKRange(lowerLimit: constraintRect.minY,
                         upperLimit: constraintRect.maxY)
    
    let edgeConstraint = SKConstraint.positionX(xRange, y: yRange)
    edgeConstraint.referenceNode = background
    
    camera.constraints = [playerConstraint, edgeConstraint]
  }
  
  func setupWorldPhysics(){
    background.physicsBody = SKPhysicsBody(edgeLoopFrom: background.frame)
    background.physicsBody?.categoryBitMask = PhysicsCategory.Edge
    physicsWorld.contactDelegate = self
  }
  
  func setupHud(){
    camera?.addChild(hud)
    hud.addTimer(time: timeLimit)
    hud.addCountBugs(bugs: bugsNode.children.count)
  }
  
  //MAK: - Touches
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesBegan(touches, with: event)
    guard let touch = touches.first else{ return }
    switch gameState {
    // 1
    case .start:
      gameState = .play
      isPaused = false
      startTime = nil
      elapsedTime = 0
    // 2
    case .play:
      player.move(target: touch.location(in: self))
    case .win:
      transitionToScene(level: currentLevel + 1)
    case .lose:
      transitionToScene(level: 1)
    case .reload:
      // 1
      if let touchedNode = atPoint(touch.location(in: self)) as? SKLabelNode {
        // 2
        if touchedNode.name == HUDMessages.yes {
          isPaused = false
          startTime = nil
          gameState = .play
          // 3
        } else if touchedNode.name == HUDMessages.no {
          transitionToScene(level: 1)
        }
      }
    default:
      break
    }
  }
  
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesMoved(touches, with: event)
    guard let touch = touches.first else{ return }
    player.move(target: touch.location(in: self))
  }
  
  //MARK: - Help
  func transitionToScene(level: Int) {
    guard let newScene = SKScene(fileNamed: "Level\(level)")
      as? GameScene else {
        fatalError("Level: \(level) not found")
    }
    
    newScene.currentLevel = level
    view!.presentScene(newScene,
                       transition: SKTransition.flipVertical(withDuration: 0.5))
  }
  
  func checkEndGame(){
    if bugsNode.children.count == 0{
      player.physicsBody?.linearDamping = 1
      gameState = .win
    } else if timeLimit - elapsedTime <= 0 {
      player.physicsBody?.linearDamping = 1
      gameState = .lose
    }
  }
  
  func updateHud(currentTime: TimeInterval){
    if let startTime = startTime{
      elapsedTime = Int(currentTime) - startTime
    }else{
      startTime = Int(currentTime) - elapsedTime
    }
    hud.updateTimer(time: timeLimit - elapsedTime)
  }
  
  func tile(in tileMap: SKTileMapNode,
            at coordinates: TileCoordnates) -> SKTileDefinition?{
    return tileMap.tileDefinition(atColumn: coordinates.column, row: coordinates.row)
  }
  
  func tileGroupForName(tileSet: SKTileSet, name: String) -> SKTileGroup?{
    let tileGroup = tileSet.tileGroups.filter { $0.name == name}.first
    return tileGroup
  }
  
  func createBugs(){
    guard let bugsMap = childNode(withName: "bugs") as? SKTileMapNode else { return }
    for row in 0..<bugsMap.numberOfRows{
      for column in 0..<bugsMap.numberOfColumns{
        guard let tile = tile(in: bugsMap, at: (column, row)) else { continue }
        let bug: Bug
        if tile.userData?.object(forKey: "firebug") != nil{
          bug = Firebug()
          firebugCount += 1
        }else{
          bug = Bug()
        }
        bug.position = bugsMap.centerOfTile(atColumn: column, row: row)
        bugsNode.addChild(bug)
        bug.moveBug()
      }
    }
    bugsNode.name = "Bugs"
    addChild(bugsNode)
    bugsMap.removeFromParent()
  }
  
  func remove(bug: Bug){
    bug.removeFromParent()
    hud.updateBugCounter(bugsCount: bugsNode.children.count)
    background.addChild(bug)
    bug.die()
  }
  
  func setupObstaclesPhysics(){
    guard let obstaclesTileMap = obstaclesTileMap else { return }
    
    for row in 0..<obstaclesTileMap.numberOfRows{
      for column in 0..<obstaclesTileMap.numberOfColumns{
        guard let tile = tile(in: obstaclesTileMap, at: (column, row)) else { continue }
        guard tile.userData?.object(forKey: "obstacle") != nil else { continue }
        let node = SKNode()
        node.physicsBody = SKPhysicsBody(rectangleOf: tile.size)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.friction = 0
        node.physicsBody?.categoryBitMask = PhysicsCategory.Breakable
        
        node.position = obstaclesTileMap.centerOfTile(atColumn: column, row: row)
        obstaclesTileMap.addChild(node)
      }
    }
  }
  
  func advanceBreakableTile(locatedAt nodePosition: CGPoint){
    guard let obstacleTileMap = obstaclesTileMap else { return }
    let (column, row) = tileCoordinates(in: obstacleTileMap, at: nodePosition)
    let obstacle = tile(in: obstacleTileMap, at: (column, row))
    guard let nextTileGroupName = obstacle?.userData?.object(forKey: "breakable") as? String else{ return }
    if let nextTileGroup = tileGroupForName(tileSet: obstacleTileMap.tileSet, name: nextTileGroupName){
      obstacleTileMap.setTileGroup(nextTileGroup, forColumn: column, row: row)
    }
  }
  
  func createBugSpray(quantity: Int){
    let tile = SKTileDefinition(texture: SKTexture(pixelImageNamed: "bugspray"))
    let tileRule = SKTileGroupRule(adjacency: SKTileAdjacencyMask.adjacencyAll, tileDefinitions: [tile])
    let tileGroup = SKTileGroup(rules: [tileRule])
    let tileSet = SKTileSet(tileGroups: [tileGroup])
    let columns = background.numberOfColumns
    let rows = background.numberOfRows
    
    bugSprayTileMap = SKTileMapNode(tileSet: tileSet,
                                    columns: columns,
                                    rows: rows,
                                    tileSize: tile.size)
    
    for _ in  1...quantity{
      let column = Int.random(min: 0, max: columns - 1)
      let row = Int.random(min: 0, max: rows - 1)
      bugSprayTileMap?.setTileGroup(tileGroup, forColumn: column, row: row)
    }
    
    bugSprayTileMap?.name = "Bugspray"
    addChild(bugSprayTileMap!)
  }
  
  func tileCoordinates(in tileMap: SKTileMapNode, at position: CGPoint) -> TileCoordnates{
    let column = tileMap.tileColumnIndex(fromPosition: position)
    let row = tileMap.tileRowIndex(fromPosition: position)
    return (column, row)
  }
  
  func updateBugspray(){
    guard let bugsprayTileMap = bugSprayTileMap else { return }
    let (column, row) = tileCoordinates(in: bugsprayTileMap, at: player.position)
    if tile(in: bugsprayTileMap, at: (column, row)) != nil{
      bugsprayTileMap.setTileGroup(nil, forColumn: column, row: row)
      player.hasBugspray = true
    }
  }
}

extension GameScene: SKPhysicsContactDelegate{
  
  func didBegin(_ contact: SKPhysicsContact) {
    let other = contact.bodyA.categoryBitMask == PhysicsCategory.Player ? contact.bodyB : contact.bodyA
    switch other.categoryBitMask {
    case PhysicsCategory.Bug:
      if let bug = other.node as? Bug{
        remove(bug: bug)
      }
    case PhysicsCategory.Firebug:
      if player.hasBugspray{
        if let firebug = other.node as? Firebug{
          remove(bug: firebug)
          player.hasBugspray = false
        }
      }
    case PhysicsCategory.Breakable:
      if let obstacleNode = other.node{
        advanceBreakableTile(locatedAt: obstacleNode.position)
        obstacleNode.removeFromParent()
      }
    default:
      break
    }
    
    if let physicsBody = player.physicsBody{
      if physicsBody.velocity.length() > 0{
        player.checkDirection()
      }
    }
  }
  
}

//MARK: - Notification
extension GameScene{
  @objc func applicationDidBecomeActive() {
    print("* applicationDidBecomeActive")
    if gameState == .pause{
      gameState = .reload
    }
  }
  @objc func applicationWillResignActive() {
    print("* applicationWillResignActive")
    isPaused = true
    if gameState != .lose{
      gameState = .pause
    }
  }
  @objc func applicationDidEnterBackground() {
    print("* applicationDidEnterBackground")
    if gameState != .lose{
      saveGame()
    }
  }
  
  func addObservers(){
    NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
  }
}

//MARK: - Saving games
extension GameScene{
  func saveGame(){
    let fileManager = FileManager.default
    guard let directory = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first else{ return }
    let saveURL = directory.appendingPathComponent("SavedGames")
    
    do{
      try fileManager.createDirectory(atPath: saveURL.path, withIntermediateDirectories: true, attributes: nil)
    }catch let error as NSError{
      fatalError("Failed to create directory: \(error.debugDescription)")
    }
    let fileURL = saveURL.appendingPathComponent("saved-game")
    print("* Saving: \(fileURL.path)")
    NSKeyedArchiver.archiveRootObject(self, toFile: fileURL.path)
  }
  
  class func loadGame() -> SKScene?{
    print("* loading game")
    var scene: SKScene?
    
    let fileManager = FileManager.default
    guard let directory = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first else {
      return nil
    }
    let url = directory.appendingPathComponent("SavedGames/saved-game")
    
    if fileManager.fileExists(atPath: url.path){
      scene = NSKeyedUnarchiver.unarchiveObject(withFile: url.path) as? GameScene
      _ = try? fileManager.removeItem(at: url)
    }
    return scene
  }
}
