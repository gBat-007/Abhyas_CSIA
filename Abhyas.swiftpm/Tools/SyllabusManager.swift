import Foundation

@MainActor
class SyllabusManager {
    static let shared = SyllabusManager()
    
    private var subjects: [Subject] = []
    private var subtopicIndex: [String: Subtopic] = [:]
    
    // Stopwords for filtering
    private let stopwords = Set([
        "the", "a", "an", "is", "was", "were", "are", "be", "been", "being",
        "about", "i", "learned", "today", "studied", "we", "my", "me",
        "what", "how", "when", "where", "why", "which", "this", "that",
        "and", "or", "but", "to", "from", "in", "on", "at", "by", "with"
    ])
    
    private init() {}

    //By editing SyllabusRoot to store an array of type [Curriculum], such that Curriculum is a struct containing 
    //an array of type [Subject], would allow syllabus loading code and further to be easily modified accordingly.
    struct SyllabusRoot: Codable {
        let subjects: [Subject]
    }
    
    func loadSyllabus() async throws {
        guard let url = Bundle.main.url(forResource: "IBDPSyllabus", withExtension: "json") else {
            throw NSError(domain: "Syllabus", code: 404, userInfo: [NSLocalizedDescriptionKey: "IBDPSyllabus.json not found"])
        }
        
        let data = try Data(contentsOf: url)
        
        let root = try JSONDecoder().decode(SyllabusRoot.self, from: data)
        subjects = root.subjects
        
        buildSubtopicIndex()
        
        print("Loaded \(subjects.count) subjects")
        print("Indexed \(subtopicIndex.count) subtopics")
    }

    
    private func buildSubtopicIndex() {
        subtopicIndex = Dictionary(uniqueKeysWithValues:
                                    subjects.flatMap { subject in
            subject.topics.flatMap { topic in
                topic.subtopics.map { ($0.id, $0) }
            }
        }
        )
    }
    
    // MARK: - Lookup Methods
    
    func getSubtopic(id: String) -> Subtopic? {
        return subtopicIndex[id]
    }
    
    func getSubject(code: String) -> Subject? {
        print(subjects)
        return subjects.first { $0.code == code }
    }
    
    func getAllSubjects() -> [Subject] {
        return subjects
    }
    
    func getAllSubtopics(for subjectCode: String) -> [Subtopic] {
        guard let subject = getSubject(code: subjectCode) else { return [] }
        return subject.topics.flatMap { $0.subtopics }
    }
    
    // YOUR IA ALGORITHM: Topic Matching
    
