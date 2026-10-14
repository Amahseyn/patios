import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var petManager: PetManager
    @EnvironmentObject private var authSession: AuthSession
    @EnvironmentObject private var householdSync: HouseholdSync
    @EnvironmentObject private var membership: MembershipStore
    @State private var showPaywall = false
    @State private var showAuth = false
    @State private var confirmSignOut = false
    @AppStorage("appearance") private var appearance = AppAppearance.system.rawValue

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.spacingL) {
                    RealmProfileHero(
                        title: displayName,
                        subtitle: statusLine,
                        systemImage: authSession.isSignedIn ? "person.crop.circle.fill" : "moon.stars.fill",
                        chips: statusChips
                    )

                    HStack(spacing: AppTheme.spacingS) {
                        RealmStatTile(
                            title: "Pets",
                            value: "\(petManager.pets.count)",
                            systemImage: "pawprint.fill",
                            tint: AppTheme.meadow
                        )
                        RealmStatTile(
                            title: "Plan",
                            value: membership.plan == .basic ? "Free" : "Plus",
                            systemImage: "star.fill",
                            tint: AppTheme.starlight
                        )
                        RealmStatTile(
                            title: "Sync",
                            value: syncShortLabel,
                            systemImage: householdSync.isSyncing ? "arrow.triangle.2.circlepath" : "icloud.fill",
                            tint: syncTint
                        )
                    }

                    if !petManager.pets.isEmpty {
                        NavigationLink {
                            PetManagementView()
                        } label: {
                            RealmCompanionStrip(
                                pets: petManager.pets,
                                selectedPetId: petManager.selectedPetId
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    RealmSectionCard(
                        title: "Account",
                        subtitle: "Sync and household sharing",
                        icon: "person.crop.circle.fill",
                        tint: AppTheme.tide
                    ) {
                        if authSession.isSignedIn {
                            RealmActionRow(
                                title: householdSync.isSyncing ? "Syncing…" : "Sync now",
                                subtitle: householdSync.statusText,
                                icon: "arrow.triangle.2.circlepath",
                                tint: AppTheme.tide,
                                disabled: householdSync.isSyncing
                            ) {
                                Task { await householdSync.pullNow() }
                            }
                            RealmRowDivider()
                            RealmNavigationRow(
                                title: "Household sharing",
                                subtitle: "Invite family and caregivers",
                                icon: "person.2.fill",
                                tint: AppTheme.sky
                            ) {
                                HouseholdSharingView()
                            }
                            RealmRowDivider()
                            RealmActionRow(
                                title: "Sign out",
                                subtitle: "Keep data on this device",
                                icon: "rectangle.portrait.and.arrow.right",
                                destructive: true
                            ) {
                                confirmSignOut = true
                            }
                        } else {
                            RealmActionRow(
                                title: "Sign in to sync",
                                subtitle: "Back up pets, tasks, and health records",
                                icon: "person.crop.circle.badge.plus",
                                tint: AppTheme.primary
                            ) {
                                showAuth = true
                            }
                        }

                        if let reachable = householdSync.apiReachable {
                            HStack(spacing: 8) {
                                Image(systemName: reachable ? "antenna.radiowaves.left.and.right" : "wifi.slash")
                                    .foregroundStyle(reachable ? AppTheme.success : AppTheme.warning)
                                Text(reachable ? "Server is reachable" : "Offline — using data on this iPhone")
                                    .font(AppTheme.captionFont())
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            .padding(.horizontal, AppTheme.spacingS)
                            .padding(.top, 8)
                            .padding(.bottom, 4)
                        }
                    }

                    RealmSectionCard(
                        title: "Pets",
                        subtitle: "Profiles, breeds, and avatars",
                        icon: "pawprint.fill",
                        tint: AppTheme.meadow
                    ) {
                        RealmNavigationRow(
                            title: "Manage pets",
                            subtitle: petManager.pets.isEmpty ? "Add your first pet" : "\(petManager.pets.count) in this household",
                            icon: "pawprint.circle.fill",
                            tint: AppTheme.meadow,
                            trailing: "\(petManager.pets.count)"
                        ) {
                            PetManagementView()
                        }
                    }

                    RealmSectionCard(
                        title: "Preferences",
                        subtitle: "Appearance and alerts",
                        icon: "slider.horizontal.3",
                        tint: AppTheme.lilac
                    ) {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: AppTheme.spacingS) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(AppTheme.lilac.opacity(0.14))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "circle.lefthalf.filled")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(AppTheme.lilac)
                                }
                                Text("Appearance")
                                    .font(AppTheme.bodyFont().weight(.medium))
                                    .foregroundStyle(AppTheme.textPrimary)
                                Spacer()
                                Picker("Appearance", selection: $appearance) {
                                    ForEach(AppAppearance.allCases) { mode in
                                        Text(mode.title).tag(mode.rawValue)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(AppTheme.primary)
                            }
                            .padding(.horizontal, AppTheme.spacingS)
                            .padding(.vertical, 10)
                        }
                        RealmRowDivider()
                        RealmNavigationRow(
                            title: "Notifications",
                            subtitle: "Tasks, health, and assistant suggestions",
                            icon: "bell.badge.fill",
                            tint: AppTheme.honey
                        ) {
                            SettingsView()
                        }
                    }

                    RealmSectionCard(
                        title: "Membership",
                        subtitle: membership.plan.detail,
                        icon: "star.circle.fill",
                        tint: AppTheme.starlight
                    ) {
                        HStack {
                            Text("Current plan")
                                .font(AppTheme.bodyFont())
                                .foregroundStyle(AppTheme.textSecondary)
                            Spacer()
                            Text(membership.plan.title)
                                .font(AppTheme.bodyFont().weight(.semibold))
                                .foregroundStyle(AppTheme.primary)
                        }
                        .padding(.horizontal, AppTheme.spacingS)
                        .padding(.vertical, 8)

                        RealmRowDivider()
                        RealmActionRow(
                            title: "View plans",
                            subtitle: membership.plan.includesAds ? "Remove banners with Pet Care+" : "Ads are off on this plan",
                            icon: "creditcard",
                            tint: AppTheme.starlight
                        ) {
                            showPaywall = true
                        }
                    }

                    RealmSectionCard(
                        title: "Legal",
                        subtitle: "Privacy and terms",
                        icon: "doc.text.fill",
                        tint: AppTheme.dusk
                    ) {
                        RealmNavigationRow(
                            title: "Privacy policy",
                            icon: "hand.raised.fill",
                            tint: AppTheme.dusk
                        ) {
                            PrivacyPolicyView()
                        }
                        RealmRowDivider()
                        RealmNavigationRow(
                            title: "Terms of use",
                            icon: "doc.text.fill",
                            tint: AppTheme.dusk
                        ) {
                            TermsOfUseView()
                        }
                    }
                }
                .padding(AppTheme.spacingM)
            }
            .fantasyScreen()
            .navigationTitle("You")
            .fantasyNavigation()
            .refreshable {
                if authSession.isSignedIn {
                    await householdSync.pullNow()
                }
            }
            .confirmationDialog("Sign out?", isPresented: $confirmSignOut, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) {
                    Task {
                        await authSession.logout()
                        householdSync.noteSignedOut()
                        householdSync.statusText = "Saved on this device"
                        householdSync.lastError = nil
                    }
                }
                Button("Stay signed in", role: .cancel) {}
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showAuth) {
                AuthView()
                    .environmentObject(authSession)
                    .environmentObject(householdSync)
            }
        }
    }

    private var displayName: String {
        if let email = authSession.currentUser?.email {
            let local = email.split(separator: "@").first.map(String.init) ?? email
            return local.capitalized
        }
        return "This iPhone"
    }

    private var statusLine: String {
        if householdSync.isSyncing { return "Syncing with your account…" }
        if let error = householdSync.lastError, authSession.isSignedIn { return error }
        if authSession.isSignedIn {
            return authSession.currentUser?.email ?? "Signed in"
        }
        return "Everything stays on this iPhone until you sign in"
    }

    private var statusChips: [RealmStatusChip] {
        var chips: [RealmStatusChip] = []
        if authSession.isSignedIn {
            chips.append(RealmStatusChip(title: "Signed in", systemImage: "checkmark.seal.fill", tint: AppTheme.success))
        } else {
            chips.append(RealmStatusChip(title: "Local only", systemImage: "iphone", tint: AppTheme.honey, isActive: true))
        }
        if membership.plan.includesAds {
            chips.append(RealmStatusChip(title: "Free", systemImage: "tag.fill", tint: AppTheme.lilac))
        } else {
            chips.append(RealmStatusChip(title: "Pet Care+", systemImage: "star.fill", tint: AppTheme.starlight))
        }
        if let reachable = householdSync.apiReachable {
            chips.append(RealmStatusChip(
                title: reachable ? "Online" : "Offline",
                systemImage: reachable ? "antenna.radiowaves.left.and.right" : "wifi.slash",
                tint: reachable ? AppTheme.tide : AppTheme.warning,
                isActive: reachable
            ))
        }
        return chips
    }

    private var syncShortLabel: String {
        if householdSync.isSyncing { return "…" }
        if authSession.isSignedIn { return "On" }
        return "Off"
    }

    private var syncTint: Color {
        if householdSync.isSyncing { return AppTheme.lilac }
        if authSession.isSignedIn { return AppTheme.tide }
        return AppTheme.textSecondary
    }
}
