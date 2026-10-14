//
//  PetProfileView.swift
//  CatEmotionAI
//
//  Pet profile screen: name, age, breed, gender, type, avatar + edit mode.
//  Reads the currently selected pet from PetManager so edits apply to a real pet.

import SwiftUI

struct PetProfileView: View {
    @EnvironmentObject private var petManager: PetManager
    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.spacingL) {
                    avatarSection

                    if viewModel.isEditing {
                        editForm
                    } else {
                        infoCard
                    }
                }
                .padding(AppTheme.spacingM)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Pet Profile")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if viewModel.isEditing {
                        Button("Save") {
                            petManager.updatePet(viewModel.draftProfile)
                            viewModel.save()
                        }
                        .fontWeight(.semibold)
                    } else {
                        Button("Edit") { viewModel.beginEditing() }
                    }
                }
                if viewModel.isEditing {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { viewModel.cancel() }
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadProfile(petManager.currentPet)
        }
    }

    private var avatarSection: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                Circle()
                    .fill(AppTheme.heroGradient)
                    .frame(width: 128, height: 128)
                Text(viewModel.draftProfile.avatarEmoji)
                    .font(.system(size: 56))
            }
            .shadow(color: AppTheme.primary.opacity(0.3), radius: 16, y: 8)

            if viewModel.isEditing {
                Button {
                } label: {
                    Image(systemName: "face.smiling.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(AppTheme.primary)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(AppTheme.background, lineWidth: 3))
                }
            }
        }
        .padding(.top, AppTheme.spacingM)
    }

    private var infoCard: some View {
        VStack(spacing: 0) {
            ProfileInfoRow(icon: "textformat", label: "Name", value: viewModel.profile.name)
            Divider().padding(.leading, 52)
            ProfileInfoRow(icon: "calendar", label: "Age", value: viewModel.profile.age.displayText)
            Divider().padding(.leading, 52)
            ProfileInfoRow(icon: "pawprint", label: "Breed", value: viewModel.profile.breed)
            Divider().padding(.leading, 52)
            ProfileInfoRow(icon: "person", label: "Gender", value: viewModel.profile.gender.rawValue)
            Divider().padding(.leading, 52)
            ProfileInfoRow(icon: viewModel.profile.petType.systemIcon, label: "Type", value: viewModel.profile.petTypeDisplayName)
            Divider().padding(.leading, 52)
            HStack(spacing: AppTheme.spacingM) {
                Image(systemName: "paintpalette.fill")
                    .foregroundStyle(AppTheme.primary)
                    .frame(width: 28)
                Text("Color")
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Circle()
                    .fill(Color(hex: viewModel.profile.petColorHex))
                    .frame(width: 20, height: 20)
                    .overlay(Circle().stroke(AppTheme.textSecondary.opacity(0.3), lineWidth: 1))
            }
            .padding(AppTheme.spacingM)
        }
        .cardStyle()
    }

    private var editForm: some View {
        VStack(spacing: AppTheme.spacingM) {
            LabeledField(label: "Name", text: $viewModel.draftProfile.name)

            VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                Text("Age")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)

                HStack(spacing: 12) {
                    Picker("Years", selection: $viewModel.draftProfile.age.years) {
                        ForEach(0...20, id: \.self) { year in
                            Text(year == 0 ? "<1" : "\(year) yr").tag(year)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("Months", selection: $viewModel.draftProfile.age.months) {
                        ForEach(0...11, id: \.self) { month in
                            Text(month == 0 ? "<1" : "\(month) mo").tag(month)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .padding(AppTheme.spacingM)
            .cardStyle(cornerRadius: AppTheme.cornerRadiusSmall)

            LabeledField(label: "Breed", text: $viewModel.draftProfile.breed)

            VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                Text("Gender")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                Picker("Gender", selection: $viewModel.draftProfile.gender) {
                    ForEach(PetGender.allCases) { gender in
                        Text(gender.rawValue).tag(gender)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(AppTheme.spacingM)
            .cardStyle(cornerRadius: AppTheme.cornerRadiusSmall)

            VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                Text("Pet Type")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                PetKindPicker(selection: $viewModel.draftProfile.petType)
                    .pickerStyle(.menu)

                if viewModel.draftProfile.petType == .other {
                    TextField("Name this kind (e.g. ferret, goat, guinea pig)", text: Binding(
                        get: { viewModel.draftProfile.customPetTypeName ?? "" },
                        set: { viewModel.draftProfile.customPetTypeName = $0 }
                    ))
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(true)
                }
            }
            .padding(AppTheme.spacingM)
            .cardStyle(cornerRadius: AppTheme.cornerRadiusSmall)

            VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                Text("Avatar Emoji")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                Picker("Avatar", selection: $viewModel.draftProfile.avatarEmoji) {
                    ForEach(viewModel.draftProfile.petType.avatarEmojis, id: \.self) { emoji in
                        Text(emoji).tag(emoji)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(AppTheme.spacingM)
            .cardStyle(cornerRadius: AppTheme.cornerRadiusSmall)

            VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                Text("Pet Color")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(petColorOptions, id: \.hex) { option in
                            Button {
                                viewModel.draftProfile.petColorHex = option.hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: option.hex))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(viewModel.draftProfile.petColorHex == option.hex ? AppTheme.textPrimary : Color.clear, lineWidth: 2)
                                    )
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .padding(AppTheme.spacingM)
            .cardStyle(cornerRadius: AppTheme.cornerRadiusSmall)
        }
    }
}

private let petColorOptions: [(name: String, hex: String)] = [
    ("Red", "#FF6B6B"),
    ("Orange", "#FF9F43"),
    ("Yellow", "#FECA57"),
    ("Green", "#1DD1A1"),
    ("Teal", "#00D2D3"),
    ("Blue", "#54A0FF"),
    ("Indigo", "#5F27CD"),
    ("Purple", "#9B59B6"),
    ("Pink", "#FF9FF3"),
    ("Brown", "#A0522D"),
    ("Gray", "#95A5A6"),
    ("Black", "#2D3436")
]

private struct ProfileInfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: AppTheme.spacingM) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.primary)
                .frame(width: 28)
            Text(label)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .foregroundStyle(AppTheme.textPrimary)
                .fontWeight(.medium)
        }
        .padding(AppTheme.spacingM)
    }
}

private struct LabeledField: View {
    let label: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingS) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
            TextField(label, text: $text)
                .padding(AppTheme.spacingM)
                .cardStyle(cornerRadius: AppTheme.cornerRadiusSmall)
        }
    }
}

#Preview {
    PetProfileView()
        .environmentObject(PetManager.shared)
}
