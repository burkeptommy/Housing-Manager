import Foundation

final class TokenManager {
    static let shared = TokenManager()
    private init() {}

    var accessToken: String? {
        get { SecureStorageService.shared.get(key: "accessToken") }
        set {
            if let newValue {
                SecureStorageService.shared.set(key: "accessToken", value: newValue)
            } else {
                SecureStorageService.shared.delete(key: "accessToken")
            }
        }
    }
}
