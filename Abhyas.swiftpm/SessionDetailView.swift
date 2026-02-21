import SwiftUI

struct SessionDetailView: View {
    let item: HistoryItem
    
    // Derived
    private var subtopic: Subtopic? {
        SyllabusManager.shared.getSubtopic(id: item.subtopicID)
    }
    
    var body: some View {
        List {
            if let sub = subtopic {
                Section("Subtopic") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(sub.number) \(sub.title)")
                            .font(.headline)
                        Text("Subject: \(subjectName(for: sub.subjectCode))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Understanding") {
                    HStack {
                        Text("Score")
                        Spacer()
                        Text("\(Int(item.understanding))%")
                            .font(.headline)
                            .foregroundStyle(scoreColor(item.understanding))
                    }
                    if let st = sub.typicalMarks {
                        HStack {
                            Text("Typical Marks")
                            Spacer()
                            Text(st)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if !sub.prerequisites.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Prerequisites").font(.subheadline)
                            ForEach(sub.prerequisites, id: \.self) { pid in
                                if let p = SyllabusManager.shared.getSubtopic(id: pid) {
                                    Text("• \(p.number) \(p.title)")
                                } else {
                                    Text("• \(pid)")
                                }
                            }
                        }
                    }
                }
                Section("Core Concepts") {
                    ForEach(sub.coreConcepts, id: \.self) { c in
                        Text("• \(c)")
                    }
                }
                if let mis = sub.commonMisconceptions, !mis.isEmpty {
                    Section("Common Misconceptions") {
                        ForEach(mis, id: \.self) { m in
                            Text("• \(m)")
                        }
                    }
                }
            } else {
                Section {
                    Text("Subtopic not found")
                }
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func subjectName(for code: String) -> String {
        SyllabusManager.shared.getSubject(code: code)?.name ?? code
    }
    
    private func scoreColor(_ score: Float) -> Color {
        if score >= 80 { return .green }
        if score >= 60 { return .orange }
        return .red
    }
}
