import SwiftUI

struct ModeSelectionView: View {
    @ObservedObject var viewModel: GameViewModel
    var onBack: () -> Void
    var onStartGame: (GameMode, Difficulty) -> Void
    
    @State private var selectedMode: GameMode = .classic
    @State private var selectedDifficulty: Difficulty = .medium
    
    var body: some View {
        ZStack {
            // Dark premium background matching default aesthetics
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
                    
                    Text("Select Mode")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Spacer to align title
                    Color.clear
                        .frame(width: 80, height: 35)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // Difficulty Segmented Control
                VStack(alignment: .leading, spacing: 8) {
                    Text("DIFFICULTY")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(viewModel.currentTheme.primaryColor)
                        .padding(.horizontal, 24)
                    
                    HStack(spacing: 6) {
                        ForEach(Difficulty.allCases) { diff in
                            Button(action: {
                                HapticsService.shared.playSelection()
                                selectedDifficulty = diff
                            }) {
                                VStack(spacing: 4) {
                                    Text(diff.name)
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                    Text("\(Int(diff.pointMultiplier))x Pts")
                                        .font(.system(size: 9, weight: .regular))
                                        .opacity(0.6)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedDifficulty == diff ? viewModel.currentTheme.primaryColor : Color.white.opacity(0.04))
                                )
                                .foregroundColor(selectedDifficulty == diff ? viewModel.currentTheme.boardColor : .white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedDifficulty == diff ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // Difficulty Description
                    Text(selectedDifficulty.description)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 24)
                        .padding(.top, 4)
                }
                .padding(.vertical, 16)
                
                // Scrollable Cards List of GameModes
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(GameMode.allCases) { mode in
                            let isSelected = selectedMode == mode
                            let highScore = viewModel.stats.highScore(for: mode, difficulty: selectedDifficulty)
                            
                            Button(action: {
                                HapticsService.shared.playSelection()
                                selectedMode = mode
                            }) {
                                HStack(spacing: 16) {
                                    // Mode Icon
                                    ZStack {
                                        Circle()
                                            .fill(isSelected ? viewModel.currentTheme.primaryColor.opacity(0.15) : Color.white.opacity(0.05))
                                            .frame(width: 48, height: 48)
                                        
                                        Image(systemName: mode.iconName)
                                            .font(.title3)
                                            .foregroundColor(isSelected ? viewModel.currentTheme.primaryColor : .white)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(mode.name)
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                        
                                        Text(mode.description)
                                            .font(.system(size: 12, weight: .regular))
                                            .foregroundColor(.white.opacity(0.6))
                                            .multilineTextAlignment(.leading)
                                            .lineLimit(2)
                                    }
                                    
                                    Spacer()
                                    
                                    // High Score badge
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("BEST")
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                            .foregroundColor(viewModel.currentTheme.secondaryColor)
                                        
                                        Text("\(highScore)")
                                            .font(.system(size: 18, weight: .black, design: .rounded))
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding(16)
                                .glassStyle(
                                    cornerRadius: 20,
                                    opacity: isSelected ? 0.12 : 0.04,
                                    borderColor: isSelected ? viewModel.currentTheme.primaryColor : Color.white.opacity(0.1)
                                )
                                .scaleEffect(isSelected ? 1.01 : 1.0)
                                .shadow(color: isSelected ? viewModel.currentTheme.primaryColor.opacity(0.15) : Color.clear, radius: 8)
                                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                
                // Play Action Area
                VStack {
                    Button(action: {
                        HapticsService.shared.buttonPressed()
                        onStartGame(selectedMode, selectedDifficulty)
                    }) {
                        Text("START GAME")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundColor(viewModel.currentTheme.boardColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(viewModel.currentTheme.primaryColor)
                            .cornerRadius(16)
                            .shadow(color: viewModel.currentTheme.primaryColor.opacity(0.4), radius: 12, x: 0, y: 6)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 24)
                    }
                }
                .glassStyle(cornerRadius: 0, opacity: 0.1, borderColor: .clear)
            }
        }
    }
}
