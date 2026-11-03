import UIKit
import SpriteKit

class GameViewController: UIViewController {

    private var skView: SKView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        skView = SKView(frame: view.bounds)
        skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        skView.ignoresSiblingOrder = true
        skView.showsFPS = false
        skView.showsNodeCount = false
        
        // Multi-touch obligatoire pour double joysticks simultanés
        skView.isMultipleTouchEnabled = true
        
        view.addSubview(skView)
        
        loadLevel(1)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Adapter la taille de la scène au Safe Area de l'iPhone 13 Pro Max
        if let currentScene = skView.scene as? GameScene {
            currentScene.updateSafeArea(insets: view.safeAreaInsets, screenSize: view.bounds.size)
        }
    }

    func loadLevel(_ levelIndex: Int) {
        let levelData = LevelManager.shared.getLevel(levelIndex)
        let sceneSize = CGSize(width: 1334, height: 750)
        let scene = GameScene(size: sceneSize, levelData: levelData)
        scene.scaleMode = .aspectFill
        scene.viewController = self
        
        let transition = SKTransition.fade(withDuration: 0.5)
        skView.presentScene(scene, transition: transition)
    }

    func openLevelEditor() {
        let editorScene = LevelEditorScene(size: CGSize(width: 1334, height: 750))
        editorScene.scaleMode = .aspectFill
        editorScene.viewController = self
        
        let transition = SKTransition.doorsOpenHorizontal(withDuration: 0.4)
        skView.presentScene(editorScene, transition: transition)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
}
