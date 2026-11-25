import Foundation
import UIKit
import AVFoundation

final class HapticsAndAudio {
    static let shared = HapticsAndAudio()

    var hapticsEnabled: Bool = true
    var soundEnabled: Bool = true

    private let lightGen = UIImpactFeedbackGenerator(style: .light)
    private let mediumGen = UIImpactFeedbackGenerator(style: .medium)
    private let notifGen = UINotificationFeedbackGenerator()

    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var dropletBuffer: AVAudioPCMBuffer?

    private init() {
        lightGen.prepare()
        mediumGen.prepare()
        setupDropletSynth()
    }

    func tapFeedback() {
        if hapticsEnabled {
            lightGen.impactOccurred()
        }
        if soundEnabled {
            playDroplet()
        }
    }

    func gentleTick() {
        if hapticsEnabled {
            lightGen.impactOccurred(intensity: 0.7)
        }
    }

    func milestoneFeedback() {
        if hapticsEnabled {
            notifGen.notificationOccurred(.success)
        }
    }

    private func setupDropletSynth() {
        let engine = AVAudioEngine()
        let node = AVAudioPlayerNode()
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1) else { return }
        let frameCount = AVAudioFrameCount(44100 * 0.08) // 80ms soft water droplet
        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buf.frameLength = frameCount
        if let data = buf.floatChannelData?[0] {
            for i in 0..<Int(frameCount) {
                let t = Double(i) / 44100.0
                let env = exp(-t * 58.0) * sin(min(1.0, t * 240.0) * .pi / 2.0)
                let freq = 680.0 + t * 1450.0
                data[i] = Float(sin(2.0 * .pi * freq * t) * env * 0.22)
            }
        }
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        self.audioEngine = engine
        self.playerNode = node
        self.dropletBuffer = buf
    }

    private func playDroplet() {
        guard let engine = audioEngine, let node = playerNode, let buf = dropletBuffer else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            if !engine.isRunning {
                try engine.start()
            }
            node.scheduleBuffer(buf, at: nil, options: .interrupts, completionHandler: nil)
            if !node.isPlaying {
                node.play()
            }
        } catch {}
    }
}
