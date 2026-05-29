import UIKit

@MainActor
class HapticsService {
    static let shared = HapticsService()
    
    private init() {}
    
    func playImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard StorageService.shared.isHapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func playNotification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard StorageService.shared.isHapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    func playSelection() {
        guard StorageService.shared.isHapticsEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    func foodEaten() {
        playImpact(.light)
    }
    
    func specialFoodEaten() {
        playNotification(.success)
    }
    
    func collisionOccurred() {
        playNotification(.error)
    }
    
    func buttonPressed() {
        playImpact(.medium)
    }
    
    func comboTriggered() {
        playImpact(.heavy)
    }
    
    func countdownTick() {
        playSelection()
    }
}
