import SwiftUI

@available(iOS 17.0, *)
struct CheckInHistoryView: View {
    @EnvironmentObject var appVM: AppViewModel
    @StateObject private var historyVM = HistoryViewModel()
    @State private var selectedTab: Tab = .daily
    @State private var showEmptyAlert = false
    @State private var showShareSheet = false
    
    enum Tab {
        case daily
        case progress
    }
    
    var body: some View {
        ZStack {
            if appVM.checkInSessions.isEmpty {
                // Empty state view
                VStack(spacing: 24) {
                    Spacer()
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.2, green: 0.6, blue: 0.9),
                                    Color(red: 0.5, green: 0.3, blue: 0.9)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    VStack(spacing: 8) {
                        Text("No Shards Yet")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.primary)
                        
                        Text("Start your learning journey by adding your first shard. Record your daily insights and understanding of concepts.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            } else {
                TabView(selection: $selectedTab) {
                    DailyHistoryTabView()
                        .environmentObject(historyVM)
                        .environmentObject(appVM)
                        .tabItem {
                            Label("History", systemImage: "calendar.badge.clock")
                        }
                        .tag(Tab.daily)
                    
                    SubjectProgressTabView()
                        .environmentObject(historyVM)
                        .environmentObject(appVM)
                        .tabItem {
                            Label("Progress", systemImage: "chart.bar.fill")
                        }
                        .tag(Tab.progress)
                }
            }
        }
        .navigationTitle("Past Shards")
        .toolbar {
            if !appVM.checkInSessions.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
        }
        .onAppear {
            showEmptyAlert = appVM.checkInSessions.isEmpty
            historyVM.load(from: appVM)
        }
        .onChange(of: appVM.checkInSessions.count) { _, _ in
            historyVM.load(from: appVM)
        }
        .accentColor(Color(red: 1.0, green: 0.75, blue: 1.0))
        // Pass sessions directly — avoids @State race condition where sheet
        // opens before csvData state update has propagated
        .sheet(isPresented: $showShareSheet) {
            ShareSheetView(sessions: appVM.checkInSessions)
        }
    }
}

// MARK: - CSV Generation

private func generateCSV(from sessions: [CheckInSession]) -> String {
    var csv = "Date,Subject,Subtopic,Understanding Score,Confidence,Status,Understood Concepts,Conceptual Gaps,Misconceptions\n"
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
    
    for session in sessions {
        for subjectCheckIn in session.subjectCheckIns {
            for subtopicCheckIn in subjectCheckIn.subtopicCheckIns {
                let dateStr = dateFormatter.string(from: subtopicCheckIn.completedAt)
                
                let subject = subjectCheckIn.subject
                    .replacingOccurrences(of: "\"", with: "\"\"")
                    .replacingOccurrences(of: ",", with: ";")
                
                let subtopic = subtopicCheckIn.subtopicID
                    .replacingOccurrences(of: "\"", with: "\"\"")
                    .replacingOccurrences(of: ",", with: ";")
                
                let understanding = String(format: "%.1f", subtopicCheckIn.understandingScore)
                let confidence = String(format: "%.1f", subtopicCheckIn.confidenceScore)
                let status = subtopicCheckIn.wasConfirmed ? "Confirmed" : "Auto-Detected"
                
                let understood = subtopicCheckIn.understoodConcepts
                    .joined(separator: "; ")
                    .replacingOccurrences(of: "\"", with: "\"\"")
                
                let gaps = (subtopicCheckIn.conceptualGaps?.joined(separator: "; ") ?? "-")
                    .replacingOccurrences(of: "\"", with: "\"\"")
                
                let misconceptions = (subtopicCheckIn.flaggedMisconceptions?.joined(separator: "; ") ?? "-")
                    .replacingOccurrences(of: "\"", with: "\"\"")
                
                csv += "\"\(dateStr)\",\"\(subject)\",\"\(subtopic)\",\"\(understanding)\",\"\(confidence)\",\"\(status)\",\"\(understood)\",\"\(gaps)\",\"\(misconceptions)\"\n"
            }
        }
    }
    
    print("📊 Sessions count: \(sessions.count)")
    print("📊 CSV length: \(csv.count) characters")
    
    return csv
}

// MARK: - Share Sheet View

struct ShareSheetView: UIViewControllerRepresentable {
    let sessions: [CheckInSession]
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let csvData = generateCSV(from: sessions)
        
        let dateString = Date().formatted(date: .abbreviated, time: .omitted)
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: ",", with: "")
        let filename = "IB_Shards_\(dateString).csv"
        
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("❌ Could not access Documents directory, falling back to string")
            return UIActivityViewController(activityItems: [csvData], applicationActivities: nil)
        }
        
        let url = documentsURL.appendingPathComponent(filename)
        
        do {
            let data = Data(csvData.utf8)
            print("📁 Writing \(data.count) bytes to: \(url.path)")
            try data.write(to: url, options: .atomic)
            
            let verified = try Data(contentsOf: url)
            print("✅ Verified \(verified.count) bytes on disk")
        } catch {
            print("❌ CSV Export Error: \(error.localizedDescription)")
            return UIActivityViewController(activityItems: [csvData], applicationActivities: nil)
        }
        
        return UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
