//
//  PetManagementView.swift
//  CatIos
//
//  Unified view: manage all pets, edit any pet, add new pets, delete pets.

import SwiftUI

struct PetManagementView: View {
    @EnvironmentObject private var petManager: PetManager
    @Environment(\.dismiss) private var dismiss

    @State private var showAddPetSheet = false
    @State private var showEditPetSheet = false
    @State private var editingPetId: UUID? = nil
    @State private var hasChosenPetType: Bool = false
    @State private var searchText: String = ""
    @State private var showDeleteAlert: Bool = false
    @State private var petToDelete: UUID? = nil

    enum SortOption: String, CaseIterable { case name = "Name", ageDesc = "Age (Newest)" }
    @State private var sortOption: SortOption = .name

    @State private var draftName: String = ""
    @State private var draftBreed: String = ""
    @State private var draftAge = AgeValue(years: 1, months: 0)
    @State private var draftPetType: PetType = .cat
    @State private var draftCustomPetTypeName: String = ""
    @State private var draftGender: PetGender = .female
    @State private var draftAvatarEmoji: String = "🐱"
    @State private var draftPetColorHex: String = "#9B59B6"

    enum Field: Hashable { case name, breed }
    @FocusState private var focusedField: Field?

    private var filteredPets: [PetProfile] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        var base = petManager.pets
        if !q.isEmpty {
            base = base.filter { pet in
                pet.name.localizedCaseInsensitiveContains(q) ||
                pet.breed.localizedCaseInsensitiveContains(q)
            }
        }
        switch sortOption {
        case .name:
            base.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .ageDesc:
            base.sort { lhs, rhs in
                let l = lhs.age.years * 12 + lhs.age.months
                let r = rhs.age.years * 12 + rhs.age.months
                return l > r
            }
        }
        return base
    }

    private var isAddValid: Bool { !draftName.isEmpty && hasChosenPetType }
    private var isEditValid: Bool { !draftName.isEmpty }

    private func loadDraft(from pet: PetProfile) {
        draftName = pet.name
        draftBreed = pet.breed
        draftAge = pet.age
        draftPetType = pet.petType
        draftCustomPetTypeName = pet.customPetTypeName ?? ""
        draftGender = pet.gender
        draftAvatarEmoji = pet.avatarEmoji
        draftPetColorHex = pet.petColorHex
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.spacingL) {
                    petsListSection

                    addPetButton
                }
                .padding(AppTheme.spacingM)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("My Pets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Picker("Sort by", selection: $sortOption) {
                            ForEach(SortOption.allCases, id: \.self) { opt in
                                Text(opt.rawValue).tag(opt)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search pets")
        }
        .sheet(isPresented: $showAddPetSheet) { addPetModal }
        .sheet(isPresented: $showEditPetSheet) { editPetModal }
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

    private var petsListSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingM) {
            Text("All Pets (\(filteredPets.count))")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            if filteredPets.isEmpty {
                VStack(spacing: AppTheme.spacingM) {
                    Text("No pets found")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .cardStyle()
            } else {
                VStack(spacing: AppTheme.spacingM) {
                    ForEach(filteredPets) { pet in
                        petRow(pet)
                    }
                }
            }
        }
    }

    private func petRow(_ pet: PetProfile) -> some View {
        HStack(spacing: AppTheme.spacingM) {
            ZStack {
                Circle()
                    .fill(Color(hex: pet.petColorHex).opacity(0.15))
                    .frame(width: 54, height: 54)
                Text(pet.avatarEmoji)
                    .font(.system(size: 32))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(pet.avatarEmoji) \(pet.name)")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("\(pet.breed) • \(pet.age.displayText)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            Button {
                editingPetId = pet.id
                loadDraft(from: pet)
                showEditPetSheet = true
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "pencil")
                        .font(.system(size: 20))
                    Text("Edit")
                        .font(.caption2.weight(.semibold))
                }
                .foregroundStyle(AppTheme.primary)
                .frame(width: 56, height: 44)
                .background(AppTheme.primary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            Button {
                petToDelete = pet.id
                showDeleteAlert = true
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "trash")
                        .font(.system(size: 20))
                    Text("Delete")
                        .font(.caption2.weight(.semibold))
                }
                .foregroundStyle(.red)
                .frame(width: 56, height: 44)
                .background(Color.red.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(AppTheme.spacingM)
        .cardStyle()
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                petToDelete = pet.id
                showDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)

            Button {
                editingPetId = pet.id
                loadDraft(from: pet)
                showEditPetSheet = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(AppTheme.primary)
        }
    }

    private var addPetButton: some View {
        Button {
            draftName = ""
            draftBreed = ""
            draftAge = AgeValue(years: 1, months: 0)
            draftPetType = .cat
            draftCustomPetTypeName = ""
            draftGender = .female
            draftAvatarEmoji = "🐱"
            draftPetColorHex = "#9B59B6"
            hasChosenPetType = false
            showAddPetSheet = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                Text("Add New Pet")
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

    private var addPetModal: some View {
        NavigationStack {
            Form {
                Section("Pet Type") {
                    Picker("Pet Type", selection: $draftPetType) {
                        ForEach([PetType.cat, .dog, .other]) { type in
                            Text(type.rawValue)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: draftPetType) { _ in
                        hasChosenPetType = true
                        if draftPetType != .other {
                            draftCustomPetTypeName = ""
                        }
                    }

                    if draftPetType == .other {
                        TextField("Enter pet type (e.g. Bird, Horse)", text: $draftCustomPetTypeName)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled(true)
                    }

                    if !hasChosenPetType {
                        Text("Please select a pet type")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                Section("Pet Details") {
                    TextField("Pet Name (e.g. Cleo)", text: $draftName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(true)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .breed }
                    TextField("Breed (e.g. Siamese)", text: $draftBreed)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(true)
                        .focused($focusedField, equals: .breed)
                        .submitLabel(.done)
                        .onSubmit { focusedField = nil }

                    HStack(spacing: 12) {
                        Picker("Years", selection: $draftAge.years) {
                            ForEach(0...20, id: \.self) { year in
                                Text(year == 0 ? "<1" : "\(year) yr").tag(year)
                            }
                        }
                        .pickerStyle(.menu)

                        Picker("Months", selection: $draftAge.months) {
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

                Section("Gender") {
                    Picker("Gender", selection: $draftGender) {
                        ForEach(PetGender.allCases) { gender in
                            Text(gender.rawValue).tag(gender)
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
            .navigationTitle("Add New Pet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddPetSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard !draftName.isEmpty else { return }
                            petManager.addPet(
                                name: draftName,
                                breed: draftBreed.isEmpty ? draftPetType.defaultBreed : draftBreed,
                                age: draftAge,
                                petType: draftPetType,
                                customPetTypeName: draftPetType == .other ? draftCustomPetTypeName : nil,
                                avatarEmoji: draftAvatarEmoji
                            )
                            if var newPet = petManager.pets.last {
                                newPet.gender = draftGender
                                newPet.petColorHex = draftPetColorHex
                                petManager.updatePet(newPet)
                            }
                        draftName = ""
                        draftBreed = ""
                        draftAge = AgeValue(years: 1, months: 0)
                        draftPetType = .cat
                        draftAvatarEmoji = "🐱"
                        showAddPetSheet = false
                    }
                    .font(.body.weight(.bold))
                    .disabled(!isAddValid)
                    .opacity(isAddValid ? 1 : 0.5)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
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
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(true)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .breed }
                    TextField("Breed (e.g. Siamese)", text: $draftBreed)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(true)
                        .focused($focusedField, equals: .breed)
                        .submitLabel(.next)
                        .onSubmit { focusedField = nil }

                    HStack(spacing: 12) {
                        Picker("Years", selection: $draftAge.years) {
                            ForEach(0...20, id: \.self) { year in
                                Text(year == 0 ? "<1" : "\(year) yr").tag(year)
                            }
                        }
                        .pickerStyle(.menu)

                        Picker("Months", selection: $draftAge.months) {
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

                Section("Gender") {
                    Picker("Gender", selection: $draftGender) {
                        ForEach(PetGender.allCases) { gender in
                            Text(gender.rawValue).tag(gender)
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
                        guard var pet = petManager.pets.first(where: { $0.id == editingPetId }) else { return }
                        pet.name = draftName
                        pet.breed = draftBreed.isEmpty ? draftPetType.defaultBreed : draftBreed
                        pet.age = draftAge
                        pet.petType = draftPetType
                        pet.customPetTypeName = draftPetType == .other ? draftCustomPetTypeName : nil
                        pet.avatarEmoji = draftAvatarEmoji
                        pet.gender = draftGender
                        pet.petColorHex = draftPetColorHex
                        petManager.updatePet(pet)
                        showEditPetSheet = false
                        editingPetId = nil
                    }
                    .font(.body.weight(.bold))
                    .disabled(!isEditValid)
                    .opacity(isEditValid ? 1 : 0.5)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }
        }
        .presentationDetents([.medium])
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

private struct InfoPill: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(AppTheme.primary)
            Text("\(label): \(value)")
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(AppTheme.primary.opacity(0.08))
        .clipShape(Capsule())
    }
}
