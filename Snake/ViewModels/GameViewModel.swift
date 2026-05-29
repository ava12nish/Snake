import SwiftUI
import Combine

@MainActor
class GameViewModel: ObservableObject {
    // MARK: - Game State Properties
    @Published var snake: [Position] = []
    @Published var direction: Direction = .right
    @Published var nextDirections: [Direction] = [] // Buffer to prevent fast swipe double turns
    
    @Published var normalFood: Position = Position(x: 5, y: 5)
    @Published var specialFood: Position? = nil
    @Published var specialFoodTimeRemaining: Int = 0 // Seconds remaining for special food
    @Published var obstacles: [Position] = []
    
    @Published var score: Int = 0
    @Published var comboMultiplier: Int = 1
    @Published var comboProgress: Double = 0.0 // 1.0 to 0.0 decay
    @Published var remainingTime: Double = 60.0 // Challenge mode timer (seconds)
    
    @Published var status: GameStatus = .launch
    @Published var countdownNumber: Int = 3
    
    @Published var currentMode: GameMode = .classic
    @Published var currentDifficulty: Difficulty = .medium
    @Published var currentTheme: Theme = .classicGreen
    
    // Stats & Settings
    @Published var stats: GameStats = GameStats()
    @Published var achievements: [Achievement] = []
    @Published var isSoundEnabled: Bool = true
    @Published var isHapticsEnabled: Bool = true
    @Published var showOnScreenControls: Bool = true
    @Published var showGridLines: Bool = true
    
    // Autoplay mode for background Home screen animations
    var isAutoplay: Bool = false
    
    // MARK: - Grid Configurations
    let columns = 20
    let rows = 25
    
    // MARK: - Internal Engine Properties
    private var gameTimer: Timer?
    private var countdownTimer: Timer?
    private var comboTimer: Timer?
    private var challengeTimer: Timer?
    
    private var lastFoodTime = Date()
    private let comboDuration: TimeInterval = 3.0
    private var specialFoodLifetime: Int = 8
    
    // MARK: - Initializer
    init() {
        loadSettingsAndStats()
    }
    
    // MARK: - Setup & Configuration
    func loadSettingsAndStats() {
        self.stats = StorageService.shared.loadStats()
        self.achievements = StorageService.shared.loadAchievements()
        self.isSoundEnabled = StorageService.shared.isSoundEnabled
        self.isHapticsEnabled = StorageService.shared.isHapticsEnabled
        self.showOnScreenControls = StorageService.shared.showOnScreenControls
        self.currentTheme = StorageService.shared.currentTheme
        self.showGridLines = StorageService.shared.showGridLines
    }
    
    func saveSettings() {
        StorageService.shared.isSoundEnabled = self.isSoundEnabled
        StorageService.shared.isHapticsEnabled = self.isHapticsEnabled
        StorageService.shared.showOnScreenControls = self.showOnScreenControls
        StorageService.shared.currentTheme = self.currentTheme
        StorageService.shared.showGridLines = self.showGridLines
    }
    
    func updateTheme(to theme: Theme) {
        self.currentTheme = theme
        StorageService.shared.currentTheme = theme
    }
    
    func resetAllStats() {
        StorageService.shared.resetStats()
        loadSettingsAndStats()
    }
    
    // MARK: - Game Control Actions
    
    func startNewGame(mode: GameMode, difficulty: Difficulty, isAutoplay: Bool = false) {
        // Stop any running timers
        stopTimers()
        
        self.currentMode = mode
        self.currentDifficulty = difficulty
        self.isAutoplay = isAutoplay
        self.score = 0
        self.comboMultiplier = 1
        self.comboProgress = 0.0
        self.remainingTime = 60.0
        self.specialFood = nil
        self.specialFoodTimeRemaining = 0
        self.nextDirections = []
        
        // Load settings to make sure they are fresh
        if !isAutoplay {
            loadSettingsAndStats()
        }
        
        // Position snake in middle of grid going right
        let startY = rows / 2
        let startLength = isAutoplay ? 4 : difficulty.startingLength
        
        snake = []
        for i in 0..<startLength {
            // e.g. on easy with 3 segments: (10, startY), (9, startY), (8, startY)
            snake.append(Position(x: 10 - i, y: startY))
        }
        direction = .right
        
        // Spawn obstacles if applicable
        setupObstacles()
        
        // Spawn first piece of food
        spawnNormalFood()
        
        if isAutoplay {
            status = .playing
            startGameLoop()
        } else {
            status = .countdown(seconds: 3)
            countdownNumber = 3
            startCountdown()
        }
    }
    
    private func setupObstacles() {
        obstacles = []
        guard currentMode == .obstacles else { return }
        
        // Number of obstacles is determined by difficulty and score (initially 0 score)
        let initialObstacleCount = currentDifficulty.obstacleCount
        addRandomObstacles(count: initialObstacleCount)
    }
    
