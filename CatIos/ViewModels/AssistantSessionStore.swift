import Combine
import Foundation

@MainActor
final class AssistantSessionStore: ObservableObject {
    static let shared = AssistantSessionStore(database: .shared)

    @Published private(set) var conversations: [AssistantConversation] = [] {
        didSet { persistIfReady() }
    }
    @Published var lastError: String?

    private let database: AppDatabase
    private var isReady = false

    init(database: AppDatabase) {
        self.database = database
        conversations = database.loadAssistantSessions()
        isReady = true
    }

    func conversation(id: UUID) -> AssistantConversation? {
        conversations.first { $0.id == id }
    }

    func availableTitle(_ base: String, petId: UUID) -> String {
        let titles = Set(conversations.filter { $0.petId == petId }.map(\.title))
        if !titles.contains(base) { return base }
        var number = 2
        while titles.contains("\(base) \(number)") {
            number += 1
        }
        return "\(base) \(number)"
    }

    @discardableResult
    func start(petId: UUID, title: String, pendingPrompt: String? = nil) -> UUID {
        let now = Date()
        let conversation = AssistantConversation(
            id: UUID(),
            petId: petId,
            title: title,
            messages: [],
            createdAt: now,
            updatedAt: now,
            synced: false,
            pendingPrompt: pendingPrompt
        )
        conversations.insert(conversation, at: 0)
        return conversation.id
    }

    func consumePendingPrompt(id: UUID) -> String? {
        guard let index = conversations.firstIndex(where: { $0.id == id }),
              let prompt = conversations[index].pendingPrompt else { return nil }
        conversations[index].pendingPrompt = nil
        return prompt
    }

    func rename(id: UUID, title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = conversations.firstIndex(where: { $0.id == id }) else { return }
        conversations[index].title = trimmed
        conversations[index].updatedAt = Date()
        let synced = conversations[index].synced
        guard synced, AuthSession.shared.isSignedIn else { return }
        Task { await pushTitle(id: id, title: trimmed) }
    }

    func delete(id: UUID) {
        delete(ids: [id])
    }

    func delete(ids: Set<UUID>) {
        guard !ids.isEmpty else { return }
        let syncedIDs = ids.filter { conversation(id: $0)?.synced == true }
        conversations.removeAll { ids.contains($0.id) }
        guard AuthSession.shared.isSignedIn else { return }
        for id in syncedIDs {
            Task { await pushDelete(id: id) }
        }
    }

    func deliver(text: String, conversationId: UUID, localReply: String) async -> String? {
        append(id: conversationId, text: text, isUser: true)
        guard AuthSession.shared.isSignedIn else {
            append(id: conversationId, text: localReply, isUser: false)
            return "Sign in to use the cloud assistant."
        }
        let ready = await ensureRemote(id: conversationId)
        guard ready, conversation(id: conversationId)?.synced == true else {
            let message = lastError ?? APIError.unreachable.errorDescription ?? "Couldn’t open this chat on the server."
            append(id: conversationId, text: localReply, isUser: false)
            return message
        }
        do {
            let message = try await postMessage(text, conversationId: conversationId)
            append(id: conversationId, text: message.content, isUser: false)
            lastError = nil
            return nil
        } catch {
            append(id: conversationId, text: localReply, isUser: false)
            lastError = error.localizedDescription
            return error.localizedDescription
        }
    }

