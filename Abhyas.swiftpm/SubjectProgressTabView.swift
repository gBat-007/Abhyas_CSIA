import SwiftUI

struct SubjectProgressTabView: View {
    @EnvironmentObject var historyVM: HistoryViewModel
    @EnvironmentObject var appVM: AppViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(historyVM.progressBySubject, id: \.subject) { p in
                    ProgressCard(progress: p)
                }
            }
            .padding()
        }
    }
}

struct ProgressCard: View {
    let progress: HistoryViewModel.SubjectProgress
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(subjectName(for: progress.subject))
                    .font(.headline)
                Spacer()
                if let d = progress.lastUpdated {
                    Text(d, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack {
                stat("Topics Covered", "\(progress.topicsCovered)")
                Divider().frame(height: 28)
                stat("Avg Understanding", "\(Int(progress.avgUnderstanding))%")
                Divider().frame(height: 28)
                stat("Active Gaps", "\(progress.activeGaps)")
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            if !progress.masteredTopics.isEmpty {
                Text("Mastered").font(.subheadline).fontWeight(.semibold)
                Text(list(progress.masteredTopics))
                    .font(.caption)
                    .foregroundStyle(.green)
            }
            if !progress.strugglingTopics.isEmpty {
                Text("Struggling").font(.subheadline).fontWeight(.semibold)
                Text(list(progress.strugglingTopics))
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
    
    private func stat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline)
        }
    }
    
    private func list(_ items: [String]) -> String {
        items.prefix(6).joined(separator: " • ")
    }
    
    private func subjectName(for code: String) -> String {
        SyllabusManager.shared.getSubject(code: code)?.name ?? code
    }
}

