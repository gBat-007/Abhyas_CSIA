import SwiftUI

struct LaunchScreenView: View {
    @State private var pulseScale = false
    
    var body: some View {
        ZStack {
            // Gradient background with 2C6E91, 2F6D4F, 6A4C93
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
            
            VStack(spacing: 0) {
                Spacer()
                
                // App logo pulsing animation on the launch screen while the app loads
                Image("AppIconCircle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .scaleEffect(pulseScale ? 1.05 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: pulseScale
                    )
                
                // App Name
                Text("IB Shards")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.top, 24)
                
                Spacer()
            }
        }
        .onAppear {
            pulseScale = true
        }
    }
}

