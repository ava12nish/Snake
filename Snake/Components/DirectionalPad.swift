import SwiftUI

struct DirectionalPad: View {
    var activeTheme: Theme
    var onDirectionChange: (Direction) -> Void
    var currentDirection: Direction
    
    var body: some View {
        VStack(spacing: 8) {
            // Up Button
            dpadButton(dir: .up, icon: "arrow.up")
            
            HStack(spacing: 40) {
                // Left Button
                dpadButton(dir: .left, icon: "arrow.left")
                
                // Center spacer placeholder or theme indicator
                Circle()
                    .fill(activeTheme.primaryColor.opacity(0.1))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(activeTheme.primaryColor.opacity(0.3), lineWidth: 1)
                    )
                
                // Right Button
                dpadButton(dir: .right, icon: "arrow.right")
            }
            
            // Down Button
            dpadButton(dir: .down, icon: "arrow.down")
        }
        .padding(16)
        .glassStyle(cornerRadius: 32, opacity: 0.05, borderColor: activeTheme.primaryColor.opacity(0.2))
    }
    
    @ViewBuilder
    private func dpadButton(dir: Direction, icon: String) -> some View {
        let isActive = currentDirection == dir
        
        Button(action: {
            HapticsService.shared.playImpact(.light)
            onDirectionChange(dir)
        }) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(isActive ? activeTheme.boardColor : .white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(isActive ? activeTheme.primaryColor : Color.white.opacity(0.1))
                )
                .overlay(
                    Circle()
                        .stroke(isActive ? activeTheme.primaryColor : Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: isActive ? activeTheme.primaryColor.opacity(0.4) : Color.clear, radius: 10)
                .scaleEffect(isActive ? 0.95 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isActive)
        }
    }
}
