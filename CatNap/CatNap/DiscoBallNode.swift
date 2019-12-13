//
//  DiscoBallNode.swift
//  CatNap
//
//  Created by Eugene  Mekhedov on 5/22/19.
//  Copyright © 2019 Eugene  Mekhedov. All rights reserved.
//

import SpriteKit
import AVFoundation

class DiscoBallNode: SKSpriteNode, EventListenerNode, InteractiveNode {
    
    private var player: AVPlayer!
    private var video: SKVideoNode!
    
    private let spinAction = SKAction.repeatForever(
        SKAction.animate(with: [
                                SKTexture(imageNamed: "discoball1"),
                                SKTexture(imageNamed: "discoball2"),
                                SKTexture(imageNamed: "discoball3")],
                         timePerFrame: 0.2))
    static private(set) var isDiscoTime = false
    private var isDiscoTime: Bool = false{
        didSet{
            DiscoBallNode.isDiscoTime = isDiscoTime
            video.isHidden = !isDiscoTime
            SKTAudio.sharedInstance().playBackgroundMusic(isDiscoTime ? "disco-sound.m4a" : "backgroundMusic.mp3")
            if isDiscoTime {
                video.play()
                run(spinAction)
            } else {
                video.pause()
                removeAllActions()
            }
            if isDiscoTime {
                video.run(SKAction.wait(forDuration: 5.0), completion: {
                    self.isDiscoTime = false
                })
            }
        }
    }
    
    func didMoveToScene() {
        isUserInteractionEnabled = true
        
        let fileURL = Bundle.main.url(forResource: "discolights-loop", withExtension: "mov")!
        player = AVPlayer(url: fileURL)
        video = SKVideoNode(avPlayer: player)
        
        video.size = scene!.size
        video.position = CGPoint(x: scene!.frame.midX,
                                 y: scene!.frame.midY)
        video.zPosition = -1
        video.alpha = 0.75
        scene!.addChild(video)
        
        video.isHidden = true
        video.pause()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didReachEndOfVideo), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    func interact() {
        if !isDiscoTime{
            isDiscoTime = true
        }
    }
    
    @objc func didReachEndOfVideo(){
        print("rewind!")
        player.currentItem!.seek(to: CMTime.zero, completionHandler: nil)
        player.play()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        interact()
    }
}
