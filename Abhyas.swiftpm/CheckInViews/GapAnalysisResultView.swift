import SwiftUI

struct GapAnalysisResultView: View {
    let subtopic: Subtopic
    let analysis: GapAnalysisResult
    let onContinue: () -> Void
    
    private var scoreColor: Color {
        if analysis.understandingScore >= 80 {
            return .green
        } else if analysis.understandingScore >= 60 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var scoreLabel: String {
        if analysis.understandingScore >= 80 {
            return "Excellent"
        } else if analysis.understandingScore >= 60 {
            return "Good"
        } else if analysis.understandingScore >= 40 {
            return "Partial"
        } else {
            return "Needs Review"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                
                scoreSection
                
                if !analysis.understoodConcepts.isEmpty {
                    understoodSection
                }
                
                if !analysis.conceptualGaps.isEmpty {
                    gapsSection
                }
                
                if !analysis.flaggedMisconceptions.isEmpty {
                    misconceptionsSection
                }
                
                if !analysis.missingPrerequisites.isEmpty {
                    prerequisitesSection
                }
                
                continueButton
            }
            .padding()
        }
        .navigationTitle("Your Understanding")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("\(subtopic.number)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text(subtopic.title)
                    .font(.title2)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            
            Text("Analysis of your responses")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Divider()
        }
    }
    
    private var scoreSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 140, height: 140)
                
                Circle()
                    .trim(from: 0, to: CGFloat(analysis.understandingScore / 100))
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 8) {
                    Text("\(Int(analysis.understandingScore))%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(scoreColor)
                    
                    Text(scoreLabel)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray6))
                        .clipShape(Capsule())
                }
            }
            
            Text("Based on your explanation and answers")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
    
    private var understoodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow(
                icon: "checkmark.circle.fill",
                title: "Well Understood",
                color: .green,
                count: analysis.understoodConcepts.count
            )
            
            VStack(spacing: 10) {
                ForEach(Array(analysis.understoodConcepts.prefix(4).enumerated()), id: \.offset) { index, concept in
                    conceptRow(
                        concept: concept,
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                }
                
                if analysis.understoodConcepts.count > 4 {
                    Text("+\(analysis.understoodConcepts.count - 4) more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var gapsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow(
                icon: "exclamationmark.triangle.fill",
                title: "Needs Review",
                color: .orange,
                count: analysis.conceptualGaps.count
            )
            
            VStack(spacing: 10) {
                ForEach(Array(analysis.conceptualGaps.prefix(4).enumerated()), id: \.offset) { index, gap in
                    conceptRow(
                        concept: gap,
                        icon: "exclamationmark.triangle.fill",
                        color: .orange
                    )
                }
                
                if analysis.conceptualGaps.count > 4 {
                    Text("+\(analysis.conceptualGaps.count - 4) more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var misconceptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow(
                icon: "xmark.circle.fill",
                title: "Misconceptions",
                color: .red,
                count: analysis.flaggedMisconceptions.count
            )
            
            VStack(spacing: 10) {
                ForEach(Array(analysis.flaggedMisconceptions.prefix(3).enumerated()), id: \.offset) { index, misconception in
                    conceptRow(
                        concept: misconception,
                        icon: "xmark.circle.fill",
                        color: .red
                    )
                }
            }
        }
        .padding()
        .background(Color.red.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.red.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var prerequisitesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow(
                icon: "arrow.triangle.branch",
                title: "Review These First",
                color: .blue,
                count: analysis.missingPrerequisites.count
            )
            
            Text("Your responses suggest reviewing these prerequisites:")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)
            
            VStack(spacing: 10) {
                ForEach(Array(analysis.missingPrerequisites.prefix(3).enumerated()), id: \.offset) { index, prereqID in
                    if let prereqSubtopic = SyllabusManager.shared.getSubtopic(id: prereqID) {
                        prerequisiteRow(subtopic: prereqSubtopic)
                    } else {
                        Text(prereqID)
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private func headerRow(icon: String, title: String, color: Color, count: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(color)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(color.opacity(0.15))
                .clipShape(Capsule())
        }
    }
    
    @ViewBuilder
    private func conceptRow(concept: String, icon: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
                .padding(.top, 2)
            
            Text(concept)
                .font(.subheadline)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private func prerequisiteRow(subtopic: Subtopic) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "book.closed")
                .font(.caption)
                .foregroundStyle(.blue)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(subtopic.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(subtopic.number)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
    
    private var continueButton: some View {
        Button(action: onContinue) {
            HStack {
                Text("Continue")
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: "arrow.right")
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [.accentColor, .accentColor.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.top, 12)
    }
}

struct LoadingAnalysisView: View {
    let currentText: String
    
    @State private var pulsePhase: Double = 0
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.accentColor.opacity(0.2), lineWidth: 4)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: 0.8)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(pulsePhase * 360))
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.accentColor)
            }
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    pulsePhase = 1
                }
            }
            
            VStack(spacing: 12) {
                Text("Analyzing Your Understanding")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text(currentText)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.accentColor)
                    .scaleEffect(0.8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    NavigationStack {
        GapAnalysisResultView(
            subtopic: Subtopic(
                id: "MATAA_HL_1.2",
                number: "1.2",
                title: "Arithmetic sequences",
                subjectCode: "MATAA_HL",
                topicNumber: "1",
                syllabusContent: "Arithmetic sequences and series...",
                syllabusGuidance: nil,
                keywords: ["arithmetic", "sequence"],
                coreConcepts: [
                    "nth term: un = u1 + (n-1)d",
                    "Constant common difference"
                ],
                commonMisconceptions: ["Using nd instead of (n-1)d"],
                prerequisites: [],
                relatedSubtopics: nil,
                paperTypes: ["paper1"],
                typicalMarks: nil,
                commandTerms: ["Find"],
                bloomLevel: 3,
                teachingHours: 3,
                questionExamples: QuestionExamples(
                    conceptual: ["Explain what the common difference represents in an arithmetic sequence."],
                    examStyle: ["Find the 15th term of the sequence 3, 7, 11, ..."]
                )
            ),
            analysis: GapAnalysisResult(
                understoodConcepts: ["Constant common difference"],
                conceptualGaps: ["nth term: un = u1 + (n-1)d"],
                flaggedMisconceptions: ["Using nd instead of (n-1)d"],
                missingPrerequisites: [],
                understandingScore: 65
            ),
            onContinue: {}
        )
    }
}
