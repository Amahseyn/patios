//
//  PetAIAssistantView.swift
//  CatIos
//
//  AI chat assistant with voice input support.

import SwiftUI
import Speech

struct PetAIAssistantView: View {
    @EnvironmentObject private var petManager: PetManager
    @State private var inputText: String = ""
    @State private var messages: [ChatMessage] = []
    @State private var isRecording: Bool = false
    @State private var recognizedText: String = ""

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()

    let suggestedQuestions = [
        "Is my pet happy?",
        "Why does my pet bark at night?",
        "Why is my pet crying?",
        "How can I improve my pet's routine?"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: AppTheme.spacingM) {
                            aiWelcomeHeader

                            suggestedQuestionsSection

                            ForEach(messages) { msg in
                                ChatBubble(message: msg)
                                    .id(msg.id)
                            }

                            if isRecording {
                                recordingIndicator
                            }
                        }
                        .padding(AppTheme.spacingM)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onTapGesture {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .onChange(of: messages.count) { _ in
                        if let last = messages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                inputFieldBar
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Patios AI")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if messages.isEmpty {
                    loadInitialConversation()
                }
            }
        }
    }

    private var aiWelcomeHeader: some View {
        HStack(spacing: AppTheme.spacingM) {
            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(AppTheme.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(petManager.currentPet.name) AI Behavior Specialist")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Trained on \(petManager.currentPet.name)'s history & vocal patterns")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()
        }
        .padding(AppTheme.spacingM)
        .cardStyle()
    }

    private var suggestedQuestionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingS) {
            Text("Suggested Questions")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.spacingS) {
                    ForEach(suggestedQuestions, id: \.self) { question in
                        Button {
                            sendMessage(question)
                        } label: {
                            Text(question)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppTheme.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(AppTheme.primary.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    private var inputFieldBar: some View {
        HStack(spacing: AppTheme.spacingS) {
            TextField("Ask anything about \(petManager.currentPet.name)...", text: $inputText)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppTheme.cardBackground)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )

            Button {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(isRecording ? Color.red : AppTheme.primary)
                        .frame(width: 44, height: 44)
                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }
            .disabled(!SFSpeechRecognizer.authorizationStatus().isAuthorized)

            Button {
                guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                sendMessage(inputText)
                inputText = ""
            } label: {
                ZStack {
                    Circle()
                        .fill(AppTheme.primary)
                        .frame(width: 44, height: 44)
                    Image(systemName: "paperplane.fill")
                        .font(.body.weight(.bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(AppTheme.spacingM)
        .background(AppTheme.cardBackground)
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

    @State private var sessionId: String? = nil
    @State private var isSending: Bool = false

    private func loadInitialConversation() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let now = formatter.string(from: Date())

        messages = [
            ChatMessage(
                text: "Hello! I am \(petManager.currentPet.name)'s AI Care Companion. How can I help you take great care of \(petManager.currentPet.name) today?",
                isUser: false,
                time: now
            )
        ]
        createBackendSession()
    }

    private func createBackendSession() {
        guard let url = URL(string: "http://localhost:8000/api/v1/assistant/sessions") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "cat_id": petManager.currentPet.id.uuidString,
            "title": "\(petManager.currentPet.name) Care Chat"
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, _ in
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let sid = json["id"] as? String {
                DispatchQueue.main.async {
                    self.sessionId = sid
                }
            }
        }.resume()
    }

    private func sendMessage(_ text: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let timeStr = formatter.string(from: Date())

        messages.append(ChatMessage(text: text, isUser: true, time: timeStr))
        isSending = true

        guard let sid = sessionId, let url = URL(string: "http://localhost:8000/api/v1/assistant/sessions/\(sid)/messages") else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                self.isSending = false
                let aiResponseText = self.generateMockAIResponse(for: text)
                self.messages.append(ChatMessage(text: aiResponseText, isUser: false, time: timeStr))
            }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["message": text]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isSending = false
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let replyContent = json["content"] as? String {
                    self.messages.append(ChatMessage(text: replyContent, isUser: false, time: timeStr))
                } else {
                    let fallback = self.generateMockAIResponse(for: text)
                    self.messages.append(ChatMessage(text: fallback, isUser: false, time: timeStr))
                }
            }
        }.resume()
    }

    private func generateMockAIResponse(for prompt: String) -> String {
        let pet = petManager.currentPet
        let lower = prompt.lowercased()

        if lower.contains("happy") {
            return "Based on \(pet.name)'s recent 92% positivity score and comfortable body cues, yes! \(pet.name) is currently very happy and content."
        } else if lower.contains("cry") || lower.contains("night") {
            return "\(pet.name) usually makes night vocalizations seeking comfort or food. Her evening sound pattern indicates she prefers interactive play before bed."
        } else if lower.contains("routine") {
            return "To optimize \(pet.name)'s routine, keep morning feeding at 09:00, schedule interactive wand play at 19:00, and maintain quiet rest hours in the afternoon."
        } else {
            return "\(pet.name)'s AI memory shows stable behavior patterns today. I recommend giving her a soft treat and checking her water fountain!"
        }
    }

    private func startRecording() {
        guard SFSpeechRecognizer.authorizationStatus() == .authorized,
              let speechRecognizer = speechRecognizer,
              speechRecognizer.isAvailable else {
            return
        }

        isRecording = true
        recognizedText = ""

        let audioEngine = self.audioEngine
        let inputNode = audioEngine.inputNode

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            // Audio buffer handled by speech recognizer request
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine error: \(error)")
            isRecording = false
            return
        }

        var recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
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

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let time: String
}

struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 40) }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.subheadline)
                    .lineSpacing(3)
                    .foregroundStyle(message.isUser ? .white : AppTheme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        message.isUser
                        ? AppTheme.primary
                        : AppTheme.cardBackground
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: AppTheme.cornerRadiusMedium,
                            style: .continuous
                        )
                    )
                    .cardShadow()

                Text(message.time)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.horizontal, 4)
            }

            if !message.isUser { Spacer(minLength: 40) }
        }
    }
}

extension SFSpeechRecognizerAuthorizationStatus {
    var isAuthorized: Bool {
        self == .authorized
    }
}
