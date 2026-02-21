import Foundation
import FoundationModels

// MARK: - Structured Output

@available(iOS 26.0, *)
@Generable
struct GeneratedQuestionResponse {
    let questions: [GeneratedQuestion]
}

@available(iOS 26.0, *)
@Generable
struct GeneratedQuestion {
    let subtopicID: String
    let text: String
    let bloomLevel: Int?
    let marks: Int?
}

// MARK: - Generator

@available(iOS 26.0, *)
struct PracticeLLMGenerator {

    enum GenerationError: Error, LocalizedError {
        case emptyScope
        case insufficientQuestions
        case invalidQuestion

        var errorDescription: String? {
            switch self {
            case .emptyScope:
                return "No subtopics available for the selected scope."
            case .insufficientQuestions:
                return "Model did not return the required number of questions."
            case .invalidQuestion:
                return "Model returned invalid question data."
            }
        }
    }

    private let session = LanguageModelSession()

    // MARK: - Public API

    func generateQuestions(
        subjectCode: String,
        subtopics: [Subtopic],
        mode: PracticeMode,
        count: Int
    ) async throws -> [PracticeQuestionItem] {

        guard !subtopics.isEmpty else {
            throw GenerationError.emptyScope
        }

        let prompt = buildPrompt(
            subjectCode: subjectCode,
            subtopics: subtopics,
            mode: mode,
            count: count
        )

        // ✅ CORRECT FOUNDATION MODELS STRUCTURED CALL
        let structuredResponse = try await session.respond(
            to: prompt,
            generating: GeneratedQuestionResponse.self
        )

        let questions = structuredResponse.content.questions

        guard questions.count == count else {
            throw GenerationError.insufficientQuestions
        }

        return try validate(
            questions,
            subtopics: subtopics,
            mode: mode
        )
    }

    // MARK: - Validation

    private func validate(
        _ questions: [GeneratedQuestion],
        subtopics: [Subtopic],
        mode: PracticeMode
    ) throws -> [PracticeQuestionItem] {

        var items: [PracticeQuestionItem] = []

        for question in questions {

            guard subtopics.contains(where: { $0.id == question.subtopicID }) else {
                throw GenerationError.invalidQuestion
            }

            guard question.text.count >= 10,
                  question.text.count <= 400 else {
                throw GenerationError.invalidQuestion
            }

            if mode == .examStyle {
                guard let marks = question.marks,
                      marks >= 2,
                      marks <= 8 else {
                    throw GenerationError.invalidQuestion
                }
            }

            items.append(
                PracticeQuestionItem(
                    subtopicID: question.subtopicID,
                    text: question.text,
                    type: mode,
                    paperType: nil,
                    bloomLevel: question.bloomLevel ??
                        (mode == .conceptual ? 3 : 4),
                    marks: question.marks,
                    commandTerms: []
                )
            )
        }

        return items
    }

    // MARK: - Prompt

    private func buildPrompt(
        subjectCode: String,
        subtopics: [Subtopic],
        mode: PracticeMode,
        count: Int
    ) -> String {

        let subtopicList = subtopics
            .prefix(3)
            .map { "\($0.id): \($0.title)" }
            .joined(separator: "\n")

        return """
        You are an expert IB-\(subjectCode) question writer.

        Generate EXACTLY \(count) questions.

        MODE: \(mode == .conceptual ? "CONCEPTUAL" : "EXAM-STYLE")

        Available Subtopics:
        \(subtopicList)

        Requirements:
        - EXACTLY \(count) questions
        - Each question must test ONE skill
        - Length 10–400 characters
        - Exam-style: marks 2–8, bloom level 3–5
        - Conceptual: no marks, bloom level 2–4
        - Use only the provided subtopic IDs
        """
    }
}
