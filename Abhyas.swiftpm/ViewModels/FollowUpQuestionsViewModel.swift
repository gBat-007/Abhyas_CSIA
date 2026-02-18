import Foundation
import SwiftUI
import FoundationModels

@MainActor
@available(iOS 26.0, *)
@Observable
class FollowUpQuestionsViewModel {
    var justGeneratedQuestionIndex: Int = -1
    var questions: [String] = []
    var currentGeneratingQuestion: String = ""
    var isGeneratingCurrentQuestion: Bool = false
    var errorMessage: String?
    var modelAvailable: Bool = false
    var unavailableReason: String = ""
    
    private let session: LanguageModelSession
    let maxQuestionsToGenerate = 3
    
    init() {
        session = LanguageModelSession(/* your instructions */)
    }
    
    // MARK: - Generate NEXT question on-demand
    
    /*
     func generateNextQuestion(...) async {
         print("🔄 Generating Q\(questions.count + 1) - currentIndex: \(currentQuestionIndex ?? 0)")
         
         guard questions.count < maxQuestionsToGenerate else {
             print("⏹️ Max 3 questions reached")
             return
         }
         
         isGeneratingCurrentQuestion = true
         // ... rest of generation ...
         
         isGeneratingCurrentQuestion = false  // ✅ MUST end here
         print("✅ Q\(questions.count) complete")
     }

     
     */
    func generateNextQuestion(
        for subtopic: Subtopic,
        userExplanation: String,
        previousAnswers: [String] = [],  // ✅ Future: context from prior answers
        onComplete: @escaping () -> Void
    ) async {
        guard questions.count < maxQuestionsToGenerate else {
                print("Max questions reached")
                isGeneratingCurrentQuestion = false
                return
        }
        print("🚀 START generate Q\(questions.count + 1)")
            isGeneratingCurrentQuestion = true
            currentGeneratingQuestion = "Thinking..."
            
        let prompt = buildNextQuestionPrompt(
            subtopic: subtopic,
            userExplanation: userExplanation,
            previousAnswers: previousAnswers
        )
            // TIMEOUT SAFETY
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(15))
                if self?.isGeneratingCurrentQuestion == true {
                    print("⏰ TIMEOUT - forcing end")
                    self?.isGeneratingCurrentQuestion = false
                    self?.currentGeneratingQuestion = "Generation timed out"
                }
            }
            
            do {
                let stream = session.streamResponse(to: prompt)
                
                for try await response in stream {
                    currentGeneratingQuestion = response.content
                    print("📝 Streaming: \(response.content.prefix(50))...")
                }
                
                let finalQuestion = currentGeneratingQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
                questions.append(finalQuestion)
                print("✅ SUCCESS: Added '\(finalQuestion)'")
                
            } catch {
                print("❌ ERROR: \(error)")
                questions.append("Explain \(subtopic.title) in your own words.")
            }
            
            // ✅ CRITICAL: Always end generation
            print("🏁 END generate - isGeneratingCurrentQuestion = false")
            isGeneratingCurrentQuestion = false
            onComplete()
            currentGeneratingQuestion = ""
    }
    
    // MARK: - Context-aware prompt
    private func buildNextQuestionPrompt(
        subtopic: Subtopic,
        userExplanation: String,
        previousAnswers: [String]
    ) -> String {
        let context = previousAnswers.isEmpty
            ? ""
            : "\nPrevious answers: \(previousAnswers.joined(separator: " | "))"
        
        return """
        Create ONE follow-up question for IB \(subtopic.subjectCode).
        
        Topic: \(subtopic.title)
        Syllabus: \(subtopic.syllabusContent)
        Core concepts: \(subtopic.coreConcepts.joined(separator: "; "))
        
        Student explanation: "\(userExplanation)"\(context)
        
        Ask ONE conceptual question:
        - Use "Explain", "Why", "How", "Compare", etc.
        - 1 sentence maximum
        - End with "?"
        - Just the question, no explanation
        
        Question \(questions.count + 1)/3:
        """
    }
    
    // Reset for new subtopic
    func reset() {
        questions = []
        currentGeneratingQuestion = ""
        errorMessage = nil
    }
}


// MARK: - Generable Response Type
@available(iOS 26, *)
@Generable
struct QuestionResponse {
    @Guide(description: "An array of exactly 3 follow-up questions, each ending with a question mark")
    var questions: [String]?
}
