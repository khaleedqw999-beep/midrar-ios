import Foundation
import UIKit
import AVFoundation

final class HapticsAndAudio {
    static let shared = HapticsAndAudio()

    var hapticsEnabled: Bool = true
    var soundEnabled: Bool = true

    private let lightGen = UIImpactFeedbackGenerator(style: .light)
    private let mediumGen = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGen = UIImpactFeedbackGenerator(style: .heavy)
    private let notifGen = UINotificationFeedbackGenerator()

    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var dropletBuffer: AVAudioPCMBuffer?

    private init() {
        lightGen.prepare()
        mediumGen.prepare()
        heavyGen.prepare()
        notifGen.prepare()
        setupDropletAudio()
    }

    func gentleTick() {
        guard hapticsEnabled else { return }
        lightGen.impactOccurred(intensity: 0.65)
    }

    func tapFeedback() {
        if hapticsEnabled {
            lightGen.impactOccurred(intensity: 0.72)
        }
        if soundEnabled {
            playDropletSound()
        }
    }

    func mediumPulse() {
        guard hapticsEnabled else { return }
        mediumGen.impactOccurred(intensity: 0.9)
    }

    /// Distinct double-pulse every 100 counts (noticeable eyes-free)
    func hundredMilestoneFeedback() {
        if hapticsEnabled {
            heavyGen.impactOccurred(intensity: 0.95)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) { [weak self] in
                self?.heavyGen.impactOccurred(intensity: 1.0)
            }
        }
        if soundEnabled {
            playDropletSound()
        }
    }

    /// Unmistakable 3-pulse escalating haptic when Daily Goal, Wird, Adhkar, or 15K/100K Chapter is completed
    func goalCompletedFeedback() {
        if hapticsEnabled {
            notifGen.notificationOccurred(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) { [weak self] in
                self?.heavyGen.impactOccurred(intensity: 1.0)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) { [weak self] in
                self?.heavyGen.impactOccurred(intensity: 1.0)
            }
        }
        if soundEnabled {
            playDropletSound()
        }
    }

    func milestoneFeedback() {
        goalCompletedFeedback()
    }

    private func setupDropletAudio() {
        let engine = AVAudioEngine()
        let node = AVAudioPlayerNode()
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1) else { return }
        let frameCount = AVAudioFrameCount(44100 * 0.08)
        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buf.frameLength = frameCount
        if let channel = buf.floatChannelData?[0] {
            for i in 0..<Int(frameCount) {
                let t = Double(i) / 44100.0
                let env = exp(-t * 46.0) * sin(min(1.0, t / 0.004) * .pi / 2.0)
                let freq = 620.0 + (t * 2400.0)
                channel[i] = Float(sin(2.0 * .pi * freq * t) * env * 0.28)
            }
        }
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        self.audioEngine = engine
        self.playerNode = node
        self.dropletBuffer = buf
    }

    private func playDropletSound() {
        guard let engine = audioEngine, let node = playerNode, let buf = dropletBuffer else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            if !engine.isRunning { try engine.start() }
            node.scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)
            if !node.isPlaying { node.play() }
        } catch {
            // Silent graceful fallback
        }
    }
}
