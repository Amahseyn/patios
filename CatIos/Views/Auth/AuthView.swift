import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var authSession: AuthSession
    @EnvironmentObject private var householdSync: HouseholdSync
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var isRegistering = false
    @State private var isWorking = false
    @State private var errorText: String?
    @AppStorage(AppConfig.apiBaseURLKey) private var apiBaseURL = AppConfig.defaultAPIBaseURL

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.spacingL) {
                    FantasyHeroHeader(
                        title: isRegistering ? "Create an account" : "Sign in",
                        subtitle: isRegistering
                            ? "Back up pets, tasks, and health records so family can share the same household."
                            : "Sign in to sync this iPhone with your account. An empty account receives this phone’s data.",
                        systemImage: isRegistering ? "person.badge.plus" : "person.crop.circle"
                    )

                    Picker("Account", selection: $isRegistering) {
                        Text("Sign In").tag(false)
                        Text("Create Account").tag(true)
                    }
                    .pickerStyle(.segmented)

                    VStack(spacing: AppTheme.spacingM) {
                        TextField("Email", text: $email)
                            .textContentType(.username)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding()
                            .cardStyle()
                        SecureField("Password (8+ characters)", text: $password)
                            .textContentType(isRegistering ? .newPassword : .password)
                            .padding()
                            .cardStyle()
                    }

                    VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                        Text("API URL")
                            .font(AppTheme.captionFont().weight(.semibold))
                            .foregroundStyle(AppTheme.textSecondary)
                        TextField("Base URL", text: $apiBaseURL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                            .padding()
                            .cardStyle()
                        Text("Use the default unless your household API runs somewhere else.")
                            .font(AppTheme.captionFont())
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    if let errorText {
                        Text(errorText)
                            .font(AppTheme.captionFont())
                            .foregroundStyle(AppTheme.danger)
                            .padding()
                            .cardStyle()
                    }

                    PrimaryButton(
                        title: isRegistering ? "Create Account" : "Sign In",
                        systemImage: isRegistering ? "person.badge.plus" : "arrow.right"
                    ) {
                        Task { await submit() }
                    }
                    .disabled(isWorking || email.isEmpty || password.count < 8)
                    .overlay {
                        if isWorking { ProgressView().tint(.white) }
                    }
                }
                .padding(AppTheme.spacingM)
            }
            .fantasyScreen()
            .navigationTitle(isRegistering ? "Create Account" : "Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .fantasyNavigation()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(AppTheme.primary)
                }
            }
        }
    }

    private func submit() async {
        isWorking = true
        errorText = nil
        defer { isWorking = false }
        do {
            if isRegistering {
                try await authSession.register(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
            } else {
                try await authSession.login(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
            }
            await householdSync.reconcileAfterSignIn()
            householdSync.apiReachable = true
            await AssistantSessionStore.shared.pullFromAccount()
            dismiss()
        } catch {
            errorText = error.localizedDescription
        }
    }
}
