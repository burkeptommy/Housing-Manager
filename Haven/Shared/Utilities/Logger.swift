import OSLog

extension Logger {
    static let app = Logger(subsystem: "com.havenhome.app", category: "app")
    static let auth = Logger(subsystem: "com.havenhome.app", category: "auth")
    static let network = Logger(subsystem: "com.havenhome.app", category: "network")
    static let documents = Logger(subsystem: "com.havenhome.app", category: "documents")
}
