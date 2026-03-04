import Foundation
import FoundationModels

@available(iOS 26.0, *)
@MainActor
class GapDetectionViewModel: ObservableObject {
    
    @Published var isAnalyzing = false
    @Published var currentAnalyzingText = ""
    @Published var gapAnalysis: GapAnalysisResult?
    
    private var session: LanguageModelSession?
    private let dataManager = DataManager()
    
    init() {
        if #available(iOS 26.0, *) {
            session = LanguageModelSession()
        }
    }
    
    // MARK: - Public Entry
    
    func detectConceptualGaps(
        subtopic: Subtopic,
        userResponses: [String],
        followUpQAs: [FollowUpQA],
        testedConcepts: [String],
        testedMisconceptions: [String]
    ) async -> GapAnalysisResult {
        
        isAnalyzing = true
        currentAnalyzingText = "Analyzing your understanding..."
        
        guard #available(iOS 26.0, *),
              let session = session else {
            let fallback = fallbackResult(testedConcepts: testedConcepts)
            gapAnalysis = fallback
            isAnalyzing = false
            return fallback
        }
        
        let prompt = buildSemanticEvaluationPrompt(
            subtopic: subtopic,
            userResponses: userResponses,
            followUpQAs: followUpQAs,
            testedConcepts: testedConcepts,
            testedMisconceptions: testedMisconceptions
        )
        
        do {
            var finalResponse = ""
            let stream = session.streamResponse(to: prompt)
            
            for try await response in stream {
                finalResponse = response.content
            }
            
            currentAnalyzingText = "Finalizing analysis..."
            
            let parsed = parseSemanticEvaluation(
                aiResponse: finalResponse,
                testedConcepts: testedConcepts
            )
            
            gapAnalysis = parsed
            isAnalyzing = false
            return parsed
            
        } catch {
            print("Semantic evaluation failed:", error)
            let fallback = fallbackResult(testedConcepts: testedConcepts)
            gapAnalysis = fallback
            isAnalyzing = false
            return fallback
        }
    }
    
    // MARK: - Prompt Construction
    
    @available(iOS 26.0, *)
    private func buildSemanticEvaluationPrompt(
        subtopic: Subtopic,
        userResponses: [String],
        followUpQAs: [FollowUpQA],
        testedConcepts: [String],
        testedMisconceptions: [String]
    ) -> String {
        
        let qaContext = followUpQAs.enumerated().map { index, qa in
            """
            Q\(index + 1) (target: \(qa.conceptTested))
            Question: \(qa.question)
            Answer: \(qa.userResponse)
            """
        }.joined(separator: "\n\n")
        
        return """
        You are evaluating a student's conceptual understanding AND factual correctness.
        
        IB Topic: \(subtopic.subjectCode) - \(subtopic.title)
        
        INITIAL RESPONSE:
        "\(userResponses.first ?? "")"
        
        FOLLOW-UP RESPONSES:
        \(qaContext)
        
        CONCEPTS TESTED:
        \(testedConcepts.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n"))
        
        MISCONCEPTIONS PROBED:
        \(testedMisconceptions.isEmpty ? "None" : testedMisconceptions.joined(separator: "\n"))
        
        STRICT EVALUATION RULES:
        1. Responses like "I don't know", "IDK", "I'm not sure", or empty answers = NO_UNDERSTANDING (always)
        2. Vague or minimal responses (< 10 words) with no specific concepts mentioned = NO_UNDERSTANDING
        3. Correct AND detailed explanation of the concept = CLEAR_UNDERSTANDING (only this qualifies)
        4. Correct BUT incomplete explanation (missing key elements) = PARTIAL_UNDERSTANDING
        5. Any factual, logical, or mathematical error = INCORRECT_UNDERSTANDING (even if partially correct)
        6. Do NOT be lenient. Accuracy and depth matter.
        
        For EACH tested concept classify as:
        - CLEAR_UNDERSTANDING (correct, detailed, demonstrates mastery)
        - PARTIAL_UNDERSTANDING (correct but incomplete, missing key elements)
        - INCORRECT_UNDERSTANDING (contains errors, misconceptions, or false reasoning)
        - NO_UNDERSTANDING (vague, minimal, or "I don't know" responses)
        
        Output EXACTLY in this format:
        
        CONCEPT_EVALUATIONS:
        Concept 1: CLEAR_UNDERSTANDING
        Concept 2: INCORRECT_UNDERSTANDING
        Concept 3: PARTIAL_UNDERSTANDING
        
        DETECTED_ERRORS: [brief list of incorrect claims or None]
        
        MISCONCEPTIONS_PRESENT: [any misconceptions found or None]
        
        PREREQUISITES_NEEDED: [IDs only or None]
        
        Do not include explanations.
        """
    }
    
    // MARK: - Parsing & Scoring
    
    private func parseSemanticEvaluation(
        aiResponse: String,
        testedConcepts: [String]
    ) -> GapAnalysisResult {
        
        var understood: [String] = []
        var gaps: [String] = []
        var misconceptions: [String] = []
        var prerequisites: [String] = []
        
        var clearCount = 0
        var partialCount = 0
        var incorrectCount = 0
        var noneCount = 0
        
        let lines = aiResponse.components(separatedBy: .newlines)
        var conceptIndex = 0
        //Parsing the model's evaluation into clear, quantitative data
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.hasPrefix("Concept"),
               conceptIndex < testedConcepts.count {
                
                let concept = testedConcepts[conceptIndex]
                
                if trimmed.contains("CLEAR_UNDERSTANDING") {
                    understood.append(concept)
                    clearCount += 1
                } else if trimmed.contains("PARTIAL_UNDERSTANDING") {
                    gaps.append(concept)
                    partialCount += 1
                } else if trimmed.contains("INCORRECT_UNDERSTANDING") {
                    gaps.append(concept)
                    incorrectCount += 1
                } else if trimmed.contains("NO_UNDERSTANDING") {
                    gaps.append(concept)
                    noneCount += 1
                }
                
                conceptIndex += 1
            }
            
            if trimmed.hasPrefix("MISCONCEPTIONS_PRESENT:") {
                let content = trimmed
                    .replacingOccurrences(of: "MISCONCEPTIONS_PRESENT:", with: "")
                    .trimmingCharacters(in: .whitespaces)
                
                if content.lowercased() != "none" {
                    misconceptions = splitList(content)
                }
            }
            
            if trimmed.hasPrefix("PREREQUISITES_NEEDED:") {
                let content = trimmed
                    .replacingOccurrences(of: "PREREQUISITES_NEEDED:", with: "")
                    .trimmingCharacters(in: .whitespaces)
                
                if content.lowercased() != "none" {
                    prerequisites = splitList(content)
                }
            }
        }

        let total = max(clearCount + partialCount + incorrectCount + noneCount, 1)

        //Ratio of understood concepts, partial ones, and incorrect ones for weightedScore 
        let weightedScore =
            (Double(clearCount) * 1.0 + Double(partialCount) * 0.5 + Double(incorrectCount) * 0.0 +
             Double(noneCount) * 0.0) / Double(total)
        
        let score = Float(weightedScore * 100)
        
        return GapAnalysisResult(
            understoodConcepts: understood,
            conceptualGaps: gaps,
            flaggedMisconceptions: misconceptions,
            missingPrerequisites: prerequisites,
            understandingScore: score
        )
    }
    
    // MARK: - Fallback
    
    private func fallbackResult(testedConcepts: [String]) -> GapAnalysisResult {
        return GapAnalysisResult(
            understoodConcepts: [],
            conceptualGaps: testedConcepts,
            flaggedMisconceptions: [],
            missingPrerequisites: [],
            understandingScore: testedConcepts.isEmpty ? 70 : 50
        )
    }
    
    private func splitList(_ text: String) -> [String] {
        return text.components(separatedBy: [";", ","])
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.lowercased() != "none" }
    }
}

struct GapAnalysisResult: Codable {
    let understoodConcepts: [String]
    let conceptualGaps: [String]
    let flaggedMisconceptions: [String]
    let missingPrerequisites: [String]
    let understandingScore: Float
}
