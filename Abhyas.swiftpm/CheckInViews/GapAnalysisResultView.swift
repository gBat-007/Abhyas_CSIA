import SwiftUI

struct GapAnalysisResultView: View {
    let subtopic: Subtopic
    let analysis: GapAnalysisResult
    let onContinue: () -> Void
    
    @State private var showDetails = false
    
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
            return "Excellent Understanding"
        } else if analysis.understandingScore >= 60 {
            return "Good Understanding"
        } else if analysis.understandingScore >= 40 {
            return "Partial Understanding"
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
        .navigationTitle("Understanding Analysis")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(subtopic.number) - \(subtopic.title)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
            Divider()
        }
    }
    
    private var scoreSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(scoreColor.opacity(0.2), lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: CGFloat(analysis.understandingScore / 100))
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Text("\(Int(analysis.understandingScore))%")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(scoreColor)
                    
                    Text(scoreLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var understoodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Concepts You Understand")
                    .font(.headline)
                Spacer()
                Text("\(analysis.understoodConcepts.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(analysis.understoodConcepts, id: \.self) { concept in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                        
                        Text(concept)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var gapsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Concepts to Review")
                    .font(.headline)
                Spacer()
                Text("\(analysis.conceptualGaps.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(analysis.conceptualGaps, id: \.self) { concept in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        
                        Text(concept)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var misconceptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
                Text("Misconceptions Detected")
                    .font(.headline)
                Spacer()
                Text("\(analysis.flaggedMisconceptions.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(analysis.flaggedMisconceptions, id: \.self) { misconception in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                        
                        Text(misconception)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var prerequisitesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.triangle.branch")
                    .foregroundStyle(.blue)
                Text("Recommended Prerequisites")
                    .font(.headline)
                Spacer()
                Text("\(analysis.missingPrerequisites.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Text("Consider reviewing these topics to strengthen your understanding:")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(analysis.missingPrerequisites, id: \.self) { prereqID in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "book.fill")
                            .foregroundStyle(.blue)
                            .font(.caption)
                        
                        if let prereqSubtopic = SyllabusManager.shared.getSubtopic(id: prereqID) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(prereqSubtopic.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text(prereqSubtopic.number)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text(prereqID)
                                .font(.subheadline)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var continueButton: some View {
        Button(action: onContinue) {
            Text("Continue")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .cornerRadius(12)
        }
        .padding(.top)
    }
}

struct LoadingAnalysisView: View {
    let currentText: String
    
    @State private var pulsePhase: Double = 0
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.accentColor.opacity(0.3), lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(pulsePhase))
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.accentColor)
            }
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    pulsePhase = 360
                }
            }
            
            VStack(spacing: 8) {
                Text("Analyzing Your Understanding")
                    .font(.headline)
                
                Text(currentText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
