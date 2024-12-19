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

    private var userHasPassword: Bool {
        guard !username.isEmpty else { return false }
        return KeychainHelper.getPassword(for: username) != nil
    }

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
                    .onChange(of: username) { oldUser, newUser in
                        isBiometricEnabledForUser = KeychainHelper.isBiometricEnabled(for: newUser)
                    }

                // Show the toggle if biometrics are available and we have a username.
                // Always show it regardless of existing preferences.
                if isBiometricAvailable && !username.isEmpty {
                    Toggle("Use Face ID / Touch ID", isOn: $isBiometricEnabledForUser)
                        .padding()
                        .onChange(of: isBiometricEnabledForUser) { oldValue, newValue in
                            KeychainHelper.saveBiometricPreference(newValue, for: username)
                        }
                }

                // If toggle ON and no password -> No password field (biometric-only).
                // Else show password field.
                if !(isBiometricEnabledForUser && !userHasPassword) {
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(5)
                }

                // If toggle ON and user has no password, show only biometric login button.
                // If toggle ON and user has password, show both biometric and normal login.
                // If toggle OFF, show only normal login.
                
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

                // If toggle OFF or userHasPassword is true, show Connect button for password login
                if !isBiometricEnabledForUser || userHasPassword {
                    Button(action: login) {
                        Text("Connect")
                            .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(5)
                }

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

        // If toggle is ON and user has NO password -> must use biometrics
        if isBiometricEnabledForUser && !userHasPassword {
            errorMessage = "Please use Touch ID / Face ID to log in."
            showError = true
            return
        }

        // Otherwise, a password is required for password-based login
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

    func authenticateWithBiometrics() {
        // If toggle ON and user has no password, then this is the only method.
        // If user does have a password, this is an alternative login method.
        
        let context = LAContext()
        let reason = "Connect to your account"
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
            DispatchQueue.main.async {
                if success {
                    // If no password is stored (biometric-only user), just proceed.
                    // If password is stored, then we trust biometrics as well.
                    if !userHasPassword || userHasPassword {
                        proceedToMainView()
                    } else {
                        errorMessage = "No account found for this username."
                        showError = true
                    }
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
