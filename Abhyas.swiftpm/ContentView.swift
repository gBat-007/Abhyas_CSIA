import SwiftUI

@available(iOS 26.0, *)
struct ContentView: View {
    @StateObject private var appVM = AppViewModel()
    @State private var showShard = false
    @State private var showSettings = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationView {
            ZStack {
                // Adaptive gradient background
                LinearGradient(
                    gradient: Gradient(
                        colors: colorScheme == .dark
                            ? [
                                Color.black.opacity(0.9),
                                Color.blue.opacity(0.1),
                                Color.purple.opacity(0.05),
                            ]
                            : [
                                Color(
                                    UIColor(
                                        red: 0.98,
                                        green: 0.98,
                                        blue: 1.0,
                                        alpha: 1.0
                                    )
                                ),
                                Color(
                                    UIColor(
                                        red: 0.95,
                                        green: 0.97,
                                        blue: 1.0,
                                        alpha: 1.0
                                    )
                                ),
                                Color(
                                    UIColor(
                                        red: 0.93,
                                        green: 0.96,
                                        blue: 1.0,
                                        alpha: 1.0
                                    )
                                ),
                            ]
                    ),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    if appVM.userProfile != nil {
                        ScrollView {
                            VStack(spacing: 24) {
                                // Welcome header
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Welcome back")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Text("Let's continue learning")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(
                                            colorScheme == .dark
                                                ? .white : .black
                                        )
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 24)
                                .padding(.top, 32)
                                .padding(.bottom, 8)

                                // Action cards with glass effect
                                VStack(spacing: 16) {
                                    // New Shard Card
                                    Button(action: { showShard = true }) {
                                        VStack(alignment: .leading, spacing: 12)
                                        {
                                            HStack {
                                                VStack(
                                                    alignment: .leading,
                                                    spacing: 4
                                                ) {
                                                    Text("New Shard")
                                                        .font(.headline)
                                                        .foregroundStyle(.white)
                                                    Text(
                                                        "Assess your understanding"
                                                    )
                                                    .font(.caption)
                                                    .foregroundStyle(
                                                        .white.opacity(0.7)
                                                    )
                                                }
                                                Spacer()
                                                Image(
                                                    systemName:
                                                        "plus.circle.fill"
                                                )
                                                .font(.system(size: 32))
                                                .foregroundStyle(.white)
                                            }
                                            .padding(20)
                                            .frame(
                                                maxWidth: .infinity,
                                                alignment: .leading
                                            )
                                        }
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(red: 0.25, green: 0.55, blue: 0.85).opacity(0.5),
                                                    Color(red: 0.25, green: 0.55, blue: 0.85).opacity(0.25),
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .clipShape(
                                            RoundedRectangle(cornerRadius: 20)
                                        )
                                    }
                                    .glassEffect(in: .rect(cornerRadius: 20))

                                    // Practice Questions Card
                                    NavigationLink {
                                        if #available(iOS 26.0, *) {
                                            PracticeHomeView()
                                                .environmentObject(appVM)
                                        } else {
                                            Text(
                                                "Please update to iOS 26.0 or later."
                                            )
                                        }
                                    } label: {
                                        VStack(alignment: .leading, spacing: 12)
                                        {
                                            HStack {
                                                VStack(
                                                    alignment: .leading,
                                                    spacing: 4
                                                ) {
                                                    Text("Practice Questions")
                                                        .font(.headline)
                                                        .foregroundStyle(.white)
                                                    Text(
                                                        "Generate & solve questions"
                                                    )
                                                    .font(.caption)
                                                    .foregroundStyle(
                                                        .white.opacity(0.7)
                                                    )
                                                }
                                                Spacer()
                                                Image(systemName: "sparkles")
                                                    .font(.system(size: 32))
                                                    .foregroundStyle(.white)
                                            }
                                            .padding(20)
                                            .frame(
                                                maxWidth: .infinity,
                                                alignment: .leading
                                            )
                                        }
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(red: 0.35, green: 0.70, blue: 0.40).opacity(0.5),
                                                    Color(red: 0.35, green: 0.70, blue: 0.40).opacity(0.25),
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .clipShape(
                                            RoundedRectangle(cornerRadius: 20)
                                        )
                                    }
                                    .glassEffect(in: .rect(cornerRadius: 20))

                                    // Past Shards Card
                                    NavigationLink {
                                        if #available(iOS 17.0, *) {
                                            CheckInHistoryView()
                                                .environmentObject(appVM)
                                        } else {
                                            Text("Please update to iOS 26.0.")
                                        }
                                    } label: {
                                        VStack(alignment: .leading, spacing: 12)
                                        {
                                            HStack {
                                                VStack(
                                                    alignment: .leading,
                                                    spacing: 4
                                                ) {
                                                    Text("Past Shards")
                                                        .font(.headline)
                                                        .foregroundStyle(.white)
                                                    Text(
                                                        "View progress & insights"
                                                    )
                                                    .font(.caption)
                                                    .foregroundStyle(
                                                        .white.opacity(0.7)
                                                    )
                                                }
                                                Spacer()
                                                Image(
                                                    systemName:
                                                        "chart.line.uptrend.xyaxis"
                                                )
                                                .font(.system(size: 32))
                                                .foregroundStyle(.white)
                                            }
                                            .padding(20)
                                            .frame(
                                                maxWidth: .infinity,
                                                alignment: .leading
                                            )
                                        }
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(red: 0.75, green: 0.55, blue: 0.90).opacity(0.5),
                                                    Color(red: 0.75, green: 0.55, blue: 0.90).opacity(0.25),
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .clipShape(
                                            RoundedRectangle(cornerRadius: 20)
                                        )
                                    }
                                    .glassEffect(in: .rect(cornerRadius: 20))
                                }
                                .padding(.horizontal, 24)
                                .padding(.bottom, 32)
                            }
                        }
                    } else {
                        OnboardingView()
                            .environmentObject(appVM)
                    }
                }
            }
