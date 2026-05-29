import Foundation

@MainActor
class StorageService {
    static let shared = StorageService()
    
    private let statsKey = "com.avanish.snake.stats"
    private let achievementsKey = "com.avanish.snake.achievements"
    private let soundEnabledKey = "com.avanish.snake.soundEnabled"
    private let hapticsEnabledKey = "com.avanish.snake.hapticsEnabled"
    private let showControlsKey = "com.avanish.snake.showControls"
    private let themeKey = "com.avanish.snake.theme"
    private let customSnakeColorKey = "com.avanish.snake.customSnakeColor"
    private let showGridLinesKey = "com.avanish.snake.showGridLines"
    
    private init() {}
    
    // MARK: - App Settings
    var isSoundEnabled: Bool {
        get { UserDefaults.standard.object(forKey: soundEnabledKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: soundEnabledKey) }
    }
    
    var isHapticsEnabled: Bool {
        get { UserDefaults.standard.object(forKey: hapticsEnabledKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: hapticsEnabledKey) }
    }
    
    var showOnScreenControls: Bool {
        get { UserDefaults.standard.object(forKey: showControlsKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: showControlsKey) }
    }
    
    var currentTheme: Theme {
        get {
            if let rawValue = UserDefaults.standard.string(forKey: themeKey),
               let theme = Theme(rawValue: rawValue) {
                return theme
            }
            return .classicGreen
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: themeKey) }
    }
    
    var customSnakeColorHex: String? {
        get { UserDefaults.standard.string(forKey: customSnakeColorKey) }
        set { UserDefaults.standard.set(newValue, forKey: customSnakeColorKey) }
    }
    
    var showGridLines: Bool {
        get { UserDefaults.standard.object(forKey: showGridLinesKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: showGridLinesKey) }
    }
    
    // MARK: - Game Statistics
    func loadStats() -> GameStats {
        guard let data = UserDefaults.standard.data(forKey: statsKey) else {
            return GameStats()
        }
        do {
            return try JSONDecoder().decode(GameStats.self, from: data)
        } catch {
            print("Failed to decode stats: \(error)")
            return GameStats()
        }
    }
    
    func saveStats(_ stats: GameStats) {
        do {
            let data = try JSONEncoder().encode(stats)
            UserDefaults.standard.set(data, forKey: statsKey)
        } catch {
            print("Failed to encode stats: \(error)")
        }
    }
    
    func resetStats() {
        saveStats(GameStats())
        saveAchievements(Achievement.defaultAchievements)
    }
    
    // MARK: - Achievements
    func loadAchievements() -> [Achievement] {
        guard let data = UserDefaults.standard.data(forKey: achievementsKey) else {
            return Achievement.defaultAchievements
        }
        do {
            return try JSONDecoder().decode([Achievement].self, from: data)
        } catch {
            print("Failed to decode achievements: \(error)")
            return Achievement.defaultAchievements
        }
    }
    
    func saveAchievements(_ achievements: [Achievement]) {
        do {
            let data = try JSONEncoder().encode(achievements)
            UserDefaults.standard.set(data, forKey: achievementsKey)
        } catch {
            print("Failed to encode achievements: \(error)")
        }
    }
    
    func unlockAchievement(withId id: String) -> Achievement? {
        var achievements = loadAchievements()
        if let index = achievements.firstIndex(where: { $0.id == id }) {
            if !achievements[index].isUnlocked {
                achievements[index].isUnlocked = true
                achievements[index].unlockedAt = Date()
                saveAchievements(achievements)
                return achievements[index]
            }
        }
        return nil
    }
}
