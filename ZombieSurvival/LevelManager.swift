import Foundation
import CoreGraphics

struct WallData: Codable {
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat
}

struct SpawnerData: Codable {
    var x: CGFloat
    var y: CGFloat
    var interval: TimeInterval
    var zombieType: String
}

struct LevelData: Codable {
    var id: Int
    var title: String
    var targetKills: Int
    var zombieHealthMultiplier: CGFloat
    var zombieSpeedMultiplier: CGFloat
    var walls: [WallData]
    var spawners: [SpawnerData]
    var isCustom: Bool
}

class LevelManager {
    static let shared = LevelManager()
    
    private let customLevelsKey = "ZombieCustomLevelsStorage"
    
    private init() {}
    
    func getLevel(_ number: Int) -> LevelData {
        let customLevels = getCustomLevels()
        if let found = customLevels.first(where: { $0.id == number }) {
            return found
        }
        return generateProceduralLevel(number: max(1, min(100, number)))
    }
    
    private func generateProceduralLevel(number: Int) -> LevelData {
        let diffFactor = CGFloat(number) / 100.0
        let targetKills = 15 + (number * 3)
        let healthMul: CGFloat = 1.0 + (diffFactor * 2.5)
        let speedMul: CGFloat = 1.0 + (diffFactor * 1.2)
        
        var walls: [WallData] = []
        
        let wallCount = 3 + (number % 7)
        for i in 0..<wallCount {
            let wx = CGFloat(300 + ((i * 180) % 750))
            let wy = CGFloat(200 + ((i * 130) % 400))
            let isVertical = (i % 2 == 0)
            walls.append(WallData(
                x: wx,
                y: wy,
                width: isVertical ? 25 : 140,
                height: isVertical ? 140 : 25
            ))
        }
        
        var spawners: [SpawnerData] = []
        let spawnerPositions: [(CGFloat, CGFloat)] = [
            (100, 100), (1234, 100), (100, 650), (1234, 650),
            (667, 700), (667, 50)
        ]
        
        let activeSpawners = min(spawnerPositions.count, 2 + (number / 20))
        let spawnInterval = max(0.9, 3.2 - (Double(number) * 0.022))
        
        for i in 0..<activeSpawners {
            let pos = spawnerPositions[i]
            let type = (number > 15 && i == 0) ? "fast" : (number > 35 && i == 1 ? "tank" : "normal")
            spawners.append(SpawnerData(x: pos.0, y: pos.1, interval: spawnInterval, zombieType: type))
        }
        
        return LevelData(
            id: number,
            title: "Zone d'Infection \(number)",
            targetKills: targetKills,
            zombieHealthMultiplier: healthMul,
            zombieSpeedMultiplier: speedMul,
            walls: walls,
            spawners: spawners,
            isCustom: false
        )
    }
    
    func saveCustomLevel(_ level: LevelData) {
        var levels = getCustomLevels()
        levels.removeAll(where: { $0.id == level.id })
        levels.append(level)
        if let encoded = try? JSONEncoder().encode(levels) {
            UserDefaults.standard.set(encoded, forKey: customLevelsKey)
        }
    }
    
    func getCustomLevels() -> [LevelData] {
        guard let data = UserDefaults.standard.data(forKey: customLevelsKey),
              let list = try? JSONDecoder().decode([LevelData].self, from: data) else {
            return []
        }
        return list
    }
}
