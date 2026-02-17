import SwiftUI
import VisionKit
import Vision

struct InputView: View {
    @EnvironmentObject var viewModel: CheckInFlowViewModel
    @EnvironmentObject var appVM: AppViewModel
    @Environment(\.dismiss) var dismiss
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // ✅ SUBJECT PICKER (from user's selected subjects)
            if let subjects = appVM.userProfile?.subjects, subjects.count > 1 {
                Menu {
                    ForEach(subjects, id: \.self) { subject in
                        Button(subject) {
                            viewModel.selectedSubject = subject
                        }
                    }
                } label: {
                    HStack {
                        Text("Subject: ")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(viewModel.selectedSubject ?? "Select")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.top)
            } else {
                // Single subject - just show it
                Text("Subject: ")
                    .font(.caption)
                    .foregroundColor(.secondary)
                + Text(viewModel.selectedSubject ?? "")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            Text("What did you learn today?")
                .font(.title2)
                .fontWeight(.semibold)
            
            
            // Input Mode Selector
            Picker("Input Mode", selection: $viewModel.inputMode) {
                ForEach(InputMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            // Input Area
            ZStack {
                // Liquid Glass Background
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)  // ✅ iOS 15+ Liquid Glass effect
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                    )
                
                if viewModel.inputMode == .text {
                    TextEditor(text: $viewModel.userExplanation)
                        .focused($isTextFieldFocused)
                        .padding()
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                } else if viewModel.inputMode == .photo {
                    PhotoCaptureView()
                        .environmentObject(viewModel)
                } else {
                    if #available(iOS 26.0, *) {
                        VoiceInputView()
                            .environmentObject(viewModel)
                    } else {
                        Text("Please update to iOS 26.0 to access voice input.")
                    }
                }
            }
            .frame(height: 250)
            .padding(.horizontal)
            
            Spacer()
            
            // Analyze Button
            Button(action: {
                viewModel.analyzeInput()
            }) {
                if viewModel.isProcessing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Analyse")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                Capsule()
                    .fill(viewModel.userExplanation.isEmpty ? Color.gray : Color.blue)
            )
            .foregroundColor(.white)
            .padding(.horizontal)
            .disabled(viewModel.userExplanation.isEmpty || viewModel.isProcessing)
            
            Spacer()
        }
        .navigationTitle("Daily Check-In")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    // ✅ Dismiss sheet directly
                    appVM.userProfile?.lastCheckIn = Date()
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Photo Capture with VisionKit OCR
struct PhotoCaptureView: View {
    @EnvironmentObject var viewModel: CheckInFlowViewModel
    @State private var showCamera = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    
    var body: some View {
        if #available(iOS 17.0, *) {
            VStack(spacing: 20) {
                if let image = viewModel.capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                        .padding()
                    
                    if isProcessing {
                        ProgressView("Extracting text...")
                            .font(.caption)
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Take a photo of your notes")
                            .font(.headline)
                        
                        Text("Math symbols will be extracted automatically")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Button(action: {
                    showCamera = true
                }) {
                    Label(viewModel.capturedImage == nil ? "Take Photo" : "Retake", systemImage: "camera")
                }
                .buttonStyle(.bordered)
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(image: $viewModel.capturedImage, sourceType: .camera)
            }
            .onChange(of: viewModel.capturedImage) { _, newImage in
                if let image = newImage {
                    extractTextFromImage(image)
                }
            }
        } else {
            Text("This feature is only available on iOS 17.0 or newer.")
        }
    }
    
    // MARK: - VisionKit Text Extraction
    private func extractTextFromImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else {
            errorMessage = "Failed to process image"
            return
        }
        
        isProcessing = true
        errorMessage = nil
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { request, error in
            DispatchQueue.main.async {
                isProcessing = false
                
                if let error = error {
                    errorMessage = "Error: \(error.localizedDescription)"
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    errorMessage = "No text found in image"
                    return
                }
                
                // Extract all recognized text
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                viewModel.userExplanation = recognizedStrings.joined(separator: " ")
                
                print(viewModel.userExplanation)
                 
                if viewModel.userExplanation.isEmpty {
                    errorMessage = "No text could be extracted"
                }
            }
        }
        
        // Configure for best accuracy (supports mathematical symbols)
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false // Better for math symbols
        request.recognitionLanguages = ["en-US"]
        
        do {
            try requestHandler.perform([request])
        } catch {
            DispatchQueue.main.async {
                isProcessing = false
                errorMessage = "Failed to process: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - UIImagePickerController Wrapper
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Voice Input (Skeleton)

import Speech
@available(iOS 26.0, *)
struct VoiceInputView: View {
    @EnvironmentObject var viewModel: CheckInFlowViewModel
    @StateObject private var speechRecognizer = SpeechRecognizer()
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: speechRecognizer.isRecording ? "waveform.path.ecg" : "mic.fill")
                .font(.system(size: 60))
                .foregroundStyle(speechRecognizer.isRecording ? .red : .blue)
                .symbolEffect(.pulse.byLayer, isActive: speechRecognizer.isRecording)
            
            VStack(spacing: 8) {
                Text(statusText)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                Text(speechRecognizer.transcript)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
            .frame(maxHeight: 100)
            
            Button(action: toggleSpeech) {
                HStack {
                    Image(systemName: speechRecognizer.isRecording ? "stop.fill" : "mic.circle.fill")
                    Text(speechRecognizer.isRecording ? "Stop Recording" : "Start Recording")
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(speechRecognizer.isRecording ? .red : .blue)
        }
        .task {
            await speechRecognizer.requestAuthorization()
            if speechRecognizer.isAuthorized {
                viewModel.userExplanation = speechRecognizer.transcript
            }
        }
        .onChange(of: speechRecognizer.transcript) { _, newValue in
            viewModel.userExplanation = newValue
        }
    }
    
    private var statusText: String {
        if !speechRecognizer.isAuthorized {
            "Speech permission needed"
        } else if speechRecognizer.isRecording {
            "Live transcription…"
        } else {
            "Tap to speak your explanation"
        }
    }
    
    private func toggleSpeech() {
        if speechRecognizer.isRecording {
            speechRecognizer.stop()
        } else {
            speechRecognizer.start()
        }
    }
}
