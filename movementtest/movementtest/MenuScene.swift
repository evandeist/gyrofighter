//
//  MenuScene.swift
//  movementtest
//
//  Created by Evan Deist on 12/3/21.
//

/*

 TODO: How to play
 
 */

import SpriteKit

class MenuScene: SKScene {
    
    let playButtonWidth = 200.0
    let playButtonHeight = 50.0
    var startSound = SKAction.playSoundFileNamed("ok.mp3", waitForCompletion: false)
    
    var titleText = SKLabelNode(text:"GYROFIGHTER")
    var playButton = SKShapeNode()
    var playText = SKLabelNode(text:"start!")
    var howToPlayButton = SKShapeNode()
    var howToPlayText = SKLabelNode(text:"instructions")
    var instructionBox = SKShapeNode()
    var instructionText = SKLabelNode(text: "hi")
    var exitButton = SKShapeNode()
    var exitText = SKLabelNode(text: "exit")
    
    func instructionBanner() {
        let banner = CGRect(x:-200.0, y:-150.0, width: 400.0, height: 300.0)
        
        instructionBox = SKShapeNode(rect: banner, cornerRadius: 10.0)
        instructionBox.fillColor = .black
        instructionBox.position = CGPoint(x:0,y:0)
        instructionBox.zPosition = 2.0
        
        instructionText = SKLabelNode(text: "Your ship has wound up in the thick of an asteroid belt! It's estimated that your ship can take around three hits from these asteroids for it to explode!  Control your ship using the tilt of your phone to weave your way around the asteroids while tapping the screen to destroy them. You can recalibrate the gyroscope using the button on the left-hand corner. Good luck! ")
        instructionText.fontName = "Futura-MediumItalic"
        instructionText.fontSize = 16.0
        instructionText.position = CGPoint(x:0.0,y:-40.0)
        instructionText.zPosition = 3.0
        instructionText.horizontalAlignmentMode = .center
        instructionText.lineBreakMode = NSLineBreakMode.byWordWrapping
        instructionText.numberOfLines = 0
        instructionText.preferredMaxLayoutWidth = 350.0
        
        addChild(instructionBox)
        addChild(instructionText)
        
        exitButton = SKShapeNode(rect: CGRect(x: 0.0, y: 0.0, width: 100.0, height: 50.0), cornerRadius: 8.0)
        exitButton.position = CGPoint(x:-50.0,y:-100)
        exitButton.zPosition = 6.0
        
        exitText = SKLabelNode(text: "exit")
        exitText.fontName = "Futura-MediumItalic"
        exitText.position = CGPoint(x:0.0,y:-85.0)
        exitText.zPosition = 8.0
        
        addChild(exitButton)
        addChild(exitText)
    }
    
    
    
    override func didMove(to view: SKView) {
        self.backgroundColor = .black
        
        // title
        titleText.position = CGPoint(x:0.0,y:100.0)
        titleText.fontColor = .white
        titleText.fontName = "Futura-MediumItalic"
        titleText.fontSize = 90.0
        self.addChild(titleText)
        
        // play button
        playButton = SKShapeNode(rect: CGRect(x: 0.0, y: 0.0, width: playButtonWidth, height: 50.0), cornerRadius: 6.0)
        playButton.position = CGPoint(x:-self.size.width + playButtonWidth + 200,y:-50.0)
        playText.position = CGPoint(x:playButton.position.x + (playButtonWidth / 2),
                                    y:playButton.position.y + (playButtonHeight / 2) - 10.0)
        playText.zPosition = -1.0
        
        howToPlayButton = SKShapeNode(rect: CGRect(x:0.0, y:0.0, width: playButtonWidth, height: 50.0), cornerRadius: 6.0)
        howToPlayButton.position = CGPoint(x:self.size.width - (playButtonWidth + 400), y: -50)
        howToPlayText.position = CGPoint(x: howToPlayButton.position.x + (playButtonWidth / 2), y:howToPlayButton.position.y + (playButtonHeight / 2) - 10)
        
        self.addChild(playButton)
        self.addChild(playText)
        self.addChild(howToPlayButton)
        self.addChild(howToPlayText)
    }
    
    

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let pos = touch.location(in: self)
            let node = self.atPoint(pos)

            if node == playButton {
                if let view = view {
                    let transition:SKTransition = SKTransition.fade(withDuration: 0.5)
                    run(startSound)
                    if let scene = GameScene(fileNamed: "GameScene") {
                        self.view?.presentScene(scene, transition: transition)
                    }
                }
            }
            
            else if node == howToPlayButton || node == howToPlayText {
                instructionBanner()
            }
            
            else if node == exitButton || node == exitText {
                instructionBox.removeFromParent()
                instructionText.removeFromParent()
                exitButton.removeFromParent()
                exitText.removeFromParent()
            }
        }
    }
    
}
