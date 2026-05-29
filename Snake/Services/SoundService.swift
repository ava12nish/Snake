import AVFoundation

@MainActor
class SoundService {
    static let shared = SoundService()
    
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    
    private init() {
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        
        engine.attach(player)
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 1)!
        engine.connect(player, to: engine.mainMixerNode, format: format)
        
        do {
            try engine.start()
            self.audioEngine = engine
            self.playerNode = player
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    private func playTone(frequency: Double, duration: Double, type: WaveType = .sine) {
        guard StorageService.shared.isSoundEnabled,
              let engine = audioEngine,
              let player = playerNode else { return }
        
        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                print("Failed to restart engine: \(error)")
                return
            }
        }
        
        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: frameCount
        ) else { return }
        
        buffer.frameLength = frameCount
        
        let channels = buffer.floatChannelData
        guard let channelData = channels?[0] else { return }
        
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            var sample = 0.0
            
            switch type {
            case .sine:
                sample = sin(2.0 * .pi * frequency * time)
            case .square:
                sample = sin(2.0 * .pi * frequency * time) >= 0 ? 0.2 : -0.2
            case .triangle:
                sample = abs((time * frequency).truncatingRemainder(dividingBy: 1.0) - 0.5) * 4.0 - 1.0
            }
            
            // Apply a quick fade-out envelope to avoid clicks
            let decay = 1.0 - (Double(frame) / Double(frameCount))
            channelData[frame] = Float(sample * decay * 0.15) // Keep volume comfortable
        }
        
        player.play()
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }
    
    enum WaveType {
        case sine
        case square
        case triangle
    }
    
    // MARK: - Game Sound Effects
    
    func playFoodSound(combo: Int = 1) {
        // High pitch beep, scales up with combo multiplier
        let baseFreq = 600.0
        let pitchShift = Double(combo - 1) * 150.0
        playTone(frequency: baseFreq + pitchShift, duration: 0.08, type: .square)
    }
    
    func playSpecialFoodSound() {
        // Rising arpeggio
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            self.playTone(frequency: 800, duration: 0.05, type: .square)
            Thread.sleep(forTimeInterval: 0.05)
            self.playTone(frequency: 1000, duration: 0.05, type: .square)
            Thread.sleep(forTimeInterval: 0.05)
            self.playTone(frequency: 1300, duration: 0.1, type: .square)
        }
    }
    
    func playCollisionSound() {
        // Falling retro explosive sound
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            for freq in stride(from: 350.0, through: 100.0, by: -15.0) {
                self.playTone(frequency: freq, duration: 0.015, type: .triangle)
                Thread.sleep(forTimeInterval: 0.01)
            }
        }
    }
    
    func playCountdownTick() {
        playTone(frequency: 450, duration: 0.05, type: .sine)
    }
    
    func playCountdownStart() {
        playTone(frequency: 900, duration: 0.22, type: .square)
    }
    
    func playPauseSound() {
        playTone(frequency: 300, duration: 0.08, type: .sine)
    }
    
    func playResumeSound() {
        playTone(frequency: 500, duration: 0.08, type: .sine)
    }
    
    func playAchievementSound() {
        // Upbeat victory tune
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            let notes = [523.25, 659.25, 783.99, 1046.50] // C E G C
            for note in notes {
                self.playTone(frequency: note, duration: 0.08, type: .square)
                Thread.sleep(forTimeInterval: 0.07)
            }
        }
    }
}
