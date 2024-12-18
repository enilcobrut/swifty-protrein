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

                TextField("Nom d'utilisateur", text: $username)
                    .textContentType(.username)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(5)
                    .onChange(of: username) { newUser in
                        isBiometricEnabledForUser = KeychainHelper.isBiometricEnabled(for: newUser)
                    }

                // Si la biométrie est activée et disponible, on ne demande pas de mot de passe,
                // car il n'est pas stocké dans ce cas.
                if !isBiometricAvailable || !isBiometricEnabledForUser {
                    SecureField("Mot de passe", text: $password)
                        .textContentType(.password)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(5)
                }

                if isBiometricAvailable && isBiometricEnabledForUser {
                    Button(action: authenticateWithBiometrics) {
                        Text("Se connecter avec Touch ID / Face ID")
                            .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(5)
                }

                Button(action: login) {
                    Text("Se connecter")
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
                    Text("S'inscrire")
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(5)

                Spacer()
            }
            .padding()
            .disabled(showRegistration)
            .blur(radius: showRegistration ? 3 : 0)

            if showRegistration {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            showRegistration = false
                        }
                    }

                // RegistrationPopupView : Lorsqu’on valide l’inscription :
                // - Si biométrie dispo et choisie => setBiometricPreference(true), ne pas savePassword
                // - Sinon => savePassword + setBiometricPreference(false)
                RegistrationPopupView(showRegistration: $showRegistration)
                    .environmentObject(appState)
                    .transition(.scale)
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
            Alert(title: Text("Erreur"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
    }

    // Vérification de la disponibilité de la biométrie
    func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            isBiometricAvailable = true
        } else {
            isBiometricAvailable = false
            if let err = error {
                print("Biométrie indisponible, erreur: \(err)")
            }
        }
    }

    // Fonction de connexion
    func login() {
        guard !username.isEmpty else {
            errorMessage = "Veuillez entrer votre nom d'utilisateur."
            showError = true
            return
        }

        // Si la biométrie est activée et disponible, on tente la biométrie.
        if isBiometricAvailable && isBiometricEnabledForUser {
            authenticateWithBiometrics()
        } else {
            // Ici, on s'attend à ce qu'un mot de passe soit enregistré si la biométrie n'est pas disponible.
            guard !password.isEmpty else {
                errorMessage = "Veuillez entrer votre mot de passe."
                showError = true
                return
            }

            if let savedPassword = KeychainHelper.getPassword(for: username), savedPassword == password {
                proceedToMainView()
            } else {
                errorMessage = "Identifiants incorrects."
                showError = true
            }
        }
    }

    // Authentification biométrique
    func authenticateWithBiometrics() {
        let context = LAContext()
        let reason = "Connectez-vous pour accéder à l'application"

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
            DispatchQueue.main.async {
                if success {
                    // Pas de mot de passe stocké si biométrie activée, donc on vérifie juste si l'user existe
                    // Par exemple, si vous stockez au moins quelque chose qui indique que l'user est créé
                    // Ici, on suppose qu'on sait que l'utilisateur existe dès l'instant où la biométrie est activée.
                    proceedToMainView()
                } else {
                    errorMessage = authenticationError?.localizedDescription ?? "Échec de l'authentification biométrique."
                    showError = true
                }
            }
        }
    }

    // Transition vers la vue principale
    func proceedToMainView() {
        appState.isLoggedIn = true
    }
}
