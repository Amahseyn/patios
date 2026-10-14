#if DEBUG
import Foundation

// Example only. Prefer editing DevAuthConfig.swift locally and keep secrets out of git.
enum DevAuthConfigExample {
    static let email = "you@example.com"
    static let password = "replace-me"
    static let apiHost = "192.168.1.10"
    static let apiPort = 8000
    static let autoSignIn = false
}
#endif
