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
                            onComplete: { followUpQAs in
                                Task {
                                    await viewModel.advanceFromFollowUp(with: followUpQAs)
                                }
                            },
                            onSkip: {
                                Task {
                                    await viewModel.advanceFromFollowUp(with: [])
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
                    GapAnalysisContainerView(
                        subtopic: subtopic,
                        gapViewModel: GapDetectionViewModel(),
                        userResponses: [viewModel.userExplanation],
                        followUpQAs: viewModel.followUpQAsMap[subtopic.id] ?? [],
                        onContinue: {
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
                    if let firstSubject = appVM.userProfile?.subjects.first {
                        viewModel.selectedSubject = firstSubject
                    }
                }
        }
    }
    
    @available(iOS 26.0, *)
    struct CompletionView: View {
        @EnvironmentObject var viewModel: CheckInFlowViewModel
        @Environment(\.dismiss) var dismiss
        
        var body: some View {
            VStack(spacing: 30) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text("Check-In Complete!")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Great work! Your understanding has been recorded.")
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