    // MARK: - IMPROVED TOPIC IDENTIFICATION ALGORITHM
    func identifyTopics(userExplanation: String, subjectCode: String) -> [TopicMatch] {
        // Step 1: Preprocess user input
        var keywords = extractKeywords(from: userExplanation)
        print("📝 After extraction: \(keywords)")
        
        keywords = removeStopwords(from: keywords)
        print("📝 After stopwords: \(keywords)")
        
        keywords = lemmatize(keywords)
        print("📝 After lemmatization: \(keywords)")
        
        // Step 2: Load syllabus data
        let allSubtopics = getAllSubtopics(for: subjectCode)
        
        guard !allSubtopics.isEmpty else {
            print("⚠️ No subtopics found for \(subjectCode)")
            return []
        }
        
        print("🔍 Searching \(allSubtopics.count) subtopics...\n")
        
        // Add to identifyTopics BEFORE the scoring loop:
        print("\n🔍 Debug: First subtopic keywords:")
        if let firstSubtopic = allSubtopics.first {
            print("   Title: \(firstSubtopic.title)")
            print("   Keywords: \(firstSubtopic.keywords)")
        }
        print("")
        /*
         // Step 3: Score each subtopic
         var matches: [TopicMatch] = []

         for subtopic in allSubtopics {
             var score: Float = 0
             var matchDetails: [String] = []
             
             // ... your existing scoring logic (keyword matching, concept matching) ...
             
             if score > 0 {
                 // Calculate max possible score for normalization
                 let maxKeywordScore = Float(subtopic.keywords.count * 2)
                 let maxConceptScore = Float(subtopic.coreConcepts.count * 3)
                 let maxPossibleScore = maxKeywordScore + maxConceptScore
                 
                 // Normalize to percentage
                 let normalizedConfidence = min((score / maxPossibleScore) * 100, 100)
                 
                 print("  \(subtopic.title): \(Int(normalizedConfidence))% (raw: \(score)/\(Int(maxPossibleScore)))")
                 for detail in matchDetails {
                     print("    \(detail)")
                 }
                 
                 matches.append(TopicMatch(
                     subtopic: subtopic,
                     confidence: normalizedConfidence,
                     rawScore: score
                 ))
             }
         }

         // Sort by confidence
         matches.sort { $0.confidence > $1.confidence }

         // Optional: Scale to highest for relative comparison
         if let maxConfidence = matches.first?.confidence, maxConfidence > 0 {
             print("\n📊 Scaling to highest (\(Int(maxConfidence))%):")
             matches = matches.map { match in
                 let scaledConfidence = (match.confidence / maxConfidence) * 100
                 print("  \(match.subtopic.title): \(Int(match.confidence))% → \(Int(scaledConfidence))%")
                 return TopicMatch(
                     subtopic: match.subtopic,
                     confidence: scaledConfidence,
                     rawScore: match.rawScore
                 )
             }
         }

         print("")
         return Array(matches.prefix(3))
         */
        // Step 3: Score each subtopic
        var matches: [TopicMatch] = []
        
        for subtopic in allSubtopics {
            var score: Float = 0
            var matchDetails: [String] = []
            
            // Keyword matching (weight: +2 per exact match, +1 per fuzzy)
            for keyword in keywords {
                var matchedThisKeyword = false
                
                // Check against whole keyword phrases
                for subtopicKeyword in subtopic.keywords {
                    let lowerSubtopicKeyword = subtopicKeyword.lowercased()
                    
                    // Skip if already matched this user keyword
                    if matchedThisKeyword { continue }
                    
                    // Exact word match
                    if lowerSubtopicKeyword == keyword {
                        score += 2
                        matchDetails.append("✓ Exact '\(keyword)'")
                        matchedThisKeyword = true
                    }
                    // Check if subtopic keyword contains our word (for multi-word keywords)
                    else if lowerSubtopicKeyword.contains(keyword) && keyword.count > 3 {
                        score += 2
                        matchDetails.append("✓ Contains '\(keyword)'")
                        matchedThisKeyword = true
                    }
                    // Fuzzy match
                    else if fuzzyMatch(keyword, in: [lowerSubtopicKeyword], threshold: 0.85) {
                        score += 1
                        matchDetails.append("~ Fuzzy '\(keyword)'")
                        matchedThisKeyword = true
                    }
                }
            }
            
            // Core concept matching (weight: +3 per concept match)
            for concept in subtopic.coreConcepts {
                let conceptKeywords = removeStopwords(from: lemmatize(extractKeywords(from: concept)))
                let matchCount = conceptKeywords.filter { keywords.contains($0) }.count
                
                // If majority of concept keywords found
                if matchCount >= max(1, conceptKeywords.count / 2) {
                    score += 3
                    matchDetails.append("★ Concept match")
                }
            }
            
            // Step 4: Normalize score
            let normalizedScore = subtopic.keywords.isEmpty ? 0 : score / Float(subtopic.keywords.count)
            let confidence = min(normalizedScore * 100, 100)
            
            if confidence > 0 {
                print("  \(subtopic.title): \(Int(confidence))% (raw: \(score))")
                for detail in matchDetails {
                    print("    \(detail)")
                }
                matches.append(TopicMatch(subtopic: subtopic, confidence: confidence, rawScore: score))
            }
            
            if score > 0 {
                // Calculate max possible score for normalization
                let maxKeywordScore = Float(subtopic.keywords.count * 2)
                let maxConceptScore = Float(subtopic.coreConcepts.count * 3)
                let maxPossibleScore = maxKeywordScore + maxConceptScore
                
                // Normalize to percentage
                let normalizedConfidence = min((score / maxPossibleScore) * 100, 100)
                
                print("  \(subtopic.title): \(Int(normalizedConfidence))% (raw: \(score)/\(Int(maxPossibleScore)))")
                for detail in matchDetails {
                    print("    \(detail)")
                }
                
                matches.append(TopicMatch(
                    subtopic: subtopic,
                    confidence: normalizedConfidence,
                    rawScore: score
                ))
            }
        }
        
        // Deduplicate and keep best per subtopic
        let bestById = Dictionary(grouping: matches, by: { $0.subtopic.id })
            .compactMap { (_, group) in group.max(by: { $0.rawScore < $1.rawScore }) }

        var uniqueMatches = Array(bestById)
        uniqueMatches.sort { $0.rawScore > $1.rawScore }

        // Relative scaling
        if let maxScore = uniqueMatches.first?.rawScore, maxScore > 0 {
            uniqueMatches = uniqueMatches.map { match in
                let scaled = (match.rawScore / maxScore) * 100
                return TopicMatch(
                    subtopic: match.subtopic,
                    confidence: scaled,
                    rawScore: match.rawScore
                )
            }
        }

        // Optional threshold
        uniqueMatches = uniqueMatches.filter { $0.confidence >= 20 }

        return Array(uniqueMatches.prefix(3))

    }
    
