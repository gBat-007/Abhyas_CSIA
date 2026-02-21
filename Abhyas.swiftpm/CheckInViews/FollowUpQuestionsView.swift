import SwiftUI
@available(iOS 26.0, *)
struct FollowUpQuestionsView: View {
    let subtopic: Subtopic
    let userExplanation: String
    // Updated to return tested concepts/misconceptions as well
    let onComplete: ([FollowUpQA], [String], [String]) -> Void
    let onSkip: () -> Void
    
    @State private var viewModel = FollowUpQuestionsViewModel()
    @State private var showQuestionCard = false
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
                            syncAnswersArray() // ensure binding is ready for the new index
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
            // Auto-sync before binding
            let safeBinding = Binding<String>(
                get: { answers.indices.contains(currentQuestionIndex) ? answers[currentQuestionIndex] : "" },
                set: {
                    syncAnswersArray()
                    if answers.indices.contains(currentQuestionIndex) {
                        answers[currentQuestionIndex] = $0
                    }
                }
            )
            // Key strictly by index so advancing always refreshes the view
            QuestionCard(
                number: currentQuestionIndex + 1,
                question: question,
                answer: safeBinding
            )
            .id(currentQuestionIndex)
            .padding(.horizontal)
        } else {
            Text("Ready to start").foregroundStyle(.secondary).padding(.horizontal)
        }
    }
    
    private var generatingQuestionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Generating question...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(viewModel.currentGeneratingQuestion)
                .font(.body)
                .italic()
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(nil)
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
        Button(nextButtonLabel) {
            nextQuestionAction()
        }
        .buttonStyle(.borderedProminent)
        .disabled(disabledNext)
    }
    
    private var disabledNext: Bool {
        viewModel.isGeneratingCurrentQuestion ||
        answers.indices.contains(currentQuestionIndex) == false ||
        answers[currentQuestionIndex].trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private var skipButton: some View {
        Button("Skip to End") { onSkip() }
            .buttonStyle(.bordered)
            .foregroundStyle(.secondary)
    }
    
    // MARK: - Actions
    private func nextQuestionAction() {
        ensureAnswerSlotExists()
        // Dismiss keyboard before advancing
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        Task {
            if currentQuestionIndex + 1 < viewModel.questions.count {
                // Advance to next existing question
                currentQuestionIndex += 1
                syncAnswersArray() // ensure binding is ready for the new index
                print("📱 Advanced to index \(currentQuestionIndex)")
            } else if viewModel.questions.count < viewModel.maxQuestionsToGenerate {
                // Generate new question then advance
                showQuestionCard = false
                await viewModel.generateNextQuestion(
                    for: subtopic,
                    userExplanation: userExplanation,
                    previousAnswers: answers
                ) {
                    currentQuestionIndex = viewModel.questions.count - 1
                    syncAnswersArray() // ensure binding is ready for the new index
                    print("📱 Generated Q\(viewModel.questions.count) → index \(currentQuestionIndex)")
                }
            } else {
                // Finish: build FollowUpQA array and pass back, including tested items
                let followUps: [FollowUpQA] = buildFollowUpQAs()
                onComplete(followUps, viewModel.testedConcepts, viewModel.testedMisconceptions)
            }
        }
    }
    
    private func buildFollowUpQAs() -> [FollowUpQA] {
        // Note: You currently don’t have per-question concept mapping stored.
        // We keep your existing approach (first core concept) to avoid breaking downstream logic.
        let concept = subtopic.coreConcepts.first ?? ""
        let topicCheckInID = UUID() // Placeholder until persisted session exists
        let count = min(viewModel.questions.count, answers.count)
        return (0..<count).map { idx in
            FollowUpQA(
                topicCheckInID: topicCheckInID,
                questionNumber: idx + 1,
                question: viewModel.questions[idx],
                userResponse: answers[idx],
                conceptTested: concept
            )
        }
    }
    
    private func ensureAnswerSlotExists() {
        let safeIndex = min(currentQuestionIndex, 100)
        while answers.count <= safeIndex {
            answers.append("")
        }
    }
}

// FIXED QuestionCard with .id refresh (kept as-is)
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
                
                MathSupportedText(question)
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
                                    .stroke(isFocused ? Color.accentColor : Color.accentColor.opacity(0.5), lineWidth: 2)
                            )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
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
