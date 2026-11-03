import SpriteKit

class ParticleEffects {
    
    // Éclair et étincelles au tir
    static func createMuzzleFlash(at position: CGPoint, angle: CGFloat, in scene: SKNode) {
        // Cône lumineux instantané
        let flash = SKShapeNode(circleOfRadius: 18)
        flash.position = position
        flash.fillColor = SKColor(red: 1.0, green: 0.92, blue: 0.45, alpha: 0.95)
        flash.strokeColor = .white
        flash.glowWidth = 10
        flash.zPosition = 35
        scene.addChild(flash)
        
        let fade = SKAction.fadeOut(withDuration: 0.05)
        let scale = SKAction.scale(to: 1.8, duration: 0.05)
        flash.run(SKAction.group([fade, scale])) {
            flash.removeFromParent()
        }
        
        // Étincelles éjectées du canon
        for _ in 0..<4 {
            let spark = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...3.0))
            spark.position = position
            spark.fillColor = SKColor(red: 1.0, green: 0.7, blue: 0.2, alpha: 1.0)
            spark.strokeColor = .clear
            spark.zPosition = 36
            scene.addChild(spark)
            
            let spread = angle + CGFloat.random(in: -0.4...0.4)
            let dist = CGFloat.random(in: 25...55)
            let move = SKAction.moveBy(x: cos(spread) * dist, y: sin(spread) * dist, duration: 0.08)
            let fadeSpark = SKAction.fadeOut(withDuration: 0.08)
            spark.run(SKAction.sequence([SKAction.group([move, fadeSpark]), SKAction.removeFromParent()]))
        }
    }
    
    // Giclées de sang avec flaques permanentes
    static func createBloodSplat(at position: CGPoint, in scene: SKNode) {
        let particleCount = 10
        for _ in 0..<particleCount {
            let size = CGFloat.random(in: 3.5...8.0)
            let blood = SKShapeNode(circleOfRadius: size)
            blood.position = position
            blood.fillColor = SKColor(red: CGFloat.random(in: 0.55...0.85), green: 0.02, blue: 0.02, alpha: 0.9)
            blood.strokeColor = .clear
            blood.zPosition = 5
            scene.addChild(blood)
            
            let angle = CGFloat.random(in: 0...(CGFloat.pi * 2))
            let dist = CGFloat.random(in: 20...95)
            let move = SKAction.moveBy(x: cos(angle) * dist, y: sin(angle) * dist, duration: 0.16)
            move.timingMode = .easeOut
            
            // Les éclaboussures restent au sol comme une scène de crime
            let fade = SKAction.fadeAlpha(to: 0.35, duration: 8.0)
            blood.run(SKAction.sequence([move, fade]))
        }
    }
    
    // Déflagration d'explosion volumétrique
    static func createExplosion(at position: CGPoint, in scene: SKNode) {
        let shockwave = SKShapeNode(circleOfRadius: 15)
        shockwave.position = position
        shockwave.strokeColor = SKColor(red: 1.0, green: 0.45, blue: 0.1, alpha: 1.0)
        shockwave.glowWidth = 14
        shockwave.lineWidth = 4
        shockwave.zPosition = 40
        scene.addChild(shockwave)
        
        let expand = SKAction.scale(to: 7.5, duration: 0.3)
        let fade = SKAction.fadeOut(withDuration: 0.3)
        shockwave.run(SKAction.group([expand, fade])) {
            shockwave.removeFromParent()
        }
        
        // Morceaux de débris
        for _ in 0..<8 {
            let debris = SKShapeNode(rectOf: CGSize(width: 6, height: 6))
            debris.position = position
            debris.fillColor = SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
            debris.strokeColor = .black
            debris.zPosition = 39
            scene.addChild(debris)
            
            let angle = CGFloat.random(in: 0...(CGFloat.pi * 2))
            let dist = CGFloat.random(in: 50...140)
            let rot = CGFloat.random(in: -3.0...3.0)
            let move = SKAction.moveBy(x: cos(angle) * dist, y: sin(angle) * dist, duration: 0.35)
            move.timingMode = .easeOut
            let rotate = SKAction.rotate(byAngle: rot, duration: 0.35)
            let fadeDebris = SKAction.fadeOut(withDuration: 0.35)
            debris.run(SKAction.sequence([SKAction.group([move, rotate, fadeDebris]), SKAction.removeFromParent()]))
        }
    }
}
