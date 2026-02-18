import Foundation
import FoundationModels

@MainActor
class GapDetectionViewModel: ObservableObject {
    @Published var isAnalyzing = false
    @Published var currentAnalyzingText = ""
    @Published var gapAnalysis: GapAnalysisResult?
    
    func detectConceptualGaps(
        subtopic: Subtopic,
        userResponses: [String],
        followUpQAs: [FollowUpQA]
    ) async -> GapAnalysisResult {
        isAnalyzing = true
        currentAnalyzingText = "Analyzing your understanding..."
        
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
                let indicatorPhrases = getMisconceptionIndicators(for: misconception)
                
                for phrase in indicatorPhrases {
                    if allText.lowercased().contains(phrase.lowercased()) {
                        flaggedMisconceptions.append(misconception)
                        
                        let relatedConcept = getCorrectConcept(for: misconception, in: subtopic)
                        
                        if !conceptualGaps.contains(relatedConcept) && !understoodConcepts.contains(relatedConcept) {
                            conceptualGaps.append(relatedConcept)
                        }
                        
                        break
                    }
                }
            }
        }
        
        let totalConcepts = subtopic.coreConcepts.count
        let gapsCount = conceptualGaps.count
        let gapPercentage = totalConcepts > 0 ? Double(gapsCount) / Double(totalConcepts) : 0.0
        
        currentAnalyzingText = "Checking prerequisites..."
        
        if gapPercentage > 0.5 {
            for prereqID in subtopic.prerequisites {
                let hasCompletedPrereq = await checkPrerequisiteCompletion(prereqID: prereqID)
                
                if !hasCompletedPrereq {
                    missingPrerequisites.append(prereqID)
                }
            }
        }
        
        let understoodCount = understoodConcepts.count
        let understandingScore = totalConcepts > 0 ? Float((Double(understoodCount) / Double(totalConcepts)) * 100) : 0.0
        
        let result = GapAnalysisResult(
            understoodConcepts: understoodConcepts,
            conceptualGaps: conceptualGaps,
            flaggedMisconceptions: flaggedMisconceptions,
            missingPrerequisites: missingPrerequisites,
            understandingScore: understandingScore
        )
        
        isAnalyzing = false
        gapAnalysis = result
        
        return result
    }
    
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
    
    private func getMisconceptionIndicators(for misconception: String) -> [String] {
        var indicators: [String] = []
        
        let lowercased = misconception.lowercased()
        
        if lowercased.contains("nd instead of (n-1)d") || lowercased.contains("using nd") {
            indicators = ["nd", "n*d", "n times d", "multiply n"]
        } else if lowercased.contains("confusing") && lowercased.contains("ram") && lowercased.contains("rom") {
            indicators = ["ram is permanent", "rom is temporary", "ram stores firmware"]
        } else if lowercased.contains("sum to infinity") && lowercased.contains("|r| ≥ 1") {
            indicators = ["r = 1", "r > 1", "r greater than", "always converge"]
        } else if lowercased.contains("direct changeover") && lowercased.contains("always best") {
            indicators = ["direct is best", "fastest is best", "always use direct"]
        } else if lowercased.contains("technical requirements") && lowercased.contains("only important") {
            indicators = ["only technical", "just technical", "hardware and software only"]
        } else if lowercased.contains("log") && lowercased.contains("ln") && lowercased.contains("interchangeable") {
            indicators = ["log and ln same", "log equals ln", "log is ln"]
        } else {
            let words = misconception.components(separatedBy: .whitespaces)
                .filter { $0.count > 3 }
                .prefix(5)
            indicators = Array(words)
        }
        
        return indicators
    }
    
    private func getCorrectConcept(for misconception: String, in subtopic: Subtopic) -> String {
        let lowercased = misconception.lowercased()
        
        for concept in subtopic.coreConcepts {
            let conceptLower = concept.lowercased()
            
            if lowercased.contains("nd") && conceptLower.contains("(n-1)") {
                return concept
            } else if lowercased.contains("ram") && conceptLower.contains("ram") {
                return concept
            } else if lowercased.contains("rom") && conceptLower.contains("rom") {
                return concept
            } else if lowercased.contains("|r|") && conceptLower.contains("|r|") {
                return concept
            } else if lowercased.contains("log") && conceptLower.contains("log") {
                return concept
            }
        }
        
        return subtopic.coreConcepts.first ?? "Core understanding of this topic"
    }
    
    private func checkPrerequisiteCompletion(prereqID: String) async -> Bool {
        // Load user data safely; if it fails, assume not completed
        let appData = (try? DataManager().loadUserData()) ?? AppData()
        guard let _ = appData.userProfile else {
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
