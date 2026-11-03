import SpriteKit

class ParticleEffects {
    
    static func createMuzzleFlash(at position: CGPoint, angle: CGFloat, in scene: SKNode) {
        let flash = SKShapeNode(circleOfRadius: 16)
        flash.position = position
        flash.fillColor = SKColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 0.9)
        flash.strokeColor = .clear
        flash.glowWidth = 8
        flash.zPosition = 25
        scene.addChild(flash)
        
        let fade = SKAction.fadeOut(withDuration: 0.06)
        let scale = SKAction.scale(to: 1.6, duration: 0.06)
        flash.run(SKAction.group([fade, scale])) {
            flash.removeFromParent()
        }
    }
    
    static func createBloodSplat(at position: CGPoint, in scene: SKNode) {
        let particleCount = 7
        for _ in 0..<particleCount {
            let blood = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...7))
            blood.position = position
            blood.fillColor = SKColor(red: CGFloat.random(in: 0.6...0.9), green: 0.05, blue: 0.05, alpha: 0.9)
            blood.strokeColor = .clear
            blood.zPosition = 5
            scene.addChild(blood)
            
            let angle = CGFloat.random(in: 0...(CGFloat.pi * 2))
            let dist = CGFloat.random(in: 25...80)
            let dx = cos(angle) * dist
            let dy = sin(angle) * dist
            
            let move = SKAction.moveBy(x: dx, y: dy, duration: 0.18)
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: CGFloat.random(in: 3.0...6.0))
            
            blood.run(SKAction.sequence([move, fade, SKAction.removeFromParent()]))
        }
    }
    
    static func createExplosion(at position: CGPoint, in scene: SKNode) {
        let shockwave = SKShapeNode(circleOfRadius: 10)
        shockwave.position = position
        shockwave.strokeColor = SKColor(red: 1.0, green: 0.5, blue: 0.1, alpha: 1.0)
        shockwave.glowWidth = 10
        shockwave.lineWidth = 4
        shockwave.zPosition = 26
        scene.addChild(shockwave)
        
        let expand = SKAction.scale(to: 9.0, duration: 0.35)
        let fade = SKAction.fadeOut(withDuration: 0.35)
        shockwave.run(SKAction.group([expand, fade])) {
            shockwave.removeFromParent()
        }
    }
}
