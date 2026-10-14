import SwiftUI

struct HouseholdSharingView: View {
    @EnvironmentObject private var authSession: AuthSession
    @EnvironmentObject private var householdSync: HouseholdSync

    @State private var members: [APIHouseholdMember] = []
    @State private var invites: [APIHouseholdMember] = []
    @State private var email = ""
    @State private var role = "family"
    @State private var message: String?
    @State private var working = false

    private var canManage: Bool {
        authSession.currentUser?.role != "viewer" && householdSync.householdRole == "owner"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacingL) {
                RealmProfileHero(
                    title: "Shared household",
                    subtitle: canManage
                        ? "Invite family or caregivers to share tasks, health records, and chats."
                        : "See who can view or update this household.",
                    systemImage: "person.2.fill"
                )

                if !invites.isEmpty {
                    RealmSectionCard(title: "Invites for you", icon: "envelope.open.fill", tint: AppTheme.starlight) {
                        ForEach(invites) { invite in
                            VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                                Text(HouseholdRoleName.title(invite.role))
                                    .font(AppTheme.headlineFont())
                                Text(invite.email)
                                    .font(AppTheme.captionFont())
                                    .foregroundStyle(AppTheme.textSecondary)
                                PrimaryButton(title: working ? "Accepting…" : "Accept invite", systemImage: "checkmark") {
                                    Task { await accept(invite) }
                                }
                                .disabled(working)
                            }
                            .padding(.horizontal, AppTheme.spacingS)
                            .padding(.vertical, 8)
                        }
                    }
                }

                RealmSectionCard(
                    title: "Members",
                    subtitle: members.isEmpty ? "Just you for now" : "\(members.count) people",
                    icon: "person.3.fill",
                    tint: AppTheme.sky
                ) {
                    if members.isEmpty {
                        EmptyStateView(
                            systemImage: "person.2",
                            title: "No shared members yet",
                            message: "Send an invite by email when you're ready to share care duties."
                        )
                        .padding(.horizontal, AppTheme.spacingS)
                        .padding(.vertical, AppTheme.spacingS)
                    } else {
                        ForEach(members) { member in
                            memberCard(member)
                            if member.id != members.last?.id {
                                RealmRowDivider()
                            }
                        }
                    }
                }

                if canManage {
                    RealmSectionCard(title: "Send invite", subtitle: "They'll get access by email", icon: "paperplane.fill", tint: AppTheme.tide) {
                        VStack(alignment: .leading, spacing: AppTheme.spacingM) {
                            TextField("Email address", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding(AppTheme.spacingM)
                                .background {
                                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall, style: .continuous)
                                        .fill(AppTheme.cardBackground.opacity(0.6))
                                }

                            Picker("Role", selection: $role) {
                                ForEach(HouseholdRoleName.inviteRoles, id: \.self) { item in
                                    Text(HouseholdRoleName.title(item)).tag(item)
                                }
                            }
                            .pickerStyle(.segmented)

                            PrimaryButton(title: working ? "Sending…" : "Send invite", systemImage: "paperplane.fill") {
                                Task { await invite() }
                            }
                            .disabled(working || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        .padding(.horizontal, AppTheme.spacingS)
                        .padding(.vertical, AppTheme.spacingS)
                    }
                }

                if let message {
                    Text(message)
                        .font(AppTheme.captionFont())
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(AppTheme.spacingM)
                        .cardStyle(cornerRadius: AppTheme.cornerRadiusMedium)
                }
            }
            .padding(AppTheme.spacingM)
        }
        .fantasyScreen()
        .navigationTitle("Household")
        .fantasyNavigation()
        .overlay {
            if working && members.isEmpty && invites.isEmpty {
                ProgressView()
            }
        }
        .task { await reload() }
        .refreshable { await reload() }
    }

    @ViewBuilder
    private func memberCard(_ member: APIHouseholdMember) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingS) {
            HStack {
                EnchantedIconBadge(systemImage: "person.fill", tint: AppTheme.sky, size: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(member.email)
                        .font(AppTheme.bodyFont().weight(.semibold))
                    Text("\(HouseholdRoleName.title(member.role)) · \(member.status.capitalized)")
                        .font(AppTheme.captionFont())
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
            }

            if canManage && member.role != "owner" && member.status != "removed" {
                Picker("Role", selection: Binding(
                    get: { member.role },
                    set: { newRole in Task { await changeRole(member, to: newRole) } }
                )) {
                    ForEach(HouseholdRoleName.inviteRoles, id: \.self) { item in
                        Text(HouseholdRoleName.title(item)).tag(item)
                    }
                }
                .pickerStyle(.menu)

                Button("Remove from household", role: .destructive) {
                    Task { await remove(member) }
                }
                .font(AppTheme.captionFont().weight(.semibold))
            }
        }
        .padding(.horizontal, AppTheme.spacingS)
        .padding(.vertical, 10)
    }

    private func reload() async {
        guard authSession.isSignedIn else { return }
        do {
            members = try await APIClient.shared.send("GET", path: "household/members")
            invites = try await APIClient.shared.send("GET", path: "household/invites")
            message = nil
        } catch {
            message = error.localizedDescription
        }
    }

    private func invite() async {
        let address = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !address.isEmpty else { return }
        working = true
        defer { working = false }
        struct Body: Encodable { let email: String; let role: String }
        do {
            let _: APIHouseholdMember = try await APIClient.shared.send(
                "POST",
                path: "household/invites",
                body: Body(email: address, role: role)
            )
            email = ""
            await reload()
        } catch {
            message = error.localizedDescription
        }
    }

    private func accept(_ invite: APIHouseholdMember) async {
        working = true
        defer { working = false }
        do {
            let _: APIHouseholdMember = try await APIClient.shared.send("POST", path: "household/invites/\(invite.id.uuidString)/accept")
            await householdSync.pullNow()
            await reload()
        } catch {
            message = error.localizedDescription
        }
    }

    private func changeRole(_ member: APIHouseholdMember, to role: String) async {
        struct Body: Encodable { let role: String }
        do {
            let _: APIHouseholdMember = try await APIClient.shared.send(
                "PATCH",
                path: "household/members/\(member.id.uuidString)",
                body: Body(role: role)
            )
            await reload()
        } catch {
            message = error.localizedDescription
        }
    }

    private func remove(_ member: APIHouseholdMember) async {
        do {
            _ = try await APIClient.shared.sendRaw("DELETE", path: "household/members/\(member.id.uuidString)")
            await reload()
        } catch {
            message = error.localizedDescription
        }
    }
}
