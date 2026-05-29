import Foundation

struct Achievement: Identifiable, Codable, Equatable {
    var id: String
    var title: String
    var description: String
    var isUnlocked: Bool
    var unlockedAt: Date?
    var iconName: String
    
    static var defaultAchievements: [Achievement] {
        [
            Achievement(id: "first_bite", title: "First Bite", description: "Eat your very first piece of food", isUnlocked: false, unlockedAt: nil, iconName: "mouth.fill"),
            Achievement(id: "length_15", title: "Long Tail", description: "Reach a snake length of 15", isUnlocked: false, unlockedAt: nil, iconName: "arrow.left.and.right"),
            Achievement(id: "score_50", title: "Centipede", description: "Achieve a score of 50 in any game mode", isUnlocked: false, unlockedAt: nil, iconName: "crown.fill"),
            Achievement(id: "speed_dash_30", title: "Speed Demon", description: "Achieve a score of 30 in Speed Dash mode", isUnlocked: false, unlockedAt: nil, iconName: "bolt.fill"),
            Achievement(id: "obstacles_30", title: "Maze Runner", description: "Achieve a score of 30 in Obstacles mode", isUnlocked: false, unlockedAt: nil, iconName: "square.grid.3x3.fill"),
            Achievement(id: "zen_100", title: "Zen Master", description: "Reach 100 points in Zen Mode with no rush", isUnlocked: false, unlockedAt: nil, iconName: "leaf.fill"),
            Achievement(id: "hard_insane_30", title: "Elite Reflexes", description: "Score 30 points on Hard or Insane difficulty", isUnlocked: false, unlockedAt: nil, iconName: "flame.fill"),
            Achievement(id: "combo_5x", title: "Combo King", description: "Reach a 5x speed combo multiplier", isUnlocked: false, unlockedAt: nil, iconName: "bolt.heart.fill"),
            Achievement(id: "challenge_40", title: "Time Lord", description: "Score 40 points in Challenge mode", isUnlocked: false, unlockedAt: nil, iconName: "timer")
        ]
    }
}
