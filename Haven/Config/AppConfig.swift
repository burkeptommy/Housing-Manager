import Foundation

enum AppConfig {
    // MARK: - App Identity
    static let appName = "Chez"
    static let bundleID = "com.havenhome.app"
    /// Pulled live from `CFBundleShortVersionString` instead of being
    /// hardcoded so the value never drifts from project.yml.
    static var version: String { Bundle.main.appVersion }

    // MARK: - API URLs
    static let supportEmail = "support@havenhome.dev"

    // MARK: - Supabase
    enum Supabase {
        static let url = "https://jsucwnkntdrxhysojgri.supabase.co"
        static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpzdWN3bmtudGRyeGh5c29qZ3JpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI2MzMxNzksImV4cCI6MjA4ODIwOTE3OX0.TLNwkT3PE4DTMFey1a7utLOROSF8zvu-ZE5us14c9ew"
    }

    // MARK: - Firebase (legacy — not used in Supabase rebuild)
    // These remain as reference for the migration period.
    // Firebase config is loaded from GoogleService-Info.plist at runtime, not hardcoded.
    enum Firebase {
        static let projectID = "home-manager-480616"
    }

    // MARK: - Google OAuth
    // Client IDs are configured in GoogleService-Info.plist and URL schemes.
    // These are public identifiers (not secrets) per Google's OAuth documentation.
    enum Google {
        static let webClientID = "421884826038-j17pdc6q3loa7kr13evbiaraq0d8cnef.apps.googleusercontent.com"
        static let iOSClientID = "421884826038-oi6sdgqco1g7umpogf1g2b754tpg80q8.apps.googleusercontent.com"
        static let placesAPIKey = "AIzaSyDeJGjktaIHmcybrOV4LZyBHiRS0G_BUaA"
    }

    // MARK: - Apple Developer (public identifiers)
    enum Apple {
        static let teamID = "RW9CWCAWGQ"
        static let appStoreConnectAppID = "6757167606"
    }

    // MARK: - Anthropic (Claude AI)
    // SECURITY: The Claude API key must NEVER be stored in the iOS client.
    // All AI calls go through Supabase Edge Functions which hold the key server-side.
    // See: supabase/functions/analyze-document/, supabase/functions/chat/

    // MARK: - Stripe
    // Publishable keys are designed to be embedded in clients (not secrets).
    // Secret keys must NEVER be in the iOS client.
    enum Stripe {
        static let publishableKey = "pk_test_51SoFNhPytM2v6SzSNBKatg7RWvnC8GAOacCgvHM8Oh25wM53bWihWd2FLEfTo22tvjI742BXpZgSkBK20QLcCvX100L7r2G1Qh"
    }
}
