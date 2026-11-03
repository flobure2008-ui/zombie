import SpriteKit

struct PhysicsCategory {
    static let none: UInt32     = 0
    static let player: UInt32   = 0b1
    static let zombie: UInt32   = 0b10
    static let bullet: UInt32   = 0b100
    static let wall: UInt32     = 0b1000
    static let barrel: UInt32   = 0b10000
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    weak var viewController: GameViewController?
    private var levelData: LevelData
    
    private var player: SKNode!
    private var flashlight: SKShapeNode!
    private var killCount = 0
    private var playerHealth: CGFloat = 100
    private var maxPlayerHealth: CGFloat = 100
    
    private var healthBarFill: SKSpriteNode!
    private var killLabel: SKLabelNode!
    private var levelLabel: SKLabelNode!
    
    private var joystickBase: SKShapeNode?
    private var joystickThumb: SKShapeNode?
    private var joystickActive = false
    private var moveVector = CGPoint.zero
    
    private var fireButton: SKShapeNode!
    private var isFiring = false
    private var lastShotTime: TimeInterval = 0
    private var currentWeapon = "Rifle" // Pistol, Shotgun, Rifle
    
    private var zombies: [SKNode] = []
    
    init(size: CGSize, levelData: LevelData) {
        self.levelData = levelData
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        backgroundColor = SKColor(red: 0.08, green: 0.09, blue: 0.11, alpha: 1.0)
        
        setupAtmosphere()
        setupLevelMap()
        setupPlayer()
        setupHUD()
        setupControls()
        startSpawners()
    }
    
    private func setupAtmosphere() {
        let gridCols = 28
        let gridRows = 16
        let tileW = size.width / CGFloat(gridCols)
        let tileH = size.height / CGFloat(gridRows)
        
        for r in 0..<gridRows {
            for c in 0..<gridCols {
                let tile = SKSpriteNode(color: ((r + c) % 2 == 0) ? SKColor(white: 0.11, alpha: 1.0) : SKColor(white: 0.13, alpha: 1.0), size: CGSize(width: tileW - 1, height: tileH - 1))
                tile.position = CGPoint(x: CGFloat(c) * tileW + tileW/2, y: CGFloat(r) * tileH + tileH/2)
                tile.zPosition = 1
                addChild(tile)
            }
        }
    }
    
