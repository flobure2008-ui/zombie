import SpriteKit
import UIKit

struct PhysicsCategory {
    static let none: UInt32     = 0
    static let player: UInt32   = 0b1
    static let zombie: UInt32   = 0b10
    static let bullet: UInt32   = 0b100
    static let wall: UInt32     = 0b1000
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    weak var viewController: GameViewController?
    private var levelData: LevelData
    
    // Conteneur de jeu avec Caméra fluide
    private let worldNode = SKNode()
    private let hudNode = SKNode()
    private let gameCamera = SKCameraNode()
    
    // Joueur & Équipement
    private var player: SKNode!
    private var playerBodyShape: SKShapeNode!
    private var flashlight: SKShapeNode!
    private var playerHealth: CGFloat = 100
    private var maxPlayerHealth: CGFloat = 100
    private var killCount = 0
    
    // Armes & Munitions
    private var ammo: Int = 30
    private var maxAmmo: Int = 30
    private var isReloading = false
    private var lastShotTime: TimeInterval = 0
    
    // Double Joysticks Virtuels Flottants (True Twin-Stick Shooter)
    private var moveTouch: UITouch?
    private var aimTouch: UITouch?
    
    private var moveBaseNode: SKShapeNode!
    private var moveThumbNode: SKShapeNode!
    private var moveVector = CGPoint.zero
    
    private var aimBaseNode: SKShapeNode!
    private var aimThumbNode: SKShapeNode!
    private var aimVector = CGPoint.zero
    private var isAimingAndShooting = false
    
    // HUD & iPhone 13 Pro Max Safe Area
    private var safeMarginLeft: CGFloat = 54
    private var safeMarginRight: CGFloat = 54
    private var safeMarginBottom: CGFloat = 25
    private var healthBarFill: SKSpriteNode!
    private var ammoLabel: SKLabelNode!
    private var killLabel: SKLabelNode!
    private var levelLabel: SKLabelNode!
    private var reloadBtn: SKShapeNode!
    
    // Liste des zombies vivants
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
        backgroundColor = SKColor(red: 0.05, green: 0.06, blue: 0.08, alpha: 1.0)
        
        // Organisation en couches
        addChild(worldNode)
        addChild(hudNode)
        
        // Caméra
        addChild(gameCamera)
        self.camera = gameCamera
        
