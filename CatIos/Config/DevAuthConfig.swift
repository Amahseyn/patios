#if DEBUG
import Foundation

/// Local DEBUG-only defaults. Do not put real passwords here.
/// Copy values privately on your machine if you need device auto-sign-in.
enum DevAuthConfig {
    static let email = ""
    static let password = ""
    static let apiHost = "127.0.0.1"
    static let apiPort = 8000
    static let autoSignIn = false

    static var apiBaseURL: String {
        "http://\(apiHost):\(apiPort)/api/v1"
    }
}
#endif
