import SwiftUI
@available(iOS 26.0, *)
struct FollowUpQuestionsView: View {
    let subtopic: Subtopic
    let userExplanation: String
    let onComplete: () -> Void
    let onSkip: () -> Void
    
    @State private var viewModel = FollowUpQuestionsViewModel()
    @State private var showQuestionCard = false  // ✅ ADD HERE
    @State private var currentQuestionIndex = 0
    @State private var answers: [String] = []
    
    private func syncAnswersArray() {
        let neededCount = max(viewModel.questions.count, currentQuestionIndex + 1)
        while answers.count < neededCount {
            answers.append("")
        }
    }
    
    var body: some View {
            NavigationStack {
                VStack(spacing: 32) {
                    headerView
                    contentView
                    actionButtons
                }
                .task(id: [viewModel.questions.count, currentQuestionIndex]) {
                    syncAnswersArray()
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { onSkip() } } }
                .onAppear {
                    // ONLY generate FIRST question automatically
                    if viewModel.questions.isEmpty {
                        answers = [""]  // Pre-allocate first answer
                        Task {
                            await viewModel.generateNextQuestion(
                                for: subtopic,
                                userExplanation: userExplanation,
                                previousAnswers: answers
                            ) {
                                showQuestionCard = true
                                currentQuestionIndex = viewModel.questions.count - 1
                            }
                        }
                    }
                }
            }
            .onChange(of: viewModel.questions.count) { _ in
                let neededCount = max(viewModel.questions.count, 1)
                while answers.count < neededCount {
                    answers.append("")
                }
            }
        }
        
        // MARK: - Subviews
        private var headerView: some View {
            VStack(spacing: 8) {
                HStack {
                    Text("\(subtopic.number) - \(subtopic.title)")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(progressText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }
        }
        
        private var contentView: some View {
            ScrollView {
                VStack(spacing: 24) {
                    explanationDisclosure
                    Divider()
                    mainQuestionView
                }
            }
        }
        
        private var actionButtons: some View {
            VStack(spacing: 12) {
                nextButton
                skipButton
            }
            .padding(.horizontal)
        }
        
        // MARK: - Helpers (computed properties)
        private var progressText: String {
            "\(min(currentQuestionIndex + 1, max(viewModel.questions.count, 1)))/3"
        }
        
        private var isCurrentQuestionAnswered: Bool {
            guard answers.indices.contains(currentQuestionIndex) else { return false }
            return !answers[currentQuestionIndex].trimmingCharacters(in: .whitespaces).isEmpty
        }

        
        private var currentQuestion: String? {
            let safeIndex = min(currentQuestionIndex, viewModel.questions.count - 1)
            guard safeIndex >= 0 && safeIndex < viewModel.questions.count else { return nil }
            return viewModel.questions[safeIndex]
        }




        
        // MARK: - View Builders
        private var explanationDisclosure: some View {
            DisclosureGroup("Your explanation") {
                Text(userExplanation)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            .padding(.horizontal)
        }
        
        

        @ViewBuilder
        private var mainQuestionView: some View {
            if viewModel.isGeneratingCurrentQuestion {
                generatingQuestionView.padding(.horizontal)
            } else if let question = currentQuestion {
                // ✅ AUTO-SYNC before binding
                let safeBinding = Binding<String>(
                    get: { answers.indices.contains(currentQuestionIndex) ? answers[currentQuestionIndex] : "" },
                    set: {
                        syncAnswersArray()
                        if answers.indices.contains(currentQuestionIndex) {
                            answers[currentQuestionIndex] = $0
                        }
                    }
                )
                QuestionCard(
                    number: currentQuestionIndex + 1,
                    question: question,
                    answer: safeBinding
                )
                .padding(.horizontal)
            } else {
                Text("Ready to start").foregroundStyle(.secondary).padding(.horizontal)
            }
        }



        
        private var generatingQuestionView: some View {
            VStack {
                Text("Generating question...").font(.subheadline).foregroundStyle(.secondary)
                Text(viewModel.currentGeneratingQuestion)
                    .font(.body).italic().foregroundStyle(.secondary)
                    .padding()
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }
        }
        
        private var nextButtonLabel: String {
            if viewModel.questions.count < viewModel.maxQuestionsToGenerate {
                "Next Question (\(viewModel.questions.count + 1)/3)"
            } else {
                "Finish"
            }
        }

        private var nextButton: some View {
            Button(nextButtonLabel) {  // ✅ Dynamic label
                nextQuestionAction()
            }
            .buttonStyle(.borderedProminent)
            .disabled(disabledNext)
        }


        private var disabledNext: Bool {
            viewModel.isGeneratingCurrentQuestion ||
            answers.indices.contains(currentQuestionIndex) == false ||
            answers[currentQuestionIndex].trimmingCharacters(in: .whitespaces).isEmpty  // ✅ Enable when NOT empty
        }


        
        private var skipButton: some View {
            Button("Skip to End") { onSkip() }
                .buttonStyle(.bordered)
                .foregroundStyle(.secondary)
        }
        
        // MARK: - Actions
            
        private func nextQuestionAction() {
            ensureAnswerSlotExists()
            
            Task {
                if currentQuestionIndex + 1 < viewModel.questions.count {
                    // ✅ Just advance existing
                    currentQuestionIndex += 1
                    print("📱 Advanced to index \(currentQuestionIndex)")
                } else if viewModel.questions.count < viewModel.maxQuestionsToGenerate {
                    // ✅ Generate NEW + advance
                    showQuestionCard = false  // Reset UI
                    await viewModel.generateNextQuestion(
                        for: subtopic,
                        userExplanation: userExplanation,
                        previousAnswers: answers
                    ) {
                        currentQuestionIndex = viewModel.questions.count - 1  // ✅ ADVANCE HERE
                        print("📱 Generated Q\(viewModel.questions.count) → index \(currentQuestionIndex)")
                    }
                } else {
                    onComplete()
                }
            }
        }



        private func ensureAnswerSlotExists() {
            let safeIndex = min(currentQuestionIndex, 100)  // Sanity cap
            while answers.count <= safeIndex {
                answers.append("")
            }
        }


}


// FIXED QuestionCard with .id refresh
struct QuestionCard: View {
    let number: Int
    let question: String
    @Binding var answer: String
    
    @State private var isRecording = false
    @State private var isTranscribing = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Question header
            HStack(alignment: .top, spacing: 12) {
                Text("\(number).")
                    .font(.headline)
                    .foregroundStyle(.blue)
                    .frame(width: 24, alignment: .leading)
                
                Text(question)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Answer input area
            VStack(alignment: .leading, spacing: 8) {
                if isRecording {
                    RecordingIndicator()
                } else if isTranscribing {
                    HStack {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.8)
                        Text("Transcribing...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    HStack {
                        TextEditor(text: $answer)
                            .focused($isFocused)
                            .scrollContentBackground(.hidden)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .frame(minHeight: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isFocused ? Color.blue : Color.clear, lineWidth: 2)
                            )
                        
                        Button(action: toggleRecording) {
                            Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(isRecording ? .red : .blue)
                        }
                        .buttonStyle(.plain)
                        .disabled(isTranscribing)  // ✅ Prevent spam
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
//        .id(question + answer)  // ✅ REFRESH ON NEW QUESTION/ANSWER
    }
    
    
    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        isRecording = true
        // TODO: Start your existing audio recording
        // When done recording:
        // isRecording = false
        // isTranscribing = true
        // transcribeRecording()
    }
    
    private func stopRecording() {
        isRecording = false
        // TODO: Stop recording, start transcription
    }
    
    private func transcribeRecording() {
        // TODO: Use your existing Whisper/local transcription
        // When complete:
        // isTranscribing = false
        // answer = transcribedText
    }
}

struct RecordingIndicator: View {
    @State private var pulsePhase: Double = 0
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.red)
                .frame(width: 12, height: 12)
                .scaleEffect(1.0 + sin(pulsePhase) * 0.3)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: pulsePhase)
            
            Text("Recording...")
                .font(.caption.bold())
                .foregroundColor(.red)
        }
        .onAppear {
            pulsePhase = 0
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                pulsePhase = .pi * 2
            }
        }
    }
}


// MARK: - Loading Placeholder
struct QuestionPlaceholder: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 24, height: 24)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 20)
            }
            
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 100)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .opacity(isAnimating ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Utilities
private extension Array where Element == String {
    func padOrTrim(to newCount: Int) -> [String] {
        guard newCount >= 0 else { return [] }
        if count == newCount { return self }
        if count > newCount {
            return Array(self.prefix(newCount))
        } else {
            return self + Array(repeating: "", count: newCount - count)
        }
    }
}


