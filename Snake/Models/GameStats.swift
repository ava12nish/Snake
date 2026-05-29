import Foundation

struct GameStats: Codable, Equatable {
    var totalGamesPlayed: Int = 0
    var totalFoodEaten: Int = 0
    var longestSnakeLength: Int = 0
    var totalPlayTime: TimeInterval = 0 // in seconds
    
    // High scores mapping: GameMode_Difficulty -> Score
    var highScores: [String: Int] = [:]
    
    // Total foods eaten per mode
    var foodEatenPerMode: [String: Int] = [:]
    
    // Overall best score
    var bestScoreOverall: Int {
        highScores.values.max() ?? 0
    }
    
    func highScore(for mode: GameMode, difficulty: Difficulty) -> Int {
        let key = "\(mode.rawValue)_\(difficulty.rawValue)"
        return highScores[key] ?? 0
    }
    
    mutating func updateHighScore(for mode: GameMode, difficulty: Difficulty, score: Int) -> Bool {
        let key = "\(mode.rawValue)_\(difficulty.rawValue)"
        let currentHighScore = highScores[key] ?? 0
        if score > currentHighScore {
            highScores[key] = score
            return true // New high score achieved
        }
        return false
    }
}
