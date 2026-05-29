import SwiftUI

struct StatsView: View {
    @ObservedObject var viewModel: GameViewModel
    var onBack: () -> Void
    
    @State private var selectedTab = 0 // 0: Stats, 1: Achievements
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    viewModel.currentTheme.boardColor.opacity(0.95),
                    Color(hex: "08080C")
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        HapticsService.shared.buttonPressed()
                        onBack()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .bold))
                            Text("Back")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .glassStyle(cornerRadius: 12, opacity: 0.1)
                    }
                    
                    Spacer()
                    
                    Text("Trophies & Logs")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Color.clear
                        .frame(width: 80, height: 35)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 16)
                
                // Tabs Picker
                HStack(spacing: 0) {
                    tabButton(title: "STATISTICS", index: 0)
                    tabButton(title: "ACHIEVEMENTS", index: 1)
                }
                .padding(4)
                .background(Color.white.opacity(0.04))
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                
                // Tab Content
                if selectedTab == 0 {
                    statsTab
                } else {
                    achievementsTab
                }
            }
        }
    }
    
    // MARK: - Tab Button Helper
    @ViewBuilder
    private func tabButton(title: String, index: Int) -> some View {
        let isSelected = selectedTab == index
        Button(action: {
            HapticsService.shared.playSelection()
            selectedTab = index
        }) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(isSelected ? viewModel.currentTheme.boardColor : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? viewModel.currentTheme.primaryColor : Color.clear)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Stats Tab View
    private var statsTab: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // Grid of Overall Stats
                VStack(alignment: .leading, spacing: 12) {
                    Text("OVERALL PROGRESS")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(viewModel.currentTheme.secondaryColor)
                        .padding(.horizontal, 8)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        statCard(title: "GAMES PLAYED", value: "\(viewModel.stats.totalGamesPlayed)", icon: "gamecontroller.fill")
                        statCard(title: "FOOD EATEN", value: "\(viewModel.stats.totalFoodEaten)", icon: "mouth.fill")
                        statCard(title: "LONGEST SNAKE", value: "\(viewModel.stats.longestSnakeLength)", icon: "arrow.left.and.right")
                        statCard(title: "PLAY TIME", value: formatPlayTime(viewModel.stats.totalPlayTime), icon: "clock.fill")
                    }
                }
                
                // Best Scores Table per Mode
                VStack(alignment: .leading, spacing: 12) {
                    Text("BEST SCORES (BY MODE & DIFFICULTY)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(viewModel.currentTheme.secondaryColor)
                        .padding(.horizontal, 8)
                    
                    VStack(spacing: 0) {
                        ForEach(GameMode.allCases, id: \.self) { mode in
                            VStack(spacing: 0) {
                                HStack {
                                    Image(systemName: mode.iconName)
                                        .foregroundColor(viewModel.currentTheme.primaryColor)
                                        .font(.subheadline)
                                        .frame(width: 24)
                                    
                                    Text(mode.name)
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color.white.opacity(0.02))
                                
                                // Show scores for each difficulty
                                HStack(spacing: 0) {
                                    ForEach(Difficulty.allCases, id: \.self) { diff in
                                        let score = viewModel.stats.highScore(for: mode, difficulty: diff)
                                        VStack(spacing: 2) {
                                            Text(diff.name.uppercased())
                                                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                                                .foregroundColor(.white.opacity(0.4))
                                            Text("\(score)")
                                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                                .foregroundColor(score > 0 ? .white : .white.opacity(0.2))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                    }
                                }
                                .padding(.horizontal, 8)
                                
                                Divider()
                                    .background(Color.white.opacity(0.08))
                            }
                        }
                    }
                    .glassStyle(cornerRadius: 18, opacity: 0.04)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }
    
    // MARK: - Achievements Tab View
    private var achievementsTab: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                // Achievements Unlocked Counter
                let unlockedCount = viewModel.achievements.filter({ $0.isUnlocked }).count
                let totalCount = viewModel.achievements.count
                
                HStack {
                    Text("UNLOCKED: \(unlockedCount) / \(totalCount)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(viewModel.currentTheme.primaryColor)
                    
                    Spacer()
                    
                    ProgressView(value: Double(unlockedCount), total: Double(totalCount))
                        .progressViewStyle(LinearProgressViewStyle(tint: viewModel.currentTheme.primaryColor))
                        .frame(width: 120)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
                
                // Achievements List Grid
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.achievements) { achievement in
                        HStack(spacing: 16) {
                            // Badge Icon
                            ZStack {
                                Circle()
                                    .fill(achievement.isUnlocked ? viewModel.currentTheme.primaryColor.opacity(0.15) : Color.white.opacity(0.03))
                                    .frame(width: 52, height: 52)
                                
                                Image(systemName: achievement.isUnlocked ? achievement.iconName : "lock.fill")
                                    .font(.title3)
                                    .foregroundColor(achievement.isUnlocked ? viewModel.currentTheme.primaryColor : .white.opacity(0.2))
                                    .shadow(color: achievement.isUnlocked ? viewModel.currentTheme.primaryColor.opacity(0.5) : Color.clear, radius: 8)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(achievement.title)
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(achievement.isUnlocked ? .white : .white.opacity(0.4))
                                
                                Text(achievement.description)
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            
                            Spacer()
                            
                            if achievement.isUnlocked, let date = achievement.unlockedAt {
                                Text(formatDate(date))
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundColor(viewModel.currentTheme.secondaryColor)
                            }
                        }
                        .padding(14)
                        .glassStyle(
                            cornerRadius: 16,
                            opacity: achievement.isUnlocked ? 0.08 : 0.02,
                            borderColor: achievement.isUnlocked ? viewModel.currentTheme.primaryColor.opacity(0.2) : Color.white.opacity(0.05)
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }
    
    // MARK: - View Helpers
    
    @ViewBuilder
    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(viewModel.currentTheme.primaryColor)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(16)
        .glassStyle(cornerRadius: 18, opacity: 0.05)
    }
    
    private func formatPlayTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        return formatter.string(from: date)
    }
}
