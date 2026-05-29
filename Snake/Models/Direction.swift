import Foundation

enum Direction: String, Codable, CaseIterable {
    case up
    case down
    case left
    case right
    
    func isOpposite(to other: Direction) -> Bool {
        switch (self, other) {
        case (.up, .down), (.down, .up):
            return true
        case (.left, .right), (.right, .left):
            return true
        default:
            return false
        }
    }
}