    private func setupLevelMap() {
        // Murs périmétriques
        let boundary = SKPhysicsBody(edgeLoopFrom: frame)
        boundary.categoryBitMask = PhysicsCategory.wall
        self.physicsBody = boundary
        
        // Murs du niveau
        for wall in levelData.walls {
            let wallNode = SKShapeNode(rectOf: CGSize(width: wall.width, height: wall.height), cornerRadius: 4)
            wallNode.position = CGPoint(x: wall.x, y: wall.y)
            wallNode.fillColor = SKColor(red: 0.22, green: 0.25, blue: 0.32, alpha: 1.0)
            wallNode.strokeColor = SKColor(red: 0.35, green: 0.40, blue: 0.50, alpha: 1.0)
            wallNode.lineWidth = 2
            wallNode.zPosition = 10
            
            wallNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: wall.width, height: wall.height))
            wallNode.physicsBody?.isDynamic = false
            wallNode.physicsBody?.categoryBitMask = PhysicsCategory.wall
            wallNode.physicsBody?.collisionBitMask = PhysicsCategory.player | PhysicsCategory.zombie | PhysicsCategory.bullet
            addChild(wallNode)
        }
    }
    
    private func setupPlayer() {
        player = SKNode()
        player.position = CGPoint(x: size.width / 2, y: size.height / 2)
        player.zPosition = 20
        
        // Corps joueur
        let body = SKShapeNode(circleOfRadius: 20)
        body.fillColor = SKColor(red: 0.2, green: 0.6, blue: 0.95, alpha: 1.0)
        body.strokeColor = SKColor.white
        body.lineWidth = 2
        player.addChild(body)
        
        // Arme / Canon
        let gun = SKShapeNode(rectOf: CGSize(width: 24, height: 7))
        gun.position = CGPoint(x: 18, y: 0)
        gun.fillColor = SKColor(white: 0.2, alpha: 1.0)
        gun.strokeColor = .clear
        player.addChild(gun)
        
        // Lampe torche / Cône lumineux
        let lightPath = CGMutablePath()
        lightPath.move(to: .zero)
        lightPath.addLine(to: CGPoint(x: 260, y: 90))
        lightPath.addLine(to: CGPoint(x: 260, y: -90))
        lightPath.closeSubpath()
        
        flashlight = SKShapeNode(path: lightPath)
        flashlight.fillColor = SKColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 0.16)
        flashlight.strokeColor = .clear
        flashlight.zPosition = -1
        player.addChild(flashlight)
        
        player.physicsBody = SKPhysicsBody(circleOfRadius: 20)
        player.physicsBody?.isDynamic = true
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.categoryBitMask = PhysicsCategory.player
        player.physicsBody?.collisionBitMask = PhysicsCategory.wall
        player.physicsBody?.contactTestBitMask = PhysicsCategory.zombie
        
        addChild(player)
    }
    
    private func setupHUD() {
        // Barre de vie
        let barBg = SKShapeNode(rectOf: CGSize(width: 200, height: 18), cornerRadius: 4)
        barBg.position = CGPoint(x: 140, y: size.height - 40)
        barBg.fillColor = SKColor(white: 0.15, alpha: 0.8)
        barBg.strokeColor = SKColor.white.withAlphaComponent(0.4)
        barBg.zPosition = 100
        addChild(barBg)
        
        healthBarFill = SKSpriteNode(color: SKColor(red: 0.15, green: 0.85, blue: 0.35, alpha: 1.0), size: CGSize(width: 196, height: 14))
        healthBarFill.anchorPoint = CGPoint(x: 0, y: 0.5)
        healthBarFill.position = CGPoint(x: 42, y: size.height - 40)
        healthBarFill.zPosition = 101
        addChild(healthBarFill)
        
        // Titre niveau
        levelLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        levelLabel.text = "\(levelData.title) (\(levelData.id)/100)"
        levelLabel.fontSize = 20
        levelLabel.fontColor = .white
        levelLabel.position = CGPoint(x: size.width / 2, y: size.height - 45)
        levelLabel.zPosition = 100
        addChild(levelLabel)
        
        // Score / Éliminations
        killLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        killLabel.text = "ZOMBIES: 0 / \(levelData.targetKills)"
        killLabel.fontSize = 18
        killLabel.fontColor = SKColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
        killLabel.horizontalAlignmentMode = .right
        killLabel.position = CGPoint(x: size.width - 50, y: size.height - 45)
        killLabel.zPosition = 100
        addChild(killLabel)
        
        // Bouton Éditeur
        let editorBtn = SKShapeNode(rectOf: CGSize(width: 110, height: 35), cornerRadius: 6)
        editorBtn.name = "editor_button"
        editorBtn.position = CGPoint(x: size.width - 90, y: 50)
        editorBtn.fillColor = SKColor(red: 0.2, green: 0.25, blue: 0.45, alpha: 0.85)
        editorBtn.strokeColor = .white
        editorBtn.zPosition = 100
        addChild(editorBtn)
        
        let editorLbl = SKLabelNode(text: "Éditeur")
        editorLbl.name = "editor_button"
        editorLbl.fontSize = 15
        editorLbl.fontName = "HelveticaNeue-Bold"
        editorLbl.verticalAlignmentMode = .center
        editorBtn.addChild(editorLbl)
    }
    
    private func setupControls() {
        // Joystick Virtuel gauche
        let base = SKShapeNode(circleOfRadius: 60)
        base.position = CGPoint(x: 130, y: 130)
        base.fillColor = SKColor(white: 0.3, alpha: 0.35)
        base.strokeColor = SKColor(white: 0.7, alpha: 0.5)
        base.lineWidth = 2
        base.zPosition = 150
        addChild(base)
        self.joystickBase = base
        
        let thumb = SKShapeNode(circleOfRadius: 28)
        thumb.position = CGPoint(x: 130, y: 130)
        thumb.fillColor = SKColor(white: 0.9, alpha: 0.75)
        thumb.strokeColor = .clear
        thumb.zPosition = 151
        addChild(thumb)
        self.joystickThumb = thumb
        
        // Bouton Tir droit
        fireButton = SKShapeNode(circleOfRadius: 50)
        fireButton.name = "fire_button"
        fireButton.position = CGPoint(x: size.width - 130, y: 130)
        fireButton.fillColor = SKColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 0.5)
        fireButton.strokeColor = SKColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 0.8)
        fireButton.lineWidth = 3
        fireButton.zPosition = 150
        addChild(fireButton)
        
        let fireLbl = SKLabelNode(text: "FIRE")
        fireLbl.name = "fire_button"
        fireLbl.fontName = "HelveticaNeue-BlackCondensed"
        fireLbl.fontSize = 20
        fireLbl.verticalAlignmentMode = .center
        fireButton.addChild(fireLbl)
    }
    
    private func startSpawners() {
        for spawner in levelData.spawners {
            let wait = SKAction.wait(forDuration: spawner.interval)
            let spawn = SKAction.run { [weak self] in
                self?.spawnZombie(at: CGPoint(x: spawner.x, y: spawner.y), type: spawner.zombieType)
            }
            run(SKAction.repeatForever(SKAction.sequence([wait, spawn])))
        }
    }
    
    private func spawnZombie(at pos: CGPoint, type: String) {
        let zombie = SKNode()
        zombie.name = "zombie"
        zombie.position = pos
        zombie.zPosition = 15
        
        var radius: CGFloat = 18
        var color = SKColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0)
        var hp: CGFloat = 35.0 * levelData.zombieHealthMultiplier
        var speed: CGFloat = 90.0 * levelData.zombieSpeedMultiplier
        
        if type == "fast" {
            radius = 14
            color = SKColor(red: 0.9, green: 0.7, blue: 0.1, alpha: 1.0)
            hp = 20.0 * levelData.zombieHealthMultiplier
            speed = 150.0 * levelData.zombieSpeedMultiplier
        } else if type == "tank" {
            radius = 28
            color = SKColor(red: 0.6, green: 0.1, blue: 0.1, alpha: 1.0)
            hp = 120.0 * levelData.zombieHealthMultiplier
            speed = 55.0 * levelData.zombieSpeedMultiplier
        }
        
        zombie.userData = NSMutableDictionary(dictionary: ["hp": hp, "speed": speed])
        
        let body = SKShapeNode(circleOfRadius: radius)
        body.fillColor = color
        body.strokeColor = SKColor.black
        body.lineWidth = 2
        zombie.addChild(body)
        
        zombie.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        zombie.physicsBody?.isDynamic = true
        zombie.physicsBody?.allowsRotation = false
        zombie.physicsBody?.categoryBitMask = PhysicsCategory.zombie
        zombie.physicsBody?.collisionBitMask = PhysicsCategory.wall | PhysicsCategory.zombie
        zombie.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.bullet
        
        addChild(zombie)
        zombies.append(zombie)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let loc = touch.location(in: self)
            let touchedNodes = nodes(at: loc)
            
            if touchedNodes.contains(where: { $0.name == "editor_button" }) {
                viewController?.openLevelEditor()
                return
            }
            
            if touchedNodes.contains(where: { $0.name == "fire_button" }) {
                isFiring = true
                shootBullet()
                continue
            }
            
            if loc.x < size.width / 2 {
                joystickActive = true
                updateJoystick(at: loc)
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let loc = touch.location(in: self)
            if loc.x < size.width / 2 && joystickActive {
                updateJoystick(at: loc)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let loc = touch.location(in: self)
            if loc.x < size.width / 2 {
                joystickActive = false
                moveVector = .zero
                joystickThumb?.position = joystickBase?.position ?? CGPoint(x: 130, y: 130)
            }
            let touchedNodes = nodes(at: loc)
            if touchedNodes.contains(where: { $0.name == "fire_button" }) {
                isFiring = false
            }
        }
    }
    
    private func updateJoystick(at loc: CGPoint) {
        guard let base = joystickBase else { return }
        let dx = loc.x - base.position.x
        let dy = loc.y - base.position.y
        let dist = sqrt(dx*dx + dy*dy)
        let maxRadius: CGFloat = 50
        
        if dist > maxRadius {
            let angle = atan2(dy, dx)
            joystickThumb?.position = CGPoint(x: base.position.x + cos(angle) * maxRadius, y: base.position.y + sin(angle) * maxRadius)
            moveVector = CGPoint(x: cos(angle), y: sin(angle))
        } else {
            joystickThumb?.position = loc
            moveVector = CGPoint(x: dx / maxRadius, y: dy / maxRadius)
        }
    }
    
    private func shootBullet() {
        let now = CACurrentMediaTime()
        if now - lastShotTime < 0.14 { return }
        lastShotTime = now
        
        let bullet = SKShapeNode(circleOfRadius: 4.5)
        bullet.name = "bullet"
        let angle = player.zRotation
        
        let spawnPos = CGPoint(x: player.position.x + cos(angle) * 30, y: player.position.y + sin(angle) * 30)
        bullet.position = spawnPos
        bullet.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1.0)
        bullet.strokeColor = .white
        bullet.glowWidth = 2
        bullet.zPosition = 22
        
        bullet.physicsBody = SKPhysicsBody(circleOfRadius: 4.5)
        bullet.physicsBody?.isDynamic = true
        bullet.physicsBody?.categoryBitMask = PhysicsCategory.bullet
        bullet.physicsBody?.collisionBitMask = PhysicsCategory.wall
        bullet.physicsBody?.contactTestBitMask = PhysicsCategory.zombie | PhysicsCategory.wall
        
        let speed: CGFloat = 1100
        bullet.physicsBody?.velocity = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)
        
        addChild(bullet)
        ParticleEffects.createMuzzleFlash(at: spawnPos, angle: angle, in: self)
        
        bullet.run(SKAction.sequence([SKAction.wait(forDuration: 1.6), SKAction.removeFromParent()]))
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Déplacement du joueur
        if joystickActive {
            let pSpeed: CGFloat = 220
            player.physicsBody?.velocity = CGVector(dx: moveVector.x * pSpeed, dy: moveVector.y * pSpeed)
            let targetAngle = atan2(moveVector.y, moveVector.x)
            player.zRotation = targetAngle
        } else {
            player.physicsBody?.velocity = .zero
        }
        
        // Tir continu si pressé
        if isFiring {
            shootBullet()
        }
        
        // IA Zombies traqueurs
        for z in zombies {
            guard z.parent != nil else { continue }
            let dx = player.position.x - z.position.x
            let dy = player.position.y - z.position.y
            let dist = sqrt(dx*dx + dy*dy)
            
            if dist > 0 {
                let angle = atan2(dy, dx)
                z.zRotation = angle
                let speed = (z.userData?["speed"] as? CGFloat) ?? 80
                z.physicsBody?.velocity = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        // Balle vs Zombie
        if firstBody.categoryBitMask == PhysicsCategory.zombie && secondBody.categoryBitMask == PhysicsCategory.bullet {
            if let zombieNode = firstBody.node, let bulletNode = secondBody.node {
                bulletNode.removeFromParent()
                ParticleEffects.createBloodSplat(at: contact.contactPoint, in: self)
                
                if let data = zombieNode.userData, var hp = data["hp"] as? CGFloat {
                    hp -= 25.0
                    data["hp"] = hp
                    if hp <= 0 {
                        ParticleEffects.createExplosion(at: zombieNode.position, in: self)
                        zombies.removeAll(where: { $0 == zombieNode })
                        zombieNode.removeFromParent()
                        recordKill()
                    }
                }
            }
        }
        
        // Zombie vs Joueur
        if firstBody.categoryBitMask == PhysicsCategory.player && secondBody.categoryBitMask == PhysicsCategory.zombie {
            playerDamage(12)
        }
    }
    
    private func playerDamage(_ amt: CGFloat) {
        playerHealth = max(0, playerHealth - amt)
        let percent = playerHealth / maxPlayerHealth
        healthBarFill.size.width = 196 * percent
        
        // Flash d'impact rouge
        let redFlash = SKSpriteNode(color: SKColor.red.withAlphaComponent(0.3), size: size)
        redFlash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        redFlash.zPosition = 200
        addChild(redFlash)
        redFlash.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.15), SKAction.removeFromParent()]))
        
        if playerHealth <= 0 {
            gameOver()
        }
    }
    
    private func recordKill() {
        killCount += 1
        killLabel.text = "ZOMBIES: \(killCount) / \(levelData.targetKills)"
        
        if killCount >= levelData.targetKills {
            levelComplete()
        }
    }
    
    private func levelComplete() {
        isPaused = true
        let victoryLabel = SKLabelNode(fontNamed: "HelveticaNeue-BlackCondensed")
        victoryLabel.text = "NIVEAU TERMINÉ !"
        victoryLabel.fontSize = 46
        victoryLabel.fontColor = SKColor(red: 0.2, green: 0.9, blue: 0.4, alpha: 1.0)
        victoryLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        victoryLabel.zPosition = 250
        addChild(victoryLabel)
        
        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.8),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                let next = (self.levelData.id % 100) + 1
                self.viewController?.loadLevel(next)
            }
        ]))
    }
    
    private func gameOver() {
        isPaused = true
        let lost = SKLabelNode(fontNamed: "HelveticaNeue-BlackCondensed")
        lost.text = "VOUS ÊTES MORT !"
        lost.fontSize = 50
        lost.fontColor = SKColor.red
        lost.position = CGPoint(x: size.width / 2, y: size.height / 2)
        lost.zPosition = 250
        addChild(lost)
        
        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                self.viewController?.loadLevel(self.levelData.id)
            }
        ]))
    }
}
