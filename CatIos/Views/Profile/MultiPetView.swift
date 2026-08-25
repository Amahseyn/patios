//
//  MultiPetView.swift
//  CatIos
//

import SwiftUI

struct MultiPetView: View {
    @EnvironmentObject private var petManager: PetManager
    @Environment(\.dismiss) private var dismiss

    @State private var showAddPetSheet = false
    @State private var showEditPetSheet = false
    @State private var editingPetId: UUID? = nil

    @State private var newPetName = ""
    @State private var newPetBreed = ""
    @State private var newPetAgeYears: Int = 1
    @State private var newPetAgeMonths: Int = 0
    @State private var newPetType: PetType = .cat
    @State private var newCustomPetTypeName: String = ""

    @State private var draftName: String = ""
    @State private var draftBreed: String = ""
    @State private var draftAgeYears: Int = 1
    @State private var draftAgeMonths: Int = 0
    @State private var draftPetType: PetType = .cat
    @State private var draftCustomPetTypeName: String = ""
    @State private var draftAvatarEmoji: String = "🐱"
    @State private var draftPetColorHex: String = "#9B59B6"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacingL) {
                Text("My Pets")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("Switch between pet profiles to view specialized AI insights and memory logs.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)

                VStack(spacing: AppTheme.spacingM) {
                    ForEach(petManager.pets) { pet in
                        PetProfileRowCard(
                            pet: pet,
                            isSelected: pet.id == petManager.selectedPetId,
                            onSelect: {
                                withAnimation {
                                    petManager.selectPet(id: pet.id)
                                }
                            },
                            onEdit: {
                                editingPetId = pet.id
                                draftName = pet.name
                                draftBreed = pet.breed
                                draftAgeYears = pet.age.years
                                draftAgeMonths = pet.age.months
                                draftPetType = pet.petType
                                draftCustomPetTypeName = pet.customPetTypeName ?? ""
                                draftAvatarEmoji = pet.avatarEmoji
                                draftPetColorHex = pet.petColorHex
                                showEditPetSheet = true
                            },
                            onDelete: {
                                withAnimation {
                                    petManager.removePet(id: pet.id)
                                }
                            }
                        )
                    }
                }

                Button {
                    showAddPetSheet = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        Text("Add New Pet Profile")
                            .font(.headline.weight(.semibold))
                    }
                    .foregroundStyle(AppTheme.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.primary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium))
                }
                .padding(.top, AppTheme.spacingM)
            }
            .padding(AppTheme.spacingM)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Pet Profiles")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddPetSheet) {
            addPetModal
        }
        .sheet(isPresented: $showEditPetSheet) {
            editPetModal
        }
    }

    private var addPetModal: some View {
        NavigationStack {
            Form {
                Section("Pet Type") {
                    Picker("Pet Type", selection: $newPetType) {
                        ForEach([PetType.cat, .dog, .other]) { type in
                            Text(type.rawValue)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: newPetType) { _ in
                        if newPetType != .other {
                            newCustomPetTypeName = ""
                        }
                    }

                    if newPetType == .other {
                        TextField("Enter pet type (e.g. Bird, Horse)", text: $newCustomPetTypeName)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled(true)
                    }

                    TextField("Pet Name (e.g. Cleo)", text: $newPetName)
                    TextField("Breed (e.g. Siamese)", text: $newPetBreed)

                    HStack(spacing: 12) {
                        Picker("Years", selection: $newPetAgeYears) {
                            ForEach(0...20, id: \.self) { year in
                                Text(year == 0 ? "<1" : "\(year) yr").tag(year)
                            }
                        }
                        .pickerStyle(.menu)

                        Picker("Months", selection: $newPetAgeMonths) {
                            ForEach(0...11, id: \.self) { month in
                                Text(month == 0 ? "<1" : "\(month) mo").tag(month)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
            .navigationTitle("Add New Pet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddPetSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard !newPetName.isEmpty else { return }
                        let petAge = AgeValue(years: newPetAgeYears, months: newPetAgeMonths)
                        petManager.addPet(
                            name: newPetName,
                            breed: newPetBreed.isEmpty ? newPetType.defaultBreed : newPetBreed,
                            age: petAge,
                            petType: newPetType,
                            customPetTypeName: newPetType == .other ? newCustomPetTypeName : nil,
                            avatarEmoji: newPetType.defaultAvatar
                        )
                        newPetName = ""
                        newPetBreed = ""
                        newPetAgeYears = 1
                        newPetAgeMonths = 0
                        newCustomPetTypeName = ""
                        showAddPetSheet = false
                    }
                    .font(.body.weight(.bold))
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var editPetModal: some View {
        NavigationStack {
            Form {
                Section("Pet Type") {
                    Picker("Pet Type", selection: $draftPetType) {
                        ForEach([PetType.cat, .dog, .other]) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: draftPetType) { _ in
                        if draftPetType != .other {
                            draftCustomPetTypeName = ""
                        }
                    }

                    if draftPetType == .other {
                        TextField("Enter pet type (e.g. Bird, Horse)", text: $draftCustomPetTypeName)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled(true)
                    }
                }

                Section("Pet Details") {
                    TextField("Pet Name (e.g. Cleo)", text: $draftName)
                    TextField("Breed (e.g. Siamese)", text: $draftBreed)

                    HStack(spacing: 12) {
                        Picker("Years", selection: $draftAgeYears) {
                            ForEach(0...20, id: \.self) { year in
                                Text(year == 0 ? "<1" : "\(year) yr").tag(year)
                            }
                        }
                        .pickerStyle(.menu)

                        Picker("Months", selection: $draftAgeMonths) {
                            ForEach(0...11, id: \.self) { month in
                                Text(month == 0 ? "<1" : "\(month) mo").tag(month)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    Picker("Avatar", selection: $draftAvatarEmoji) {
                        ForEach(draftPetType.avatarEmojis, id: \.self) { emoji in
                            Text(emoji).tag(emoji)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Pet Color") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(petColorOptions, id: \.hex) { option in
                                Button {
                                    draftPetColorHex = option.hex
                                } label: {
                                    Circle()
                                        .fill(Color(hex: option.hex))
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Circle()
                                                .stroke(draftPetColorHex == option.hex ? AppTheme.textPrimary : Color.clear, lineWidth: 2)
                                        )
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Edit Pet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showEditPetSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard !draftName.isEmpty, let petId = editingPetId else { return }
                        var pet = petManager.pets.first(where: { $0.id == petId }) ?? PetProfile.mockLuna
                        pet.name = draftName
                        pet.breed = draftBreed.isEmpty ? draftPetType.defaultBreed : draftBreed
                        pet.age = AgeValue(years: draftAgeYears, months: draftAgeMonths)
                        pet.petType = draftPetType
                        pet.customPetTypeName = draftPetType == .other ? draftCustomPetTypeName : nil
                        pet.avatarEmoji = draftAvatarEmoji
                        pet.petColorHex = draftPetColorHex
                        petManager.updatePet(pet)
                        showEditPetSheet = false
                        editingPetId = nil
                    }
                    .font(.body.weight(.bold))
                    .disabled(draftName.isEmpty)
                    .opacity(draftName.isEmpty ? 0.5 : 1)
                }
            }
        }
        .presentationDetents([.medium])
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

struct PetProfileRowCard: View {
    let pet: PetProfile
    let isSelected: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: AppTheme.spacingM) {
            ZStack {
                Circle()
                    .fill(Color(hex: pet.petColorHex).opacity(0.15))
                    .frame(width: 54, height: 54)
                Text(pet.avatarEmoji)
                    .font(.system(size: 32))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(pet.name)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)

                }

                
            }

            Spacer()

            HStack(spacing: 16) {
                Button(action: onEdit) {
                    VStack(spacing: 2) {
                        Image(systemName: "pencil")
                            .font(.system(size: 20))
                        Text("Edit")
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(AppTheme.primary)
                    .frame(width: 56, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                Button(action: onDelete) {
                    VStack(spacing: 2) {
                        Image(systemName: "trash")
                            .font(.system(size: 20))
                        Text("Delete")
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(.red)
                    .frame(width: 56, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
        .padding(AppTheme.spacingM)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                .stroke(isSelected ? AppTheme.primary : Color.clear, lineWidth: 2)
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(AppTheme.primary)

            Button {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
        }
        .onTapGesture {
            onSelect()
        }
    }
}

#Preview {
    NavigationStack {
        MultiPetView()
            .environmentObject(PetManager.shared)
    }
}
