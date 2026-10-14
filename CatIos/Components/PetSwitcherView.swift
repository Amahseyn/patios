//
//  PetSwitcherView.swift
//  CatIos
//

import SwiftUI

struct PetSwitcherView: View {
    @EnvironmentObject var petManager: PetManager
    @State private var showAddPetModal = false
    @State private var showEditPetSheet = false
    @State private var editingPetId: UUID? = nil
    @State private var petToDelete: UUID? = nil
    @State private var showDeleteAlert: Bool = false

    @State private var draftName: String = ""
    @State private var draftBreed: String = ""
    @State private var draftAgeYears: Int = 1
    @State private var draftAgeMonths: Int = 0
    @State private var draftPetType: PetType = .cat
    @State private var draftCustomPetTypeName: String = ""
    @State private var draftAvatarEmoji: String = "🐱"
    @State private var draftPetColorHex: String = "#9B59B6"

    var body: some View {
        HStack(spacing: 12) {
            Menu {
                Section("Your Managed Pets") {
                    ForEach(petManager.pets) { pet in
                        Section {
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    petManager.selectPet(id: pet.id)
                                }
                            }) {
                                HStack {
                                    Text("\(pet.avatarEmoji) \(pet.name)")
                                    Spacer()
                                    if pet.id == petManager.selectedPetId {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }

                            Button("Edit") {
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
                            }

                            Button("Delete", role: .destructive) {
                                petToDelete = pet.id
                                showDeleteAlert = true
                            }
                        }
                    }
                }

                Button(action: {
                    showAddPetModal = true
                }) {
                    Label("Add New Pet Profile", systemImage: "plus.circle.fill")
                }
            } label: {
                HStack(spacing: 8) {
                    Text(petManager.isAllPetsSelected ? "🐾" : petManager.currentPet.avatarEmoji)
                        .font(.title2)
                        .padding(6)
                        .background(petManager.isAllPetsSelected ? AppTheme.primary.opacity(0.15) : Color(hex: petManager.currentPet.petColorHex).opacity(0.15))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(petManager.isAllPetsSelected ? "All Pets" : petManager.currentPet.name)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.textPrimary)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        Text(petManager.isAllPetsSelected ? "Combined Family (\(petManager.pets.count) Pets)" : "\(petManager.currentPet.breed) • \(petManager.currentPet.userRole.rawValue)")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppTheme.cardBackground)
                .cornerRadius(20)
                .shadow(color: AppTheme.shadowColor, radius: 4, x: 0, y: 2)
            }

            Spacer()

            Button(action: {
                showAddPetModal = true
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.primary)
                    .frame(width: 38, height: 38)
                    .background(AppTheme.primary.opacity(0.12))
                    .clipShape(Circle())
            }
        }
        .sheet(isPresented: $showAddPetModal) {
            AddPetModalView()
                .environmentObject(petManager)
        }
        .sheet(isPresented: $showEditPetSheet) {
            NavigationStack {
                Form {
                    Section("Pet Details") {
                        TextField("Pet Name", text: $draftName)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled(true)
                        TextField("Breed", text: $draftBreed)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled(true)

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
                    }

                    Section("Pet Type") {
                    PetKindPicker(selection: $draftPetType)

                    if draftPetType == .other {
                            TextField("Name this kind (e.g. ferret, goat, guinea pig)", text: $draftCustomPetTypeName)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled(true)
                        }
                    }

                    Section("Avatar") {
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
        }
        .alert("Delete Pet?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let id = petToDelete {
                    withAnimation { petManager.removePet(id: id) }
                }
                petToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                petToDelete = nil
            }
        } message: {
            Text("This action cannot be undone.")
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

struct AddPetModalView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var petManager: PetManager

    @State private var name: String = ""
    @State private var breed: String = ""
    @State private var ageYears: Int = 1
    @State private var ageMonths: Int = 0
    @State private var petType: PetType = .cat
    @State private var customPetTypeName: String = ""
    @State private var avatarEmoji: String = "🐱"

    var availableEmojis: [String] {
        petType.avatarEmojis
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Pet Type") {
                    PetKindPicker(selection: $petType)
                    .onChange(of: petType) { newType in
                        avatarEmoji = newType.defaultAvatar
                        if newType != .other {
                            customPetTypeName = ""
                        }
                    }

                    if petType == .other {
                        TextField("Name this kind (e.g. ferret, goat, guinea pig)", text: $customPetTypeName)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled(true)
                    }
                }

                Section("Pet Details") {
                    HStack {
                        Text("Avatar")
                        Spacer()
                        Picker("Avatar", selection: $avatarEmoji) {
                            ForEach(availableEmojis, id: \.self) { emoji in
                                Text(emoji).tag(emoji)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    TextField("Pet Name (e.g. Luna)", text: $name)
                    TextField("Breed (e.g. Persian Cat)", text: $breed)

                    HStack(spacing: 12) {
                        Picker("Years", selection: $ageYears) {
                            ForEach(0...20, id: \.self) { year in
                                Text(year == 0 ? "<1" : "\(year) yr").tag(year)
                            }
                        }
                        .pickerStyle(.menu)

                        Picker("Months", selection: $ageMonths) {
                            ForEach(0...11, id: \.self) { month in
                                Text(month == 0 ? "<1" : "\(month) mo").tag(month)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                Section {
                    Button(action: {
                        guard !name.isEmpty else { return }
                        let petAge = AgeValue(years: ageYears, months: ageMonths)
                        let finalCustomName = petType == .other ? customPetTypeName : nil
                        petManager.addPet(name: name, breed: breed, age: petAge, petType: petType, customPetTypeName: finalCustomName, avatarEmoji: avatarEmoji)
                        dismiss()
                    }) {
                        HStack {
                            Spacer()
                            Text("Create Pet Profile")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Spacer()
                        }
                    }
                    .listRowBackground(name.isEmpty ? Color.gray : AppTheme.primary)
                    .disabled(name.isEmpty)
                }
            }
            .navigationTitle("New Pet Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
