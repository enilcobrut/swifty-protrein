import SwiftUI

@main
struct Swifty_protein42App: App {
    @Environment(\.scenePhase) var scenePhase
    @StateObject var appState = AppState()
    @State private var showLaunchScreen = true

    var body: some Scene {
        WindowGroup {
            Group {
                if showLaunchScreen {
                    LaunchScreen()
                        .onAppear {
                            // Simule un temps de chargement de vos données ou initialisations
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showLaunchScreen = false
                            }
                        }
                } else {
                    if appState.isLoggedIn {
                        ProteinListView()
                            .environmentObject(appState)
                    } else {
                        LoginView()
                            .environmentObject(appState)
                    }
                }
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    print("App is active")
                }
                else {
                    appState.isLoggedIn = false
                }
            }
        }
    }
}

