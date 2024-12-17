import SwiftUI

@main
struct Swifty_protein42App: App {
    @Environment(\.scenePhase) var scenePhase
    @StateObject var appState = AppState()
    @AppStorage("hasLaunchedBefore") var hasLaunchedBefore = false

    var body: some Scene {
        WindowGroup {
            if !hasLaunchedBefore {
                LaunchScreen()
                    .onAppear {
                        hasLaunchedBefore = true
                    }
            } else if appState.isLoggedIn {
                
                ProteinListView()
                    .environmentObject(appState)
                
            } else {
                
                LoginView()
                    .environmentObject(appState)
            }
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                appState.isLoggedIn = false
            }
        }
    }
}
