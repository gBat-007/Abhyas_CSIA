

import SwiftUI

@available(iOS 26.0, *)
struct GapAnalysisContainerView: View {
    let subtopic: Subtopic
    let gapViewModel: GapDetectionViewModel
    let userResponses: [String]
    let followUpQAs: [FollowUpQA]
    let onContinue: () -> Void
    
    @State private var analysisResult: GapAnalysisResult?
    
    var body: some View {
        NavigationStack {
            Group {
                if gapViewModel.isAnalyzing {
                    LoadingAnalysisView(currentText: gapViewModel.currentAnalyzingText)
                } else if let result = analysisResult {
                    GapAnalysisResultView(
                        subtopic: subtopic,
                        analysis: result,
                        onContinue: onContinue
                    )
                } else {
                    // Fallback - should not happen
                    Text("Analysis complete")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Text(subtopic.number)
                            .font(.headline)
                            .fontWeight(.bold)
                        Text(subtopic.title)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .task {
            analysisResult = await gapViewModel.detectConceptualGaps(
                subtopic: subtopic,
                userResponses: userResponses,
                followUpQAs: followUpQAs
            )
        }
    }
}
