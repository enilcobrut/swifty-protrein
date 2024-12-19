import SwiftUI
import LocalAuthentication

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var username = ""
    @State private var password = ""
    @State private var isBiometricAvailable = false
    @State private var isBiometricEnabledForUser = false
    @State private var showRegistration = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            VStack {
                Text("Connexion")
                    .font(.largeTitle)
                    .padding()

                TextField("Username", text: $username)
                    .textContentType(.username)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(5)
                    .onChange(of: username) { newUser in
                        isBiometricEnabledForUser = KeychainHelper.isBiometricEnabled(for: newUser)
                    }

                if !isBiometricAvailable || !isBiometricEnabledForUser {
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(5)
                }

                if isBiometricAvailable && isBiometricEnabledForUser {
                    Button(action: authenticateWithBiometrics) {
                        Text("Connect with Touch ID / Face ID")
                            .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(5)
                }

                Button(action: login) {
                    Text("Connect")
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(5)

                Button(action: {
                    withAnimation {
                        showRegistration = true
                    }
                }) {
                    Text("Register")
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(5)

                Spacer()
            }
            .padding()
            .blur(radius: showRegistration ? 3 : 0)
            .disabled(showRegistration)

            // Overlay and Popup
            if showRegistration {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                
                RegistrationPopupView(showRegistration: $showRegistration) { errorText in
                    // If an error occurs inside registration, show it here
                    self.errorMessage = errorText
                    self.showError = true
                }
                .transition(.scale)
                .environmentObject(appState)
            }
        }
        .onAppear {
            checkBiometricAvailability()
            if !username.isEmpty {
                isBiometricEnabledForUser = KeychainHelper.isBiometricEnabled(for: username)
            } else {
                isBiometricEnabledForUser = false
            }
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            isBiometricAvailable = true
        } else {
            isBiometricAvailable = false
            if let err = error {
                print("Biometric not supported, error: \(err)")
            }
        }
    }

    func login() {
        guard !username.isEmpty else {
            errorMessage = "Please enter your username"
            showError = true
            return
        }

        if isBiometricAvailable && isBiometricEnabledForUser {
            authenticateWithBiometrics()
        } else {
            guard !password.isEmpty else {
                errorMessage = "Please enter a password"
                showError = true
                return
            }

            if let savedPassword = KeychainHelper.getPassword(for: username), savedPassword == password {
                proceedToMainView()
            } else {
                errorMessage = "Wrong identity or password"
                showError = true
            }
        }
    }

    func authenticateWithBiometrics() {
        let context = LAContext()
        let reason = "Connect to your account"
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
            DispatchQueue.main.async {
                if success {
                    proceedToMainView()
                } else {
                    errorMessage = authenticationError?.localizedDescription ?? "Biometric authentication failed."
                    showError = true
                }
            }
        }
    }

    func proceedToMainView() {
        appState.isLoggedIn = true
    }
}
