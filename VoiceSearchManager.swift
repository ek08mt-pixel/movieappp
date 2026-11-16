import SwiftUI
import Speech
import AVFoundation

@MainActor
class VoiceSearchManager: ObservableObject {
    @Published var transcript = ""
    @Published var audioLevel: CGFloat = 0
    @Published var isRecording = false
    
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?
    private var silenceTimer: Timer?
    
    func start() {
        SFSpeechRecognizer.requestAuthorization { status in
            guard status == .authorized else { return }
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                guard granted else { return }
                DispatchQueue.main.async {
                    self.beginRecording()
                }
            }
        }
    }
    
    private func beginRecording() {
        stop()
        transcript = ""
        audioLevel = 0
        
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "vi-VN"))
        guard let recognizer = speechRecognizer, recognizer.isAvailable else { return }
        
        let engine = AVAudioEngine()
        audioEngine = engine
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            
            let inputNode = engine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
                self?.updateAudioLevel(buffer: buffer)
            }
            
            engine.prepare()
            try engine.start()
            isRecording = true
            
            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                guard let self = self else { return }
                if let result = result {
                    DispatchQueue.main.async {
                        self.transcript = result.bestTranscription.formattedString
                        self.resetSilenceTimer()
                        if result.isFinal {
                            self.finish(with: self.transcript)
                        }
                    }
                }
                if error != nil {
                    DispatchQueue.main.async {
                        self.finish(with: self.transcript)
                    }
                }
            }
            
            resetSilenceTimer()
        } catch {
            print("Voice error: \(error)")
            stop()
        }
    }
    
    private func updateAudioLevel(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frames = Int(buffer.frameLength)
        var sum: Float = 0
        for i in 0..<frames {
            sum += channelData[i] * channelData[i]
        }
        let rms = sqrt(sum / Float(frames))
        let level = max(0.05, min(1.0, CGFloat(rms) * 20))
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.1)) {
                self.audioLevel = level
            }
        }
    }
    
    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            guard let self = self, !self.transcript.isEmpty else { return }
            DispatchQueue.main.async {
                self.finish(with: self.transcript)
            }
        }
    }
    
    private var onComplete: ((String) -> Void)?
    
    func setOnComplete(_ handler: @escaping (String) -> Void) {
        onComplete = handler
    }
    
    private func finish(with text: String) {
        let finalText = text
        stop()
        onComplete?(finalText)
    }
    
    func stop() {
        silenceTimer?.invalidate()
        silenceTimer = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        isRecording = false
        audioLevel = 0
    }
}