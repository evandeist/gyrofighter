//
//  GameViewController.swift
//  movementtest
//
//  Created by Bryson Foye on 11/7/21.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {
    
    private var orientations = UIInterfaceOrientationMask.landscapeRight
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get { return self.orientations }
        set { self.orientations = newValue }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            // Load the SKScene from 'GameScene.sks'
            if let scene = MenuScene(fileNamed: "MenuScene") {
                // Set the scale mode to scale to fit the window
                //scene.scaleMode = .aspectFill
                // Present the scene
                print("presenting scene")
                view.presentScene(scene)
            } else {
                print("cant find scene!")
            }
            
            
            //TODO: Remove when finalizing!!
            /*
            view.ignoresSiblingOrder = true
            view.showsFPS = true
            view.showsNodeCount = true
            view.showsPhysics = true
            view.showsFields = true
             */
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
