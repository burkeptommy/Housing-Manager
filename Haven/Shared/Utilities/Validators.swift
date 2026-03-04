import Foundation

enum Validators {
    static func isValidEmail(_ email: String) -> Bool {
        email.isValidEmail
    }

    static func isValidPassword(_ password: String) -> Bool {
        password.count >= 8
    }

    static func isNotEmpty(_ value: String) -> Bool {
        !value.trimmed.isEmpty
    }
}
