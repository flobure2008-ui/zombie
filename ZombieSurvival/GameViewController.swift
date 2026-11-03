import UIKit
import SpriteKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let skView = SKView(frame: view.bounds)
        skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        skView.ignoresSiblingOrder = true
        skView.showsFPS = false
        skView.showsNodeCount = false
        
        view.addSubview(skView)
        
        loadLevel(1)
    }

    func loadLevel(_ levelIndex: Int) {
        guard let skView = view.subviews.compactMap({ $0 as? SKView }).first else { return }
        
        let levelData = LevelManager.shared.getLevel(levelIndex)
        let scene = GameScene(size: CGSize(width: 1334, height: 750), levelData: levelData)
        scene.scaleMode = .aspectFill
        scene.viewController = self
        
        let transition = SKTransition.fade(withDuration: 0.6)
        skView.presentScene(scene, transition: transition)
    }

    func openLevelEditor() {
        guard let skView = view.subviews.compactMap({ $0 as? SKView }).first else { return }
        
        let editorScene = LevelEditorScene(size: CGSize(width: 1334, height: 750))
        editorScene.scaleMode = .aspectFill
        editorScene.viewController = self
        
        let transition = SKTransition.push(with: .up, duration: 0.5)
        skView.presentScene(editorScene, transition: transition)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
}