//            .navigationTitle("Abhyas")
            .overlay(alignment: .topTrailing) {
                if appVM.userProfile != nil {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.accentColor.opacity(0.4),
                                        Color.accentColor.opacity(0.1),
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                    }
                    .glassEffect(in: .circle)
                    .padding(16)
                }
            }
        }
        .onAppear {
            Task { await appVM.loadData() }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(isPresented: $showSettings)
                .environmentObject(appVM)
        }
        .sheet(isPresented: $showShard) {
            NavigationStack {
                if #available(iOS 26.0, *) {
                    CheckInFlowView()
                        .environmentObject(appVM)
                } else {
                    Text("Please update to iOS 26.0 to use this app.")
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .interactiveDismissDisabled()
        }
    }
}

@available(iOS 26.0, *)
struct PracticeHomeView: View {
    @EnvironmentObject var appVM: AppViewModel
    @StateObject private var internalVM = PracticeQuestionsViewModel()
    var injectedVM: PracticeQuestionsViewModel?

    private var vm: PracticeQuestionsViewModel {
        injectedVM ?? internalVM
    }

    var body: some View {
        Form {
            Section("Mode") {
                Picker("Question Type", selection: binding(\.mode)) {
                    ForEach(PracticeMode.allCases, id: \.self) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Scope") {
                Picker(
                    "Subject",
                    selection: bindingOptional(\.selectedSubjectCode)
                ) {
                    Text("Select").tag(String?.none)
                    ForEach(appVM.userProfile?.subjects ?? [], id: \.self) {
                        code in
                        Text(subjectName(for: code)).tag(String?.some(code))
                    }
                }

                if let code = vm.selectedSubjectCode,
                    let subject = SyllabusManager.shared.getSubject(code: code)
                {
                    Picker("Scope Type", selection: binding(\.scopeType)) {
                        ForEach(PracticeScopeType.allCases, id: \.self) { t in
                            Text(t.title).tag(t)
                        }
                    }

                    switch vm.scopeType {
                    case .entireSubject:
                        EmptyView()
                    case .topicRange, .entireTopic:
                        TopicPicker(
                            subject: subject,
                            selectedTopicNumbers: bindingSet(
                                \.selectedTopicNumbers
                            ),
                            allowRange: vm.scopeType == .topicRange
                        )
                    case .subtopicRange, .singleSubtopic:
                        TopicPicker(
                            subject: subject,
                            selectedTopicNumbers: bindingSet(
                                \.selectedTopicNumbers
                            ),
                            allowRange: false
                        )
                        if let topicNumber = vm.selectedTopicNumbers.first,
                            let topic = subject.topics.first(where: {
                                $0.number == topicNumber
                            })
                        {
                            SubtopicPicker(
                                topic: topic,
                                selectedSubtopicNumbers: bindingSet(
                                    \.selectedSubtopicNumbers
                                ),
                                allowRange: vm.scopeType == .subtopicRange
                            )
                        } else {
                            Text("Select a topic first to choose subtopics")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("Choose a subject to continue").font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Options") {
                Stepper(value: binding(\.questionCount), in: 1...5) {
                    Text("Number of Questions: \(vm.questionCount)")
                }
            }

            Section {
                Button {
                    vm.generate()
                } label: {
                    HStack {
                        if vm.isGenerating {
                            ProgressView().padding(.trailing, 6)
                        }
                        Text("Generate Questions")
                    }
                }
                .disabled(!vm.canGenerate || vm.isGenerating)
            }

            if let error = vm.generationError {
                Section {
                    Text(error).foregroundStyle(.red).font(.caption)
                }
            }

            if !vm.generated.questions.isEmpty {
                Section("Generated Questions") {
                    NavigationLink {
                        PracticeSessionView(session: vm.generated)
                    } label: {
                        HStack {
                            Image(systemName: "list.bullet.rectangle")
                            Text(
                                "Start Practice"
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle("Practice")
        .onAppear {
            vm.bindAppData(appVM)
        }
    }

    private func binding<T>(
        _ keyPath: ReferenceWritableKeyPath<PracticeQuestionsViewModel, T>
    ) -> Binding<T> {
        Binding(
            get: { vm[keyPath: keyPath] },
            set: { vm[keyPath: keyPath] = $0 }
        )
    }
    private func bindingOptional<T>(
        _ keyPath: ReferenceWritableKeyPath<PracticeQuestionsViewModel, T?>
    ) -> Binding<T?> {
        Binding(
            get: { vm[keyPath: keyPath] },
            set: { vm[keyPath: keyPath] = $0 }
        )
    }
    private func bindingSet<T: Hashable>(
        _ keyPath: ReferenceWritableKeyPath<PracticeQuestionsViewModel, Set<T>>
    ) -> Binding<Set<T>> {
        Binding(
            get: { vm[keyPath: keyPath] },
            set: { vm[keyPath: keyPath] = $0 }
        )
    }

    private func subjectName(for code: String) -> String {
        SyllabusManager.shared.getSubject(code: code)?.name ?? code
    }
}

struct TopicPicker: View {
    let subject: Subject
    @Binding var selectedTopicNumbers: Set<String>
    let allowRange: Bool

    var body: some View {
        if allowRange {
            VStack(alignment: .leading) {
                Text("Select a range of topics")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(subject.topics) { topic in
                    Toggle(
                        "\(topic.number) - \(topic.title)",
                        isOn: Binding(
                            get: {
                                selectedTopicNumbers.contains(topic.number)
                            },
                            set: { newVal in
                                if newVal {
                                    selectedTopicNumbers.insert(topic.number)
                                } else {
                                    selectedTopicNumbers.remove(topic.number)
                                }
                            }
                        )
                    )
                }
            }
        } else {
            Picker(
                "Topic",
                selection: Binding(
                    get: {
                        selectedTopicNumbers.first ?? ""
                    },
                    set: { newVal in
                        selectedTopicNumbers = newVal.isEmpty ? [] : [newVal]
                    }
                )
            ) {
                Text("Select").tag("")
                ForEach(subject.topics) { topic in
                    Text("\(topic.number) - \(topic.title)").tag(topic.number)
                }
            }
        }
    }
}

struct SubtopicPicker: View {
    let topic: Topic
    @Binding var selectedSubtopicNumbers: Set<String>
    let allowRange: Bool

    var body: some View {
        if allowRange {
            VStack(alignment: .leading) {
                Text("Select a range of subtopics")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(topic.subtopics) { st in
                    Toggle(
                        "\(st.number) - \(st.title)",
                        isOn: Binding(
                            get: {
                                selectedSubtopicNumbers.contains(st.number)
                            },
                            set: { newVal in
                                if newVal {
                                    selectedSubtopicNumbers.insert(st.number)
                                } else {
                                    selectedSubtopicNumbers.remove(st.number)
                                }
                            }
                        )
                    )
                }
            }
        } else {
            Picker(
                "Subtopic",
                selection: Binding(
                    get: {
                        selectedSubtopicNumbers.first ?? ""
                    },
                    set: { newVal in
                        selectedSubtopicNumbers = newVal.isEmpty ? [] : [newVal]
                    }
                )
            ) {
                Text("Select").tag("")
                ForEach(topic.subtopics) { st in
                    Text("\(st.number) - \(st.title)").tag(st.number)
                }
            }
        }
    }
}

@available(iOS 26.0, *)
struct SettingsView: View {
    @EnvironmentObject var appVM: AppViewModel
    @Binding var isPresented: Bool
    @State private var selectedSubjects: Set<String> = []

    let subjects = [
        (
            "MATAA_HL", "Mathematics:\nAnalysis and\nApproaches", Color.blue,
            "Math AA"
        ),
        (
            "MATAI_SL", "Mathematics:\nApplications\nand Interpretations",
            Color.cyan, "Math AI"
        ),
        ("PHYSHL", "Physics", Color.green, "Physics"),
        ("CHEM_SL", "Chemistry", Color.brown, "Chemistry"),
        ("CSHL", "Computer\nScience", Color.purple, "Computer Science"),
        (
            "ENGLISHA_HL", "English A\nLanguage and\nLiterature", Color.red,
            "Eng A L & L"
        ),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Update your subjects")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 20)

                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()), GridItem(.flexible()),
                        ],
                        spacing: 16
                    ) {
                        ForEach(subjects, id: \.0) {
                            code,
                            name,
                            color,
                            shortName in
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

                Button(action: saveSubjects) {
                    Text("Save Changes")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(selectedSubjects.isEmpty)
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .onAppear {
                selectedSubjects = Set(appVM.userProfile?.subjects ?? [])
            }
        }
    }

    private func saveSubjects() {
        appVM.createProfile(subjects: Array(selectedSubjects))
        isPresented = false
    }
}
