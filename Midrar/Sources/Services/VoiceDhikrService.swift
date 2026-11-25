import Foundation
import AVFoundation

final class VoiceDhikrService: ObservableObject {
    @Published var isListening = false
    @Published var statusMessage: String?

    private var audioEngine: AVAudioEngine?
    private var noiseFloor: Double = 0.015
    private var inSpeech = false
    private var speechStart: Date = Date()
    private var lastLoud: Date = Date()
    private var lastCounted: Date = Date.distantPast
    var onDhikrDetected: (() -> Void)?

    func toggle() {
        if isListening {
            stop()
        } else {
            start()
        }
    }

    func start() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                guard let self else { return }
                if !granted {
                    self.statusMessage = "يرجى السماح بصلاحية الميكروفون من الإعدادات"
                    self.isListening = false
                    return
                }
                self.beginEngine()
            }
        }
    }

    private func beginEngine() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)

            let engine = AVAudioEngine()
            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            guard format.sampleRate > 0 && format.channelCount > 0 else { return }
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                self?.processBuffer(buffer)
            }
            try engine.start()
            self.audioEngine = engine
            self.isListening = true
            self.statusMessage = "أستمع لصوتك الآن بدون إنترنت.. اذكر الله وسيُحسب تلقائياً"
        } catch {
            self.isListening = false
            self.statusMessage = "تعذّر تشغيل الميكروفون حالياً"
        }
    }

    func stop() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        isListening = false
        statusMessage = nil
    }

    private func processBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let data = buffer.floatChannelData?[0] else { return }
        let count = Int(buffer.frameLength)
        guard count > 0 else { return }

        var sumSq: Double = 0
        for i in 0..<count {
            let v = Double(data[i])
            sumSq += v * v
        }
        let rms = sqrt(sumSq / Double(count))
        let now = Date()

        if !inSpeech {
            noiseFloor = noiseFloor * 0.94 + min(rms, 0.08) * 0.06
        }
        let trigger = max(0.024, noiseFloor * 2.3)
        let release = max(0.016, noiseFloor * 1.65)

        if !inSpeech {
            if rms >= trigger {
                inSpeech = true
                speechStart = now
                lastLoud = now
            }
        } else {
            if rms >= release {
                lastLoud = now
            }
            let spoken = lastLoud.timeIntervalSince(speechStart)
            let silence = now.timeIntervalSince(lastLoud)

            if (silence >= 0.26 && spoken >= 0.14) || (spoken >= 1.8 && now.timeIntervalSince(lastCounted) >= 1.35) {
                if now.timeIntervalSince(lastCounted) >= 0.65 {
                    lastCounted = now
                    DispatchQueue.main.async { [weak self] in
                        if self?.isListening == true {
                            self?.onDhikrDetected?()
                        }
                    }
                }
                if silence >= 0.26 {
                    inSpeech = false
                } else {
                    speechStart = now
                }
            } else if silence >= 0.26 {
                inSpeech = false
            }
        }
    }
}
