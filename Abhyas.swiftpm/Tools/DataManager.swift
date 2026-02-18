import Foundation

struct AppData: Codable {
    var userProfile: UserProfile?
    var checkInSessions: [CheckInSession] = []
    var practiceQuestions: [PracticeQuestion] = []
    var progressStats: [ProgressStats] = []
}

class DataManager {
    private let userDataURL: URL
    private let syllabusURL: URL?
    
    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        userDataURL = docs.appendingPathComponent("userData.json")
        syllabusURL = Bundle.main.url(forResource: "IBDPSyllabus", withExtension: "json")
    }
    
    // MARK: - User Data
    func saveUserData(_ data: AppData) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try encoder.encode(data)
        try jsonData.write(to: userDataURL)
    }
    
    func loadUserData() throws -> AppData {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let data = try? Data(contentsOf: userDataURL) {
            return try decoder.decode(AppData.self, from: data)
        }
        return AppData()
    }
    
    // MARK: - Syllabus (Read-only)
    func loadSyllabus() throws -> [Subject] {
        guard let url = Bundle.main.url(forResource: "IBDPSyllabus", withExtension: "json") else {
            throw NSError(domain: "SyllabusError", code: 404, userInfo: [NSLocalizedDescriptionKey: "IBDPSyllabus.json not found"])
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([Subject].self, from: data)
    }
}
