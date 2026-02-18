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
    
    func detectConceptualGaps(
        subtopic: Subtopic,
        userResponses: [String],
        followUpQAs: [FollowUpQA]
    ) async -> GapAnalysisResult {
        isAnalyzing = true
        currentAnalyzingText = "Analyzing your understanding..."
        
        // Step 1: Algorithmic baseline (fast)
        var preliminaryResult = await performAlgorithmicAnalysis(
            subtopic: subtopic,
            userResponses: userResponses,
            followUpQAs: followUpQAs
        )
        
        // Step 2: AI refinement (shows loading until complete)
        currentAnalyzingText = "Generating personalized feedback..."
        
        if #available(iOS 26.0, *), session != nil {
            preliminaryResult = await refineAnalysisWithAI(
                preliminaryResult: preliminaryResult,
                subtopic: subtopic,
                userResponses: userResponses,
                followUpQAs: followUpQAs
            )
        }
        
        isAnalyzing = false
        gapAnalysis = preliminaryResult
        
        return preliminaryResult
    }
    
    private func performAlgorithmicAnalysis(
        subtopic: Subtopic,
        userResponses: [String],
        followUpQAs: [FollowUpQA]
    ) async -> GapAnalysisResult {
        var understoodConcepts: [String] = []
        var conceptualGaps: [String] = []
        var flaggedMisconceptions: [String] = []
        var missingPrerequisites: [String] = []
        
        let allText = userResponses.joined(separator: " ")
        let responseKeywords = extractAndLemmatizeKeywords(from: allText)
        
        currentAnalyzingText = "Checking core concepts..."
        
        for concept in subtopic.coreConcepts {
            let conceptKeywords = extractAndLemmatizeKeywords(from: concept)
            let matchCount = conceptKeywords.filter { responseKeywords.contains($0) }.count
            let matchPercentage = conceptKeywords.isEmpty ? 0.0 : Double(matchCount) / Double(conceptKeywords.count)
            
            if matchPercentage >= 0.6 {
                understoodConcepts.append(concept)
            } else {
                conceptualGaps.append(concept)
            }
        }
        
        currentAnalyzingText = "Checking for misconceptions..."
        
        if let misconceptions = subtopic.commonMisconceptions {
            for misconception in misconceptions {
                let misconceptionKeywords = extractAndLemmatizeKeywords(from: misconception)
                let matchCount = misconceptionKeywords.filter { responseKeywords.contains($0) }.count
                let matchPercentage = misconceptionKeywords.isEmpty ? 0.0 : Double(matchCount) / Double(misconceptionKeywords.count)
                
                if matchPercentage >= 0.4 {
                    flaggedMisconceptions.append(misconception)
                    
                    let relatedConcept = getCorrectConcept(for: misconception, in: subtopic)
                    if !conceptualGaps.contains(relatedConcept) && !understoodConcepts.contains(relatedConcept) {
                        conceptualGaps.append(relatedConcept)
                    }
                }
            }
        }
        
        let totalConcepts = subtopic.coreConcepts.count
        let gapPercentage = totalConcepts > 0 ? Double(conceptualGaps.count) / Double(totalConcepts) : 0.0
        
        currentAnalyzingText = "Checking prerequisites..."
        
        if gapPercentage > 0.5 {
            for prereqID in subtopic.prerequisites {
                let hasCompletedPrereq = await checkPrerequisiteCompletion(prereqID: prereqID)
                if !hasCompletedPrereq {
                    missingPrerequisites.append(prereqID)
                }
            }
        }
        
        let understandingScore = totalConcepts > 0 ? Float((Double(understoodConcepts.count) / Double(totalConcepts)) * 100) : 0.0
        
        return GapAnalysisResult(
            understoodConcepts: understoodConcepts,
            conceptualGaps: conceptualGaps,
            flaggedMisconceptions: flaggedMisconceptions,
            missingPrerequisites: missingPrerequisites,
            understandingScore: understandingScore
        )
    }
    
    @available(iOS 26.0, *)
    private func refineAnalysisWithAI(
        preliminaryResult: GapAnalysisResult,
        subtopic: Subtopic,
        userResponses: [String],
        followUpQAs: [FollowUpQA]
    ) async -> GapAnalysisResult {
        guard let session = session else { return preliminaryResult }
        
        let prompt = buildRefinementPrompt(
            preliminaryResult: preliminaryResult,
            subtopic: subtopic,
            userResponses: userResponses,
            followUpQAs: followUpQAs
        )
        
        do {
            var refinedAnalysisText = ""
            let stream = session.streamResponse(to: prompt)
            
            for try await response in stream {
                currentAnalyzingText = "Analyzing your responses... \(response.content.prefix(50))..."
                refinedAnalysisText = response.content
            }
            
            currentAnalyzingText = "Finalizing analysis..."
            
            let refinedResult = parseRefinedAnalysis(
                aiResponse: refinedAnalysisText,
                preliminaryResult: preliminaryResult,
                subtopic: subtopic
            )
            
            return refinedResult
            
        } catch {
            print("AI refinement error: \(error)")
            currentAnalyzingText = "Analysis complete"
            return preliminaryResult
        }
    }
    
    @available(iOS 26.0, *)
    private func buildRefinementPrompt(
        preliminaryResult: GapAnalysisResult,
        subtopic: Subtopic,
        userResponses: [String],
        followUpQAs: [FollowUpQA]
    ) -> String {
        let allResponses = userResponses + followUpQAs.map { $0.userResponse }
        
        let qaContext = followUpQAs.enumerated().map { index, qa in
            "Q\(index + 1): \(qa.question)\nA\(index + 1): \(qa.userResponse)"
        }.joined(separator: "\n\n")
        
        let syllabusContext = """
        Topic: \(subtopic.title)
        Core concepts to assess: \(subtopic.coreConcepts.joined(separator: "; "))
        Common misconceptions: \(subtopic.commonMisconceptions?.joined(separator: "; ") ?? "None listed")
        """
        
        return """
        Analyze this student's understanding of IB \(subtopic.subjectCode) \(subtopic.title).
        
        STUDENT RESPONSES:
        \(allResponses.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n\n"))
        
        SYLLABUS CONTEXT:
        \(syllabusContext)
        
        TASK: Identify specific gaps in the student's understanding based on their ACTUAL responses. Focus on:
        1. Which core concepts they clearly understand vs. struggle with
        2. Evidence of misconceptions in their wording
        3. Prerequisite knowledge gaps only if their responses show fundamental confusion
        
        Output ONLY in this exact format:
        
        UNDERSTOOD: [list 2-3 concepts they clearly explained well, or "None clearly understood"]
        GAPS: [list 2-4 specific gaps/missing understanding from their responses, or "No major gaps"]
        MISCONCEPTIONS: [1-2 misconceptions if clearly present in wording, or "None detected"]
        PREREQUISITES: [prereq subtopic IDs if responses show fundamental gaps, or "None needed"]
        SCORE: [0-100, based on depth/accuracy of understanding]
        
        Base decisions on their actual responses, not just keyword matching.
        Be specific about what they got wrong/right.
        """
    }
    
    @available(iOS 26.0, *)
    private func parseRefinedAnalysis(
        aiResponse: String,
        preliminaryResult: GapAnalysisResult,
        subtopic: Subtopic
    ) -> GapAnalysisResult {
        // Parse AI's free-form response into structured data
        // Use the AI response as the source of truth for final analysis
        let parsed = parseAIFreeformResponse(aiResponse, subtopic: subtopic)
        
        return GapAnalysisResult(
            understoodConcepts: parsed.understoodConcepts,
            conceptualGaps: parsed.conceptualGaps,
            flaggedMisconceptions: parsed.misconceptions,
            missingPrerequisites: parsed.prerequisites,
            understandingScore: parsed.score
        )
    }
    
    private func parseAIFreeformResponse(_ response: String, subtopic: Subtopic) -> (understoodConcepts: [String], conceptualGaps: [String], misconceptions: [String], prerequisites: [String], score: Float) {
        var understoodConcepts: [String] = []
        var conceptualGaps: [String] = []
        var misconceptions: [String] = []
        var prerequisites: [String] = []
        var score: Float = 50.0 // default
        
        let lines = response.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmed.hasPrefix("UNDERSTOOD:") {
                let content = String(trimmed.dropFirst(11)).trimmingCharacters(in: .whitespaces)
                understoodConcepts = splitConcepts(content)
            } else if trimmed.hasPrefix("GAPS:") {
                let content = String(trimmed.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                conceptualGaps = splitConcepts(content)
            } else if trimmed.hasPrefix("MISCONCEPTIONS:") {
                let content = String(trimmed.dropFirst(15)).trimmingCharacters(in: .whitespaces)
                misconceptions = splitConcepts(content)
            } else if trimmed.hasPrefix("PREREQUISITES:") {
                let content = String(trimmed.dropFirst(14)).trimmingCharacters(in: .whitespaces)
                prerequisites = content.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            } else if trimmed.hasPrefix("SCORE:") {
                let content = String(trimmed.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                score = Float(content) ?? 50.0
            }
        }
        
        // Fallback to syllabus concepts if AI didn't specify enough
        if understoodConcepts.count + conceptualGaps.count < 2 {
            let allConcepts = subtopic.coreConcepts
            let understoodCount = min(understoodConcepts.count + 1, allConcepts.count / 2)
            understoodConcepts = Array(allConcepts.prefix(understoodCount))
            conceptualGaps = Array(allConcepts.dropFirst(understoodCount))
        }
        
        return (understoodConcepts, conceptualGaps, misconceptions, prerequisites, score)
    }
    
    private func splitConcepts(_ text: String) -> [String] {
        text.components(separatedBy: [";", ","])
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.lowercased() != "none" && $0.lowercased() != "no major gaps" }
    }
    
    // ... rest of helper methods remain the same (extractAndLemmatizeKeywords, lemmatize, etc.)
    
    private func extractAndLemmatizeKeywords(from text: String) -> [String] {
        let cleanText = text.lowercased()
            .replacingOccurrences(of: "[^a-z0-9\\s]", with: "", options: .regularExpression)
        
        let words = cleanText.components(separatedBy: .whitespaces)
            .filter { $0.count > 2 }
        
        let stopWords = Set(["the", "and", "for", "with", "that", "this", "from", "have", "has", "had", "are", "was", "were", "been", "will", "would", "could", "should"])
        
        let filteredWords = words.filter { !stopWords.contains($0) }
        
        let lemmatized = filteredWords.map { lemmatize($0) }
        
        return Array(Set(lemmatized))
    }
    
    private func lemmatize(_ word: String) -> String {
        let rules: [(suffix: String, replacement: String)] = [
            ("ies", "y"),
            ("es", "e"),
            ("ed", ""),
            ("ing", ""),
            ("s", "")
        ]
        
        for rule in rules {
            if word.hasSuffix(rule.suffix) && word.count > rule.suffix.count + 2 {
                let base = String(word.dropLast(rule.suffix.count))
                return base + rule.replacement
            }
        }
        
        return word
    }
    
    private func getCorrectConcept(for misconception: String, in subtopic: Subtopic) -> String {
        let misconceptionKeywords = extractAndLemmatizeKeywords(from: misconception)
        
        var bestMatch: (concept: String, matchCount: Int) = (subtopic.coreConcepts.first ?? "Core understanding of this topic", 0)
        
        for concept in subtopic.coreConcepts {
            let conceptKeywords = extractAndLemmatizeKeywords(from: concept)
            let matchCount = misconceptionKeywords.filter { conceptKeywords.contains($0) }.count
            
            if matchCount > bestMatch.matchCount {
                bestMatch = (concept, matchCount)
            }
        }
        
        return bestMatch.concept
    }
    
    private func checkPrerequisiteCompletion(prereqID: String) async -> Bool {
        guard let appData = try? dataManager.loadUserData(),
              let profile = appData.userProfile else {
            return false
        }
        
        for session in appData.checkInSessions {
            for subjectCheckIn in session.subjectCheckIns {
                for subtopicCheckIn in subjectCheckIn.subtopicCheckIns {
                    if subtopicCheckIn.subtopicID == prereqID && subtopicCheckIn.understandingScore >= 70 {
                        return true
                    }
                }
            }
        }
        
        return false
    }
}

struct GapAnalysisResult: Codable {
    let understoodConcepts: [String]
    let conceptualGaps: [String]
    let flaggedMisconceptions: [String]
    let missingPrerequisites: [String]
    let understandingScore: Float
}
