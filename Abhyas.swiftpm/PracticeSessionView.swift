import SwiftUI

enum PracticeDisplayMode {
    case all
    case paginated
    
    var title: String {
        switch self {
        case .all: return "All Together"
        case .paginated: return "One Per Page"
        }
    }
}

struct PracticeSessionView: View {
    let session: PracticeSession
    @State private var answers: [UUID: String] = [:]
    @State private var displayMode: PracticeDisplayMode = .all
    @State private var currentPageIndex: Int = 0
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            if displayMode == .all {
                allQuestionsView
            } else {
                paginatedView
            }
        }
        .navigationTitle("Practice")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Picker("Display", selection: $displayMode) {
                    Image(systemName: "square.grid.2x2").tag(PracticeDisplayMode.all)
                    Image(systemName: "list.number").tag(PracticeDisplayMode.paginated)
                }
                .pickerStyle(.segmented)
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Done") { dismiss() }
            }
        }
        .accentColor(Color(red: 0.50, green: 0.85, blue: 0.50))
    }
    
    private var allQuestionsView: some View {
        List {
            Section(header: header) {
                ForEach(session.questions) { item in
                    QuestionRow(item: item, answer: Binding(
                        get: { answers[item.id] ?? "" },
                        set: { answers[item.id] = $0 }
                    ))
                }
            }
        }
    }
    
    private var paginatedView: some View {
        VStack(spacing: 0) {
            // Page header
            VStack(alignment: .leading, spacing: 8) {
                Text(titleText).font(.headline)
                Text("Question \(currentPageIndex + 1) of \(session.questions.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemGray6))
            
            // Question with scrollable area
            ScrollViewReader { reader in
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        let item = session.questions[currentPageIndex]
                        QuestionRow(item: item, answer: Binding(
                            get: { answers[item.id] ?? "" },
                            set: { answers[item.id] = $0 }
                        ))
                    }
                    .padding()
                    .id("question")
                    .onAppear {
                        reader.scrollTo("question", anchor: .top)
                    }
                }
            }
            
            Spacer()
            
            // Navigation buttons
            HStack(spacing: 12) {
                Button(action: { if currentPageIndex > 0 { currentPageIndex -= 1 } }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Previous")
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(currentPageIndex == 0)
                
                Button(action: { if currentPageIndex < session.questions.count - 1 { currentPageIndex += 1 } }) {
                    HStack(spacing: 6) {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(currentPageIndex == session.questions.count - 1)
            }
            .buttonStyle(.bordered)
            .padding()
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(titleText).font(.headline)
            Text(subtitleText).font(.caption).foregroundStyle(.secondary)
        }
    }
    
    private var titleText: String {
        let subject = SyllabusManager.shared.getSubject(code: session.subjectCode)?.name ?? session.subjectCode
        return "\(subject) • \(session.mode.title)"
    }
    
    private var subtitleText: String {
        "Questions: \(session.questions.count)"
    }
}

struct QuestionRow: View {
    let item: PracticeQuestionItem
    @Binding var answer: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Allow question text to wrap fully without truncation, with LaTeX support
            HStack(alignment: .top, spacing: 8) {
                MathSupportedText(item.text)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                        
                Spacer(minLength: 8)
                if let m = item.marks, item.type == .examStyle {
                    Text("[\(m) marks]")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
            }
            meta
            TextEditor(text: $answer)
                .frame(minHeight: 80)
                .scrollContentBackground(.hidden)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
        .padding(.vertical, 6)
    }
    
    private var meta: some View {
        HStack(spacing: 8) {
            if let p = item.paperType, item.type == .examStyle {
                Label(p.uppercased(), systemImage: "doc.plaintext").font(.caption2)
            }
            if let b = item.bloomLevel {
                Label("Bloom \(b)", systemImage: "chart.bar.xaxis").font(.caption2)
            }
            if !item.commandTerms.isEmpty {
                Label(item.commandTerms.first ?? "", systemImage: "text.book.closed").font(.caption2)
            }
        }
        .foregroundStyle(.secondary)
    }
}
