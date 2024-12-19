import SwiftUI
import LocalAuthentication

struct RegistrationPopupView: View {
    @Binding var showRegistration: Bool
    @EnvironmentObject var appState: AppState

    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isBiometricChosen: Bool = false
    @State private var showError = false
    @State private var errorMessage = ""

    var onError: (String) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Register")
                .font(.title)
                .padding()

            TextField("Username", text: $username)
                .textContentType(.username)
                .autocapitalization(.none)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(5)

            // Only show the password field if biometrics not chosen
            if !isBiometricChosen {
                SecureField("Password", text: $password)
                    .textContentType(.none)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(5)
            }

            Toggle("Activate Touch ID / Face ID", isOn: $isBiometricChosen)
                .padding()

            HStack {
                Button("Cancel") {
                    withAnimation {
                        showRegistration = false
                    }
                }
                .padding()
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(5)

                Button("Validate") {
                    register()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(5)
            }
        }
        .padding()
        .alert(isPresented: $showError) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
    }

    func register() {
        guard !username.isEmpty else {
            setError("Enter a username")
            return
        }

        if LocalUserStore.isUsernameTaken(username) {
            setError("Username is already taken")
            return
        }

        let isBioAvailable = isBiometricDeviceAvailable()

        if isBiometricChosen {
            
            // Biometrics chosen, no password required if available
            if isBioAvailable {
                // Authenticate biometrically
                authenticateBiometric { success in
                    if success {
                        KeychainHelper.saveBiometricPreference(true, for: username)
                        sendRegistrationRequest(username: username, password: nil, useBiometry: true) { success in
                            if success {
                                DispatchQueue.main.async {
                                    withAnimation {
                                        showRegistration = false
                                    }
                                }
                            } else {
                                setError("Register failed")
                            }
                        }
                    } else {
                        setError("Biometric authentication failed")
                    }
                }
            } else {
                // Biometrics chosen but not available
                setError("Biometric not available on this device. Please deactivate Touch ID / Face ID or choose a password.")
            }
        } else {
            // Biometrics not chosen, password is mandatory
            guard !password.isEmpty else {
                setError("Enter a password")
                return
            }

            KeychainHelper.savePassword(password, for: username)
            KeychainHelper.saveBiometricPreference(false, for: username)

            sendRegistrationRequest(username: username, password: password, useBiometry: false) { success in
                if success {
                    DispatchQueue.main.async {
                        withAnimation {
                            showRegistration = false
                        }
                    }
                } else {
                    setError("Register failed")
                }
            }
        }
    }

    func setError(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.showError = true
            self.onError(message)
        }
    }

    func isBiometricDeviceAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    func authenticateBiometric(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        let reason = "Please authenticate using your biometric device"
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
            completion(success)
        }
    }

    func sendRegistrationRequest(username: String, password: String?, useBiometry: Bool, completion: @escaping (Bool) -> Void) {
        // Simulate a network request
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            LocalUserStore.saveUsername(username)
            completion(true)
        }
    }
}