    func pullFromAccount() async {
        guard AuthSession.shared.isSignedIn else { return }
        do {
            let remote: [APIAssistantSession] = try await APIClient.shared.send("GET", path: "assistant/sessions")
            merge(remote)
            for conversation in conversations where !conversation.synced {
                await ensureRemote(id: conversation.id)
            }
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func append(id: UUID, text: String, isUser: Bool) {
        guard let index = conversations.firstIndex(where: { $0.id == id }) else { return }
        conversations[index].messages.append(
            AssistantTurn(id: UUID(), text: text, isUser: isUser, createdAt: Date())
        )
        conversations[index].updatedAt = Date()
        let updated = conversations.remove(at: index)
        conversations.insert(updated, at: 0)
    }

    @discardableResult
    private func ensureRemote(id: UUID) async -> Bool {
        guard let conversation = conversation(id: id), AuthSession.shared.isSignedIn else {
            return conversation(id: id)?.synced == true
        }
        if conversation.synced { return true }

        await HouseholdSync.shared.pushNow()

        struct Body: Encodable {
            let id: UUID
            let petId: UUID?
            let title: String
        }

        let preferredPetId = APIMapping.petIDForAPI(conversation.petId)
        for petId in [preferredPetId, nil] {
            do {
                let _: APIAssistantSession = try await APIClient.shared.send(
                    "POST",
                    path: "assistant/sessions",
                    body: Body(
                        id: conversation.id,
                        petId: petId,
                        title: conversation.title
                    )
                )
                markSynced(id)
                lastError = nil
                return true
            } catch APIError.message(let message) where message.localizedCaseInsensitiveContains("pet not found") {
                continue
            } catch APIError.message(let message) where message.localizedCaseInsensitiveContains("not found") && petId != nil {
                continue
            } catch {
                lastError = error.localizedDescription
                return false
            }
        }

        lastError = lastError ?? "Couldn’t create this chat on the server."
        return false
    }

    private func postMessage(_ text: String, conversationId: UUID) async throws -> APIAssistantMessage {
        struct Body: Encodable { let message: String }
        return try await APIClient.shared.send(
            "POST",
            path: "assistant/sessions/\(conversationId.uuidString.lowercased())/messages",
            body: Body(message: text)
        )
    }

    private func pushTitle(id: UUID, title: String) async {
        struct Body: Encodable { let title: String }
        do {
            let _: APIAssistantSession = try await APIClient.shared.send(
                "PATCH",
                path: "assistant/sessions/\(id.uuidString.lowercased())",
                body: Body(title: title)
            )
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func pushDelete(id: UUID) async {
        do {
            let _: EmptyResponse = try await APIClient.shared.send("DELETE", path: "assistant/sessions/\(id.uuidString.lowercased())")
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func markSynced(_ id: UUID) {
        guard let index = conversations.firstIndex(where: { $0.id == id }) else { return }
        conversations[index].synced = true
    }

    private func merge(_ remote: [APIAssistantSession]) {
        var local = conversations
        for item in remote {
            if let index = local.firstIndex(where: { $0.id == item.id }) {
                local[index].synced = true
                local[index].title = item.title
                let remoteUpdated = item.updatedAt ?? item.createdAt ?? .distantPast
                let remoteTurns = (item.messages ?? []).map(Self.turn)
                if !remoteTurns.isEmpty, local[index].messages.isEmpty || local[index].updatedAt <= remoteUpdated {
                    local[index].messages = remoteTurns
                    local[index].updatedAt = remoteUpdated
                }
            } else {
                local.append(Self.conversation(from: item))
            }
        }
        conversations = local.sorted { $0.updatedAt > $1.updatedAt }
    }

    private static func conversation(from item: APIAssistantSession) -> AssistantConversation {
        AssistantConversation(
            id: item.id,
            petId: item.petId ?? PetManager.allPetsId,
            title: item.title,
            messages: (item.messages ?? []).map(turn),
            createdAt: item.createdAt ?? Date(),
            updatedAt: item.updatedAt ?? item.createdAt ?? Date(),
            synced: true,
            pendingPrompt: nil
        )
    }

    private static func turn(from message: APIAssistantMessage) -> AssistantTurn {
        AssistantTurn(
            id: message.id,
            text: message.content,
            isUser: message.role == "user",
            createdAt: message.createdAt ?? Date()
        )
    }
}

private extension AssistantSessionStore {
    func persistIfReady() {
        guard isReady else { return }
        database.saveAssistantSessions(conversations)
    }
}
