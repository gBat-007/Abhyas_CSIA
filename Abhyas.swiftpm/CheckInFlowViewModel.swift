import Foundation
import SwiftUI
import Vision
import VisionKit

@MainActor
class CheckInFlowViewModel: ObservableObject {
    @Published var currentStep: CheckInStep = .input
    
    // Step 1: Subject Selection
    @Published var selectedSubject: String?
    
    // Step 2: Input
    @Published var inputMode: InputMode = .text
    @Published var userExplanation: String = ""
    @Published var capturedImage: UIImage?
    @Published var isProcessing = false
    
    // Step 3: Topic Matching
    @Published var identifiedTopics: [TopicMatch] = []
    @Published var selectedTopicIDs: Set<String> = []
    
    // Step 4: Follow-up Questions
    @Published var currentQuestionIndex = 0
    @Published var followUpQuestions: [FollowUpQuestion] = []
    @Published var answers: [String] = []
    
    // NEW: track subtopics sequence
    @Published var selectedSubtopics: [Subtopic] = []
    @Published var currentSubtopicIndex: Int = 0
    
    // Convenience
    var currentSubtopic: Subtopic? {
        guard currentSubtopicIndex < selectedSubtopics.count else { return nil }
        return selectedSubtopics[currentSubtopicIndex]
    }
    
    func analyzeInput() {
        guard let subject = selectedSubject else { return }
        
        isProcessing = true
        
        Task {
            identifiedTopics = SyllabusManager.shared.identifyTopics(
                userExplanation: userExplanation,
                subjectCode: subject
            )
            
            // preselect >= 70% as before
            selectedTopicIDs = Set(
                identifiedTopics
                    .filter { $0.confidence >= 70 }
                    .map { $0.subtopic.id }
            )
            
            isProcessing = false
            currentStep = .topicSelection
        }
    }
    
    func confirmTopics() {
        // Build ordered list of selected subtopics
        selectedSubtopics = identifiedTopics
            .filter { selectedTopicIDs.contains($0.subtopic.id) }
            .map { $0.subtopic }
        
        guard !selectedSubtopics.isEmpty else { return }
        
        currentSubtopicIndex = 0
        currentStep = .followUp
    }
    
    // Called when user finishes follow-ups for one subtopic
    func advanceFromFollowUp() {
        if currentSubtopicIndex + 1 < selectedSubtopics.count {
            currentSubtopicIndex += 1      // go to next subtopic
        } else {
            currentStep = .complete        // all done
        }
    }
    
    func goBack() {
        switch currentStep {
        case .topicSelection:
            currentStep = .input
        case .followUp:
            currentStep = .topicSelection
        default:
            break
        }
    }
}


enum CheckInStep {
    case input
    case topicSelection
    case followUp
    case complete
}

enum InputMode: String, CaseIterable {
    case voice = "Voice"
    case text = "Text"
    case photo = "Photo"
}

struct FollowUpQuestion: Identifiable {
    let id = UUID()
    let text: String
    let concept: String
}