    private func addRandomObstacles(count: Int) {
        var added = 0
        var attempts = 0
        
        while added < count && attempts < 100 {
            attempts += 1
            let pos = Position(x: Int.random(in: 1..<columns-1), y: Int.random(in: 1..<rows-1))
            
            // Check that it's not spawning on snake, normal food, special food, or existing obstacles
            if !snake.contains(pos) &&
                pos != normalFood &&
                pos != specialFood &&
                !obstacles.contains(pos) &&
                // Keep center of the board relatively clean at startup
                abs(pos.x - 10) > 2 {
                obstacles.append(pos)
                added += 1
            }
        }
    }
    
    private func startCountdown() {
        SoundService.shared.playCountdownTick()
        HapticsService.shared.countdownTick()
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                if self.countdownNumber > 1 {
                    self.countdownNumber -= 1
                    self.status = .countdown(seconds: self.countdownNumber)
                    SoundService.shared.playCountdownTick()
                    HapticsService.shared.countdownTick()
                } else {
                    self.status = .playing
                    self.countdownTimer?.invalidate()
                    self.countdownTimer = nil
                    SoundService.shared.playCountdownStart()
                    self.startGameLoop()
                    
                    if self.currentMode == .challenge {
                        self.startChallengeTimer()
                    }
                }
            }
        }
    }
    
    private func startGameLoop() {
        let speed = getSpeedInterval()
        gameTimer = Timer.scheduledTimer(withTimeInterval: speed, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.gameTick()
            }
        }
        
        // Combo decay timer
        comboTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.updateComboDecay()
            }
        }
    }
    
    private func startChallengeTimer() {
        challengeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                if self.remainingTime > 0 {
                    self.remainingTime -= 0.1
                } else {
                    self.remainingTime = 0
                    self.triggerGameOver()
                }
            }
        }
    }
    
    func pauseGame() {
        guard status == .playing && !isAutoplay else { return }
        status = .paused
        gameTimer?.invalidate()
        gameTimer = nil
        comboTimer?.invalidate()
        comboTimer = nil
        challengeTimer?.invalidate()
        challengeTimer = nil
        SoundService.shared.playPauseSound()
    }
    
    func resumeGame() {
        guard status == .paused && !isAutoplay else { return }
        status = .playing
        startGameLoop()
        if currentMode == .challenge {
            startChallengeTimer()
        }
        SoundService.shared.playResumeSound()
    }
    
    func changeDirection(to newDirection: Direction) {
        guard status == .playing else { return }
        
        // Prevent registering a move in the same frame that is opposite to current or immediately scheduled
        let activeDirection = nextDirections.last ?? direction
        if !newDirection.isOpposite(to: activeDirection) && newDirection != activeDirection {
            // Buffer the direction changes up to 3 frames to allow fluid fast control
            if nextDirections.count < 3 {
                nextDirections.append(newDirection)
            }
        }
    }
    
    // MARK: - Game Loop Core Tick
    
    private func gameTick() {
        // 1. Process direction from buffer
        if !nextDirections.isEmpty {
            direction = nextDirections.removeFirst()
        }
        
        // If background autoplay, overwrite direction with AI choice
        if isAutoplay {
            runBackgroundAI()
        }
        
        // 2. Calculate next head position
        guard let head = snake.first else { return }
        var nextHead = head
        
        switch direction {
        case .up: nextHead.y -= 1
        case .down: nextHead.y += 1
        case .left: nextHead.x -= 1
        case .right: nextHead.x += 1
        }
        
        // 3. Handle Wall collision based on mode
        let hitsWall = nextHead.x < 0 || nextHead.x >= columns || nextHead.y < 0 || nextHead.y >= rows
        
        if hitsWall {
            if currentMode == .noWalls || currentMode == .zen || isAutoplay {
                // Wrap around edges
                if nextHead.x < 0 { nextHead.x = columns - 1 }
                else if nextHead.x >= columns { nextHead.x = 0 }
                
                if nextHead.y < 0 { nextHead.y = rows - 1 }
                else if nextHead.y >= rows { nextHead.y = 0 }
            } else {
                // Classic wall death
                HapticsService.shared.collisionOccurred()
                SoundService.shared.playCollisionSound()
                triggerGameOver()
                return
            }
        }
        
        // 4. Handle Self Collision (except if length is 2, shouldn't occur)
        // Self-collision only triggers if nextHead lands on any of the snake segments (excluding tail end if it moves, but we calculate it including all body positions except tail if not eating)
        let isEatingNormal = nextHead == normalFood
        let isEatingSpecial = specialFood != nil && nextHead == specialFood
        let isEating = isEatingNormal || isEatingSpecial
        
        var bodyToCheck = snake
        if !isEating {
            bodyToCheck.removeLast()
        }
        
        if bodyToCheck.contains(nextHead) {
            if !isAutoplay {
                HapticsService.shared.collisionOccurred()
                SoundService.shared.playCollisionSound()
                triggerGameOver()
            } else {
                // AI died or collided, just restart immediately to keep home screen alive
                startNewGame(mode: currentMode, difficulty: currentDifficulty, isAutoplay: true)
            }
            return
        }
        
        // 5. Handle Obstacle collision
        if currentMode == .obstacles && obstacles.contains(nextHead) {
            HapticsService.shared.collisionOccurred()
            SoundService.shared.playCollisionSound()
            triggerGameOver()
            return
        }
        
        // 6. Move the snake head
        snake.insert(nextHead, at: 0)
        
        // 7. Handle eating food
        if isEating {
            // Play haptic & sound
            if isEatingSpecial {
                HapticsService.shared.specialFoodEaten()
                SoundService.shared.playSpecialFoodSound()
                
                let basePoints = 5
                let comboPoints = basePoints * comboMultiplier
                score += comboPoints
                stats.totalFoodEaten += 1
                
                specialFood = nil
                specialFoodTimeRemaining = 0
            } else {
                HapticsService.shared.foodEaten()
                
                let basePoints = 1
                let comboPoints = basePoints * comboMultiplier
                score += comboPoints
                stats.totalFoodEaten += 1
                
                // Keep track of combo multiplier
                triggerComboMultiplier()
                
                // Spawn new food
                spawnNormalFood()
                
                // Clean up / update obstacles if in obstacles mode
                if currentMode == .obstacles {
                    // Spawn another obstacle every 3 points
                    if score % 3 == 0 {
                        addRandomObstacles(count: 1)
                    }
                }
                
                // Speed Mode speed adjustment (realtime timer reset)
                if currentMode == .speed && score % 4 == 0 {
                    // Update timer frequency dynamically
                    gameTimer?.invalidate()
                    startGameLoop()
                }
                
                // Roll for special food spawn (12% chance if not already active)
                if specialFood == nil && Int.random(in: 1...100) <= 12 {
                    spawnSpecialFood()
                }
            }
            
            // Check achievement requirements
            checkAchievements()
        } else {
            // Just move, remove tail segment
            snake.removeLast()
        }
        
        // 8. Update Special food countdown
        if specialFood != nil {
            specialFoodTimeRemaining -= 1
            if specialFoodTimeRemaining <= 0 {
                specialFood = nil
            }
        }
    }
    
    // MARK: - Game Autoplay AI
    
    private func runBackgroundAI() {
        // Direct greedy pathfinding with simple obstacle avoidance
        guard let head = snake.first else { return }
        
        let target = specialFood ?? normalFood
        
        // Find list of candidate directions
        var candidates: [(Direction, Double)] = [] // (direction, distance to target)
        
        for dir in Direction.allCases {
            // Prevent immediate backwards movement
            if dir.isOpposite(to: direction) { continue }
            
            // Calculate next position for this direction
            var nextPos = head
            switch dir {
            case .up: nextPos.y -= 1
            case .down: nextPos.y += 1
            case .left: nextPos.x -= 1
            case .right: nextPos.x += 1
            }
            
            // Portals wrap for AI
            if nextPos.x < 0 { nextPos.x = columns - 1 }
            else if nextPos.x >= columns { nextPos.x = 0 }
            
            if nextPos.y < 0 { nextPos.y = rows - 1 }
            else if nextPos.y >= rows { nextPos.y = 0 }
            
            // Check collision with obstacles and snake body (excluding tail segment if moving)
            let willCollideBody = snake.contains(nextPos)
            let willCollideObstacle = currentMode == .obstacles && obstacles.contains(nextPos)
            
            if !willCollideBody && !willCollideObstacle {
                // Calculate distance to target
                let dx = Double(nextPos.x - target.x)
                let dy = Double(nextPos.y - target.y)
                let dist = dx*dx + dy*dy
                candidates.append((dir, dist))
            }
        }
        
        // If we have candidates, pick the one that gets us closest to food
        if !candidates.isEmpty {
            candidates.sort(by: { $0.1 < $1.1 })
            direction = candidates[0].0
        }
    }
    
    // MARK: - Helper Methods
    
    private func getSpeedInterval() -> Double {
        var base = currentDifficulty.baseSpeed
        
        if currentMode == .zen {
            base = base * 1.5 // Relaxed / 50% slower
        } else if currentMode == .speed {
            // Speed increases by 8% every 4 points scored, capped at 60% speed increase
            let speedUps = min(score / 4, 8)
            base = base * pow(0.92, Double(speedUps))
        }
        
        return max(base, 0.04) // Safety cap
    }
    
    private func spawnNormalFood() {
        var attempts = 0
        while attempts < 300 {
            attempts += 1
            let pos = Position(x: Int.random(in: 0..<columns), y: Int.random(in: 0..<rows))
            if !snake.contains(pos) && !obstacles.contains(pos) && (specialFood == nil || pos != specialFood) {
                normalFood = pos
                return
            }
        }
    }
    
    private func spawnSpecialFood() {
        var attempts = 0
        while attempts < 300 {
            attempts += 1
            let pos = Position(x: Int.random(in: 0..<columns), y: Int.random(in: 0..<rows))
            if !snake.contains(pos) && !obstacles.contains(pos) && pos != normalFood {
                specialFood = pos
                specialFoodTimeRemaining = specialFoodLifetime
                return
            }
        }
    }
    
    private func triggerComboMultiplier() {
        let now = Date()
        let interval = now.timeIntervalSince(lastFoodTime)
        lastFoodTime = now
        
        if interval <= comboDuration {
            // Increase combo up to 5x
            comboMultiplier = min(comboMultiplier + 1, 5)
            if comboMultiplier == 5 {
                HapticsService.shared.comboTriggered()
            }
        } else {
            comboMultiplier = 1
        }
        
        // Reset progress bar to full
        comboProgress = 1.0
    }
    
    private func updateComboDecay() {
        guard status == .playing else { return }
        
        let elapsed = Date().timeIntervalSince(lastFoodTime)
        if elapsed < comboDuration {
            comboProgress = 1.0 - (elapsed / comboDuration)
        } else {
            comboProgress = 0.0
            comboMultiplier = 1
        }
    }
    
    private func triggerGameOver() {
        status = .gameOver
        stopTimers()
        
        guard !isAutoplay else { return }
        
        // Update stats
        stats.totalGamesPlayed += 1
        if snake.count > stats.longestSnakeLength {
            stats.longestSnakeLength = snake.count
        }
        
        // Update total play time (approximate since we only track finished game, or could add session time)
        // Hardcode a generic average run length based on score or just a fixed value for simplicity
        let gameDuration = Date().timeIntervalSince(lastFoodTime) // approximate
        stats.totalPlayTime += gameDuration
        
        // Save High Score
        let newRecord = stats.updateHighScore(
            for: currentMode,
            difficulty: currentDifficulty,
            score: score
        )
        
        // Write to storage
        StorageService.shared.saveStats(stats)
        
        // Final achievement check
        checkEndGameAchievements(isNewRecord: newRecord)
    }
    
    private func stopTimers() {
        gameTimer?.invalidate()
        gameTimer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
        comboTimer?.invalidate()
        comboTimer = nil
        challengeTimer?.invalidate()
        challengeTimer = nil
    }
    
    // MARK: - Achievements System Integration
    
    private func checkAchievements() {
        guard !isAutoplay else { return }
        
        // 1. First bite
        if score >= 1 {
            unlockNotification(id: "first_bite")
        }
        
        // 2. Length 15
        if snake.count >= 15 {
            unlockNotification(id: "length_15")
        }
        
        // 3. Centipede (Score 50)
        if score >= 50 {
            unlockNotification(id: "score_50")
        }
        
        // 4. Speed Demon (Score 30 in Speed Dash)
        if currentMode == .speed && score >= 30 {
            unlockNotification(id: "speed_dash_30")
        }
        
        // 5. Maze Runner (Score 30 in Obstacles)
        if currentMode == .obstacles && score >= 30 {
            unlockNotification(id: "obstacles_30")
        }
        
        // 6. Zen Master (Score 100 in Zen Mode)
        if currentMode == .zen && score >= 100 {
            unlockNotification(id: "zen_100")
        }
        
        // 7. Elite Reflexes (Score 30 in Hard/Insane)
        if (currentDifficulty == .hard || currentDifficulty == .insane) && score >= 30 {
            unlockNotification(id: "hard_insane_30")
        }
        
        // 8. Combo King (5x Combo)
        if comboMultiplier >= 5 {
            unlockNotification(id: "combo_5x")
        }
        
        // 9. Time Lord (Challenge 40 score)
        if currentMode == .challenge && score >= 40 {
            unlockNotification(id: "challenge_40")
        }
    }
    
    private func checkEndGameAchievements(isNewRecord: Bool) {
        // Triggered after game over
        checkAchievements()
    }
    
    private func unlockNotification(id: String) {
        if let unlocked = StorageService.shared.unlockAchievement(withId: id) {
            // Update local list
            self.achievements = StorageService.shared.loadAchievements()
            SoundService.shared.playAchievementSound()
            
            // We can post a notification or toast here if we want!
            print("UNLOCKED ACHIEVEMENT: \(unlocked.title)")
        }
    }
}

// MARK: - Game Status Enum
enum GameStatus: Equatable {
    case launch
    case countdown(seconds: Int)
    case playing
    case paused
    case gameOver
}