        setupMapEnvironment()
        setupPlayer()
        setupHUD()
        setupTouchControls()
        startZombieSpawners()
    }
    
    func updateSafeArea(insets: UIEdgeInsets, screenSize: CGSize) {
        // Adaptation dynamique pour Notch iPhone 13 Pro Max & barre d'accueil
        safeMarginLeft = max(50, insets.left * 1.5)
        safeMarginRight = max(50, insets.right * 1.5)
        safeMarginBottom = max(30, insets.bottom * 1.5)
        refreshHUDLayout()
    }
    
    // MARK: - Environnement & Graphismes
    private func setupMapEnvironment() {
        // Sol texturé style béton industriel / apocalypse
        let cols = 36
        let rows = 24
        let tileW: CGFloat = 80
        let tileH: CGFloat = 80
        
        for r in 0..<rows {
            for c in 0..<cols {
                let x = CGFloat(c) * tileW - (CGFloat(cols) * tileW) / 2
                let y = CGFloat(r) * tileH - (CGFloat(rows) * tileH) / 2
                
                let tile = SKSpriteNode(color: ((r + c) % 2 == 0) ? SKColor(red: 0.12, green: 0.13, blue: 0.16, alpha: 1.0) : SKColor(red: 0.10, green: 0.11, blue: 0.14, alpha: 1.0), size: CGSize(width: tileW - 2, height: tileH - 2))
                tile.position = CGPoint(x: x, y: y)
                tile.zPosition = 1
                worldNode.addChild(tile)
            }
        }
        
        // Limites de la zone
        let mapRect = CGRect(x: -1400, y: -900, width: 2800, height: 1800)
        let border = SKPhysicsBody(edgeLoopFrom: mapRect)
        border.categoryBitMask = PhysicsCategory.wall
        let borderNode = SKNode()
        borderNode.physicsBody = border
        worldNode.addChild(borderNode)
        
        // Murs tactiques avec bordures néon
        for wall in levelData.walls {
            let wx = wall.x - size.width/2
            let wy = wall.y - size.height/2
            
            let wallNode = SKShapeNode(rectOf: CGSize(width: wall.width, height: wall.height), cornerRadius: 6)
            wallNode.position = CGPoint(x: wx, y: wy)
            wallNode.fillColor = SKColor(red: 0.18, green: 0.22, blue: 0.28, alpha: 1.0)
            wallNode.strokeColor = SKColor(red: 0.35, green: 0.65, blue: 0.95, alpha: 0.8)
            wallNode.glowWidth = 2
            wallNode.lineWidth = 2.5
            wallNode.zPosition = 10
            
            wallNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: wall.width, height: wall.height))
            wallNode.physicsBody?.isDynamic = false
            wallNode.physicsBody?.categoryBitMask = PhysicsCategory.wall
            wallNode.physicsBody?.collisionBitMask = PhysicsCategory.player | PhysicsCategory.zombie | PhysicsCategory.bullet
            worldNode.addChild(wallNode)
        }
    }
    
    // MARK: - Personnage Joueur
    private func setupPlayer() {
        player = SKNode()
        player.position = .zero
        player.zPosition = 25
        
        // Ombre portée au sol
        let shadow = SKShapeNode(circleOfRadius: 24)
        shadow.fillColor = SKColor(white: 0, alpha: 0.45)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -4)
        shadow.zPosition = -2
        player.addChild(shadow)
        
        // Corps commando tactique
        playerBodyShape = SKShapeNode(circleOfRadius: 22)
        playerBodyShape.fillColor = SKColor(red: 0.15, green: 0.45, blue: 0.85, alpha: 1.0)
        playerBodyShape.strokeColor = SKColor(red: 0.5, green: 0.8, blue: 1.0, alpha: 1.0)
        playerBodyShape.glowWidth = 3
        playerBodyShape.lineWidth = 2
        player.addChild(playerBodyShape)
        
        // Casque / Tête
        let helmet = SKShapeNode(circleOfRadius: 11)
        helmet.fillColor = SKColor(red: 0.08, green: 0.12, blue: 0.18, alpha: 1.0)
        helmet.strokeColor = .clear
        player.addChild(helmet)
        
        // Fusil d'assaut tactique double canon
        let gun = SKShapeNode(rectOf: CGSize(width: 28, height: 9), cornerRadius: 2)
        gun.position = CGPoint(x: 20, y: 7)
        gun.fillColor = SKColor(white: 0.15, alpha: 1.0)
        gun.strokeColor = SKColor.darkGray
        player.addChild(gun)
        
        // Lampe torche réaliste avec cône volumétrique
        let lightPath = CGMutablePath()
        lightPath.move(to: CGPoint(x: 10, y: 0))
        lightPath.addLine(to: CGPoint(x: 380, y: 130))
        lightPath.addLine(to: CGPoint(x: 380, y: -130))
        lightPath.closeSubpath()
        
        flashlight = SKShapeNode(path: lightPath)
        flashlight.fillColor = SKColor(red: 1.0, green: 0.95, blue: 0.75, alpha: 0.18)
        flashlight.strokeColor = .clear
        flashlight.zPosition = -1
        player.addChild(flashlight)
        
        // Physique
        player.physicsBody = SKPhysicsBody(circleOfRadius: 20)
        player.physicsBody?.isDynamic = true
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.categoryBitMask = PhysicsCategory.player
        player.physicsBody?.collisionBitMask = PhysicsCategory.wall
        player.physicsBody?.contactTestBitMask = PhysicsCategory.zombie
        
        worldNode.addChild(player)
    }
    
    // MARK: - Interface HUD Tactique
    private func setupHUD() {
        hudNode.zPosition = 100
        
        // 1. Barre de vie (Haut Gauche)
        let hpBg = SKShapeNode(rectOf: CGSize(width: 220, height: 22), cornerRadius: 6)
        hpBg.name = "hp_bg"
        hpBg.fillColor = SKColor(white: 0.12, alpha: 0.85)
        hpBg.strokeColor = SKColor(white: 0.4, alpha: 0.5)
        hudNode.addChild(hpBg)
        
        healthBarFill = SKSpriteNode(color: SKColor(red: 0.1, green: 0.85, blue: 0.35, alpha: 1.0), size: CGSize(width: 214, height: 16))
        healthBarFill.anchorPoint = CGPoint(x: 0, y: 0.5)
        healthBarFill.name = "hp_fill"
        hudNode.addChild(healthBarFill)
        
        // 2. Compteur Munitions & Bouton Recharge
        ammoLabel = SKLabelNode(fontNamed: "TrebuchetMS-Bold")
        ammoLabel.text = "AMMO: 30 / 30"
        ammoLabel.fontSize = 20
        ammoLabel.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1.0)
        hudNode.addChild(ammoLabel)
        
        reloadBtn = SKShapeNode(rectOf: CGSize(width: 95, height: 32), cornerRadius: 6)
        reloadBtn.name = "btn_reload"
        reloadBtn.fillColor = SKColor(red: 0.8, green: 0.4, blue: 0.1, alpha: 0.85)
        reloadBtn.strokeColor = .white
        hudNode.addChild(reloadBtn)
        
        let relLbl = SKLabelNode(text: "RELOAD")
        relLbl.name = "btn_reload"
        relLbl.fontSize = 13
        relLbl.fontName = "HelveticaNeue-BlackCondensed"
        relLbl.verticalAlignmentMode = .center
        reloadBtn.addChild(relLbl)
        
        // 3. Titre Niveau & Objectif (Haut Centre / Droit)
        levelLabel = SKLabelNode(fontNamed: "HelveticaNeue-BlackCondensed")
        levelLabel.text = "\(levelData.title.uppercased()) [NIVEAU \(levelData.id)/100]"
        levelLabel.fontSize = 22
        levelLabel.fontColor = .white
        hudNode.addChild(levelLabel)
        
        killLabel = SKLabelNode(fontNamed: "TrebuchetMS-Bold")
        killLabel.text = "KILLS: 0 / \(levelData.targetKills)"
        killLabel.fontSize = 19
        killLabel.fontColor = SKColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
        hudNode.addChild(killLabel)
        
        // 4. Bouton Éditeur
        let editBtn = SKShapeNode(rectOf: CGSize(width: 110, height: 34), cornerRadius: 8)
        editBtn.name = "btn_editor"
        editBtn.fillColor = SKColor(red: 0.2, green: 0.25, blue: 0.45, alpha: 0.8)
        editBtn.strokeColor = .white
        hudNode.addChild(editBtn)
        
        let editLbl = SKLabelNode(text: "⚙ ÉDITEUR")
        editLbl.name = "btn_editor"
        editLbl.fontName = "HelveticaNeue-Bold"
        editLbl.fontSize = 14
        editLbl.verticalAlignmentMode = .center
        editBtn.addChild(editLbl)
        
        refreshHUDLayout()
    }
    
    private func refreshHUDLayout() {
        let halfW = size.width / 2
        let halfH = size.height / 2
        
        // Aligner en tenant compte de la Dynamic Island / Notch
        let leftX = -halfW + safeMarginLeft
        let rightX = halfW - safeMarginRight
        let topY = halfH - 45
        
        if let hpBg = hudNode.childNode(withName: "hp_bg") {
            hpBg.position = CGPoint(x: leftX + 110, y: topY)
        }
        healthBarFill.position = CGPoint(x: leftX + 3, y: topY)
        
        ammoLabel.position = CGPoint(x: leftX + 80, y: topY - 32)
        reloadBtn.position = CGPoint(x: leftX + 205, y: topY - 30)
        
        levelLabel.position = CGPoint(x: 0, y: topY)
        killLabel.position = CGPoint(x: rightX - 60, y: topY)
        
        if let editBtn = hudNode.childNode(withName: "btn_editor") {
            editBtn.position = CGPoint(x: rightX - 55, y: topY - 45)
        }
    }
    
    // MARK: - Contrôles Twin-Stick (Tactile console pro)
    private func setupTouchControls() {
        // Base Joystick Gauche (Déplacement)
        moveBaseNode = SKShapeNode(circleOfRadius: 65)
        moveBaseNode.fillColor = SKColor(white: 0.15, alpha: 0.45)
        moveBaseNode.strokeColor = SKColor(white: 0.8, alpha: 0.6)
        moveBaseNode.lineWidth = 2.5
        moveBaseNode.isHidden = true
        hudNode.addChild(moveBaseNode)
        
        moveThumbNode = SKShapeNode(circleOfRadius: 30)
        moveThumbNode.fillColor = SKColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 0.85)
        moveThumbNode.strokeColor = .white
        moveThumbNode.lineWidth = 2
        moveThumbNode.isHidden = true
        hudNode.addChild(moveThumbNode)
        
        // Base Joystick Droit (Visée & Tir 360°)
        aimBaseNode = SKShapeNode(circleOfRadius: 65)
        aimBaseNode.fillColor = SKColor(red: 0.7, green: 0.15, blue: 0.15, alpha: 0.45)
        aimBaseNode.strokeColor = SKColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 0.7)
        aimBaseNode.lineWidth = 2.5
        aimBaseNode.isHidden = true
        hudNode.addChild(aimBaseNode)
        
        aimThumbNode = SKShapeNode(circleOfRadius: 30)
        aimThumbNode.fillColor = SKColor(red: 1.0, green: 0.25, blue: 0.25, alpha: 0.9)
        aimThumbNode.strokeColor = .white
        aimThumbNode.lineWidth = 2
        aimThumbNode.isHidden = true
        hudNode.addChild(aimThumbNode)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let hudLoc = touch.location(in: hudNode)
            let touchedHud = hudNode.nodes(at: hudLoc)
            
            if touchedHud.contains(where: { $0.name == "btn_editor" }) {
                viewController?.openLevelEditor()
                return
            }
            if touchedHud.contains(where: { $0.name == "btn_reload" }) {
                reloadWeapon()
                return
            }
            
            // Côté Gauche -> Joystick Mouvement Flottant
            if hudLoc.x < 0 && moveTouch == nil {
                moveTouch = touch
                moveBaseNode.position = hudLoc
                moveThumbNode.position = hudLoc
                moveBaseNode.isHidden = false
                moveThumbNode.isHidden = false
            }
            // Côté Droit -> Joystick Visée & Tir Flottant
            else if hudLoc.x >= 0 && aimTouch == nil {
                aimTouch = touch
                aimBaseNode.position = hudLoc
                aimThumbNode.position = hudLoc
                aimBaseNode.isHidden = false
                aimThumbNode.isHidden = false
                isAimingAndShooting = true
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let hudLoc = touch.location(in: hudNode)
            
            // Mise à jour Déplacement
            if touch == moveTouch {
                let dx = hudLoc.x - moveBaseNode.position.x
                let dy = hudLoc.y - moveBaseNode.position.y
                let dist = sqrt(dx*dx + dy*dy)
                let maxDist: CGFloat = 55
                
                if dist > maxDist {
                    let angle = atan2(dy, dx)
                    moveThumbNode.position = CGPoint(x: moveBaseNode.position.x + cos(angle) * maxDist, y: moveBaseNode.position.y + sin(angle) * maxDist)
                    moveVector = CGPoint(x: cos(angle), y: sin(angle))
                } else {
                    moveThumbNode.position = hudLoc
                    moveVector = CGPoint(x: dx / maxDist, y: dy / maxDist)
                }
            }
            
            // Mise à jour Visée / Tir
            if touch == aimTouch {
                let dx = hudLoc.x - aimBaseNode.position.x
                let dy = hudLoc.y - aimBaseNode.position.y
                let dist = sqrt(dx*dx + dy*dy)
                let maxDist: CGFloat = 55
                
                if dist > 15 {
                    let angle = atan2(dy, dx)
                    aimVector = CGPoint(x: cos(angle), y: sin(angle))
                    player.zRotation = angle
                    
                    if dist > maxDist {
                        aimThumbNode.position = CGPoint(x: aimBaseNode.position.x + cos(angle) * maxDist, y: aimBaseNode.position.y + sin(angle) * maxDist)
                    } else {
                        aimThumbNode.position = hudLoc
                    }
                    isAimingAndShooting = true
                }
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if touch == moveTouch {
                moveTouch = nil
                moveVector = .zero
                moveBaseNode.isHidden = true
                moveThumbNode.isHidden = true
            }
            if touch == aimTouch {
                aimTouch = nil
                aimVector = .zero
                aimBaseNode.isHidden = true
                aimThumbNode.isHidden = true
                isAimingAndShooting = false
            }
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
    
    // MARK: - Mécaniques d'Armes & Tirs
    private func shootBullet() {
        if isReloading { return }
        if ammo <= 0 {
            reloadWeapon()
            return
        }
        
        let now = CACurrentMediaTime()
        if now - lastShotTime < 0.11 { return } // Cadence rapide de fusil d'assaut
        lastShotTime = now
        ammo -= 1
        updateAmmoHUD()
        
        let angle = player.zRotation
        let spawnPos = CGPoint(x: player.position.x + cos(angle) * 34, y: player.position.y + sin(angle) * 34)
        
        let bullet = SKShapeNode(circleOfRadius: 4.0)
        bullet.position = spawnPos
        bullet.fillColor = SKColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 1.0)
        bullet.strokeColor = .white
        bullet.glowWidth = 3
        bullet.zPosition = 28
        
        bullet.physicsBody = SKPhysicsBody(circleOfRadius: 4.0)
        bullet.physicsBody?.isDynamic = true
        bullet.physicsBody?.categoryBitMask = PhysicsCategory.bullet
        bullet.physicsBody?.collisionBitMask = PhysicsCategory.wall
        bullet.physicsBody?.contactTestBitMask = PhysicsCategory.zombie | PhysicsCategory.wall
        
        let speed: CGFloat = 1350
        bullet.physicsBody?.velocity = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)
        
        worldNode.addChild(bullet)
        ParticleEffects.createMuzzleFlash(at: spawnPos, angle: angle, in: worldNode)
        
        bullet.run(SKAction.sequence([SKAction.wait(forDuration: 1.3), SKAction.removeFromParent()]))
    }
    
    private func reloadWeapon() {
        if isReloading || ammo == maxAmmo { return }
        isReloading = true
        ammoLabel.text = "RECHARGEMENT..."
        ammoLabel.fontColor = .orange
        
        let reloadAction = SKAction.sequence([
            SKAction.wait(forDuration: 1.2),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                self.ammo = self.maxAmmo
                self.isReloading = false
                self.updateAmmoHUD()
            }
        ])
        run(reloadAction)
    }
    
    private func updateAmmoHUD() {
        ammoLabel.text = "AMMO: \(ammo) / \(maxAmmo)"
        ammoLabel.fontColor = ammo <= 5 ? .red : SKColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1.0)
    }
    
    // MARK: - Spawners & Zombies variés
    private func startZombieSpawners() {
        for spawner in levelData.spawners {
            let wait = SKAction.wait(forDuration: spawner.interval)
            let spawn = SKAction.run { [weak self] in
                let sx = spawner.x - (self?.size.width ?? 0)/2
                let sy = spawner.y - (self?.size.height ?? 0)/2
                self?.spawnZombie(at: CGPoint(x: sx, y: sy), type: spawner.zombieType)
            }
            run(SKAction.repeatForever(SKAction.sequence([wait, spawn])))
        }
    }
    
    private func spawnZombie(at pos: CGPoint, type: String) {
        let zombie = SKNode()
        zombie.name = "zombie"
        zombie.position = pos
        zombie.zPosition = 20
        
        var radius: CGFloat = 20
        var color = SKColor(red: 0.18, green: 0.75, blue: 0.35, alpha: 1.0)
        var hp: CGFloat = 40.0 * levelData.zombieHealthMultiplier
        var speed: CGFloat = 95.0 * levelData.zombieSpeedMultiplier
        
        if type == "fast" {
            radius = 16
            color = SKColor(red: 0.95, green: 0.75, blue: 0.1, alpha: 1.0)
            hp = 25.0 * levelData.zombieHealthMultiplier
            speed = 165.0 * levelData.zombieSpeedMultiplier
        } else if type == "tank" {
            radius = 32
            color = SKColor(red: 0.75, green: 0.12, blue: 0.12, alpha: 1.0)
            hp = 150.0 * levelData.zombieHealthMultiplier
            speed = 60.0 * levelData.zombieSpeedMultiplier
        }
        
        zombie.userData = NSMutableDictionary(dictionary: ["hp": hp, "speed": speed])
        
        // Corps zombie
        let body = SKShapeNode(circleOfRadius: radius)
        body.fillColor = color
        body.strokeColor = SKColor(white: 0.1, alpha: 0.9)
        body.lineWidth = 2.5
        zombie.addChild(body)
        
        // Yeux menaçants lumineux
        let eye1 = SKShapeNode(circleOfRadius: 3)
        eye1.position = CGPoint(x: radius * 0.5, y: 5)
        eye1.fillColor = .red
        eye1.strokeColor = .clear
        zombie.addChild(eye1)
        
        let eye2 = SKShapeNode(circleOfRadius: 3)
        eye2.position = CGPoint(x: radius * 0.5, y: -5)
        eye2.fillColor = .red
        eye2.strokeColor = .clear
        zombie.addChild(eye2)
        
        zombie.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        zombie.physicsBody?.isDynamic = true
        zombie.physicsBody?.allowsRotation = false
        zombie.physicsBody?.categoryBitMask = PhysicsCategory.zombie
        zombie.physicsBody?.collisionBitMask = PhysicsCategory.wall | PhysicsCategory.zombie
        zombie.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.bullet
        
        worldNode.addChild(zombie)
        zombies.append(zombie)
    }
    
    // MARK: - Boucle Principale & Caméra
    override func update(_ currentTime: TimeInterval) {
        // Déplacement du joueur
        let pSpeed: CGFloat = 240
        player.physicsBody?.velocity = CGVector(dx: moveVector.x * pSpeed, dy: moveVector.y * pSpeed)
        
        if moveVector != .zero && !isAimingAndShooting {
            player.zRotation = atan2(moveVector.y, moveVector.x)
        }
        
        // Tir en continu si visée active
        if isAimingAndShooting {
            shootBullet()
        }
        
        // La caméra suit le joueur avec amorti fluide
        let targetCamPos = player.position
        gameCamera.position = CGPoint(
            x: gameCamera.position.x + (targetCamPos.x - gameCamera.position.x) * 0.12,
            y: gameCamera.position.y + (targetCamPos.y - gameCamera.position.y) * 0.12
        )
        
        // Le HUD reste fixé à la caméra
        hudNode.position = gameCamera.position
        
        // IA Zombies traqueurs
        for z in zombies {
            guard z.parent != nil else { continue }
            let dx = player.position.x - z.position.x
            let dy = player.position.y - z.position.y
            let dist = sqrt(dx*dx + dy*dy)
            
            if dist > 0 {
                let angle = atan2(dy, dx)
                z.zRotation = angle
                let speed = (z.userData?["speed"] as? CGFloat) ?? 85
                z.physicsBody?.velocity = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)
            }
        }
    }
    
    // MARK: - Contacts & Physique
    func didBegin(_ contact: SKPhysicsContact) {
        var first = contact.bodyA
        var second = contact.bodyB
        if first.categoryBitMask > second.categoryBitMask {
            first = contact.bodyB
            second = contact.bodyA
        }
        
        // Balle vs Zombie
        if first.categoryBitMask == PhysicsCategory.zombie && second.categoryBitMask == PhysicsCategory.bullet {
            if let zombieNode = first.node, let bulletNode = second.node {
                bulletNode.removeFromParent()
                ParticleEffects.createBloodSplat(at: contact.contactPoint, in: worldNode)
                
                if let data = zombieNode.userData, var hp = data["hp"] as? CGFloat {
                    hp -= 30.0
                    data["hp"] = hp
                    if hp <= 0 {
                        ParticleEffects.createExplosion(at: zombieNode.position, in: worldNode)
                        zombies.removeAll(where: { $0 == zombieNode })
                        zombieNode.removeFromParent()
                        recordKill()
                    }
                }
            }
        }
        
        // Zombie vs Joueur
        if first.categoryBitMask == PhysicsCategory.player && second.categoryBitMask == PhysicsCategory.zombie {
            playerDamage(10)
        }
    }
    
    private func playerDamage(_ amt: CGFloat) {
        playerHealth = max(0, playerHealth - amt)
        let percent = playerHealth / maxPlayerHealth
        healthBarFill.size.width = 214 * percent
        
        // Effet de choc rouge à l'écran
        let flash = SKSpriteNode(color: SKColor.red.withAlphaComponent(0.35), size: size)
        flash.position = .zero
        flash.zPosition = 200
        hudNode.addChild(flash)
        flash.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.15), SKAction.removeFromParent()]))
        
        if playerHealth <= 0 {
            gameOver()
        }
    }
    
    private func recordKill() {
        killCount += 1
        killLabel.text = "KILLS: \(killCount) / \(levelData.targetKills)"
        if killCount >= levelData.targetKills {
            levelComplete()
        }
    }
    
    private func levelComplete() {
        isPaused = true
        let victory = SKLabelNode(fontNamed: "HelveticaNeue-BlackCondensed")
        victory.text = "ZONE PURIFIÉE ! NIVEAU TERMINÉ"
        victory.fontSize = 42
        victory.fontColor = SKColor(red: 0.2, green: 0.95, blue: 0.4, alpha: 1.0)
        victory.position = CGPoint(x: 0, y: 0)
        victory.zPosition = 300
        hudNode.addChild(victory)
        
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
        lost.text = "VOUS AVEZ ÉTÉ DÉVORÉ !"
        lost.fontSize = 48
        lost.fontColor = SKColor.red
        lost.position = CGPoint(x: 0, y: 0)
        lost.zPosition = 300
        hudNode.addChild(lost)
        
        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                self.viewController?.loadLevel(self.levelData.id)
            }
        ]))
    }
}
