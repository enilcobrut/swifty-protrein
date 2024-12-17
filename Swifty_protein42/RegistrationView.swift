import SwiftUI
import LocalAuthentication

struct RegistrationView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appState: AppState
    @State private var email = ""
    @State private var password = ""
    @State private var enableBiometrics = false
    @State private var isBiometricAvailable = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack {
            Text("S'inscrire")
                .font(.largeTitle)
                .padding()

            TextField("Adresse e-mail", text: $email)
                .keyboardType(.emailAddress)
                .textContentType(.username)
                .autocapitalization(.none)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(5)

            SecureField("Mot de passe", text: $password)
                .textContentType(.newPassword)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(5)

            if isBiometricAvailable {
                Toggle("Activer l'authentification biométrique", isOn: $enableBiometrics)
                    .padding()
            }

            Button(action: register) {
                Text("Créer un compte")
                    .frame(maxWidth: .infinity)
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(5)

            Spacer()
        }
        .padding()
        .onAppear {
            checkBiometricAvailability()
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Erreur"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
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
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Veuillez remplir tous les champs."
            showError = true
            return
        }

        // Vérifier si l'utilisateur existe déjà
        if KeychainHelper.getPassword(for: email) != nil {
            errorMessage = "Un compte existe déjà avec cet e-mail."
            showError = true
        } else {
            // Enregistrer le mot de passe dans le Keychain
            KeychainHelper.savePassword(password, for: email)

            // Enregistrer la préférence biométrique
            if enableBiometrics {
                KeychainHelper.saveBiometricPreference(true, for: email)
            } else {
                KeychainHelper.saveBiometricPreference(false, for: email)
            }

            // Fermer la vue d'inscription
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct RegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        RegistrationView()
    }
}
