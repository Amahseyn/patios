import SwiftUI

struct AssistantSessionListView: View {
    @EnvironmentObject private var sessions: AssistantSessionStore
    @EnvironmentObject private var petManager: PetManager
    @EnvironmentObject private var authSession: AuthSession
    @EnvironmentObject private var householdSync: HouseholdSync
    @Binding var path: NavigationPath

    @State private var scope: UUID = PetManager.allPetsId
    @State private var query = ""
    @State private var renamingId: UUID?
    @State private var renameText = ""
    @State private var showRename = false
    @State private var isManaging = false
    @State private var selection = Set<UUID>()
    @State private var confirmDelete = false

    private var petForNewChat: PetProfile {
        if scope != PetManager.allPetsId, let pet = petManager.pets.first(where: { $0.id == scope }) {
            return pet
        }
        return petManager.currentPet
    }

    private var filtered: [AssistantConversation] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return sessions.conversations.filter { conversation in
            let petMatches = scope == PetManager.allPetsId || conversation.petId == scope
            let textMatches = needle.isEmpty
                || conversation.title.localizedCaseInsensitiveContains(needle)
                || conversation.messages.contains { $0.text.localizedCaseInsensitiveContains(needle) }
            return petMatches && textMatches
        }
    }

    var body: some View {
        chatList
            .searchable(text: $query, prompt: "Search chats")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if householdSync.canMutate {
                        Button("New", systemImage: "square.and.pencil") {
                            startChat()
                        }
                    }
                }
                if householdSync.canMutate, !filtered.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(isManaging ? "Done" : "Manage") {
                            withAnimation {
                                isManaging.toggle()
                                if !isManaging { selection.removeAll() }
                            }
                        }
                    }
                }
            }
            .refreshable {
                await sessions.pullFromAccount()
            }
            .onAppear {
                Task { await sessions.pullFromAccount() }
            }
            .alert("Rename chat", isPresented: $showRename) {
                TextField("Title", text: $renameText)
                Button("Save") {
                    if let renamingId {
                        sessions.rename(id: renamingId, title: renameText)
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog(
                "Delete \(selection.count) chat\(selection.count == 1 ? "" : "s")?",
                isPresented: $confirmDelete,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    sessions.delete(ids: selection)
                    selection.removeAll()
                    isManaging = false
                }
                Button("Cancel", role: .cancel) {}
            }
    }

    private var chatList: some View {
        List(selection: $selection) {
            if !authSession.isSignedIn {
                Section {
                    HStack(alignment: .top, spacing: 12) {
                        EnchantedIconBadge(systemImage: "key.fill", tint: AppTheme.warning, size: 40)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sign in for cloud answers")
                                .font(AppTheme.headlineFont())
                            Text("Chats stay on this iPhone until you sign in. Open You to connect your account for AI replies that sync.")
                                .font(AppTheme.captionFont())
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            if let error = sessions.lastError {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(AppTheme.warning)
                }
            }

            Section {
                PetScopePicker(selection: $scope, pets: petManager.pets)
            }

            Section {
                topicRow
            } header: {
                FantasySectionHeader(title: "Quick prompts", subtitle: "Start a chat with a topic")
            }

            Section {
                chatRows
            } header: {
                HStack {
                    FantasySectionHeader(title: "Your chats", subtitle: sessionFooter)
                    Spacer()
                    if isManaging, !selection.isEmpty {
                        Button("Delete", role: .destructive) {
                            confirmDelete = true
                        }
                        .font(AppTheme.captionFont().weight(.bold))
                    }
                }
            }
        }
        .environment(\.editMode, .constant(isManaging ? .active : .inactive))
    }

    private var sessionFooter: String {
        if isManaging {
            return "Select chats to delete, or swipe one to rename or delete"
        }
        if authSession.isSignedIn {
            return "Swipe or use Manage to rename or delete"
        }
        return "Saved on this iPhone"
    }

    private var topicRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.spacingS) {
                ForEach(AssistantTopic.allCases) { topic in
                    Button {
                        openTopic(topic)
                    } label: {
                        FantasyTopicChip(title: topic.rawValue, systemImage: topic.systemImage)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private var chatRows: some View {
        if filtered.isEmpty {
            emptyChats
        } else {
            ForEach(filtered) { conversation in
                if isManaging {
                    sessionRow(conversation)
                        .tag(conversation.id)
                } else {
                    conversationButton(conversation)
                }
            }
        }
    }

    @ViewBuilder
    private var emptyChats: some View {
        if query.isEmpty {
            EmptyStateView(
                systemImage: "envelope.open.fill",
                title: "No chats yet",
                message: "Ask about meals, mood, health, or this week's routine.",
                actionTitle: householdSync.canMutate ? "New Chat" : nil,
                action: householdSync.canMutate ? { startChat() } : nil
            )
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
        } else {
            EmptyStateView(
                systemImage: "magnifyingglass",
                title: "No matching chats",
                message: "Try another title or phrase."
            )
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
        }
    }

    private func conversationButton(_ conversation: AssistantConversation) -> some View {
        Button {
            path.append(conversation.id)
        } label: {
            sessionRow(conversation)
        }
        .foregroundStyle(.primary)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if householdSync.canMutate {
                Button("Delete", role: .destructive) {
                    sessions.delete(id: conversation.id)
                }
                Button("Rename") {
                    beginRename(conversation)
                }
                .tint(AppTheme.primary)
            }
        }
        .contextMenu {
            if householdSync.canMutate {
                Button("Open", systemImage: "bubble.left.and.bubble.right") {
                    path.append(conversation.id)
                }
                Button("Rename", systemImage: "pencil") {
                    beginRename(conversation)
                }
                Button("Delete", systemImage: "trash", role: .destructive) {
                    sessions.delete(id: conversation.id)
                }
            }
        }
    }

    private func beginRename(_ conversation: AssistantConversation) {
        renamingId = conversation.id
        renameText = conversation.title
        showRename = true
    }

    private func sessionRow(_ conversation: AssistantConversation) -> some View {
        let pet = petManager.pets.first { $0.id == conversation.petId }
        return HStack(spacing: AppTheme.spacingM) {
            Text(pet?.avatarEmoji ?? "🐾")
                .font(.title2)
                .frame(width: 40)
                .padding(6)
                .background(AppTheme.primary.opacity(0.1), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.title)
                        .font(AppTheme.headlineFont())
                    Spacer()
                    Text(conversation.updatedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(AppTheme.captionFont())
                        .foregroundStyle(AppTheme.textSecondary)
                }
                HStack(spacing: 6) {
                    Text(pet?.name ?? "Pet")
                        .font(AppTheme.captionFont().weight(.semibold))
                        .foregroundStyle(AppTheme.primary)
                    if conversation.synced {
                        Image(systemName: "icloud.fill")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.success)
                    }
                    Text("\(conversation.messages.count) messages")
                        .font(AppTheme.captionFont())
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Text(conversation.preview)
                    .font(AppTheme.bodyFont())
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 6)
    }

    private func startChat() {
        let pet = petForNewChat
        let title = sessions.availableTitle("New chat", petId: pet.id)
        path.append(sessions.start(petId: pet.id, title: title))
    }

    private func openTopic(_ topic: AssistantTopic) {
        let pet = petForNewChat
        if let existing = sessions.conversations.first(where: { $0.petId == pet.id && $0.title == topic.rawValue }) {
            path.append(existing.id)
            return
        }
        let id = sessions.start(
            petId: pet.id,
            title: topic.rawValue,
            pendingPrompt: topic.prompt(petName: pet.name)
        )
        path.append(id)
    }
}
