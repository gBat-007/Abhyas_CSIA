import Foundation
import SwiftUI
import FoundationModels

@MainActor
@available(iOS 26.0, *)
@Observable
class FollowUpQuestionsViewModel {
    var questions: [String] = []
    var currentGeneratingQuestion: String = ""
    var isGeneratingCurrentQuestion: Bool = false
    var errorMessage: String?
    
    var testedConcepts: [String] = []
    var testedMisconceptions: [String] = []
    
    private let session: LanguageModelSession
    let maxQuestionsToGenerate = 3
    
    init() {
        session = LanguageModelSession()
    }
    
    // MARK: - Generate NEXT question
    func generateNextQuestion(
        for subtopic: Subtopic,
        userExplanation: String,
        previousAnswers: [String] = [],
        onComplete: @escaping () -> Void
    ) async {
        guard questions.count < maxQuestionsToGenerate else {
            isGeneratingCurrentQuestion = false
            return
        }
        
        isGeneratingCurrentQuestion = true
        currentGeneratingQuestion = "Thinking..."
        errorMessage = nil
        
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(20))
            if self?.isGeneratingCurrentQuestion == true {
                self?.isGeneratingCurrentQuestion = false
                self?.currentGeneratingQuestion = "Generation timed out"
            }
        }
        
        let maxAttempts = 6
        var attempt = 0
        
        var target = pickNextTarget(for: subtopic)
        var strategy = pickStrategy(for: subtopic, target: target)
        
        while attempt < maxAttempts && questions.count < maxQuestionsToGenerate {
            attempt += 1
            
            let prompt = buildNextQuestionPrompt(
                subtopic: subtopic,
                userExplanation: userExplanation,
                previousQuestions: questions,
                previousAnswers: previousAnswers,
                target: target,
                strategy: strategy,
                forceDifferent: attempt > 1
            )
            
            do {
                let candidate = try await streamOneQuestion(prompt: prompt)
                
                if let accepted = acceptOrRetry(
                    proposed: candidate,
                    previousQuestions: questions
                ) {
                    finalizeAcceptedQuestion(accepted, target: target)
                    break
                } else {
                    strategy = (strategy == .deepen) ? .pivot : .deepen
                    target = pickNextTarget(for: subtopic, preferNewConcept: strategy == .pivot)
                }
            } catch {
                strategy = (strategy == .deepen) ? .pivot : .deepen
                target = pickNextTarget(for: subtopic, preferNewConcept: strategy == .pivot)
            }
        }
        
        if questions.count < maxQuestionsToGenerate && attempt >= maxAttempts {
            errorMessage = "Couldn't generate a distinct follow-up. Please try again."
        }
        
        isGeneratingCurrentQuestion = false
        currentGeneratingQuestion = ""
        onComplete()
    }
    
    // MARK: - Streaming
    private func streamOneQuestion(prompt: String) async throws -> String {
        var last = ""
        let stream = session.streamResponse(to: prompt)
        for try await response in stream {
            last = response.content
            currentGeneratingQuestion = last
        }
        return last
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
    }
    
    // MARK: - Relaxed Acceptance Gate
    private func acceptOrRetry(
        proposed: String,
        previousQuestions: [String]
    ) -> String? {
        let trimmed = proposed.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        // Allow up to 2 sentences
        let sentenceCount = trimmed
            .split(whereSeparator: { ".!?".contains($0) })
            .count
        
        guard sentenceCount <= 2 else { return nil }
        
        // Reject only near-exact duplicates (very relaxed threshold)
        if isTooSimilar(toAnyOf: previousQuestions, candidate: trimmed) {
            return nil
        }
        
        return trimmed
    }
    
    private func finalizeAcceptedQuestion(_ question: String, target: QuestionTarget) {
        questions.append(question)
        
        switch target {
        case .concept(let concept):
            if !testedConcepts.contains(concept) {
                testedConcepts.append(concept)
            }
        case .misconception(let misconception):
            if !testedMisconceptions.contains(misconception) {
                testedMisconceptions.append(misconception)
            }
        }
    }
    
    // MARK: - Target Selection
    
    private enum QuestionTarget {
        case concept(String)
        case misconception(String)
    }
    
    private enum Strategy {
        case deepen
        case pivot
    }
    
    private func pickStrategy(for subtopic: Subtopic, target: QuestionTarget) -> Strategy {
        if questions.isEmpty { return .pivot }
        return .pivot
    }
    
    private func pickNextTarget(for subtopic: Subtopic, preferNewConcept: Bool = true) -> QuestionTarget {
        let allConcepts = subtopic.coreConcepts
        let allMisconceptions = subtopic.commonMisconceptions ?? []
        
        let untestedConcepts = allConcepts.filter { !testedConcepts.contains($0) }
        let untestedMisconceptions = allMisconceptions.filter { !testedMisconceptions.contains($0) }
        
        if preferNewConcept, let nextConcept = untestedConcepts.first {
            return .concept(nextConcept)
        }
        
        if let nextMisconception = untestedMisconceptions.first {
            return .misconception(nextMisconception)
        }
        
        return .concept(allConcepts.first ?? subtopic.title)
    }
    
    // MARK: - Prompt
    
    private func buildNextQuestionPrompt(
        subtopic: Subtopic,
        userExplanation: String,
        previousQuestions: [String],
        previousAnswers: [String],
        target: QuestionTarget,
        strategy: Strategy,
        forceDifferent: Bool = false
    ) -> String {
        
        let contextAnswers = previousAnswers.isEmpty
            ? ""
            : "\nPrevious answers: \(previousAnswers.joined(separator: " | "))"
        
        let previousQs = previousQuestions.isEmpty
            ? "None"
            : previousQuestions.joined(separator: " | ")
        
        let targetInstruction: String
        switch target {
        case .concept(let concept):
            targetInstruction = "Focus on this core concept: \(concept)"
        case .misconception(let misconception):
            targetInstruction = "Probe for this misconception without explicitly stating it: \(misconception)"
        }
        
        let differenceText = forceDifferent
            ? "The question should explore a different angle from earlier ones."
            : ""
        
        return """
        Create a follow-up question for IB \(subtopic.subjectCode) - \(subtopic.title).
        
        Student explanation: "\(userExplanation)"\(contextAnswers)
        
        Previous questions:
        \(previousQs)
        
        \(targetInstruction)
        \(differenceText)
        
        Guidelines:
        - Up to two sentences.
        - Avoid repeating earlier questions.
        - Do not explain anything — output only the question text.
        
        Question \(questions.count + 1)/\(maxQuestionsToGenerate):
        """
    }
    
    // MARK: - Reset
    
    func reset() {
        questions = []
        currentGeneratingQuestion = ""
        errorMessage = nil
        testedConcepts = []
        testedMisconceptions = []
    }
    
    // MARK: - Very Relaxed Similarity Check
    
    private func isTooSimilar(toAnyOf existing: [String], candidate: String, threshold: Float = 0.95) -> Bool {
        let c = candidate.lowercased()
        for q in existing {
            let sim = levenshteinSimilarity(c, q.lowercased())
            if sim >= threshold { return true }
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
        let a = Array(s1)
        let b = Array(s2)
        if a.isEmpty || b.isEmpty { return max(a.count, b.count) }
        
        var matrix = Array(
            repeating: Array(repeating: 0, count: b.count + 1),
            count: a.count + 1
        )
        
        for i in 0...a.count { matrix[i][0] = i }
        for j in 0...b.count { matrix[0][j] = j }
        
        for i in 1...a.count {
            for j in 1...b.count {
                let cost = a[i-1] == b[j-1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i-1][j] + 1,
                    matrix[i][j-1] + 1,
                    matrix[i-1][j-1] + cost
                )
            }
        }
        return matrix[a.count][b.count]
    }
}
