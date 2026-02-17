import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var selectedSubjects: Set<String> = []
    
    let subjects = [
        ("MATAA_HL", "Mathematics:\nAnalysis and\nApproaches", Color.blue),
        ("MATAI_SL", "Mathematics:\nApplications\nand Interpretations", Color.cyan),
        ("PHYS_HL", "Physics", Color.green),
        ("CHEM_SL", "Chemistry", Color.brown),
        ("COMPSCI_HL", "Computer\nScience", Color.purple),
        ("ENGLISHA_HL", "English A\nLanguage and\nLiterature", Color.red)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Choose 1-6 subjects you are currently studying.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 20)
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(subjects, id: \.0) { code, name, color in
                            SubjectCard(
                                name: name,
                                color: color,
                                isSelected: selectedSubjects.contains(code)
                            )
                            .onTapGesture {
                                if selectedSubjects.contains(code) {
                                    selectedSubjects.remove(code)
                                } else if selectedSubjects.count < 6 {
                                    selectedSubjects.insert(code)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                Button("Done") {
                    appVM.createProfile(subjects: Array(selectedSubjects))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(selectedSubjects.isEmpty)
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationTitle("Select Your IB Subjects")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.title3)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        appVM.createProfile(subjects: Array(selectedSubjects))
                    }) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title3)
                    }
                    .disabled(selectedSubjects.isEmpty)
                }
            }
        }
    }
}

struct SubjectCard: View {
    let name: String
    let color: Color
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(color.gradient)
                .frame(height: 140)
                .shadow(color: color.opacity(0.4), radius: isSelected ? 12 : 6, x: 0, y: isSelected ? 6 : 3)
            
            Text(name)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()
                .lineLimit(3)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white, lineWidth: isSelected ? 4 : 0)
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
    }
}
