import Foundation
import Security

class KeychainHelper {
    static func savePassword(_ password: String, for account: String) {
        if let data = password.data(using: .utf8) {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: account,
                kSecValueData as String: data
            ]

            // Supprimer les anciennes données si elles existent
            SecItemDelete(query as CFDictionary)
            let status = SecItemAdd(query as CFDictionary, nil)
            if status != errSecSuccess {
                print("Erreur lors de la sauvegarde du mot de passe : \(status)")
            }
        }
    }

    static func getPassword(for account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?

        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        if status == errSecSuccess {
            if let data = dataTypeRef as? Data, let password = String(data: data, encoding: .utf8) {
                return password
            }
        }
        return nil
    }

    static func saveBiometricPreference(_ enabled: Bool, for account: String) {
        let key = "\(account)_biometric"
        let value = enabled ? "true" : "false"

        if let data = value.data(using: .utf8) {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
                kSecValueData as String: data
            ]

            SecItemDelete(query as CFDictionary)
            let status = SecItemAdd(query as CFDictionary, nil)
            if status != errSecSuccess {
                print("Erreur lors de la sauvegarde de la préférence biométrique : \(status)")
            }
        }
    }

    static func isBiometricEnabled(for account: String) -> Bool {
        let key = "\(account)_biometric"

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?

        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        if status == errSecSuccess {
            if let data = dataTypeRef as? Data, let value = String(data: data, encoding: .utf8) {
                return value == "true"
            }
        }
        return false
    }
}
