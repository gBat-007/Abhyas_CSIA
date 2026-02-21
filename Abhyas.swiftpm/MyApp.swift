import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            if #available(iOS 26.0, *) {
                AppLaunchWrapper()
            } else {
                Text("Please update to iOS 26.0 or later to use this app.")
            }
        }
    }
}

@available(iOS 26.0, *)
struct AppLaunchWrapper: View {
    @State private var isLaunching = true
    
    var body: some View {
        ZStack {
            if isLaunching {
                LaunchScreenView()
                    .transition(.opacity)
            } else {
                ContentView()
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isLaunching = false
                }
            }
        }
    }
}

