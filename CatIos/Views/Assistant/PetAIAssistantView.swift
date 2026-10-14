//
//  PetAIAssistantView.swift
//  CatIos
//
//  AI chat assistant with voice input support.
//

import Speech
import SwiftUI
import UIKit

struct PetAIAssistantView: View {
    @EnvironmentObject private var petManager: PetManager
    @EnvironmentObject private var authSession: AuthSession
    @EnvironmentObject private var sessions: AssistantSessionStore
    @EnvironmentObject private var householdSync: HouseholdSync
    let conversationId: UUID
    @Binding var path: NavigationPath

    @State private var inputText: String = ""
    @State private var isRecording: Bool = false
    @State private var recognizedText: String = ""
    @State private var isSending: Bool = false
    @State private var speechStatus = SFSpeechRecognizer.authorizationStatus()
    @State private var assistantError: String?
    @State private var renaming = false
    @State private var renameText = ""
    @State private var confirmDelete = false
    @AppStorage(NotificationPreferences.assistantKey) private var suggestionsEnabled = true

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()

    private var conversation: AssistantConversation? {
        sessions.conversation(id: conversationId)
    }

    private var messages: [AssistantTurn] {
        conversation?.messages ?? []
    }

    private var sessionPet: PetProfile {
        if let petId = conversation?.petId, let pet = petManager.pets.first(where: { $0.id == petId }) {
            return pet
        }
        return petManager.currentPet
    }

    private var suggestedQuestions: [String] {
        let name = sessionPet.name
        return [
            "How is \(name) feeling today?",
            "What should I feed \(name) this evening?",
            "What’s coming due for \(name)?",
            "Help me plan \(name)’s care this week."
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        if !authSession.isSignedIn {
                            HStack(alignment: .top, spacing: 10) {
                                EnchantedIconBadge(systemImage: "key.fill", tint: AppTheme.warning, size: 36)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("On-device answers only")
                                        .font(AppTheme.headlineFont())
                                    Text("Sign in from You for cloud AI answers that sync with your account.")
                                        .font(AppTheme.captionFont())
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                            }
                            .padding(AppTheme.spacingM)
                            .cardStyle()
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }

                        if speechStatus == .denied || speechStatus == .restricted {
                            speechDeniedBanner
                                .padding(.horizontal)
                        }

                        if let assistantError {
                            Text(assistantError)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .padding(.horizontal)
                        } else if let syncError = sessions.lastError {
                            Text(syncError)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .padding(.horizontal)
                        }

                        if messages.isEmpty {
                            aiWelcomeHeader
                                .padding(.horizontal)
                            if suggestionsEnabled && householdSync.canMutate {
                                suggestedQuestionsSection
                                    .padding(.horizontal)
                            }
                        }

                        ForEach(messages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                                .padding(.horizontal)
                        }

                        if isSending {
                            typingIndicator.id("typing").padding(.horizontal)
                        }

                        if isRecording {
                            recordingIndicator.padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: messages.count) {
                    scrollToLatest(proxy)
                }
                .onChange(of: isSending) { _, sending in
                    if sending { scrollToLatest(proxy) }
                }
            }

            Divider()
            if householdSync.canMutate {
                inputFieldBar
            }
            Text(CareInsights.disclaimer)
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
        }
        .fantasyScreen()
        .fantasyNavigation()
        .navigationTitle(conversation?.title ?? "Chat")
        .navigationSubtitle(sessionPet.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if householdSync.canMutate {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("New Chat", systemImage: "square.and.pencil") {
                        startAnotherChat()
                    }
                    Button("Rename", systemImage: "pencil") {
                        renameText = conversation?.title ?? ""
                        renaming = true
                    }
                    Button("Delete Chat", systemImage: "trash", role: .destructive) {
                        confirmDelete = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Chat actions")
            }
            }
        }
        .confirmationDialog("Delete this chat?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                sessions.delete(id: conversationId)
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Rename chat", isPresented: $renaming) {
            TextField("Title", text: $renameText)
            Button("Save") {
                sessions.rename(id: conversationId, title: renameText)
            }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear {
            requestSpeechIfNeeded()
            if let prompt = sessions.consumePendingPrompt(id: conversationId) {
                sendMessage(prompt)
            }
        }
        .onChange(of: sessions.conversations.contains { $0.id == conversationId }) { _, exists in
            if !exists, !path.isEmpty {
                path.removeLast()
            }
        }
    }

