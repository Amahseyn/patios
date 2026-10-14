//
//  PetManagementView.swift
//  CatIos
//
//  Unified view: manage all pets, edit any pet, add new pets, delete pets.

import SwiftUI

struct PetManagementView: View {
    @EnvironmentObject private var petManager: PetManager
    @EnvironmentObject private var householdSync: HouseholdSync
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
        List {
            Section {
                VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                    Text("\(petManager.pets.count) pet\(petManager.pets.count == 1 ? "" : "s")")
                        .font(AppTheme.titleFont(22))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("Tap a profile to edit. Swipe to remove.")
                        .font(AppTheme.captionFont())
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.vertical, 4)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            }

            if filteredPets.isEmpty {
                Section {
                    EmptyStateView(
                        systemImage: searchText.isEmpty ? "pawprint.circle" : "magnifyingglass",
                        title: searchText.isEmpty ? "No pets yet" : "No matches",
                        message: searchText.isEmpty
                            ? "Add a pet to personalize tasks, health records, and assistant answers."
                            : "Try another name or breed.",
                        actionTitle: searchText.isEmpty && householdSync.canMutate ? "Add pet" : nil,
                        action: searchText.isEmpty && householdSync.canMutate ? { showAddPetSheet = true } : nil
                    )
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
            } else {
                Section {
                    ForEach(filteredPets) { pet in
                        Button {
                            guard householdSync.canMutate else { return }
                            editingPetId = pet.id
                            loadDraft(from: pet)
                            showEditPetSheet = true
                        } label: {
                            HStack(spacing: AppTheme.spacingM) {
                                Text(pet.avatarEmoji)
                                    .font(.title)
                                    .frame(width: 48, height: 48)
                                    .background {
                                        Circle()
                                            .fill(Color(hex: pet.petColorHex).opacity(0.22))
                                            .overlay {
                                                Circle()
                                                    .strokeBorder(
                                                        pet.id == petManager.selectedPetId ? AppTheme.primary : Color.clear,
                                                        lineWidth: 2
                                                    )
                                            }
                                    }
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text(pet.name)
                                            .font(AppTheme.headlineFont())
                                            .foregroundStyle(AppTheme.textPrimary)
                                        if pet.id == petManager.selectedPetId {
                                            Text("Active")
                                                .font(.caption2.weight(.bold))
                                                .foregroundStyle(AppTheme.primary)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Capsule().fill(AppTheme.primary.opacity(0.12)))
                                        }
                                    }
                                    Text("\(pet.breed.isEmpty ? pet.petType.rawValue : pet.breed) · \(pet.age.displayText)")
                                        .font(AppTheme.captionFont())
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.forward")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppTheme.textSecondary.opacity(0.6))
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                                .fill(AppTheme.cardBackground)
                                .padding(.vertical, 2)
                        )
                        .swipeActions(edge: .trailing, allowsFullSwipe: householdSync.canMutate) {
                            if householdSync.canMutate {
                                Button("Delete", role: .destructive) {
                                    petToDelete = pet.id
                                    showDeleteAlert = true
                                }
                            }
                        }
                    }
                }
            }
        }
        .fantasyScreen()
        .navigationTitle("Pets")
        .fantasyNavigation()
        .searchable(text: $searchText, prompt: "Search by name or breed")
        .toolbar {
            if householdSync.canMutate {
            ToolbarItem(placement: .primaryAction) {
                Button("Add", systemImage: "plus") {
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
                }
            }
            }
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Picker("Sort", selection: $sortOption) {
                        ForEach(SortOption.allCases, id: \.self) { opt in
                            Text(LocalizedStringKey(opt.rawValue)).tag(opt)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
            }
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
            Text("This cannot be undone.")
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

    private var addPetModal: some View {
        NavigationStack {
            Form {
                Section("Pet Type") {
                    PetKindPicker(selection: $draftPetType)
                    .onChange(of: draftPetType) { _ in
                        hasChosenPetType = true
                        if draftPetType != .other {
                            draftCustomPetTypeName = ""
                        }
                    }

                    if draftPetType == .other {
                        TextField("Name this kind (e.g. ferret, goat, guinea pig)", text: $draftCustomPetTypeName)
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
                            Text(LocalizedStringKey(gender.rawValue)).tag(gender)
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
                    PetKindPicker(selection: $draftPetType)
                    .onChange(of: draftPetType) { _ in
                        if draftPetType != .other {
                            draftCustomPetTypeName = ""
                        }
                    }

                    if draftPetType == .other {
                        TextField("Name this kind (e.g. ferret, goat, guinea pig)", text: $draftCustomPetTypeName)
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
                            Text(LocalizedStringKey(gender.rawValue)).tag(gender)
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
