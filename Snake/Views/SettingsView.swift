import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: GameViewModel
    var onBack: () -> Void
    
    @State private var showingResetAlert = false
    
    // Preset colors for the custom snake color override
    let colorPresets = [
        ("34C759", "Green"),
        ("00E5FF", "Cyan"),
        ("FF2D55", "Pink"),
        ("FF9500", "Orange"),
        ("FFCC00", "Gold"),
        ("AF52DE", "Purple"),
        ("FFFFFF", "White")
    ]
    
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
                    
                    Text("Settings")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Color.clear
                        .frame(width: 80, height: 35)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 16)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // MARK: - General Settings
                        VStack(alignment: .leading, spacing: 12) {
                            Text("GAME CONFIGURATION")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(viewModel.currentTheme.primaryColor)
                                .padding(.horizontal, 8)
                            
                            VStack(spacing: 0) {
                                toggleRow(title: "Sound Effects", subtitle: "Retro 8-bit audio blips", systemImage: "speaker.wave.2.fill", isOn: $viewModel.isSoundEnabled)
                                Divider().background(Color.white.opacity(0.08))
                                toggleRow(title: "Tactile Haptics", subtitle: "Feel bites and crashes", systemImage: "waveform.path", isOn: $viewModel.isHapticsEnabled)
                                Divider().background(Color.white.opacity(0.08))
                                toggleRow(title: "On-Screen Controls", subtitle: "Show 4-way D-Pad on board", systemImage: "gamecontroller.fill", isOn: $viewModel.showOnScreenControls)
                                Divider().background(Color.white.opacity(0.08))
                                toggleRow(title: "Grid Board Lines", subtitle: "Faint lines for easier steering", systemImage: "grid", isOn: $viewModel.showGridLines)
                            }
                            .glassStyle(cornerRadius: 20, opacity: 0.04)
                            .onChange(of: viewModel.isSoundEnabled) { _, _ in viewModel.saveSettings() }
                            .onChange(of: viewModel.isHapticsEnabled) { _, _ in viewModel.saveSettings() }
                            .onChange(of: viewModel.showOnScreenControls) { _, _ in viewModel.saveSettings() }
                            .onChange(of: viewModel.showGridLines) { _, _ in viewModel.saveSettings() }
                        }
                        
                        // MARK: - Board Themes
                        VStack(alignment: .leading, spacing: 12) {
                            Text("BOARD THEME")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(viewModel.currentTheme.primaryColor)
                                .padding(.horizontal, 8)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(Theme.allCases) { theme in
                                        let isSelected = viewModel.currentTheme == theme
                                        
                                        Button(action: {
                                            HapticsService.shared.playSelection()
                                            viewModel.updateTheme(to: theme)
                                        }) {
                                            VStack(alignment: .leading, spacing: 8) {
                                                // Mini preview box of the colors
                                                HStack(spacing: 4) {
                                                    Circle()
                                                        .fill(Color(hex: theme.primaryColorHex))
                                                        .frame(width: 14, height: 14)
                                                    Circle()
                                                        .fill(Color(hex: theme.secondaryColorHex))
                                                        .frame(width: 14, height: 14)
                                                    Circle()
                                                        .fill(Color(hex: theme.foodColorHex))
                                                        .frame(width: 14, height: 14)
                                                }
                                                
                                                Text(theme.name)
                                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                                    .foregroundColor(.white)
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 16)
                                            .frame(width: 130, alignment: .leading)
                                            .background(Color(hex: theme.boardColorHex))
                                            .cornerRadius(16)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(isSelected ? Color(hex: theme.primaryColorHex) : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
                                            )
                                            .shadow(color: isSelected ? Color(hex: theme.primaryColorHex).opacity(0.15) : Color.clear, radius: 8)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        
                        // MARK: - Snake Color customization
                        VStack(alignment: .leading, spacing: 12) {
                            Text("CUSTOM SNAKE COLOR OVERRIDE")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(viewModel.currentTheme.primaryColor)
                                .padding(.horizontal, 8)
                            
                            VStack(spacing: 16) {
                                HStack(spacing: 12) {
                                    // Theme default option
                                    Button(action: {
                                        HapticsService.shared.playSelection()
                                        StorageService.shared.customSnakeColorHex = nil
                                        viewModel.loadSettingsAndStats()
                                    }) {
                                        let isThemeDefault = StorageService.shared.customSnakeColorHex == nil
                                        
                                        VStack(spacing: 6) {
                                            Image(systemName: "paintpalette.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(isThemeDefault ? viewModel.currentTheme.boardColor : .white)
                                            Text("Theme")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(isThemeDefault ? viewModel.currentTheme.boardColor : .white)
                                        }
                                        .frame(width: 50, height: 50)
                                        .background(isThemeDefault ? viewModel.currentTheme.primaryColor : Color.white.opacity(0.05))
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle().stroke(Color.white.opacity(0.15), lineWidth: 1)
                                        )
                                    }
                                    
                                    // Custom preset colors
                                    ForEach(colorPresets, id: \.0) { hex, name in
                                        Button(action: {
                                            HapticsService.shared.playSelection()
                                            StorageService.shared.customSnakeColorHex = hex
                                            viewModel.loadSettingsAndStats()
                                        }) {
                                            let isSelected = StorageService.shared.customSnakeColorHex == hex
                                            
                                            Circle()
                                                .fill(Color(hex: hex))
                                                .frame(width: 50, height: 50)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.white, lineWidth: isSelected ? 3.0 : 0.0)
                                                        .shadow(radius: 4)
                                                )
                                                .scaleEffect(isSelected ? 1.08 : 1.0)
                                                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isSelected)
                                        }
                                    }
                                }
                                .padding(.horizontal, 4)
                                
                                Text("Personalize your snake with custom glow skin overrides.")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity)
                            .glassStyle(cornerRadius: 20, opacity: 0.04)
                        }
                        
                        // MARK: - Data Management Settings
                        VStack(alignment: .leading, spacing: 12) {
                            Text("DATA PRIVACY")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.red)
                                .padding(.horizontal, 8)
                            
                            Button(action: {
                                HapticsService.shared.buttonPressed()
                                showingResetAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "trash.fill")
                                        .foregroundColor(.red)
                                    Text("Reset Statistics & High Scores")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(.red)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .glassStyle(cornerRadius: 16, opacity: 0.04, borderColor: Color.red.opacity(0.2))
                            }
                        }
                        .padding(.bottom, 32)
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .alert("Reset All Data?", isPresented: $showingResetAlert) {
            Button("Reset Everything", role: .destructive) {
                HapticsService.shared.playNotification(.success)
                viewModel.resetAllStats()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all high scores, accumulated logs, and unlockable achievements.")
        }
    }
    
    @ViewBuilder
    private func toggleRow(title: String, subtitle: String, systemImage: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 38, height: 38)
                Image(systemName: systemImage)
                    .font(.subheadline)
                    .foregroundColor(viewModel.currentTheme.primaryColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: viewModel.currentTheme.primaryColor))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
