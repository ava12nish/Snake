import SwiftUI

struct GameView: View {
    @ObservedObject var viewModel: GameViewModel
    var onQuit: () -> Void
    
    @State private var showQuitConfirmation = false
    
    var body: some View {
        ZStack {
            // Dark Board background
            viewModel.currentTheme.boardColor
                .ignoresSafeArea()
            
            VStack(spacing: 8) {
                // MARK: - HUD Header
                HStack(alignment: .center) {
                    // Quit/Back Button
                    Button(action: {
                        HapticsService.shared.buttonPressed()
                        viewModel.pauseGame()
                        showQuitConfirmation = true
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // Scores & Mode Info
                    VStack(spacing: 2) {
                        Text(viewModel.currentMode.name.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(viewModel.currentTheme.secondaryColor)
                        
                        HStack(spacing: 8) {
                            Text("SCORE: \(viewModel.score)")
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("•")
                                .foregroundColor(.white.opacity(0.3))
                            
                            Text("BEST: \(viewModel.stats.highScore(for: viewModel.currentMode, difficulty: viewModel.currentDifficulty))")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                    
                    // Pause Button
                    Button(action: {
                        HapticsService.shared.buttonPressed()
                        if viewModel.status == .playing {
                            viewModel.pauseGame()
                        } else if viewModel.status == .paused {
                            viewModel.resumeGame()
                        }
                    }) {
                        Image(systemName: viewModel.status == .paused ? "play.fill" : "pause.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // MARK: - Challenge mode timer & Combo multiplier indicators
                HStack(spacing: 16) {
                    if viewModel.currentMode == .challenge {
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                                .foregroundColor(viewModel.currentTheme.primaryColor)
                            Text(String(format: "%.1fs", viewModel.remainingTime))
                                .font(.system(size: 15, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .glassStyle(cornerRadius: 10, opacity: 0.1)
                    }
                    
                    // Combo Multiplier HUD
                    if viewModel.comboMultiplier > 1 {
                        HStack(spacing: 6) {
                            Text("\(viewModel.comboMultiplier)x COMBO")
                                .font(.system(size: 12, weight: .black, design: .monospaced))
                                .foregroundColor(viewModel.currentTheme.primaryColor)
                            
                            // Glowing Progress bar for decay
                            GeometryReader { progressGeo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.white.opacity(0.1))
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(viewModel.currentTheme.primaryColor)
                                        .frame(width: progressGeo.size.width * CGFloat(viewModel.comboProgress))
                                        .shadow(color: viewModel.currentTheme.primaryColor.opacity(0.6), radius: 4)
                                }
                            }
                            .frame(width: 60, height: 6)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .glassStyle(cornerRadius: 10, opacity: 0.1)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: 32)
                .animation(.spring(), value: viewModel.comboMultiplier)
                
                Spacer(minLength: 0)
                
                // MARK: - Game Board
                GameBoardView(viewModel: viewModel)
                    .padding(.horizontal, 12)
                    .contentShape(Rectangle())
                    // Swipe gesture detector
                    .gesture(
                        DragGesture(minimumDistance: 18)
                            .onEnded { value in
                                let horizontal = value.translation.width
                                let vertical = value.translation.height
                                
                                if abs(horizontal) > abs(vertical) {
                                    // Swipe horizontal
                                    if horizontal > 0 {
                                        viewModel.changeDirection(to: .right)
                                    } else {
                                        viewModel.changeDirection(to: .left)
                                    }
                                } else {
                                    // Swipe vertical
                                    if vertical > 0 {
                                        viewModel.changeDirection(to: .down)
                                    } else {
                                        viewModel.changeDirection(to: .up)
                                    }
                                }
                            }
                    )
                
                Spacer(minLength: 0)
                
                // MARK: - D-Pad Controllers (If enabled)
                if viewModel.showOnScreenControls {
                    DirectionalPad(
                        activeTheme: viewModel.currentTheme,
                        onDirectionChange: { dir in
                            viewModel.changeDirection(to: dir)
                        },
                        currentDirection: viewModel.direction
                    )
                    .padding(.bottom, 12)
                } else {
                    // Small instructions text
                    Text("Swipe anywhere on the board to turn")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.bottom, 24)
                }
            }
            
            // MARK: - Pause Overlay
            if viewModel.status == .paused {
                VisualEffectBlur(style: .dark)
                    .ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 24) {
                            Text("GAME PAUSED")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: viewModel.currentTheme.primaryColor.opacity(0.4), radius: 8)
                            
                            VStack(spacing: 12) {
                                Button(action: {
                                    HapticsService.shared.buttonPressed()
                                    viewModel.resumeGame()
                                }) {
                                    menuOverlayButton(title: "RESUME", color: viewModel.currentTheme.primaryColor)
                                }
                                
                                Button(action: {
                                    HapticsService.shared.buttonPressed()
                                    viewModel.startNewGame(mode: viewModel.currentMode, difficulty: viewModel.currentDifficulty)
                                }) {
                                    menuOverlayButton(title: "RESTART", color: .white)
                                }
                                
                                Button(action: {
                                    HapticsService.shared.buttonPressed()
                                    onQuit()
                                }) {
                                    menuOverlayButton(title: "QUIT TO MENU", color: .red)
                                }
                            }
                            .padding(.horizontal, 48)
                        }
                    )
                    .transition(.opacity)
            }
            
            // MARK: - Countdown Overlay
            if case let .countdown(seconds) = viewModel.status {
                ZStack {
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                    
                    Text(seconds > 0 ? "\(seconds)" : "GO!")
                        .font(.system(size: 120, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(color: viewModel.currentTheme.primaryColor.opacity(0.8), radius: 25)
                        .scaleEffect(1.0)
                        .transition(.scale.combined(with: .opacity))
                        .id("countdown_\(seconds)")
                        .animation(.spring(response: 0.4, dampingFraction: 0.5), value: seconds)
                }
            }
            
            // MARK: - Game Over Overlay
            if viewModel.status == .gameOver {
                let isHighScore = viewModel.score >= viewModel.stats.highScore(for: viewModel.currentMode, difficulty: viewModel.currentDifficulty) && viewModel.score > 0
                
                ZStack {
                    VisualEffectBlur(style: .dark)
                        .ignoresSafeArea()
                    
                    if isHighScore {
                        ConfettiView()
                            .ignoresSafeArea()
                    }
                    
                    VStack(spacing: 28) {
                        VStack(spacing: 6) {
                            Text("GAME OVER")
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .foregroundColor(.red)
                                .shadow(color: Color.red.opacity(0.5), radius: 10)
                            
                            if isHighScore {
                                Text("NEW HIGH SCORE!")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(viewModel.currentTheme.primaryColor)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .glassStyle(cornerRadius: 8, opacity: 0.15, borderColor: viewModel.currentTheme.primaryColor)
                                    .scaleEffect(1.1)
                                    .shadow(color: viewModel.currentTheme.primaryColor.opacity(0.6), radius: 8)
                            }
                        }
                        
                        // Game Over Stats Table
                        VStack(spacing: 16) {
                            statRow(title: "FINAL SCORE", value: "\(viewModel.score)", highlight: true)
                            statRow(title: "BEST SCORE", value: "\(viewModel.stats.highScore(for: viewModel.currentMode, difficulty: viewModel.currentDifficulty))", highlight: false)
                            statRow(title: "MODE", value: viewModel.currentMode.name, highlight: false)
                            statRow(title: "DIFFICULTY", value: viewModel.currentDifficulty.name, highlight: false)
                        }
                        .padding(20)
                        .glassStyle(cornerRadius: 18, opacity: 0.08)
                        .padding(.horizontal, 36)
                        
                        // Action buttons
                        VStack(spacing: 12) {
                            Button(action: {
                                HapticsService.shared.buttonPressed()
                                viewModel.startNewGame(mode: viewModel.currentMode, difficulty: viewModel.currentDifficulty)
                            }) {
                                menuOverlayButton(title: "PLAY AGAIN", color: viewModel.currentTheme.primaryColor)
                            }
                            
                            Button(action: {
                                HapticsService.shared.buttonPressed()
                                onQuit()
                            }) {
                                menuOverlayButton(title: "MAIN MENU", color: .white)
                            }
                        }
                        .padding(.horizontal, 48)
                    }
                }
                .transition(.opacity)
            }
        }
        // Exit warning alert
        .alert("Pause game and exit?", isPresented: $showQuitConfirmation) {
            Button("Exit Game", role: .destructive) {
                viewModel.pauseGame()
                onQuit()
            }
            Button("Cancel", role: .cancel) {
                viewModel.resumeGame()
            }
        } message: {
            Text("Your current score progress will be lost.")
        }
    }
    
    @ViewBuilder
    private func menuOverlayButton(title: String, color: Color) -> some View {
        Text(title)
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundColor(color == .white ? .black : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: color.opacity(0.3), radius: 8, y: 3)
    }
    
    @ViewBuilder
    private func statRow(title: String, value: String, highlight: Bool) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
            
            Spacer()
            
            Text(value)
                .font(.system(size: highlight ? 22 : 16, weight: highlight ? .black : .bold, design: .rounded))
                .foregroundColor(highlight ? viewModel.currentTheme.primaryColor : .white)
        }
    }
}
