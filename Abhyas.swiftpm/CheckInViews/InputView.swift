import SwiftUI
import VisionKit
import Vision

func toUserReadableName(subjectCode: String) -> String {
    if subjectCode == "MATAA_HL" {
        return "Math AA"
    } else if subjectCode == "PHYSHL" {
        return "Physics"
    } else if subjectCode == "CSHL" {
        return "Computer Science"
    }
    
    return subjectCode
}

@available(iOS 26.0, *)
struct InputView: View {
    @EnvironmentObject var viewModel: CheckInFlowViewModel
    @EnvironmentObject var appVM: AppViewModel
    @Environment(\.dismiss) var dismiss
    @FocusState private var isTextFieldFocused: Bool
        private var isAnalyzeDisabled: Bool {
        let trimmed = viewModel.userExplanation.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count < 10 || viewModel.isProcessing
    }
        var body: some View {
        VStack(spacing: 20) {
            // ✅ SUBJECT PICKER (from user's selected subjects)
            if let subjects = appVM.userProfile?.subjects, subjects.count > 1 {
                Menu {
                    ForEach(subjects, id: \.self) { subject in
                        Button(toUserReadableName(subjectCode: subject)) {
                            viewModel.selectedSubject = subject
                        }
                    }
                } label: {
                    HStack {
                        Text("Subject: ")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(toUserReadableName(subjectCode: viewModel.selectedSubject ?? "Select"))
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
                + Text(toUserReadableName(subjectCode: viewModel.selectedSubject ?? "Select") ?? "")
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
                let trimmed = viewModel.userExplanation.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.count < 10 {
                    // Too short - show feedback
                    return
                }
                // Dismiss keyboard before processing
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
                    .fill(isAnalyzeDisabled ? Color.gray : Color.blue)
            )
            .foregroundColor(.white)
            .padding(.horizontal)
            .disabled(isAnalyzeDisabled)
            
            Spacer()
        }
        .navigationTitle("New Shard")
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
@available(iOS 26.0, *)
struct PhotoCaptureView: View {
    @EnvironmentObject var viewModel: CheckInFlowViewModel
    @State private var showCameraPicker = false
    @State private var showPhotoLibraryPicker = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    
    var body: some View {
        if #available(iOS 17.0, *) {
            VStack(spacing: 16) {
                if let image = viewModel.capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
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
                        
                        Text("Add a photo of your notes")
                            .font(.headline)
                        
                        Text("Math symbols will be extracted automatically")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                }
                
                HStack(spacing: 12) {
                    Button {
                        showCameraPicker = true
                    } label: {
                        Label(viewModel.capturedImage == nil ? "Take Photo" : "Retake", systemImage: "camera")
                    }
                    .buttonStyle(.bordered)
                    
                    Button {
                        showPhotoLibraryPicker = true
                    } label: {
                        Label("Choose Photo", systemImage: "photo.on.rectangle")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .sheet(isPresented: $showCameraPicker) {
                ImagePicker(image: $viewModel.capturedImage, sourceType: .camera)
            }
            .sheet(isPresented: $showPhotoLibraryPicker) {
                PhotoLibraryPicker(image: $viewModel.capturedImage)
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
    
    private func extractTextFromImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else {
            errorMessage = "Failed to process image"
            return
        }
        
        isProcessing = true
        errorMessage = nil
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        //Asynchronous request to VisionKit API
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
                
                // Extract all recognized text as strings for further usage
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

// MARK: - UIImagePickerController Wrapper (Camera)
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
        //Using UIImagePickerController to handle SwiftUI's ImagePicker
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            //Safely retrieving the captured image as a UIImage
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

// Library required for displaying photo library.
import PhotosUI

struct PhotoLibraryPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    //The below functions allow for UIKit View Controllers to be used in a SwiftUI app.
    func makeUIViewController(context: Context) -> PHPickerViewController {
        //This configuration ensures a clear user experience, with only selecting 1 image allowed.
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 1
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoLibraryPicker
        
        init(_ parent: PhotoLibraryPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            defer { parent.dismiss() }
            guard let provider = results.first?.itemProvider else { return }
            
            // Prefer UIImage directly if available
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { object, _ in
                    if let uiImage = object as? UIImage {
                        DispatchQueue.main.async {
                            self.parent.image = uiImage
                        }
                    }
                }
                return
            }
            
            // Fallback: load data representation of an image
            let typeIdentifiers = ["public.image"]
            provider.loadDataRepresentation(forTypeIdentifier: typeIdentifiers[0]) { data, _ in
                if let data, let uiImage = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.parent.image = uiImage
                    }
                }
            }
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
