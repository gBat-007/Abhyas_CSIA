import Foundation
import SwiftUI

enum PracticeMode: String, CaseIterable {
    case conceptual
    case examStyle
    
    var title: String {
        switch self {
        case .conceptual: return "Conceptual"
        case .examStyle: return "Exam-style"
        }
    }
}

enum PracticeScopeType: String, CaseIterable {
    case entireSubject
    case topicRange
    case entireTopic
    case subtopicRange
    case singleSubtopic
    
    var title: String {
        switch self {
        case .entireSubject: return "Entire Subject"
        case .topicRange: return "Range of Topics"
        case .entireTopic: return "Entire Topic"
        case .subtopicRange: return "Range of Subtopics"
        case .singleSubtopic: return "Single Subtopic"
        }
    }
}

struct PracticeSession: Identifiable {
    let id = UUID()
    let subjectCode: String
    let mode: PracticeMode
    let generatedAt: Date
    let questions: [PracticeQuestionItem]
}

struct PracticeQuestionItem: Identifiable {
    let id = UUID()
    let subtopicID: String
    let text: String
    let type: PracticeMode
    let paperType: String?
    let bloomLevel: Int?
    let marks: Int?
    let commandTerms: [String]
}

@MainActor
@available(iOS 26.0, *)
final class PracticeQuestionsViewModel: ObservableObject {
    // Inputs
    @Published var mode: PracticeMode = .conceptual
    @Published var selectedSubjectCode: String?
    @Published var scopeType: PracticeScopeType = .entireSubject
    @Published var selectedTopicNumbers: Set<String> = []
    @Published var selectedSubtopicNumbers: Set<String> = []
    @Published var questionCount: Int = 5
    
    // Output
    @Published var generated: PracticeSession = PracticeSession(subjectCode: "", mode: .conceptual, generatedAt: Date(), questions: [])
    @Published var isGenerating = false
    @Published var generationError: String?
    
    // Persistence handle
    private var appVM: AppViewModel?
    private let dataManager = DataManager()
    private let generator = PracticeLLMGenerator()
    
    var canGenerate: Bool {
        guard let code = selectedSubjectCode else { return false }
        switch scopeType {
        case .entireSubject:
            return !code.isEmpty
        case .topicRange:
            return !selectedTopicNumbers.isEmpty
        case .entireTopic:
            return selectedTopicNumbers.count == 1
        case .subtopicRange:
            return !selectedSubtopicNumbers.isEmpty && selectedTopicNumbers.count == 1
        case .singleSubtopic:
            return selectedSubtopicNumbers.count == 1 && selectedTopicNumbers.count == 1
        }
    }
    
    func bindAppData(_ appVM: AppViewModel) {
        self.appVM = appVM
    }
    
    func presetSingleSubtopic(subjectCode: String, topicNumber: String, subtopicNumber: String, mode: PracticeMode = .examStyle, count: Int = 5) {
        self.selectedSubjectCode = subjectCode
        self.scopeType = .singleSubtopic
        self.selectedTopicNumbers = [topicNumber]
        self.selectedSubtopicNumbers = [subtopicNumber]
        self.mode = mode
        self.questionCount = count
    }
    
    func generate() {
        guard let code = selectedSubjectCode else { return }
        isGenerating = true
        generationError = nil
        
        Task {
            let subtopics = resolveScopeSubtopics()
            do {
                var items: [PracticeQuestionItem] = []
                var attemptsRemaining = 3 // Retry up to 3 times to get exact count
                
                while items.count < questionCount && attemptsRemaining > 0 {
                    attemptsRemaining -= 1
                    let needed = questionCount - items.count
                    
                    // Request extra questions to account for possible rejections
                    let requestCount = Int(Double(needed) * 1.2) + 1  // Request 20% extra
                    
                    // Split into batches if more than 5 questions to avoid overwhelming LLM
                    if requestCount > 5 {
                        let firstBatch = 5
                        let secondBatch = requestCount - 5
                        
                        // Generate first batch
                        let firstItems = try await generator.generateQuestions(
                            subjectCode: code,
                            subtopics: subtopics,
                            mode: mode,
                            count: firstBatch
                        )
                        items.append(contentsOf: firstItems)
                        
                        // Generate second batch
                        let secondItems = try await generator.generateQuestions(
                            subjectCode: code,
                            subtopics: subtopics,
                            mode: mode,
                            count: secondBatch
                        )
                        items.append(contentsOf: secondItems)
                    } else if requestCount > 0 {
                        // Request exactly what we need (plus buffer)
                        let moreItems = try await generator.generateQuestions(
                            subjectCode: code,
                            subtopics: subtopics,
                            mode: mode,
                            count: requestCount
                        )
                        items.append(contentsOf: moreItems)
                    }
                }
                
                // If we still don't have enough after retries
                if items.count < questionCount {
                    throw PracticeQuestionsViewModel.GenerationError.insufficientQuestions(requested: questionCount, received: items.count)
                }
                
                // Ensure exactly the right number (in case we got more somehow)
                let finalItems = Array(items.prefix(questionCount))
                
                let session = PracticeSession(subjectCode: code, mode: mode, generatedAt: Date(), questions: finalItems)
                await MainActor.run {
                    self.generated = session
                    self.isGenerating = false
                }
                persistGenerated(items: finalItems)
            } catch {
                await MainActor.run {
                    self.isGenerating = false
                    self.generationError = error.localizedDescription
                }
            }
        }
    }
    
