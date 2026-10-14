import Foundation
import Combine

@MainActor
final class AuthSession: ObservableObject {
    static let shared = AuthSession()

    @Published private(set) var accessToken: String?
    @Published private(set) var currentUser: APIUser?
    @Published var lastError: String?

    var isSignedIn: Bool { accessToken != nil }

    private let defaults = UserDefaults.standard
    private let accessKey = "patios.accessToken"
    private let refreshKey = "patios.refreshToken"
    private let userKey = "patios.currentUser"

    init() {
        accessToken = defaults.string(forKey: accessKey)
        if let data = defaults.data(forKey: userKey) {
            currentUser = try? JSONDecoder().decode(APIUser.self, from: data)
        }
        MembershipStore.shared.applyServerPlan(currentUser?.plan)
    }

    func bootstrap() async {
        #if DEBUG
        AppConfig.applyDevAPIBaseURLIfNeeded()
        #endif

        if accessToken == nil, defaults.string(forKey: refreshKey) != nil {
            _ = await refreshIfPossible()
        }

        #if DEBUG
        if !isSignedIn, DevAuthConfig.autoSignIn {
            do {
                try await login(email: DevAuthConfig.email, password: DevAuthConfig.password)
                await HouseholdSync.shared.reconcileAfterSignIn()
                await AssistantSessionStore.shared.pullFromAccount()
                return
            } catch {
                lastError = error.localizedDescription
            }
        }
        #endif

        guard isSignedIn else { return }
        if currentUser == nil {
            await reloadMe()
        }
        await HouseholdSync.shared.connect()
    }

    func register(email: String, password: String) async throws {
        struct Body: Encodable { let email: String; let password: String }
        let _: APIUser = try await APIClient.shared.send("POST", path: "auth/register", body: Body(email: email, password: password), authorized: false)
        try await login(email: email, password: password)
    }

    func login(email: String, password: String) async throws {
        struct Body: Encodable { let email: String; let password: String }
        let tokens: APITokenPair = try await APIClient.shared.send("POST", path: "auth/login", body: Body(email: email, password: password), authorized: false)
        store(tokens)
        currentUser = try await APIClient.shared.send("GET", path: "me")
        persistUser()
        MembershipStore.shared.applyServerPlan(currentUser?.plan)
        lastError = nil
    }

    func logout() async {
        if let refresh = defaults.string(forKey: refreshKey) {
            struct Body: Encodable { let refreshToken: String }
            _ = try? await APIClient.shared.sendRaw("POST", path: "auth/logout", body: Body(refreshToken: refresh), authorized: false)
        }
        clear()
    }

    func refreshIfPossible() async -> Bool {
        guard let refresh = defaults.string(forKey: refreshKey) else { return false }
        struct Body: Encodable { let refreshToken: String }
        do {
            let tokens: APITokenPair = try await APIClient.shared.send("POST", path: "auth/refresh", body: Body(refreshToken: refresh), authorized: false, allowRetry: false)
            store(tokens)
            return true
        } catch {
            clear()
            return false
        }
    }

    func reloadMe() async {
        guard isSignedIn else { return }
        do {
            currentUser = try await APIClient.shared.send("GET", path: "me")
            persistUser()
            MembershipStore.shared.applyServerPlan(currentUser?.plan)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func store(_ tokens: APITokenPair) {
        accessToken = tokens.accessToken
        defaults.set(tokens.accessToken, forKey: accessKey)
        defaults.set(tokens.refreshToken, forKey: refreshKey)
    }

    func adopt(_ user: APIUser) {
        currentUser = user
        persistUser()
        MembershipStore.shared.applyServerPlan(user.plan)
    }

    private func persistUser() {
        if let currentUser, let data = try? JSONEncoder().encode(currentUser) {
            defaults.set(data, forKey: userKey)
        }
    }

    private func clear() {
        accessToken = nil
        currentUser = nil
        defaults.removeObject(forKey: accessKey)
        defaults.removeObject(forKey: refreshKey)
        defaults.removeObject(forKey: userKey)
        MembershipStore.shared.applyServerPlan(nil)
    }
}
