import SwiftUI

@MainActor
final class HistoryViewModel: ObservableObject {
    // Source data
    @Published private(set) var sessions: [CheckInSession] = []
    
    // Filters
    @Published var selectedSubject: String? = nil
    @Published var searchText: String = ""
    
    // Derived: grouped by day (date without time)
    var groupedByDay: [(day: Date, items: [HistoryItem])] {
        let calendar = Calendar.current
        
        let items = sessions.flatMap { session -> [HistoryItem] in
            session.subjectCheckIns.flatMap { sci -> [HistoryItem] in
                sci.subtopicCheckIns.map { stci in
                    HistoryItem(
                        sessionID: session.id,
                        subject: sci.subject,
                        date: session.sessionDate,
                        subtopicID: stci.subtopicID,
                        understanding: stci.understandingScore
                    )
                }
            }
        }
        .filter { item in
            if let subj = selectedSubject, !subj.isEmpty {
                return item.subject == subj
            }
            return true
        }
        .filter { item in
            // Search on subtopic title/number
            guard !searchText.isEmpty,
                  let sub = SyllabusManager.shared.getSubtopic(id: item.subtopicID)
            else { return searchText.isEmpty }
            let hay = (sub.title + " " + sub.number).lowercased()
            return hay.contains(searchText.lowercased())
        }
        
        let grouped = Dictionary(grouping: items) { item in
            calendar.startOfDay(for: item.date)
        }
        .map { (key, vals) in
            (day: key, items: vals.sorted { $0.date > $1.date })
        }
        .sorted { $0.day > $1.day }
        
        return grouped
    }
    
    // Subject progress aggregation
    struct SubjectProgress {
        let subject: String
        let topicsCovered: Int
        let avgUnderstanding: Float
        let activeGaps: Int
        let lastUpdated: Date?
        let masteredTopics: [String]
        let strugglingTopics: [String]
    }
    
    var progressBySubject: [SubjectProgress] {
        // Build map subject -> [SubtopicCheckIn]
        var map: [String: [SubtopicCheckIn]] = [:]
        for session in sessions {
            for sci in session.subjectCheckIns {
                map[sci.subject, default: []].append(contentsOf: sci.subtopicCheckIns)
            }
        }
        
        return map.keys.sorted().compactMap { subject in
            let subs = map[subject] ?? []
            guard !subs.isEmpty else { return nil }
            
            // Unique subtopics covered
            let uniqueByID = Dictionary(grouping: subs, by: { $0.subtopicID })
            let topicsCovered = uniqueByID.keys.count
            
            // Average understanding
            let avg = subs.map { $0.understandingScore }.reduce(0, +) / Float(subs.count)
            
            // Active gaps: unique concepts where understanding < 60% (proxy)
            // We don’t store per-concept scores; use subtopic-level gaps if present.
            let activeGapIDs = subs.filter { $0.understandingScore < 60 }.map { $0.subtopicID }
            let activeGaps = Set(activeGapIDs).count
            
            // Mastered/struggling topic titles
            let masteredIDs = subs.filter { $0.understandingScore >= 80 }.map { $0.subtopicID }
            let strugglingIDs = subs.filter { $0.understandingScore < 60 }.map { $0.subtopicID }
            let masteredTitles = masteredIDs.compactMap { SyllabusManager.shared.getSubtopic(id: $0)?.title }
            let strugglingTitles = strugglingIDs.compactMap { SyllabusManager.shared.getSubtopic(id: $0)?.title }
            
            // Last updated
            let lastDate = sessions
                .filter { s in s.subjectCheckIns.contains(where: { $0.subject == subject }) }
                .map { $0.sessionDate }
                .max()
            
            return SubjectProgress(
                subject: subject,
                topicsCovered: topicsCovered,
                avgUnderstanding: avg,
                activeGaps: activeGaps,
                lastUpdated: lastDate,
                masteredTopics: Array(Set(masteredTitles)).sorted(),
                strugglingTopics: Array(Set(strugglingTitles)).sorted()
            )
        }
    }
    
    func load(from appVM: AppViewModel) {
        sessions = appVM.checkInSessions
        // Default filter to first subject if none
        if selectedSubject == nil {
            selectedSubject = appVM.userProfile?.subjects.first
        }
    }
}

struct HistoryItem: Identifiable {
    let id = UUID()
    let sessionID: UUID
    let subject: String
    let date: Date
    let subtopicID: String
    let understanding: Float
}
