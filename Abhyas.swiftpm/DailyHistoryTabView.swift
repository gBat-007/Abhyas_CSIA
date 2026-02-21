import SwiftUI

struct DailyHistoryTabView: View {
    @EnvironmentObject var historyVM: HistoryViewModel
    @EnvironmentObject var appVM: AppViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Search + Filter Header
            VStack(spacing: 12) {
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search topics", text: $historyVM.searchText)
                    if !historyVM.searchText.isEmpty {
                        Button(action: { historyVM.searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Filter button (centered)
                HStack {
                    Spacer()
                    Menu {
                        Button("All Subjects") { historyVM.selectedSubject = nil }
                        Divider()
                        ForEach(appVM.userProfile?.subjects ?? [], id: \.self) { code in
                            Button(subjectName(for: code)) { historyVM.selectedSubject = code }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text(historyVM.selectedSubject.flatMap(subjectName(for:)) ?? "All Subjects")
                        }
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                }
            }
            .padding()
            
            List {
                ForEach(historyVM.groupedByDay, id: \.day) { group in
                    Section(header: dayHeader(group.day)) {
                        ForEach(group.items) { item in
                            HistoryRow(item: item)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }
    
    private func dayHeader(_ day: Date) -> some View {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return Text(df.string(from: day))
            .font(.headline)
    }
    
    private func subjectName(for code: String) -> String {
        SyllabusManager.shared.getSubject(code: code)?.name ?? code
    }
}

struct HistoryRow: View {
    let item: HistoryItem
    
    var body: some View {
        NavigationLink {
            SessionDetailView(item: item)
        } label: {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    if let sub = SyllabusManager.shared.getSubtopic(id: item.subtopicID) {
                        Text("\(sub.number) \(sub.title)")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Text(subjectName(for: item.subject))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(item.subtopicID).font(.subheadline)
                    }
                }
                Spacer()
                Text("\(Int(item.understanding))%")
                    .font(.headline)
                    .foregroundStyle(scoreColor(item.understanding))
            }
        }
    }
    
    private func scoreColor(_ score: Float) -> Color {
        if score >= 80 { return .green }
        if score >= 60 { return .orange }
        return .red
    }
    
    private func subjectName(for code: String) -> String {
        SyllabusManager.shared.getSubject(code: code)?.name ?? code
    }
}

