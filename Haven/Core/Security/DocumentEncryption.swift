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

    /// Placeholder shown when a message was clearly encrypted with a key we
    /// no longer have (e.g. simulator Keychain wipe, fresh install on new device).
    static let undecryptableMessagePlaceholder =
        "🔒 This message was encrypted with a key that's no longer on this device. It may have been written from another device or before this app was reinstalled."

    /// Decrypt a base64-encoded AES-256-GCM string (IV + ciphertext combined).
    /// Used for chat messages encrypted by the Edge Function.
    /// Returns the decrypted plaintext, the input as-is if it's plain text
    /// (backwards-compat for legacy unencrypted rows), or a friendly placeholder
    /// if the value is clearly encrypted but we can't decrypt it.
    func decryptString(_ base64String: String, householdId: UUID) -> String {
        // Heuristic: legitimate plaintext chat messages are very unlikely to be
        // long, valid base64 strings. Only treat as "maybe encrypted" if it
        // decodes to a buffer large enough to contain GCM nonce(12) + tag(16).
        guard let combined = Data(base64Encoded: base64String), combined.count >= 28 else {
            return base64String // Plain text or too short to be ciphertext
        }
        do {
            let encryptionKey = key(for: householdId)
            let sealedBox = try AES.GCM.SealedBox(combined: combined)
            let decrypted = try AES.GCM.open(sealedBox, using: encryptionKey)
            return String(data: decrypted, encoding: .utf8) ?? base64String
        } catch {
            // Decryption failed but the input looked like ciphertext — show a
            // placeholder instead of dumping the raw base64 into the UI.
            return Self.undecryptableMessagePlaceholder
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
