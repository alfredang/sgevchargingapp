import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }

            FeedbackView()
                .tabItem {
                    Label("Feedback", systemImage: "bubble.left.and.bubble.right.fill")
                }

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle.fill")
                }
        }
        .tint(Theme.primary)
    }
}

#Preview {
    RootView()
}
