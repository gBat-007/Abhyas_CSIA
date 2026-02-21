import Foundation
import SwiftUI

@MainActor
class AppViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var checkInSessions: [CheckInSession] = []
    @Published var syllabusLoaded = false  // ✅ ADD
    
    var recentSessions: [CheckInSession] {
        Array(checkInSessions.suffix(5))
    }
    
    private let dataManager = DataManager()
    private let syllabusManager = SyllabusManager.shared  // ✅ ADD
    
    func loadData() async {
        // Load syllabus FIRST
        do {
            try await syllabusManager.loadSyllabus()
            syllabusLoaded = true
        } catch {
            print("❌ Syllabus load error: \(error)")
        }
        
        // Then load user data
        do {
            let appData = try dataManager.loadUserData()
            userProfile = appData.userProfile
            checkInSessions = appData.checkInSessions
        } catch {
            print("User data load error: \(error)")
        }
    }
    
    func createProfile(subjects: [String]) {
        userProfile = UserProfile(subjects: subjects)
        saveData()
    }
    
    func startCheckIn() {
        guard let profileID = userProfile?.id else { return }
        let session = CheckInSession(userProfileID: profileID)
        checkInSessions.append(session)
        saveData()
    }

    // Public helper to add a completed session and persist
    func addSession(_ session: CheckInSession) {
        checkInSessions.append(session)
        saveData()
    }
    
    private func saveData() {
        let appData = AppData(
            userProfile: userProfile,
            checkInSessions: checkInSessions,
            practiceQuestions: [],
            progressStats: []
        )
        Task {
            try? dataManager.saveUserData(appData)
        }
    }
}
