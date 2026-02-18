import Foundation
import AVFoundation
import Speech

@available(iOS 26.0, *)
@MainActor
final class SpeechRecognizer: NSObject, ObservableObject {
    // Public state
    @Published var transcript: String = ""
    @Published var isAuthorized: Bool = false
    @Published var isRecording: Bool = false

    // Configuration
    @Published var localeIdentifier: String {
        didSet {
            recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier))
        }
    }

    // Internals
    private var audioEngine: AVAudioEngine?
    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    override init() {
        self.localeIdentifier = "en-US"
        super.init()
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier))
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        let speechStatus: SFSpeechRecognizerAuthorizationStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        let micGranted: Bool = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }

        isAuthorized = (speechStatus == .authorized && micGranted)
        if !isAuthorized {
            print("SpeechRecognizer: Authorization failed. Speech=\(speechStatus.rawValue), Mic=\(micGranted)")
        }
    }

    // MARK: - Public control

    func start() {
        guard !isRecording else { return }
        guard isAuthorized else {
            print("SpeechRecognizer: start() called without authorization")
            return
        }
        Task { await startInternal() }
    }

    func stop() {
        Task { await stopInternal() }
    }

    // MARK: - Private lifecycle

    private func startInternal() async {
        // Lazy init engine
        if audioEngine == nil {
            audioEngine = AVAudioEngine()
        }
        guard let audioEngine else {
            print("SpeechRecognizer: No audio engine")
            return
        }

        // Reset state
        transcript = ""
        isRecording = true

        do {
            // Configure audio session first
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record,
                                    mode: .default,
                                    options: [.duckOthers, .allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            // Prepare recognition request
            let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            recognitionRequest.shouldReportPartialResults = true
            self.request = recognitionRequest

            // Ensure recognizer exists and is available
            guard let recognizer, recognizer.isAvailable else {
                print("SpeechRecognizer: Recognizer unavailable for locale \(localeIdentifier)")
                await stopInternal()
                return
            }

            // Install input tap
            let inputNode = audioEngine.inputNode
            inputNode.removeTap(onBus: 0)
            let format = inputNode.outputFormat(forBus: 0)

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                // IMPORTANT: Append from the audio tap thread to avoid queue assertions.
                guard let self = self, let req = self.request else { return }
                req.append(buffer)
            }

            // Start engine
            try audioEngine.prepare()
            try audioEngine.start()

            // Start recognition task; hop to MainActor inside callback before touching state
            recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                Task { @MainActor in
                    guard let self else { return }
                    if let result {
                        self.transcript = result.bestTranscription.formattedString
                    }
                    if let error {
                        print("SpeechRecognizer: recognition error: \(error)")
                        await self.stopInternal()
                    }
                }
            }

            print("SpeechRecognizer: Recording started (locale \(localeIdentifier))")
        } catch {
            print("SpeechRecognizer: start error: \(error)")
            await stopInternal()
        }
    }

    private func stopInternal() async {
        // Ensure this executes on MainActor (class is @MainActor, but be explicit through call sites)
        isRecording = false

        // Remove tap before stopping engine to stop further buffers
        if let engine = audioEngine {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
        }

        // Finish/cancel recognition gracefully
        request?.endAudio()
        recognitionTask?.cancel()

        // Nil out in safe order
        recognitionTask = nil
        request = nil

        // Deactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("SpeechRecognizer: session deactivate error: \(error)")
        }

        print("SpeechRecognizer: Stopped")
    }

    deinit {
        // Ensure we don’t capture self strongly and that we hop to MainActor
        Task { @MainActor [weak self] in
            await self?.stopInternal()
        }
    }
}
