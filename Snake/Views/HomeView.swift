import SwiftUI

struct HomeView: View {
    @StateObject private var bgViewModel = GameViewModel()
    @ObservedObject var mainViewModel: GameViewModel
    var onNavigate: (ActiveScreen) -> Void
    
    var body: some View {
        ZStack {
            // 1. Live Autoplay Snake Background
            GameBoardView(viewModel: bgViewModel)
                .opacity(0.18)
                .blur(radius: 2.0)
                .scaleEffect(1.1)
                .ignoresSafeArea()
                .onAppear {
                    bgViewModel.startNewGame(mode: .classic, difficulty: .easy, isAutoplay: true)
                }
                .onDisappear {
                    bgViewModel.pauseGame()
                }
            
            // Subtle dark overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // 2. Main Title and Navigation Menu
            VStack(spacing: 40) {
                Spacer()
                
                // Title Area
                VStack(spacing: 8) {
                    // Logo Image Placeholder Vibe or Icon
                    ZStack {
                        Circle()
                            .fill(mainViewModel.currentTheme.primaryColor.opacity(0.15))
                            .frame(width: 90, height: 90)
                            .overlay(
                                Circle()
                                    .stroke(mainViewModel.currentTheme.primaryColor.opacity(0.4), lineWidth: 2)
                            )
                        
                        Image(systemName: "crown.fill")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(mainViewModel.currentTheme.primaryColor)
                            .shadow(color: mainViewModel.currentTheme.primaryColor.opacity(0.6), radius: 10)
                    }
                    
                    Text("S N A K E")
                        .font(.system(size: 48, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(color: mainViewModel.currentTheme.primaryColor.opacity(0.5), radius: 15)
                    
                    Text("THE ULTIMATE ARCADE")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(mainViewModel.currentTheme.secondaryColor)
                        .tracking(4)
                }
                
                Spacer()
                
                // Menu Buttons
                VStack(spacing: 16) {
                    menuButton(
                        title: "QUICK PLAY",
                        subtitle: "Classic Rules, Medium Speed",
                        icon: "play.fill",
                        color: mainViewModel.currentTheme.primaryColor
                    ) {
                        mainViewModel.startNewGame(mode: .classic, difficulty: .medium)
                        onNavigate(.game(mode: .classic, difficulty: .medium))
                    }
                    
                    menuButton(
                        title: "ARCADE MODES",
                        subtitle: "6 Unique Game Modes",
                        icon: "gamecontroller.fill",
                        color: .white
                    ) {
                        onNavigate(.modeSelection)
                    }
                    
                    HStack(spacing: 16) {
                        menuButton(
                            title: "STATS",
                            subtitle: "Trophies & Logs",
                            icon: "chart.bar.fill",
                            color: .white,
                            halfWidth: true
                        ) {
                            onNavigate(.stats)
                        }
                        
                        menuButton(
                            title: "SETTINGS",
                            subtitle: "Themes & Controls",
                            icon: "gearshape.fill",
                            color: .white,
                            halfWidth: true
                        ) {
                            onNavigate(.settings)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    @ViewBuilder
    private func menuButton(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        halfWidth: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            HapticsService.shared.buttonPressed()
            action()
        }) {
            HStack(spacing: 16) {
                if !halfWidth {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundColor(color)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                if !halfWidth {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                } else {
                    Image(systemName: icon)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: halfWidth ? .infinity : nil)
            .glassStyle(cornerRadius: 20, opacity: 0.08, borderColor: color.opacity(0.25))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(color.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

enum ActiveScreen: Equatable {
    case home
    case modeSelection
    case game(mode: GameMode, difficulty: Difficulty)
    case stats
    case settings
}
