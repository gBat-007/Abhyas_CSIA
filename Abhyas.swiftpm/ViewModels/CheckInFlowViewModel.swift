import Foundation
import SwiftUI
import Vision
import VisionKit

@available(iOS 26.0, *)
@MainActor
class CheckInFlowViewModel: ObservableObject {
    @Published var currentStep: CheckInStep = .input
    @Published var selectedSubject: String?
    @Published var inputMode: InputMode = .text
    @Published var userExplanation: String = ""
    @Published var capturedImage: UIImage?
    @Published var isProcessing = false
    @Published var identifiedTopics: [TopicMatch] = []
    @Published var selectedTopicIDs: Set<String> = []
    @Published var currentQuestionIndex = 0
    @Published var followUpQuestions: [FollowUpQuestion] = []
    @Published var answers: [String] = []
    @Published var selectedSubtopics: [Subtopic] = []
    @Published var currentSubtopicIndex: Int = 0
    @Published var followUpQAsMap: [String: [FollowUpQA]] = [:]
    @Published var gapAnalysisMap: [String: GapAnalysisResult] = [:]
    
    // New: track what was tested per subtopic
    @Published var testedConceptsMap: [String: [String]] = [:]
    @Published var testedMisconceptionsMap: [String: [String]] = [:]
    
    private let dataManager = DataManager()
    // Attached application view-model (set by the hosting view)
    private var appViewModel: AppViewModel?

    func setAppViewModel(_ vm: AppViewModel) {
        self.appViewModel = vm
    }
    
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
        selectedSubtopics = identifiedTopics
            .filter { selectedTopicIDs.contains($0.subtopic.id) }
            .map { $0.subtopic }
        
        guard !selectedSubtopics.isEmpty else { return }
        
        currentSubtopicIndex = 0
        currentStep = .followUp
    }
    
    // Updated: capture what was tested and move to gap analysis
    func advanceFromFollowUp(with followUpQAs: [FollowUpQA], testedConcepts: [String], testedMisconceptions: [String]) async {
        guard let subtopic = currentSubtopic else { return }
        
        followUpQAsMap[subtopic.id] = followUpQAs
        testedConceptsMap[subtopic.id] = testedConcepts
        testedMisconceptionsMap[subtopic.id] = testedMisconceptions
        
        currentStep = .gapAnalysis
    }
    
    func storeGapAnalysis(_ result: GapAnalysisResult, for subtopicID: String) {
        gapAnalysisMap[subtopicID] = result
    }
    
    func advanceFromGapAnalysis() {
        if currentSubtopicIndex + 1 < selectedSubtopics.count {
            currentSubtopicIndex += 1
            currentStep = .followUp
        } else {
            saveCheckInData()
            currentStep = .complete
        }
    }
    
    private func saveCheckInData() {
        // Build session from the attached AppViewModel's profile
        guard let appVM = appViewModel, let profile = appVM.userProfile else { return }

        var session = CheckInSession(userProfileID: profile.id)
        session.isCompleted = true
        session.subjectsCount = 1

        var subjectCheckIn = SubjectCheckIn(
            sessionID: session.id,
            subject: selectedSubject ?? "",
            inputMethod: inputMode.rawValue,
            explanation: userExplanation
        )
        subjectCheckIn.identifiedTopicIDs = selectedSubtopics.map { $0.id }
        subjectCheckIn.topicConfidences = identifiedTopics.prefix(selectedSubtopics.count).map { $0.confidence }
        subjectCheckIn.completedAt = Date()
        
        var subtopicCheckIns: [SubtopicCheckIn] = []
        
        for (index, topic) in selectedSubtopics.enumerated() {
            guard let analysis = gapAnalysisMap[topic.id] else { continue }
            
            let wasConfirmed = index < identifiedTopics.count
            let confidence = wasConfirmed ? identifiedTopics[index].confidence : 0.0
            
            let subtopicCheckIn = SubtopicCheckIn(
                subjectCheckInID: subjectCheckIn.id,
                subtopicID: topic.id,
                wasConfirmed: wasConfirmed,
                confidence: confidence,
                understanding: analysis.understandingScore,
                conceptualGaps: analysis.conceptualGaps.isEmpty ? nil : analysis.conceptualGaps,
                understoodConcepts: analysis.understoodConcepts,
                flaggedMisconceptions: analysis.flaggedMisconceptions.isEmpty ? nil : analysis.flaggedMisconceptions,
                missingPrerequisites: analysis.missingPrerequisites.isEmpty ? nil : analysis.missingPrerequisites
            )
            
            subtopicCheckIns.append(subtopicCheckIn)
        }
        
        subjectCheckIn.subtopicCheckIns = subtopicCheckIns
        
        let totalScore = subtopicCheckIns.map { $0.understandingScore }.reduce(0, +)
        subjectCheckIn.averageUnderstandingScore = subtopicCheckIns.isEmpty ? 0 : totalScore / Float(subtopicCheckIns.count)
        
        session.subjectCheckIns = [subjectCheckIn]
        // Append to in-memory AppViewModel and persist
        appViewModel?.addSession(session)
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
    
    func reset() {
        currentStep = .input
        selectedSubject = nil
        inputMode = .text
        userExplanation = ""
        capturedImage = nil
        isProcessing = false
        identifiedTopics = []
        selectedTopicIDs = []
        currentQuestionIndex = 0
        followUpQuestions = []
        answers = []
        selectedSubtopics = []
        currentSubtopicIndex = 0
        followUpQAsMap = [:]
        gapAnalysisMap = [:]
        testedConceptsMap = [:]
        testedMisconceptionsMap = [:]
    }
}

enum CheckInStep {
    case input
    case topicSelection
    case followUp
    case gapAnalysis
    case complete
}

enum InputMode: String, CaseIterable {
    case text = "Text"
    case photo = "Photo"
}

struct FollowUpQuestion: Identifiable {
    let id = UUID()
    let text: String
    let concept: String
}