    private func scrollToLatest(_ proxy: ScrollViewProxy) {
        withAnimation {
            if isSending {
                proxy.scrollTo("typing", anchor: .bottom)
            } else if let last = messages.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }

    private func startAnotherChat() {
        let title = sessions.availableTitle("New chat", petId: sessionPet.id)
        let id = sessions.start(petId: sessionPet.id, title: title)
        if !path.isEmpty { path.removeLast() }
        path.append(id)
    }

    private var aiWelcomeHeader: some View {
        HStack(spacing: AppTheme.spacingM) {
            EnchantedIconBadge(systemImage: "bubble.left.and.bubble.right.fill", tint: AppTheme.assistant, size: 52)
            VStack(alignment: .leading, spacing: 4) {
                Text(conversation?.title ?? "Assistant")
                    .font(AppTheme.headlineFont())
                    .foregroundStyle(AppTheme.textPrimary)
                Text(authSession.isSignedIn
                     ? "Using \(sessionPet.name)’s tasks and health records"
                     : "Using \(sessionPet.name)’s data saved on this iPhone")
                    .font(AppTheme.captionFont())
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
        }
        .padding(AppTheme.spacingM)
        .cardStyle(cornerRadius: AppTheme.cornerRadiusLarge)
    }

    private var speechDeniedBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "mic.slash.fill")
                .foregroundStyle(AppTheme.warning)
            VStack(alignment: .leading, spacing: 4) {
                Text("Microphone is off")
                    .font(.caption.weight(.bold))
                Text("Enable Speech Recognition and Microphone in Settings to dictate questions.")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    Button("Open Settings") {
                        UIApplication.shared.open(url)
                    }
                    .font(.caption.weight(.bold))
                }
            }
            Spacer()
        }
        .padding(12)
        .background(AppTheme.warning.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var suggestedQuestionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingS) {
            Text("Try asking")
                .font(AppTheme.captionFont().weight(.bold))
                .foregroundStyle(AppTheme.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.spacingS) {
                    ForEach(suggestedQuestions, id: \.self) { question in
                        Button {
                            sendMessage(question)
                        } label: {
                            Text(question)
                                .font(AppTheme.captionFont())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background {
                                    Capsule(style: .continuous)
                                        .fill(AppTheme.cardBackground)
                                        .overlay {
                                            Capsule(style: .continuous)
                                                .strokeBorder(AppTheme.enchantedBorder, lineWidth: 1)
                                        }
                                }
                        }
                        .buttonStyle(.plain)
                        .disabled(isSending)
                    }
                }
            }
        }
    }

    private var inputFieldBar: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Ask about meals, health, or routines…", text: $inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...5)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(AppTheme.cardBackground)
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(AppTheme.enchantedBorder, lineWidth: 1)
                        }
                }

            Button {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            } label: {
                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.title)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isRecording ? Color.red : Color.accentColor)
            }
            .disabled(!speechStatus.isAuthorized)
            .accessibilityLabel(isRecording ? "Stop recording" : "Dictate")

            Button {
                guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                let text = inputText
                inputText = ""
                sendMessage(text)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
                    .symbolRenderingMode(.hierarchical)
            }
            .disabled(isSending || inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel("Send")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private var recordingIndicator: some View {
        HStack(spacing: AppTheme.spacingS) {
            Image(systemName: "mic.fill")
                .foregroundStyle(.red)
            Text("Listening...")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.red)
            if !recognizedText.isEmpty {
                Text("• \"\(recognizedText)\"")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
        }
        .padding(AppTheme.spacingM)
        .background(Color.red.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
    }

    private var typingIndicator: some View {
        HStack {
            ProgressView()
            Text("\(sessionPet.name)’s assistant is typing…")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    private func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSending else { return }
        isSending = true
        assistantError = nil
        let local = CareAssistantReply.reply(
            for: trimmed,
            petName: sessionPet.name,
            wellnessScore: sessionPet.wellnessScore
        )
        Task {
            assistantError = await sessions.deliver(text: trimmed, conversationId: conversationId, localReply: local)
            isSending = false
        }
    }

    private func requestSpeechIfNeeded() {
        let status = SFSpeechRecognizer.authorizationStatus()
        speechStatus = status
        guard status == .notDetermined else { return }
        SFSpeechRecognizer.requestAuthorization { next in
            DispatchQueue.main.async {
                speechStatus = next
            }
        }
    }

    private func startRecording() {
        guard speechStatus == .authorized,
              let speechRecognizer = speechRecognizer,
              speechRecognizer.isAvailable else {
            requestSpeechIfNeeded()
            return
        }

        isRecording = true
        recognizedText = ""

        let audioEngine = self.audioEngine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { _, _ in }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            isRecording = false
            assistantError = "Could not start the microphone."
            return
        }

        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest.shouldReportPartialResults = true

        speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                let transcript = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.recognizedText = transcript
                }
            }

            if error != nil || (result?.isFinal ?? false) {
                audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                DispatchQueue.main.async {
                    self.isRecording = false
                    if let transcript = result?.bestTranscription.formattedString, !transcript.isEmpty {
                        self.inputText = transcript
                    }
                }
            }
        }
    }

    private func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        isRecording = false
    }
}

struct ChatBubble: View {
    let message: AssistantTurn

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser { Spacer(minLength: 48) } else {
                EnchantedIconBadge(systemImage: "pawprint.fill", tint: AppTheme.assistant, size: 28)
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(AppTheme.bodyFont())
                    .foregroundStyle(message.isUser ? Color.white : AppTheme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background {
                        if message.isUser {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(AppTheme.heroGradient)
                        } else {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(AppTheme.cardBackground)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .strokeBorder(AppTheme.enchantedBorder, lineWidth: 1)
                                }
                        }
                    }
                    .contextMenu {
                        Button("Copy", systemImage: "doc.on.doc") {
                            UIPasteboard.general.string = message.text
                        }
                    }
                Text(message.createdAt, format: .dateTime.hour().minute())
                    .font(AppTheme.captionFont())
                    .foregroundStyle(AppTheme.textSecondary)
            }

            if !message.isUser { Spacer(minLength: 48) }
        }
    }
}

extension SFSpeechRecognizerAuthorizationStatus {
    var isAuthorized: Bool {
        self == .authorized
    }
}
