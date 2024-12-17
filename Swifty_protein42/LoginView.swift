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
                    .onChange(of: username) {
                        isBiometricEnabledForUser = KeychainHelper.isBiometricEnabled(for: username)
                    }

                if !isBiometricEnabledForUser || !isBiometricAvailable {
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

                RegistrationPopupView(showRegistration: $showRegistration)
                    .environmentObject(appState)
                    .transition(.scale)
            }
        }
        .onAppear {
            checkBiometricAvailability()
            isBiometricEnabledForUser = KeychainHelper.isBiometricEnabled(for: username)
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Erreur"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
    }

    // Fonction pour vérifier la disponibilité de l'authentification biométrique
    func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            isBiometricAvailable = true
        } else {
            isBiometricAvailable = false
            if let err = error {
                print("Biometric not available, error: \(err)")
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

        if isBiometricAvailable && isBiometricEnabledForUser {
            authenticateWithBiometrics()
        } else {
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

    // Fonction pour l'authentification biométrique
    func authenticateWithBiometrics() {
        let context = LAContext()
        let reason = "Connectez-vous pour accéder à l'application"

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
            DispatchQueue.main.async {
                if success {
                    // Vérifier si l'utilisateur existe
                    if KeychainHelper.getPassword(for: username) != nil {
                        proceedToMainView()
                    } else {
                        errorMessage = "Aucun compte associé à ce nom d'utilisateur."
                        showError = true
                    }
                } else {
                    errorMessage = authenticationError?.localizedDescription ?? "Échec de l'authentification biométrique."
                    showError = true
                }
            }
        }
    }

    // Fonction pour passer à la vue principale
    func proceedToMainView() {
        appState.isLoggedIn = true
        print("here !")
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
