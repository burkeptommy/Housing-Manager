import Foundation
import CryptoKit

/// Handles client-side AES-256-GCM encryption/decryption for documents.
/// Each household gets a unique symmetric key stored in Keychain.
/// Documents are encrypted before upload and decrypted after download.
final class DocumentEncryption {
    static let shared = DocumentEncryption()
    private let keyPrefix = "household_encryption_key_"

    private init() {}

    /// Get or create the encryption key for a household.
    func key(for householdId: UUID) -> SymmetricKey {
        let keyName = keyPrefix + householdId.uuidString

        // Try to load existing key from Keychain
        if let existingKeyData = SecureStorageService.shared.getData(key: keyName) {
            return SymmetricKey(data: existingKeyData)
        }

        // Generate a new 256-bit key
        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }
        SecureStorageService.shared.setData(key: keyName, data: keyData)

        return newKey
    }

    /// Encrypt document data before uploading to Supabase Storage.
    func encrypt(data: Data, householdId: UUID) throws -> Data {
        let encryptionKey = key(for: householdId)
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey)
        guard let combined = sealedBox.combined else {
            throw EncryptionError.encryptionFailed
        }
        return combined
    }

    /// Decrypt document data after downloading from Supabase Storage.
    /// Backwards compatible: if decryption fails, assumes the file is a
    /// legacy unencrypted upload and returns the data as-is.
    func decrypt(data: Data, householdId: UUID) -> Data {
        do {
            let encryptionKey = key(for: householdId)
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            return try AES.GCM.open(sealedBox, using: encryptionKey)
        } catch {
            // Legacy unencrypted file — return as-is
            return data
        }
    }

    /// Export the household encryption key as base64 string (for sharing with Edge Functions).
    func keyBase64(for householdId: UUID) -> String {
        let symmetricKey = key(for: householdId)
        return symmetricKey.withUnsafeBytes { Data($0).base64EncodedString() }
    }

    /// Decrypt a base64-encoded AES-256-GCM string (IV + ciphertext combined).
    /// Used for chat messages encrypted by the Edge Function.
    /// Returns the original string, or the input as-is if it's not encrypted (backwards compat).
    func decryptString(_ base64String: String, householdId: UUID) -> String {
        guard let combined = Data(base64Encoded: base64String) else {
            return base64String // Not base64 — treat as plaintext
        }
        do {
            let encryptionKey = key(for: householdId)
            let sealedBox = try AES.GCM.SealedBox(combined: combined)
            let decrypted = try AES.GCM.open(sealedBox, using: encryptionKey)
            return String(data: decrypted, encoding: .utf8) ?? base64String
        } catch {
            // Not encrypted or wrong key — return as-is (backwards compat with old plaintext messages)
            return base64String
        }
    }

    enum EncryptionError: LocalizedError {
        case encryptionFailed
        case decryptionFailed

        var errorDescription: String? {
            switch self {
            case .encryptionFailed: return "Failed to encrypt document"
            case .decryptionFailed: return "Failed to decrypt document"
            }
        }
    }
}
