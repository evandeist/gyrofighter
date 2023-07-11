//
//  GameScene.swift
//  movementtest
//
//  Created by Bryson Foye on 11/7/21.
//

/*
 articles for reference:
 https://www.raywenderlich.com/5504-trigonometry-for-game-programming-spritekit-and-swift-tutorial-part-1-2
 
 MINIMUM VIABLE PRODUCT:
 
 TODO: Make title screen with the title graphic ("GYROFIGHTER!") and a start button
 
 TODO: Scale asteroid speed and frequency to score
 TODO: Scale asteroid impulse to size (so no mini asteroids spin out of control
 TODO: Game over screen with functional reset button
 
 TODO: Include sound effects
 TODO: Grace Period
 TODO: (WHEN ALL IS FINISHED) remove onscreen debug info
 
 
 CURRENT ISSUES:
 
 STRETCH GOALS:
 TODO: persistent highscores list in coredata
 TODO: Asteroids split into two smaller asteroids when hit
 TODO: Background music
 TODO: Bullets disappear offscreen (can't hit offscreen asteroids)
 TODO: Enemy?
 TODO: Afterburner trail
 */


import SpriteKit
import AudioToolbox
import CoreMotion

// Vector functions
func +(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func -(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func *(point: CGPoint, scalar: CGFloat) -> CGPoint {
  return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func /(point: CGPoint, scalar: CGFloat) -> CGPoint {
  return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

func normalize (_ vec:CGVector) -> CGVector {
    let len = sqrt((vec.dx * vec.dx) + (vec.dy * vec.dy))
    return CGVector(dx:vec.dx/len, dy:vec.dy/len)
}

#if !(arch(x86_64) || arch(arm64))
  func sqrt(a: CGFloat) -> CGFloat {
    return CGFloat(sqrtf(Float(a)))
  }
#endif

extension Double {
    func truncate(places : Int)-> Double {
        return Double(floor(pow(10.0, Double(places)) * self)/pow(10.0, Double(places)))
    }
}

extension CGPoint {
  func length() -> CGFloat {
    return sqrt(x*x + y*y)
  }
  func normalized() -> CGPoint {
    return self / length()
  }
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // controls
    let moveThresh = 0.015
    var xAccelAdjust = 0.0
    var yAccelAdjust = 0.0
    
    // ship
    let shipSize = 0.65
    let xmult = 100.0
    let ymult = 100.0
    let speedcap = 290.0
    let accel = 1.0
    let decel = 7.0
    let shipRestitution = 5.0
    let iframes = 120
   
    // asteroids
    let asteroidSizeRange = (0.7...1.4)
    let asteroidImpulseRange = (-0.04...0.04)
    let asteroidSpeedRange = (140.0...260.0)
    let asteroidCenters = [CGPoint(x:0.5,y:0.5), CGPoint(x:0.5,y:0.5), CGPoint(x:0.5,y:0.42)]
    let asteroidHitboxScales = [2.35, 3.5, 2.85]
    let xpad = 1.5
    let ypad = 1.5
    
    // bullets
    let bulletSize = 0.5
    let maxBullets = 1 //idk why but 1 = 2 and 2 = 3
    
    // core motion
    var motionManager : CMMotionManager!
    
    // UI
    let scorePosition = CGPoint(x: 300, y: 150)
    let heartX = -300.0
    let heartY = 150.0
    
    // game objects
    var background : SKSpriteNode!
    var player : SKSpriteNode!
    var bullet : SKSpriteNode!
    var hearts : [SKSpriteNode] = []
    var asteroid : SKSpriteNode!
    var scoreLabel : SKLabelNode!
    var recenter : SKSpriteNode!
    var gameOverBox : SKShapeNode!
    var gameOverText : SKLabelNode!
    var retryButton : SKShapeNode!
    var retryText : SKLabelNode!
    var menuButton : SKShapeNode!
    var menuText : SKLabelNode!
    
    // sounds
    var startSound = SKAction.playSoundFileNamed("ok.mp3", waitForCompletion: false)
    let shootSound = SKAction.playSoundFileNamed("shoot.wav", waitForCompletion: false)
    var destroySound = SKAction.playSoundFileNamed("destroy.wav", waitForCompletion: false)
    var recenterSound = SKAction.playSoundFileNamed("recenter.wav", waitForCompletion: false)
    var hurtSound = SKAction.playSoundFileNamed("hurt.wav", waitForCompletion: false)
    
    // game vars
    var isGameOver: Bool = false {
        didSet {
            if isGameOver == true {
                if let particles = SKEmitterNode(fileNamed:"sparks") {
                    particles.position = player.position
                    addChild(particles)
                }
                destroy(player)
                scoreLabel.position = CGPoint(x:0, y:0)
                gameOverBanner()
            }
        }
    }
    var asteroidChance = 0.0
    var chanceGrowth = 0.06
    var asteroids = 0
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    var intangible = false
    var intangibleFrame = 0
    
    // testing in sim
    var lastTouchPosition: CGPoint?
    
    
    func gameOverBanner() {
        let banner = CGRect(x:-200.0, y:-150.0, width: 400.0, height: 300.0)
        
        gameOverBox = SKShapeNode(rect: banner, cornerRadius: 10.0)
        gameOverBox.fillColor = .black
        gameOverBox.alpha = 0.4
        gameOverBox.position = CGPoint(x:0,y:0)
        gameOverBox.zPosition = 2.0
        
        gameOverText = SKLabelNode(text: "Game Over")
        gameOverText.fontName = "Futura-MediumItalic"
        gameOverText.fontSize = 60.0
        gameOverText.position = CGPoint(x:0.0,y:50.0)
        gameOverText.zPosition = 3.0
        
        addChild(gameOverBox)
        addChild(gameOverText)
        
        retryButton = SKShapeNode(rect: CGRect(x: 0.0, y: 0.0, width: 100.0, height: 50.0), cornerRadius: 8.0)
        retryButton.position = CGPoint(x:-50.0,y:-85.0)
        retryButton.zPosition = 6.0
        
        retryText = SKLabelNode(text: "retry")
        retryText.fontName = "Futura-MediumItalic"
        retryText.position = CGPoint(x:0.0,y:-73.0)
        retryText.zPosition = 8.0
        
        addChild(retryButton)
        addChild(retryText)
    }
    
    func createSceneContents() {
        //self.scaleMode = .resizeFill
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        self.physicsBody?.collisionBitMask = 0
        self.physicsBody?.categoryBitMask = CollisionTypes.wall.rawValue
        
    }
    
    func createRecenterButton() {
        recenter = SKSpriteNode(imageNamed:"gyroscope")
        recenter.setScale(0.4)
        //recenter.position = CGPoint(x:0,y:0)
        recenter.position = CGPoint(x:-(size.width/2)+40.0, y:(-(size.height/2) + 50.0))
        
        recenter.zPosition = 10.0
        recenter.alpha = 0.5
        
        addChild(recenter)
    }
    
    func createPlayer() {
        player = SKSpriteNode(imageNamed: "ship.png")
        player.name = "player"
        player.setScale(shipSize)
        player.anchorPoint = CGPoint(x:0.5, y:0.5)
        player.position = randomPointOnScreen()
        player.zPosition = 1
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width / 2)
        //player.physicsBody?.allowsRotation = true
        //player.physicsBody?.angularDamping = 0.1
        player.physicsBody?.linearDamping = decel
        player.physicsBody?.restitution = shipRestitution
        player.physicsBody?.categoryBitMask = CollisionTypes.player.rawValue
        player.physicsBody?.contactTestBitMask = CollisionTypes.asteroid.rawValue
        player.physicsBody?.collisionBitMask = CollisionTypes.wall.rawValue
        addChild(player)
    }
    
    func createBullet() {
        bullet = SKSpriteNode(imageNamed:"bullet")
        bullet.name = "bullet"
        bullet.setScale(bulletSize)
        bullet.position = player.position
        bullet.zRotation = player.zRotation
        bullet.physicsBody = SKPhysicsBody(circleOfRadius: bullet.size.height/2)
        bullet.physicsBody?.isDynamic = true
        bullet.physicsBody?.categoryBitMask = CollisionTypes.bullet.rawValue
        bullet.physicsBody?.contactTestBitMask = CollisionTypes.asteroid.rawValue
        bullet.physicsBody?.collisionBitMask = 0
        run(shootSound)
        addChild(bullet)
        
    }
    
    func randomPointOnScreen() -> CGPoint {
        let w = size.width/2
        let h = size.height/2
        let x = Double.random(in: (-w+50...w-50) )
        let y = Double.random(in: (-h+30...h-30) )
        return CGPoint(x:x, y:y)
    }
    
    func randomPointOffScreen() -> CGPoint {
        let w = size.width/2
        let h = size.height/2
        
        let x = Double.random(in: (-(xpad)*w...(xpad)*w))
        var y : Double
        if (x < -w) || (x > w) { // off screen left or right
            y = Double.random(in: (-h...h))
        } else { // off screen at top or bottom
            if Int.random(in: (0...1)) == 0 {
                y = Double.random(in: (-(ypad)*h...(-h)))
            } else {
                y = Double.random(in: (h...(ypad)*h))
            }
        }
        return CGPoint(x:x, y:y)
    }
    
    func createAsteroid() {
        
        let from = randomPointOffScreen()
        let to = randomPointOnScreen()
        
        let randNameNum = Int.random(in: 1...3)
        
        asteroid = SKSpriteNode(imageNamed:"asteroid\(randNameNum)")
        asteroid.name = "asteroid"
        asteroid.anchorPoint = asteroidCenters[randNameNum-1]
        asteroid.position = from
        asteroid.setScale(Double.random(in: asteroidSizeRange))
        asteroid.physicsBody = SKPhysicsBody(circleOfRadius: (asteroid.size.width / asteroidHitboxScales[randNameNum-1]) ,center: asteroidCenters[randNameNum-1])
        
        asteroid.physicsBody?.affectedByGravity = false
        asteroid.physicsBody?.categoryBitMask = CollisionTypes.asteroid.rawValue
        asteroid.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue | CollisionTypes.bullet.rawValue
        asteroid.physicsBody?.collisionBitMask = 0
        let dir = normalize(CGVector(dx:to.x - from.x, dy:to.y - from.y))
        let speed = Double.random(in: asteroidSpeedRange)
        asteroid.physicsBody?.velocity = CGVector(dx:dir.dx * speed, dy:dir.dy * speed)
        //asteroid.physicsBody?.velocity = CGVector(dx:0, dy:0)
        addChild(asteroid)
        let action1 = SKAction.applyAngularImpulse(Double.random(in: asteroidImpulseRange), duration: 0.01)
        let action2 = SKAction.wait(forDuration: 10)
        let actionDone = SKAction.removeFromParent()
        asteroid.run(SKAction.sequence([action1,action2,actionDone]))
    }
    
    func reset() {
        
        self.removeAllChildren()
        
        // vars
        isGameOver = false
        score = 0
        asteroidChance = 0.0
        chanceGrowth = 0.06
        asteroids = 0
        intangible = false
        intangibleFrame = 0
        drawGameScene()
    }
    
    func drawGameScene() {
        
        let background = SKSpriteNode(imageNamed: "background")
        background.zPosition = -4.0
        background.setScale(0.7)
        background.position = CGPoint(x: 0, y: 0)
        addChild(background)
        
        //create three lives
        for i in 1...3 {
            let heart = SKSpriteNode(imageNamed: "heart")
            heart.setScale(1.5)
            heart.alpha = 0.5
            heart.position = CGPoint(x: heartX + (1.1 * heart.size.width * CGFloat(i)), y: heartY)
            addChild(heart)
            hearts.append(heart)
        }
       
        scoreLabel = SKLabelNode(fontNamed: "Futura-MediumItalic")
        scoreLabel.fontSize = (30.0)
        scoreLabel.text = "Score: 0"
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.position = scorePosition
        scoreLabel.zPosition = 10
        addChild(scoreLabel)
        
        physicsWorld.gravity = .zero
        createSceneContents()
        createRecenterButton()
        createPlayer()
        recenterTilt()
    }
    
    // when scene is presented:
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        motionManager = CMMotionManager()
        motionManager.startAccelerometerUpdates()
        drawGameScene()
    }
    
    
    
    //Contact function. if Two nodes collided then run either playerCollided or
    // bulletCollided
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }

        if nodeA == player {
            if !intangible {
                playerCollided(with: nodeB)
                run(hurtSound)
            }
           }
        else if nodeB == player {
            if !intangible {
                playerCollided(with: nodeA)
                run(hurtSound)
            }
           }
        else if (nodeA.name == "bullet") {
            destroy(nodeA)
            run(destroySound)
            bulletCollided(with: nodeB)
        }
        else if (nodeB.name == "bullet") {
            destroy(nodeB)
            run(destroySound)
            bulletCollided(with: nodeA)
        }
        
    }
    
    func playerCollided(with: SKNode) {
        guard let heart = hearts.last else {return}
        
        if let particles = SKEmitterNode(fileNamed:"sparks") {
            particles.position = with.position
            addChild(particles)
        }
        destroy(with)
        
        
        heart.removeFromParent()
        hearts.removeLast()
        
        if hearts.isEmpty {
            isGameOver = true
            return
        }
        
        intangible = true
        
        let blink = SKAction.sequence([SKAction.fadeOut(withDuration: 0.05), SKAction.fadeIn(withDuration: 0.05)])
        
        let timesBlinked = SKAction.repeat(blink,count: 20)
        
        player.run(timesBlinked)
    }
    
    func bulletCollided(with: SKNode) {
        if with.name == "asteroid" {
            if let particles = SKEmitterNode(fileNamed:"sparks") {
                particles.position = with.position
                addChild(particles)
            }
        }
        destroy(with)
        score += 10
    }
    
    func destroy(_ node: SKNode) {
        if (node.physicsBody != nil) {
            node.physicsBody = nil
        }
        node.removeFromParent()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        // if on sim, move with touch
        let location = touch.location(in: self)
        lastTouchPosition = location
        
        if (isGameOver && retryButton.contains(touch.location(in:self))) {
            run(startSound)
            reset()
        }
        
        // recenter button
        if recenter.contains(touch.location(in: self)) {
            run(recenterSound)
            recenterTilt()
        } else {
            // shoot if able
            var bullets = 0
            enumerateChildNodes(withName: "bullet") { node, stop in
                  bullets += 1
            }
            if (!isGameOver && bullets <= maxBullets) {
                createBullet()
                //trig magic
                let action = SKAction.move(to: CGPoint(x: 1000.0 * cos(bullet.zRotation + .pi/2) + bullet.position.x , y: 1000.0 * (sin(bullet.zRotation + .pi/2) ) + bullet.position.y), duration: 0.8)
                
                let actionDone = SKAction.removeFromParent()
                bullet.run(SKAction.sequence([action, actionDone]))
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard let touch = touches.first else { return }
            let location = touch.location(in: self)
            lastTouchPosition = location
    }
    
    
    override func didEvaluateActions() {
        if (isGameOver || player==nil || player.physicsBody==nil) { return }
        let dx = player.physicsBody!.velocity.dx
        let dy = player.physicsBody!.velocity.dy
        
        let dz = sqrt((dx*dx) + (dy*dy))
        
        player.zRotation = atan2(dy, dx) - ((CGFloat.pi/2))
        
        // "animate"
        if dz > 110.0 {
            player.run(SKAction.setTexture(SKTexture(imageNamed: "ship3")))
        } else {
            player.run(SKAction.setTexture(SKTexture(imageNamed: "ship")))
        }
        
        // cannot exceed speed limit
        if dz > speedcap {
            var cappedx = dx/dz
            var cappedy = dy/dz
            
            cappedx = cappedx * speedcap
            cappedy = cappedy * speedcap
            
            player.physicsBody?.velocity = CGVector(dx: cappedx, dy: cappedy)
        }
        
    }
    
    func recenterTilt () {
        if let accelData = motionManager.accelerometerData {
            yAccelAdjust = -accelData.acceleration.x
            xAccelAdjust = accelData.acceleration.y
        }
    }
    
    func getVec() -> CGVector? {
        
        var ret : CGVector? = nil
        
        if let accelerometerData = motionManager.accelerometerData {
            
            let accx = (-accelerometerData.acceleration.y) + xAccelAdjust
            let accy = (accelerometerData.acceleration.x) + yAccelAdjust
            
            if (abs(accx) + abs(accy) >= moveThresh) {
                // accelerate in tilted direction
                
                player.physicsBody?.linearDamping = accel
                ret = CGVector(dx: accx * xmult, dy: accy * ymult)
            } else {
                // stop accelerating, slow to halt
                player.run(SKAction.setTexture(SKTexture(imageNamed: "ship")))
                player.physicsBody?.linearDamping = decel
                ret = CGVector(dx: 0.0, dy: 0.0)
            }
        }
        return ret
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        // asteroid spawning
        asteroidChance += chanceGrowth
        if Double.random(in: (0.0...100.0)) < asteroidChance {
            asteroids+=1
            createAsteroid()
            asteroidChance /= 10.0
        }
        
        // invincibility
        if (intangible == true) {
            if intangibleFrame >= iframes {
                intangibleFrame = 0
                intangible = false
            } else {
                intangibleFrame += 1
            }
            
        }
        
        #if targetEnvironment(simulator)
        if let currentTouch = lastTouchPosition {
                let diff = CGPoint(x: xmult * (currentTouch.x - player.position.x), y: ymult * (currentTouch.y - player.position.y))
                physicsWorld.gravity = CGVector(dx: diff.x / 100, dy: diff.y / 100)
        }
        #else
        // accelerate ship
        if let vec = getVec() {
            physicsWorld.gravity = vec
        }
        #endif
    }
}
