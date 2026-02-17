import SwiftUI

struct TopicSelectionView: View {
    @EnvironmentObject var viewModel: CheckInFlowViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("I've identified these topics from your response. Please select the ones that you'd like to proceed with:")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(viewModel.identifiedTopics) { match in
                        TopicMatchCard(
                            match: match,
                            isSelected: viewModel.selectedTopicIDs.contains(match.subtopic.id)
                        )
                        .onTapGesture {
                            if viewModel.selectedTopicIDs.contains(match.subtopic.id) {
                                viewModel.selectedTopicIDs.remove(match.subtopic.id)
                            } else {
                                viewModel.selectedTopicIDs.insert(match.subtopic.id)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            Button("Confirm and Continue") {
                viewModel.confirmTopics()
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.selectedTopicIDs.isEmpty)
            .padding()
            
            Button(action: {
                viewModel.currentStep = .input
            }) {
                Text("Not the topics you meant? Try again.")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .navigationTitle("Identified Topics")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    viewModel.currentStep = .input
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
            }
        }
    }
}

struct TopicMatchCard: View {
    let match: TopicMatch
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .orange : .gray)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(match.subtopic.number) \(match.subtopic.title)")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Confidence: \(Int(match.confidence))%")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.yellow.opacity(0.3))
                    )
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.gradient)
                .shadow(color: .blue.opacity(0.2), radius: 4, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(isSelected ? 0.5 : 0), lineWidth: 2)
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}
