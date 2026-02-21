import SwiftUI

@available(iOS 26.0, *)
struct OnboardingView: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var showWelcome = true
    
    var body: some View {
        ZStack {
            if showWelcome {
                OnboardingWelcomeView(showWelcome: $showWelcome)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                OnboardingSubjectSelectView()
                    .environmentObject(appVM)
                    .transition(.opacity.combined(with: .scale(scale: 1.05)))
            }
        }
        .animation(.easeInOut(duration: 0.6), value: showWelcome)
    }
}

@available(iOS 26.0, *)
struct OnboardingWelcomeView: View {
    @Binding var showWelcome: Bool
    
    var body: some View {
        ZStack {
            // Gradient background matching launch screen
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(red: 0.173, green: 0.431, blue: 0.569), location: 0),
                    .init(color: Color(red: 0.184, green: 0.427, blue: 0.310), location: 0.5),
                    .init(color: Color(red: 0.416, green: 0.298, blue: 0.576), location: 1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Title
                VStack(spacing: 12) {
                    Text("Welcome to IB Shards")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Text("Build Your Understanding")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                        .tracking(0.5)
                }
                
                Spacer()
                
                // Explanation
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.top, 2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("What are Shards?")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                            
                            Text("Your daily learning moments. Each shard represents a concept you've learned, understood, or struggled with during your IB studies.")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(.white.opacity(0.85))
                                .lineLimit(nil)
                        }
                    }
                    
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "puzzle.piece.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.top, 2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Build Complete Understanding")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                            
                            Text("Track your understanding across all topics. Watch the gaps in your knowledge and focus on what matters most.")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(.white.opacity(0.85))
                                .lineLimit(nil)
                        }
                    }
                }
                .padding(20)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)
                
                Spacer()
                
                // CTA Button
                Button(action: { showWelcome = false }) {
                    Text("Get Started")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(Color.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 60)
            }
        }
    }
}

@available(iOS 26.0, *)
struct OnboardingSubjectSelectView: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var selectedSubjects: Set<String> = []
    
    let subjects = [
        ("MATAA_HL", "Mathematics:\nAnalysis and\nApproaches", Color.blue, "Math AA"),
        ("MATAI_SL", "Mathematics:\nApplications\nand Interpretations", Color.cyan, "Math AI"),
        ("PHYSHL", "Physics", Color.green, "Physics"),
        ("CHEM_SL", "Chemistry", Color.brown, "Chemistry"),
        ("CSHL", "Computer\nScience", Color.purple, "Computer Science"),
        ("ENGLISHA_HL", "English A\nLanguage and\nLiterature", Color.red, "Eng A L & L")
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
                        ForEach(subjects, id: \.0) { code, name, color, shortName in
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

@available(iOS 26.0, *)
struct SubjectCard: View {
    let name: String
    let color: Color
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            // Glass background
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            color.opacity(0.3),
                            color.opacity(0.1),
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 140)
            
            // Text content with proper wrapping
            VStack(alignment: .center, spacing: 0) {
                Text(name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .glassEffect(in: .rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white, lineWidth: isSelected ? 2.5 : 0)
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
    }
}
