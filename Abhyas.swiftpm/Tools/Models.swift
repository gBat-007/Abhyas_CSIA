import Foundation

// MARK: - Syllabus (Static JSON)
struct Subject: Codable, Identifiable {
    let id: String
    let name: String
    let shortName: String
    let code: String
    let level: String
    let totalTopics: Int
    let assessmentObjectives: [String]
    let topics: [Topic]
}

struct Topic: Codable, Identifiable {
    let id: String
    let number: String
    let title: String
    let subjectCode: String
    let syllabusDescription: String
    let teachingHours: Int?
    let subtopics: [Subtopic]
}

struct Subtopic: Codable, Identifiable {
    let id: String
    let number: String
    let title: String
    let subjectCode: String
    let topicNumber: String
    let syllabusContent: String
    let syllabusGuidance: String?
    let keywords: [String]
    let coreConcepts: [String]
    let commonMisconceptions: [String]?
    let prerequisites: [String]
    let relatedSubtopics: [String]?
    let paperTypes: [String]
    let typicalMarks: String?
    let commandTerms: [String]
    let bloomLevel: Int
    let teachingHours: Int?
    let questionExamples: QuestionExamples
}

struct QuestionExamples: Codable {
    let conceptual: [String]
    let examStyle: [String]
}

struct UserProfile: Codable, Identifiable {
    let id: UUID
    var subjects: [String]
    let createdAt: Date
    var lastCheckIn: Date?
    
    init(subjects: [String]) {
        self.id = UUID()
        self.subjects = subjects
        self.createdAt = Date()
    }
}

struct CheckInSession: Codable, Identifiable {
    let id: UUID
    let userProfileID: UUID
    let sessionDate: Date
    var isCompleted: Bool = false
    var totalDuration: Int?
    var subjectsCount: Int = 0
    var subjectCheckIns: [SubjectCheckIn] = []
    
    init(userProfileID: UUID) {
        self.id = UUID()
        self.userProfileID = userProfileID
        self.sessionDate = Date()
    }
}

struct SubjectCheckIn: Codable, Identifiable {
    let id: UUID
    let sessionID: UUID
    let subject: String
    let inputMethod: String
    let userExplanation: String
    var identifiedTopicIDs: [String] = []
    var topicConfidences: [Float] = []
    var completedAt: Date?
    var duration: Int?
    var averageUnderstandingScore: Float?
    var subtopicCheckIns: [SubtopicCheckIn] = []
    
    init(sessionID: UUID, subject: String, inputMethod: String, explanation: String) {
        self.id = UUID()
        self.sessionID = sessionID
        self.subject = subject
        self.inputMethod = inputMethod
        self.userExplanation = explanation
    }
}

struct SubtopicCheckIn: Codable, Identifiable {
    let id: UUID
    let subjectCheckInID: UUID
    let subtopicID: String
    let wasConfirmed: Bool
    let confidenceScore: Float
    let understandingScore: Float
    var conceptualGaps: [String]?
    var understoodConcepts: [String]
    var flaggedMisconceptions: [String]?
    var missingPrerequisites: [String]?
    let completedAt: Date
    
    init(subjectCheckInID: UUID, subtopicID: String, wasConfirmed: Bool,
         confidence: Float, understanding: Float,
         conceptualGaps: [String]? = nil,
         understoodConcepts: [String] = [],
         flaggedMisconceptions: [String]? = nil,
         missingPrerequisites: [String]? = nil) {
        self.id = UUID()
        self.subjectCheckInID = subjectCheckInID
        self.subtopicID = subtopicID
        self.wasConfirmed = wasConfirmed 
        self.confidenceScore = confidence
        self.understandingScore = understanding
        self.conceptualGaps = conceptualGaps
        self.understoodConcepts = understoodConcepts
        self.flaggedMisconceptions = flaggedMisconceptions
        self.missingPrerequisites = missingPrerequisites
        self.completedAt = Date()
    }
}

struct FollowUpQA: Codable, Identifiable {
    let id: UUID
    let topicCheckInID: UUID
    let questionNumber: Int
    let question: String
    let userResponse: String
    let conceptTested: String
    let responseQuality: String?
    
    init(topicCheckInID: UUID, questionNumber: Int, question: String, userResponse: String, conceptTested: String){
        self.id = UUID()
        self.topicCheckInID = topicCheckInID
        self.questionNumber = questionNumber
        self.question = question
        self.userResponse = userResponse
        self.conceptTested = conceptTested
        self.responseQuality = nil
    }
}

struct PracticeQuestion: Codable, Identifiable {
    let id: UUID
    let subtopicID: String
    let questionType: String
    let paperType: String?
    let questionText: String
    let markscheme: String?
    let difficulty: String?
    let marksAllocated: Int?
    let generatedAt: Date
    var usedCount: Int = 0
}

struct ProgressStats: Codable, Identifiable {
    let id: UUID
    let userProfileID: UUID
    let subject: String
    let totalSubtopicCheckIns: Int
    let uniqueSubtopicsCovered: [String]
    let subtopicScoreMap: [String: Float]
    let averageUnderstandingScore: Float
    let activeConceptualGaps: Int
    let lastUpdated: Date
    let masteredTopics: [String]
    let strugglingTopics: [String]
}
