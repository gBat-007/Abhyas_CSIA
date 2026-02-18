import SwiftUI
struct ContentView: View {
    @StateObject private var appVM = AppViewModel()
    @State private var showCheckIn = false  // ✅ ADD THIS
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Syllabus Status Indicator
                if appVM.syllabusLoaded {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Syllabus Loaded")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                }
                
                if let profile = appVM.userProfile {
//                    ProfileHeaderView(profile: profile)
                    
                    List {
                        Section("Recent Check-ins") {
//                            ForEach(appVM.recentSessions) { session in
//                                CheckInRow(session: session)
//                            }
                        }
                        
                        Section("Quick Actions") {
                            Button(action: {
                                showCheckIn = true  // ✅ TRIGGER SHEET
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("New Check-in")
                                }
                            }
                            
                            NavigationLink("Practice Questions") {
                                PracticeView()
                                    .environmentObject(appVM)
                            }
                        }
                    }
                } else {
                    OnboardingView()
                        .environmentObject(appVM)
                }
            }
            .navigationTitle("Abhyas")
        }
        .onAppear {
            Task { await appVM.loadData() }
        }
        .sheet(isPresented: $showCheckIn) {
            NavigationStack {
                if #available(iOS 26.0, *) {
                    CheckInFlowView()
                        .environmentObject(appVM)
                } else {
                    Text("Please update to iOS 26.0 to use this app.")
                }
            }
            .presentationDetents([.large])  // Full screen
            .presentationDragIndicator(.hidden)  // Hide drag indicator
            .interactiveDismissDisabled()  // Prevent accidental dismiss
        }
    }
}

struct PracticeView: View {
    var body: some View {
        VStack{
            Text("Practice Under Construction")
        }
    }
}
