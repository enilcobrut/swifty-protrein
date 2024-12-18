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

    var body: some View {
        VStack(spacing: 20) {
            Text("Inscription")
                .font(.title)
                .padding()

            TextField("Nom d'utilisateur", text: $username)
                .textContentType(.username)
                .autocapitalization(.none)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(5)

            // Si la biométrie n'est pas choisie, on demande un mot de passe
            if !isBiometricChosen {
                SecureField("Mot de passe", text: $password)
                    .textContentType(.newPassword)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(5)
            }

            Toggle("Utiliser Touch ID / Face ID", isOn: $isBiometricChosen)
                .padding()

            HStack {
                Button("Annuler") {
                    withAnimation {
                        showRegistration = false
                    }
                }
                .padding()
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(5)

                Button("Valider") {
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
            Alert(title: Text("Erreur"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
    }

    func register() {
        guard !username.isEmpty else {
            errorMessage = "Veuillez entrer un nom d'utilisateur."
            showError = true
            return
        }

        // Vérifier la disponibilité de la biométrie
        let isBioAvailable = isBiometricDeviceAvailable()

        if isBiometricChosen && isBioAvailable {
            // Demander une authentification biométrique
            authenticateBiometric { success in
                if success {
                    // L'utilisateur est authentifié biométriquement pour l'inscription
                    // On n'enregistre pas le mot de passe, juste la préférence biométrique
                    KeychainHelper.saveBiometricPreference(true, for: username)
                    
                    // Envoyer la requête de validation d'inscription (sans mot de passe)
                    // Exemple:
                    sendRegistrationRequest(username: username, password: nil, useBiometry: true) { success in
                        if success {
                            DispatchQueue.main.async {
                                withAnimation {
                                    showRegistration = false
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                errorMessage = "Échec de l'inscription. Veuillez réessayer."
                                showError = true
                            }
                        }
                    }
                } else {
                    // Échec biométrique
                    errorMessage = "L'authentification biométrique a échoué."
                    showError = true
                }
            }
        } else {
            // La biométrie n'est pas choisie ou pas disponible, on demande un mot de passe
            guard !password.isEmpty else {
                errorMessage = "Veuillez entrer un mot de passe."
                showError = true
                return
            }

            // Enregistrer le mot de passe dans le keychain
            KeychainHelper.savePassword(password, for: username)
            KeychainHelper.saveBiometricPreference(false, for: username)

            // Envoyer la requête de validation d'inscription (avec mot de passe)
            sendRegistrationRequest(username: username, password: password, useBiometry: false) { success in
                if success {
                    DispatchQueue.main.async {
                        withAnimation {
                            showRegistration = false
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        errorMessage = "Échec de l'inscription. Veuillez réessayer."
                        showError = true
                    }
                }
            }
        }
    }

    // Fonction de vérification de la disponibilité biométrique
    func isBiometricDeviceAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    // Authentification biométrique
    func authenticateBiometric(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        let reason = "Veuillez vous authentifier pour finaliser votre inscription"

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authError in
            completion(success)
        }
    }

    // Fonction simulant l'envoi d'une requête réseau pour l'inscription
    func sendRegistrationRequest(username: String, password: String?, useBiometry: Bool, completion: @escaping (Bool) -> Void) {
        // Exemple fictif :
        // Ici vous faites votre appel réseau à votre backend.
        // Paramètres :
        // - username
        // - password (optionnel si useBiometry == true)
        // - useBiometry
        // Une fois la requête terminée, appelez completion(true/false) selon le résultat

        // Simulons un succès immédiat
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            completion(true)
        }
    }
}
