import Foundation

enum Difficulty: String, CaseIterable, Identifiable, Codable {
    case easy
    case medium
    case hard
    case insane
    
    var id: String { self.rawValue }
    
    var name: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .insane: return "Insane"
        }
    }
    
    var baseSpeed: Double {
        switch self {
        case .easy: return 0.20
        case .medium: return 0.14
        case .hard: return 0.09
        case .insane: return 0.055
        }
    }
    
    var startingLength: Int {
        switch self {
        case .easy: return 3
        case .medium: return 4
        case .hard: return 5
        case .insane: return 6
        }
    }
    
    var obstacleCount: Int {
        switch self {
        case .easy: return 3
        case .medium: return 6
        case .hard: return 10
        case .insane: return 15
        }
    }
    
    var pointMultiplier: Double {
        switch self {
        case .easy: return 1.0
        case .medium: return 1.5
        case .hard: return 2.0
        case .insane: return 3.0
        }
    }
    
    var description: String {
        switch self {
        case .easy: return "Chill speed. Great for beginners."
        case .medium: return "Standard speed. Perfect balance."
        case .hard: return "Fast action. Recommends quick reflexes."
        case .insane: return "Lightning speed. Only for true masters."
        }
    }
}