    enum GenerationError: LocalizedError {
        case insufficientQuestions(requested: Int, received: Int)
        
        var errorDescription: String? {
            switch self {
            case .insufficientQuestions(let req, let rec):
                return "Could only generate \(rec) of \(req) requested questions. Try again with fewer questions or a narrower scope."
            }
        }
    }
    
    private func resolveScopeSubtopics() -> [Subtopic] {
        guard let code = selectedSubjectCode, let subject = SyllabusManager.shared.getSubject(code: code) else { return [] }
        
        switch scopeType {
        case .entireSubject:
            // Cap at 2-3 subtopics to avoid context window overflow
            // Entire subject draws from all topics; metadata bloat is significant
            let allSubtopics = subject.topics.flatMap { $0.subtopics }
            return smartlySelectSubtopics(from: allSubtopics, limit: 2)
            
        case .topicRange:
            let chosen = subject.topics.filter { selectedTopicNumbers.contains($0.number) }
            let allSubtopics = chosen.flatMap { $0.subtopics }
            return smartlySelectSubtopics(from: allSubtopics, limit: 3)
            
        case .entireTopic:
            guard let number = selectedTopicNumbers.first,
                  let topic = subject.topics.first(where: { $0.number == number }) else { return [] }
            return topic.subtopics
            
        case .subtopicRange:
            guard let number = selectedTopicNumbers.first,
                  let topic = subject.topics.first(where: { $0.number == number }) else { return [] }
            return topic.subtopics.filter { selectedSubtopicNumbers.contains($0.number) }
            
        case .singleSubtopic:
            guard let number = selectedTopicNumbers.first,
                  let topic = subject.topics.first(where: { $0.number == number }),
                  let subNum = selectedSubtopicNumbers.first,
                  let sub = topic.subtopics.first(where: { $0.number == subNum }) else { return [] }
            return [sub]
        }
    }
    
    /// Intelligently select subtopics: prioritize weaker areas, cap at limit, with randomness
    private func smartlySelectSubtopics(from subtopics: [Subtopic], limit: Int) -> [Subtopic] {
        guard subtopics.count > limit else { return subtopics }
        
        // Get progress stats to identify struggling topics
        let progressBySubtopic = buildProgressMap()
        
        // Separate into struggling and others
        var struggling: [Subtopic] = []
        var others: [Subtopic] = []
        
        for sub in subtopics {
            let score = progressBySubtopic[sub.id] ?? 100.0
            if score < 70.0 {
                struggling.append(sub)
            } else {
                others.append(sub)
            }
        }
        
        // Shuffle each group
        struggling.shuffle()
        others.shuffle()
        
        // Priority: struggling topics first, then random others
        let prioritized = (struggling + others).prefix(limit)
        return Array(prioritized)
    }
    
    /// Build a map of subtopic ID -> average understanding score from progress
    private func buildProgressMap() -> [String: Float] {
        guard let appVM = appVM else { return [:] }
        
        var map: [String: [Float]] = [:]
        
        // Collect understanding scores per subtopic from shard history
        for session in appVM.checkInSessions {
            for subjectCheckIn in session.subjectCheckIns {
                for subtopicCheckIn in subjectCheckIn.subtopicCheckIns {
                    map[subtopicCheckIn.subtopicID, default: []].append(subtopicCheckIn.understandingScore)
                }
            }
        }
        
        // Average each subtopic
        let result = map.mapValues { scores in
            scores.reduce(0, +) / Float(scores.count)
        }
        return result
    }
    
    private func persistGenerated(items: [PracticeQuestionItem]) {
        guard !items.isEmpty else { return }
        let loaded: AppData
        do {
            loaded = try dataManager.loadUserData()
        } catch {
            return
        }
        var appData = loaded
        let toAppend: [PracticeQuestion] = items.map { item in
            PracticeQuestion(
                id: UUID(),
                subtopicID: item.subtopicID,
                questionType: item.type == .conceptual ? "conceptual" : "examStyle",
                paperType: item.paperType,
                questionText: item.text,
                markscheme: nil,
                difficulty: nil,
                marksAllocated: item.marks,
                generatedAt: Date(),
                usedCount: 0
            )
        }
        appData.practiceQuestions.append(contentsOf: toAppend)
        try? dataManager.saveUserData(appData)
    }
}
