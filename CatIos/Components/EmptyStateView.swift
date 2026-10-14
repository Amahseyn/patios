import SwiftUI

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: AppTheme.spacingM) {
            EnchantedIconBadge(systemImage: systemImage, tint: AppTheme.primary, size: 56)
            VStack(spacing: AppTheme.spacingS) {
                Text(title)
                    .font(AppTheme.titleFont(20))
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(AppTheme.bodyFont())
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            if let actionTitle, let action {
                PrimaryButton(title: actionTitle, systemImage: "plus", action: action)
                    .padding(.top, 4)
            }
        }
        .padding(AppTheme.spacingL)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

struct LoadingStateView: View {
    var title: String = "Loading…"
    var message: String? = nil

    var body: some View {
        VStack(spacing: AppTheme.spacingM) {
            ProgressView()
                .controlSize(.large)
                .tint(AppTheme.primary)
            VStack(spacing: AppTheme.spacingS) {
                Text(title)
                    .font(AppTheme.headlineFont())
                    .foregroundStyle(AppTheme.textPrimary)
                if let message {
                    Text(message)
                        .font(AppTheme.bodyFont())
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(AppTheme.spacingL)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

struct InlineErrorCard: View {
    let title: String
    let message: String
    var retryTitle: String = "Try Again"
    var retry: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingS) {
            HStack(alignment: .top, spacing: 10) {
                EnchantedIconBadge(systemImage: "exclamationmark.triangle.fill", tint: AppTheme.warning, size: 36)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppTheme.headlineFont())
                    Text(message)
                        .font(AppTheme.captionFont())
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if let retry {
                SecondaryButton(title: retryTitle, systemImage: "arrow.clockwise", action: retry)
            }
        }
        .padding(AppTheme.spacingM)
        .cardStyle()
        .accessibilityElement(children: .combine)
    }
}

struct SyncStatusBanner: View {
    @EnvironmentObject private var householdSync: HouseholdSync
    @EnvironmentObject private var authSession: AuthSession

    var body: some View {
        if let error = householdSync.lastError, authSession.isSignedIn {
            InlineErrorCard(
                title: "Couldn’t sync",
                message: "\(error)\nPull to refresh, or tap Try Again. Your data is still saved on this iPhone.",
                retryTitle: "Try Again"
            ) {
                Task { await householdSync.pullNow() }
            }
        }
    }
}

struct PetKindPicker: View {
    @Binding var selection: PetType

    var body: some View {
        Picker("Kind", selection: $selection) {
            ForEach(PetType.allCases) { type in
                Label(type.rawValue, systemImage: type.systemIcon).tag(type)
            }
        }
    }
}

struct PetScopePicker: View {
    @Binding var selection: UUID
    let pets: [PetProfile]

    var body: some View {
        Picker("Pet", selection: $selection) {
            Text("All pets").tag(PetManager.allPetsId)
            ForEach(pets) { pet in
                Text("\(pet.avatarEmoji) \(pet.name)").tag(pet.id)
            }
        }
    }
}
