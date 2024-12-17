import SwiftUI
import LocalAuthentication

struct RegistrationPopupView: View {
    @Binding var showRegistration: Bool
    @EnvironmentObject var appState: AppState
    @State private var username = ""
    @State private var password = ""
    @State private var isBiometricAvailable = false
    // Variables d'état pour les messages d'erreur
    @State private var usernameErrorMessage = ""
    @State private var passwordErrorMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Register")
                .font(.title)
                .padding()

            VStack(alignment: .leading, spacing: 5) {
                TextField("Login", text: $username)
                    .textContentType(.username)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(5)

                if !usernameErrorMessage.isEmpty {
                    Text(usernameErrorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }

            if !isBiometricAvailable {
                VStack(alignment: .leading, spacing: 5) {
                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(5)

                    if !passwordErrorMessage.isEmpty {
                        Text(passwordErrorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            } else {
                Text("L'authentification biométrique est requise.")
                    .padding()
            }

            HStack {
                Button(action: {
                    withAnimation {
                        showRegistration = false
                    }
                }) {
                    Text("Annuler")
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(5)

                Button(action: register) {
                    Text("Register")
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(5)
            }

        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .padding(.horizontal, 40)
        .onAppear {
            checkBiometricAvailability()
        }
    }

    func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            isBiometricAvailable = true
        } else {
            isBiometricAvailable = false
        }
    }

    func register() {
        // Réinitialiser les messages d'erreur
        usernameErrorMessage = ""
        passwordErrorMessage = ""

        var hasError = false

        // Vérifier si le nom d'utilisateur est vide
        if username.trimmingCharacters(in: .whitespaces).isEmpty {
            usernameErrorMessage = "Enter a login"
            hasError = true
        } else if KeychainHelper.getPassword(for: username) != nil {
            // Vérifier si l'utilisateur existe déjà
            usernameErrorMessage = "This login is already taken"
            hasError = true
        }

        if isBiometricAvailable {
            // Si la biométrie est disponible, pas besoin de mot de passe
        } else {
            // Vérifier si le mot de passe est vide
            if password.isEmpty {
                passwordErrorMessage = "Enter a password."
                hasError = true
            }
        }

        // Si une erreur est détectée, ne pas poursuivre l'inscription
        if hasError {
            return
        }

        if isBiometricAvailable {
            // Enregistrer la préférence biométrique activée
            KeychainHelper.saveBiometricPreference(true, for: username)
            // Sauvegarder un identifiant factice dans le Keychain
            KeychainHelper.savePassword("biometric_only_user", for: username)
        } else {
            // Enregistrer le mot de passe dans le Keychain
            KeychainHelper.savePassword(password, for: username)
            // Enregistrer la préférence biométrique désactivée
            KeychainHelper.saveBiometricPreference(false, for: username)
        }

        // Fermer le popup
        withAnimation {
            showRegistration = false
        }
    }
}
