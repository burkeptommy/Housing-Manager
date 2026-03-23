import Foundation
import CryptoKit

/// Handles per-document client-side encryption for Vault Lock.
/// Vault-locked documents have an additional layer of AES-256-GCM encryption
/// using a key stored only in the device Keychain (biometric-protected).
/// The server cannot decrypt these documents.
final class VaultLockService {
    static let shared = VaultLockService()
    private let keychainKey = "vault_lock_master_key"

    private init() {}

    /// Get or create the Vault Lock master key (device-only, Keychain-stored).
    private func masterKey() -> SymmetricKey {
        if let existingKeyData = SecureStorageService.shared.getData(key: keychainKey) {
            return SymmetricKey(data: existingKeyData)
        }
        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }
        SecureStorageService.shared.setData(key: keychainKey, data: keyData)
        return newKey
    }

    /// Encrypt data for Vault Lock. Returns encrypted data and the IV (to store in DB).
    func encrypt(data: Data) throws -> (encryptedData: Data, iv: String) {
        let key = masterKey()
        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let combined = sealedBox.combined else {
            throw VaultLockError.encryptionFailed
        }
        let iv = sealedBox.nonce.withUnsafeBytes { Data($0) }.base64EncodedString()
        return (combined, iv)
    }

    /// Decrypt Vault-locked data on-device.
    func decrypt(data: Data) throws -> Data {
        let key = masterKey()
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }

    /// Check if a Vault Lock key exists on this device.
    var hasKey: Bool {
        SecureStorageService.shared.getData(key: keychainKey) != nil
    }

    enum VaultLockError: LocalizedError {
        case encryptionFailed
        case noKeyAvailable

        var errorDescription: String? {
            switch self {
            case .encryptionFailed: return "Failed to encrypt document with Vault Lock"
            case .noKeyAvailable: return "No Vault Lock key found on this device"
            }
        }
    }
}
