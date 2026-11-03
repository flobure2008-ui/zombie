import SpriteKit

class LevelEditorScene: SKScene {
    
    weak var viewController: GameViewController?
    
    private var selectedTool: String = "wall" // wall, spawner, test, save
    private var walls: [WallData] = []
    private var spawners: [SpawnerData] = []
    private var levelIndex: Int = 101 // Custom ID
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.12, green: 0.14, blue: 0.18, alpha: 1.0)
        drawGrid()
        setupToolbar()
    }
    
    private func drawGrid() {
        let step: CGFloat = 40
        for x in stride(from: CGFloat(0), to: size.width, by: step) {
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            line.path = path
            line.strokeColor = SKColor(white: 0.22, alpha: 0.5)
            line.lineWidth = 1
            line.zPosition = 1
            addChild(line)
        }
        
        for y in stride(from: CGFloat(0), to: size.height, by: step) {
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            line.path = path
            line.strokeColor = SKColor(white: 0.22, alpha: 0.5)
            line.lineWidth = 1
            line.zPosition = 1
            addChild(line)
        }
    }
    
    private func setupToolbar() {
        let tools = [
            ("Mur", "wall", 80),
            ("Spawner", "spawner", 210),
            ("Tester", "test", 340),
            ("Sauvegarder", "save", 480),
            ("Retour", "back", 610)
        ]
        
        for (name, id, x) in tools {
            let btn = SKShapeNode(rectOf: CGSize(width: 110, height: 42), cornerRadius: 8)
            btn.name = "btn_\(id)"
            btn.position = CGPoint(x: CGFloat(x), y: size.height - 40)
            btn.fillColor = SKColor(red: 0.18, green: 0.35, blue: 0.65, alpha: 0.9)
            btn.strokeColor = .white
            btn.zPosition = 100
            addChild(btn)
            
            let lbl = SKLabelNode(text: name)
            lbl.name = "btn_\(id)"
            lbl.fontSize = 16
            lbl.fontName = "HelveticaNeue-Bold"
            lbl.verticalAlignmentMode = .center
            btn.addChild(lbl)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        
        // Clic sur la toolbar
        if loc.y > size.height - 70 {
            let touched = nodes(at: loc)
            for node in touched {
                if let name = node.name {
                    if name == "btn_wall" { selectedTool = "wall" }
                    if name == "btn_spawner" { selectedTool = "spawner" }
                    if name == "btn_save" { saveLevel() }
                    if name == "btn_test" { testLevel() }
                    if name == "btn_back" { viewController?.loadLevel(1) }
                }
            }
            return
        }
        
        // Placement d'éléments sur la grille
        let snappedX = round(loc.x / 40) * 40
        let snappedY = round(loc.y / 40) * 40
        
        if selectedTool == "wall" {
            let wall = WallData(x: snappedX, y: snappedY, width: 40, height: 40)
            walls.append(wall)
            
            let shape = SKShapeNode(rectOf: CGSize(width: 40, height: 40))
            shape.position = CGPoint(x: snappedX, y: snappedY)
            shape.fillColor = SKColor.lightGray
            shape.strokeColor = .white
            shape.zPosition = 10
            addChild(shape)
        } else if selectedTool == "spawner" {
            let spawner = SpawnerData(x: snappedX, y: snappedY, interval: 2.0, zombieType: "normal")
            spawners.append(spawner)
            
            let marker = SKShapeNode(circleOfRadius: 18)
            marker.position = CGPoint(x: snappedX, y: snappedY)
            marker.fillColor = SKColor.red
            marker.strokeColor = .yellow
            marker.zPosition = 10
            addChild(marker)
        }
    }
    
    private func saveLevel() {
        let level = LevelData(
            id: levelIndex,
            title: "Niveau Personnalisé #\(levelIndex)",
            targetKills: max(10, spawners.count * 8),
            zombieHealthMultiplier: 1.2,
            zombieSpeedMultiplier: 1.1,
            walls: walls,
            spawners: spawners.isEmpty ? [SpawnerData(x: 100, y: 100, interval: 2.5, zombieType: "normal")] : spawners,
            isCustom: true
        )
        LevelManager.shared.saveCustomLevel(level)
        
        let confirm = SKLabelNode(text: "Niveau Sauvegardé !")
        confirm.fontName = "HelveticaNeue-Bold"
        confirm.fontSize = 24
        confirm.fontColor = .green
        confirm.position = CGPoint(x: size.width / 2, y: size.height / 2)
        confirm.zPosition = 200
        addChild(confirm)
        confirm.run(SKAction.sequence([SKAction.wait(forDuration: 1.0), SKAction.removeFromParent()]))
    }
    
    private func testLevel() {
        saveLevel()
        viewController?.loadLevel(levelIndex)
    }
}
