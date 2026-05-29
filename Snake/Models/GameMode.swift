import Foundation

enum GameMode: String, CaseIterable, Identifiable, Codable {
    case classic
    case noWalls
    case speed
    case obstacles
    case zen
    case challenge
    
    var id: String { self.rawValue }
    
    var name: String {
        switch self {
        case .classic: return "Classic"
        case .noWalls: return "No Walls"
        case .speed: return "Speed Dash"
        case .obstacles: return "Obstacles"
        case .zen: return "Zen Mode"
        case .challenge: return "Time Attack"
        }
    }
    
    var description: String {
        switch self {
        case .classic:
            return "Classic snake rules. Avoid colliding with walls and your own tail."
        case .noWalls:
            return "The walls are portals. Wrap around screen edges safely."
        case .speed:
            return "Hold on tight! Snake speeds up after eating food."
        case .obstacles:
            return "Navigate a shifting maze of random obstacles that grow with your score."
        case .zen:
            return "Relaxed mode with slower speeds, portal walls, and no pressure."
        case .challenge:
            return "60-second timed race. Get as many points as you can before time runs out!"
        }
    }
    
    var iconName: String {
        switch self {
        case .classic: return "play.fill"
        case .noWalls: return "arrow.up.and.down.and.arrow.left.and.right"
        case .speed: return "bolt.fill"
        case .obstacles: return "shield.fill"
        case .zen: return "leaf.fill"
        case .challenge: return "timer"
        }
    }
}
