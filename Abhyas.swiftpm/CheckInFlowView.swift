import SwiftUI

@available(iOS 26.0, *)
struct CheckInFlowView: View {
    @EnvironmentObject var appVM: AppViewModel
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = CheckInFlowViewModel()
    
    var body: some View {
        Group {
            if viewModel.currentStep == .input {
                InputView()
                    .environmentObject(viewModel)
            } else if viewModel.currentStep == .topicSelection {
                TopicSelectionView()
                    .environmentObject(viewModel)
            } else if viewModel.currentStep == .followUp {
                if let subtopic = viewModel.currentSubtopic {
                    if #available(iOS 26.0, *) {
                        FollowUpQuestionsView(
                            subtopic: subtopic,
                            userExplanation: viewModel.userExplanation,
                            onComplete: { followUpQAs, testedConcepts, testedMisconceptions in
                                Task {
                                    await viewModel.advanceFromFollowUp(
                                        with: followUpQAs,
                                        testedConcepts: testedConcepts,
                                        testedMisconceptions: testedMisconceptions
                                    )
                                }
                            },
                            onSkip: {
                                Task {
                                    await viewModel.advanceFromFollowUp(
                                        with: [],
                                        testedConcepts: [],
                                        testedMisconceptions: []
                                    )
                                }
                            }
                        )
                    } else {
                        Text("You must update to iOS 26.0.")
                    }
                } else {
                    CompletionView()
                        .environmentObject(viewModel)
                }
            } else if viewModel.currentStep == .gapAnalysis {
                if let subtopic = viewModel.currentSubtopic {
                    let followUpQAs = viewModel.followUpQAsMap[subtopic.id] ?? []
                    let testedConcepts = viewModel.testedConceptsMap[subtopic.id] ?? []
                    let testedMisconceptions = viewModel.testedMisconceptionsMap[subtopic.id] ?? []
                    
                    GapAnalysisContainerView(
                        subtopic: subtopic,
                        gapViewModel: GapDetectionViewModel(),
                        userResponses: [viewModel.userExplanation],
                        followUpQAs: followUpQAs,
                        testedConcepts: testedConcepts,
                        testedMisconceptions: testedMisconceptions,
                        onContinue: { analysis in
                            viewModel.storeGapAnalysis(analysis, for: subtopic.id)
                            viewModel.advanceFromGapAnalysis()
                        }
                    )
                }
            } else if viewModel.currentStep == .complete {
                CompletionView()
                    .environmentObject(viewModel)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            dismiss()
                        }
                    }
            }
        }
        .onAppear {
            // Attach the AppViewModel so shard saves update in-memory
            viewModel.setAppViewModel(appVM)
            if let firstSubject = appVM.userProfile?.subjects.first {
                viewModel.selectedSubject = firstSubject
            }
        }
        .accentColor(Color(red: 0.40, green: 0.75, blue: 1.0))
    }
    
    @available(iOS 26.0, *)
    struct CompletionView: View {
        @EnvironmentObject var viewModel: CheckInFlowViewModel
        @Environment(\.dismiss) var dismiss
        
        var body: some View {
            VStack(spacing: 30) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Shard Recorded!")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("You've captured your learning moment. Your understanding has been recorded.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationBarBackButtonHidden()
        }
    }
}
