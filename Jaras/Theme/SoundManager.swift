import AudioToolbox
import AVFoundation
import UIKit

/// Plays the two-note bell chime, coordinates vibration haptics on iOS,
/// and maintains a silent background keep-alive audio session so calendar changes
/// and T-3m class alerts trigger reliably even while the app is in the background.
final class SoundManager {
    static let shared = SoundManager()
    private var player: AVAudioPlayer?
    private var keepAlivePlayer: AVAudioPlayer?

    private init() {}

    /// Starts an inaudible (`volume = 0.0`) `.playback` + `.mixWithOthers` audio loop so iOS
    /// keeps the app alive in the background to detect new calendar events and fire T-3m alerts on time.
    func startBackgroundKeepAlive() {
        guard keepAlivePlayer == nil || !(keepAlivePlayer?.isPlaying ?? false) else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)

            let silentWav = Self.makeSilentWavData()
            let silentPlayer = try AVAudioPlayer(data: silentWav)
            silentPlayer.numberOfLoops = -1
            silentPlayer.volume = 0.0
            silentPlayer.prepareToPlay()
            silentPlayer.play()
            keepAlivePlayer = silentPlayer
        } catch {
            // Ignore if background session cannot be started yet
        }
    }

    func playBellChime() {
        triggerHapticPattern()

        guard let url = Bundle.main.url(forResource: "bell", withExtension: "wav") else {
            AudioServicesPlaySystemSound(1007)
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
            try session.setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            player?.volume = 1.0
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

    /// Replicates the Android waveform `{0, 180, 120, 180, 380, 260}` using iOS Haptics + System Vibration.
    private func triggerHapticPattern() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
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

    /// Generates a minimal 1-second 8kHz 16-bit mono PCM silent WAV file in memory.
    private static func makeSilentWavData() -> Data {
        let sampleRate: UInt32 = 8000
        let numSamples: UInt32 = 8000
        let dataSize: UInt32 = numSamples * 2
        let fileSize: UInt32 = 36 + dataSize

        var data = Data()
        data.append(contentsOf: "RIFF".utf8)
        data.append(withUnsafeBytes(of: fileSize.littleEndian) { Data($0) })
        data.append(contentsOf: "WAVE".utf8)
        data.append(contentsOf: "fmt ".utf8)
        let fmtChunkSize: UInt32 = 16
        let audioFormat: UInt16 = 1 // PCM
        let numChannels: UInt16 = 1
        let byteRate: UInt32 = sampleRate * 2
        let blockAlign: UInt16 = 2
        let bitsPerSample: UInt16 = 16
        data.append(withUnsafeBytes(of: fmtChunkSize.littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: audioFormat.littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: numChannels.littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: sampleRate.littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: byteRate.littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: blockAlign.littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: bitsPerSample.littleEndian) { Data($0) })
        data.append(contentsOf: "data".utf8)
        data.append(withUnsafeBytes(of: dataSize.littleEndian) { Data($0) })
        data.append(Data(count: Int(dataSize)))
        return data
    }
}
