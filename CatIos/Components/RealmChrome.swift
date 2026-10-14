import SwiftUI

struct RealmStatusChip: View {
    let title: String
    let systemImage: String
    var tint: Color = AppTheme.primary
    var isActive: Bool = true

    var body: some View {
        Label(LocalizedStringKey(title), systemImage: systemImage)
            .font(AppTheme.captionFont().weight(.semibold))
            .foregroundStyle(isActive ? tint : AppTheme.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background {
                Capsule(style: .continuous)
                    .fill(tint.opacity(isActive ? 0.12 : 0.06))
            }
    }
}

struct RealmStatTile: View {
    let title: String
    let value: String
    let systemImage: String
    var tint: Color = AppTheme.primary

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(tint)
                Text(LocalizedStringKey(title))
                    .font(AppTheme.captionFont())
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.spacingM)
        .cardStyle(cornerRadius: AppTheme.cornerRadiusMedium)
    }
}

struct RealmSectionCard<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    let icon: String
    var tint: Color = AppTheme.primary
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: AppTheme.spacingS) {
                EnchantedIconBadge(systemImage: icon, tint: tint, size: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey(title))
                        .font(AppTheme.headlineFont())
                        .foregroundStyle(AppTheme.textPrimary)
                    if let subtitle {
                        Text(LocalizedStringKey(subtitle))
                            .font(AppTheme.captionFont())
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, AppTheme.spacingM)
            .padding(.top, AppTheme.spacingM)
            .padding(.bottom, AppTheme.spacingS)

            VStack(spacing: 0) {
                content()
            }
            .padding(.horizontal, AppTheme.spacingS)
            .padding(.bottom, AppTheme.spacingS)
        }
        .cardStyle(cornerRadius: AppTheme.cornerRadiusLarge)
    }
}

struct RealmRowDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 52)
    }
}

struct RealmNavigationRow<Destination: View>: View {
    let title: String
    var subtitle: String? = nil
    let icon: String
    var tint: Color = AppTheme.primary
    var trailing: String? = nil
    @ViewBuilder var destination: () -> Destination

    var body: some View {
        NavigationLink {
            destination()
        } label: {
            RealmRowLabel(title: title, subtitle: subtitle, icon: icon, tint: tint, trailing: trailing, showsChevron: true)
        }
        .buttonStyle(.plain)
    }
}

struct RealmActionRow: View {
    let title: String
    var subtitle: String? = nil
    let icon: String
    var tint: Color = AppTheme.primary
    var destructive: Bool = false
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            RealmRowLabel(
                title: title,
                subtitle: subtitle,
                icon: icon,
                tint: destructive ? AppTheme.danger : tint,
                showsChevron: false
            )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.55 : 1)
    }
}

private struct RealmRowLabel: View {
    let title: String
    var subtitle: String?
    let icon: String
    var tint: Color
    var trailing: String?
    var showsChevron: Bool

    var body: some View {
        HStack(spacing: AppTheme.spacingS) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(tint.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(title))
                    .font(AppTheme.bodyFont().weight(.medium))
                    .foregroundStyle(AppTheme.textPrimary)
                if let subtitle {
                    Text(LocalizedStringKey(subtitle))
                        .font(AppTheme.captionFont())
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            Spacer(minLength: 0)
            if let trailing {
                Text(LocalizedStringKey(trailing))
                    .font(AppTheme.captionFont().weight(.semibold))
                    .foregroundStyle(tint)
            }
            if showsChevron {
                Image(systemName: "chevron.forward")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary.opacity(0.7))
            }
        }
        .padding(.horizontal, AppTheme.spacingS)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

struct RealmProfileHero: View {
    let title: String
    let subtitle: String
    var systemImage: String = "person.crop.circle.fill"
    var chips: [RealmStatusChip] = []

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingM) {
            HStack(alignment: .top, spacing: AppTheme.spacingM) {
                EnchantedIconBadge(systemImage: systemImage, tint: AppTheme.primary, size: 56)

                VStack(alignment: .leading, spacing: 6) {
                    Text(LocalizedStringKey(title))
                        .font(AppTheme.titleFont(24))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(LocalizedStringKey(subtitle))
                        .font(AppTheme.bodyFont())
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            if !chips.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.spacingS) {
                        ForEach(Array(chips.enumerated()), id: \.offset) { _, chip in
                            chip
                        }
                    }
                }
            }
        }
        .padding(AppTheme.spacingM)
        .cardStyle(cornerRadius: AppTheme.cornerRadiusLarge)
    }
}

struct RealmCompanionStrip: View {
    let pets: [PetProfile]
    let selectedPetId: UUID

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingS) {
            HStack {
                Text("Your pets")
                    .font(AppTheme.headlineFont())
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text("Manage")
                    .font(AppTheme.captionFont().weight(.semibold))
                    .foregroundStyle(AppTheme.primary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.spacingS) {
                    ForEach(pets) { pet in
                        VStack(spacing: 6) {
                            Text(pet.avatarEmoji)
                                .font(.title)
                                .frame(width: 56, height: 56)
                                .background {
                                    Circle()
                                        .fill(Color(hex: pet.petColorHex).opacity(0.18))
                                        .overlay {
                                            Circle()
                                                .strokeBorder(
                                                    pet.id == selectedPetId ? AppTheme.primary : Color.clear,
                                                    lineWidth: 2
                                                )
                                        }
                                }
                            Text(pet.name)
                                .font(AppTheme.captionFont().weight(.semibold))
                                .foregroundStyle(AppTheme.textPrimary)
                                .lineLimit(1)
                        }
                        .frame(width: 72)
                    }
                }
            }
        }
        .padding(AppTheme.spacingM)
        .cardStyle(cornerRadius: AppTheme.cornerRadiusLarge)
    }
}

struct RealmLegalHero: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        HStack(spacing: AppTheme.spacingM) {
            EnchantedIconBadge(systemImage: icon, tint: AppTheme.dusk, size: 48)
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(title))
                    .font(AppTheme.titleFont(22))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(LocalizedStringKey(subtitle))
                    .font(AppTheme.captionFont())
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(AppTheme.spacingM)
        .cardStyle(cornerRadius: AppTheme.cornerRadiusLarge)
    }
}
