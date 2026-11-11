import AudioToolbox
import AVFoundation
import UIKit

/// Plays the two-note bell chime and coordinates vibration haptics on iOS.
/// Respects the iPhone's physical Silent Mode switch via `.ambient` session category.
final class SoundManager {
    static let shared = SoundManager()
    private var player: AVAudioPlayer?

    private init() {}

    func playBellChime() {
        triggerHapticPattern()

        guard let url = Bundle.main.url(forResource: "bell", withExtension: "wav") else {
            AudioServicesPlaySystemSound(1007)
            return
        }

        do {
            // .ambient respects the Ring/Silent switch on iPhone
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
        } catch {
            AudioServicesPlaySystemSound(1007)
        }
    }

    func stop() {
        player?.stop()
        player = nil
    }

    /// Replicates the Android waveform `{0, 180, 120, 180, 380, 260}` using iOS Haptics.
    private func triggerHapticPattern() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            let heavy = UIImpactFeedbackGenerator(style: .heavy)
            heavy.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.68) {
            let rigid = UIImpactFeedbackGenerator(style: .rigid)
            rigid.impactOccurred()
        }
    }
}
