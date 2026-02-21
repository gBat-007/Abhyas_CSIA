import SwiftUI

@available(iOS 26.0, *)
struct GapAnalysisContainerView: View {
    let subtopic: Subtopic
    let gapViewModel: GapDetectionViewModel
    let userResponses: [String]
    let followUpQAs: [FollowUpQA]
    let testedConcepts: [String]
    let testedMisconceptions: [String]
    let onContinue: (GapAnalysisResult) -> Void
    
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
                        onContinue: { onContinue(result) }
                    )
                } else {
                    LoadingAnalysisView(currentText: "Starting analysis...")
                }
            }
            .navigationTitle("Understanding Analysis")
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
                            .lineLimit(1)
                    }
                }
            }
        }
        .task {
            analysisResult = await gapViewModel.detectConceptualGaps(
                subtopic: subtopic,
                userResponses: userResponses,
                followUpQAs: followUpQAs,
                testedConcepts: testedConcepts,
                testedMisconceptions: testedMisconceptions
            )
        }
    }
}
