import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()
    @State private var activeScreen: ActiveScreen = .home
    
    var body: some View {
        ZStack {
            // Dark base background
            Color.black
                .ignoresSafeArea()
            
            Group {
                switch activeScreen {
                case .home:
                    HomeView(mainViewModel: viewModel, onNavigate: { screen in
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                            activeScreen = screen
                        }
                    })
                    .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
                    
                case .modeSelection:
                    ModeSelectionView(
                        viewModel: viewModel,
                        onBack: {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                activeScreen = .home
                            }
                        },
                        onStartGame: { mode, diff in
                            viewModel.startNewGame(mode: mode, difficulty: diff)
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                activeScreen = .game(mode: mode, difficulty: diff)
                            }
                        }
                    )
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                    
                case .game:
                    GameView(
                        viewModel: viewModel,
                        onQuit: {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                activeScreen = .home
                            }
                        }
                    )
                    .transition(.asymmetric(insertion: .scale(scale: 0.95).combined(with: .opacity), removal: .move(edge: .leading)))
                    
                case .stats:
                    StatsView(
                        viewModel: viewModel,
                        onBack: {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                activeScreen = .home
                            }
                        }
                    )
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                    
                case .settings:
                    SettingsView(
                        viewModel: viewModel,
                        onBack: {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                activeScreen = .home
                            }
                        }
                    )
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