    // MARK: - Helper Functions
    
    private func extractKeywords(from text: String) -> [String] {
        let lowercase = text.lowercased()
        
        // Split by whitespace and punctuation
        let components = lowercase.components(separatedBy: CharacterSet.alphanumerics.inverted)
        
        return components.filter { !$0.isEmpty && $0.count > 2 }
    }
    
    private func removeStopwords(from keywords: [String]) -> [String] {
        return keywords.filter { !stopwords.contains($0) }
    }
    
    private func lemmatize(_ keywords: [String]) -> [String] {
        return keywords.map { word in
            var lemma = word
            
            // Special cases first
            if word == "sequences" { return "sequence" }
            if word == "series" { return "series" }  // Already singular
            if word == "formulas" { return "formula" }
            
            // General plural rules
            if word.hasSuffix("ies") && word.count > 4 {
                // studies -> study, series stays series
                if word != "series" {
                    lemma = String(word.dropLast(3)) + "y"
                }
            } else if word.hasSuffix("ses") && word.count > 4 {
                // sequences -> sequence
                lemma = String(word.dropLast(2))
            } else if word.hasSuffix("s") && word.count > 3 && !word.hasSuffix("ss") {
                // terms -> term, but not class -> clas
                lemma = String(word.dropLast())
            }
            
            // -ing forms
            if lemma.hasSuffix("ing") && lemma.count > 5 {
                lemma = String(lemma.dropLast(3))
            }
            
            // -ed forms
            if lemma.hasSuffix("ed") && lemma.count > 4 {
                lemma = String(lemma.dropLast(2))
            }
            
            return lemma
        }
    }
    
    private func fuzzyMatch(_ word: String, in wordList: [String], threshold: Float) -> Bool {
        for target in wordList {
            // Check the whole phrase
            let similarity = levenshteinSimilarity(word.lowercased(), target.lowercased())
            if similarity >= threshold {
                return true
            }
            
            // Also check individual words in the phrase
            let targetWords = target.lowercased().components(separatedBy: .whitespaces)
            for targetWord in targetWords where targetWord.count > 2 {
                let wordSimilarity = levenshteinSimilarity(word.lowercased(), targetWord)
                if wordSimilarity >= threshold {
                    return true
                }
            }
        }
        return false
    }
    
    private func levenshteinSimilarity(_ s1: String, _ s2: String) -> Float {
        let distance = levenshteinDistance(s1, s2)
        let maxLength = max(s1.count, s2.count)
        
        guard maxLength > 0 else { return 1.0 }
        
        return 1.0 - (Float(distance) / Float(maxLength))
    }
    
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)
        
        guard !s1Array.isEmpty && !s2Array.isEmpty else {
            return max(s1Array.count, s2Array.count)
        }
        
        var matrix = [[Int]](repeating: [Int](repeating: 0, count: s2Array.count + 1), count: s1Array.count + 1)
        
        for i in 0...s1Array.count { matrix[i][0] = i }
        for j in 0...s2Array.count { matrix[0][j] = j }
        
        for i in 1...s1Array.count {
            for j in 1...s2Array.count {
                let cost = s1Array[i-1] == s2Array[j-1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i-1][j] + 1,
                    matrix[i][j-1] + 1,
                    matrix[i-1][j-1] + cost
                )
            }
        }
        
        return matrix[s1Array.count][s2Array.count]
    }
}
// MARK: - TopicMatch Model

struct TopicMatch: Identifiable {
    let id = UUID()
    let subtopic: Subtopic
    let confidence: Float
    let rawScore: Float
}
