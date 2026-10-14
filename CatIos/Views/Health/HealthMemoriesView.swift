//
//  HealthMemoriesView.swift
//  CatEmotionAI
//

import SwiftUI

struct HealthMemoriesView: View {
    @EnvironmentObject private var healthStore: HealthRecordStore
    @EnvironmentObject private var petManager: PetManager
    @EnvironmentObject private var householdSync: HouseholdSync

    @State private var selectedPetScopeId: UUID = PetManager.allPetsId

    @State private var showAddHealthSheet = false
    @State private var showEditHealthSheet = false
    @State private var editingRecord: HealthRecord?

    @State private var newRecordTitle: String = ""
    @State private var newRecordType: HealthRecordType = .vaccination
    @State private var newVaccineName: String = "DHPP Booster"
    @State private var newRecordDate: Date = Date()
    @State private var hasNextDueDate: Bool = true
    @State private var newNextDueDate: Date = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var newDoctorLocation: String = ""
    @State private var newNotes: String = ""
    @State private var scheduleReminderAlarm: Bool = true
    @State private var newFrequency: TaskFrequency = .yearly
    @State private var newCustomInterval: Int = 1
    @State private var newCustomUnit: FrequencyUnit = .day
    @State private var newSelectedDays: Set<Int> = [2, 3, 4, 5, 6]
    @State private var newPetScopeId: UUID = PetManager.allPetsId

    @State private var editRecordTitle: String = ""
    @State private var editRecordType: HealthRecordType = .vaccination
    @State private var editVaccineName: String = "DHPP Booster"
    @State private var editRecordDate: Date = Date()
    @State private var editHasNextDueDate: Bool = true
    @State private var editNextDueDate: Date = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var editDoctorLocation: String = ""
    @State private var editNotes: String = ""
    @State private var editScheduleReminderAlarm: Bool = true
    @State private var editFrequency: TaskFrequency = .yearly
    @State private var editCustomInterval: Int = 1
    @State private var editCustomUnit: FrequencyUnit = .day
    @State private var editSelectedDays: Set<Int> = [2, 3, 4, 5, 6]
    @State private var editPetScopeId: UUID = PetManager.allPetsId

    private var filteredHealthRecords: [HealthRecord] {
        let records = if selectedPetScopeId == PetManager.allPetsId {
            healthStore.records
        } else {
            healthStore.records.filter { $0.petId == selectedPetScopeId || $0.petId == nil }
        }
        // Sort by date, most recent first
        return records.sorted { ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast) }
    }

    private var upcomingRecords: [HealthRecord] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let horizon = calendar.date(byAdding: .day, value: 45, to: today) ?? today
        return filteredHealthRecords
            .filter { record in
                guard let due = record.nextDueDate else { return false }
                return calendar.startOfDay(for: due) <= horizon
            }
            .sorted { ($0.nextDueDate ?? .distantFuture) < ($1.nextDueDate ?? .distantFuture) }
    }

    var body: some View {
        NavigationStack {
            List {
                if householdSync.lastError != nil {
                    Section {
                        SyncStatusBanner()
                    }
                }

                Section {
                    PetScopePicker(selection: $selectedPetScopeId, pets: petManager.pets)
                } footer: {
                    Text("Nutrition, weight, and behavior sit with health so due dates and daily logs stay together.")
                }

                if !upcomingRecords.isEmpty {
                    Section {
                        ForEach(upcomingRecords) { rec in
                            healthRecordButton(rec, emphasizeDueDate: true)
                        }
                    } header: {
                        Text("Coming up")
                    } footer: {
                        Text("Due in the next 45 days, or already overdue. Tap a record to edit.")
                    }
                }

                Section("Logs") {
                    NavigationLink {
                        NutritionView()
                    } label: {
                        ModuleLink(title: "Nutrition", systemImage: "fork.knife", tint: AppTheme.nutrition)
                    }
                    NavigationLink {
                        WeightView()
                    } label: {
                        ModuleLink(title: "Weight", systemImage: "scalemass", tint: AppTheme.health)
                    }
                    NavigationLink {
                        BehaviorView()
                    } label: {
                        ModuleLink(title: "Activity", systemImage: "figure.walk", tint: AppTheme.behavior)
                    }
                }

                if !healthStore.reminders.isEmpty {
                    Section("Reminders") {
                        ForEach(healthStore.reminders, id: \.self) { rem in
                            Label(rem, systemImage: "bell.badge")
                        }
                    }
                }

                Section {
                    if filteredHealthRecords.isEmpty {
                        EmptyStateView(
                            systemImage: "cross.case",
                            title: "No health records yet",
                            message: "Add a vaccine, vet visit, or treatment so due dates and reminders stay on this iPhone — and in your account after you sign in.",
                            actionTitle: householdSync.canMutate ? "Add Record" : nil,
                            action: householdSync.canMutate ? { showAddHealthSheet = true } : nil
                        )
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                    } else {
                        ForEach(filteredHealthRecords) { rec in
                            healthRecordButton(rec)
                        }
                    }
                } header: {
                    Text("All records")
                } footer: {
                    if !filteredHealthRecords.isEmpty {
                        Text("Newest first. Swipe a record to delete or toggle its reminder.")
                    }
                }
            }
            .refreshable {
                await householdSync.pullNow()
            }
            .fantasyScreen()
            .fantasyNavigation()
            .navigationTitle("Health")
            .toolbar {
                if householdSync.canMutate {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Add", systemImage: "plus") {
                            showAddHealthSheet = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddHealthSheet) {
                addHealthRecordSheet
            }
            .sheet(isPresented: $showEditHealthSheet) {
                editHealthRecordSheet
            }
        }
    }

    @ViewBuilder
    private func healthRecordButton(_ rec: HealthRecord, emphasizeDueDate: Bool = false) -> some View {
        Button {
            guard householdSync.canMutate else { return }
            loadEditDraft(from: rec)
            editingRecord = rec
            showEditHealthSheet = true
        } label: {
            HealthRecordRow(record: rec, petName: petName(for: rec), emphasizeDueDate: emphasizeDueDate)
        }
        .foregroundStyle(.primary)
        .swipeActions(edge: .trailing, allowsFullSwipe: householdSync.canMutate) {
            if householdSync.canMutate {
                Button("Delete", role: .destructive) {
                    healthStore.removeHealthRecord(rec)
                }
            }
        }
        .swipeActions(edge: .leading) {
            if householdSync.canMutate {
                Button(rec.isReminderSet == true ? "Mute" : "Remind") {
                    var updated = rec
                    updated.isReminderSet = (updated.isReminderSet == true) ? false : true
                    healthStore.updateHealthRecord(updated)
                }
                .tint(AppTheme.warning)
            }
        }
    }

    private func loadEditDraft(from record: HealthRecord) {
        editRecordTitle = record.title
        editRecordType = record.recordType
        editVaccineName = record.vaccineName ?? "DHPP Booster"
        editRecordDate = record.date ?? Date()
        editHasNextDueDate = record.nextDueDate != nil
        editNextDueDate = record.nextDueDate ?? Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
        editDoctorLocation = record.doctorOrLocation ?? ""
        editNotes = record.notes
        editScheduleReminderAlarm = record.isReminderSet ?? false
        editFrequency = record.frequency
        editCustomInterval = record.customInterval
        editCustomUnit = record.customUnit
        editSelectedDays = record.selectedDays
        editPetScopeId = record.petId ?? PetManager.allPetsId
    }

    private var addHealthRecordSheet: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    Picker("Type", selection: $newRecordType) {
                        ForEach(HealthRecordType.allCases) { type in
                            Text(LocalizedStringKey(type.rawValue)).tag(type)
                        }
                    }

                    if newRecordType == .vaccination {
                        Picker("Vaccine Name", selection: $newVaccineName) {
                            Text("DHPP Booster").tag("DHPP Booster")
                            Text("Rabies Vaccine").tag("Rabies Vaccine")
                            Text("Leptospirosis").tag("Leptospirosis")
                            Text("Bordetella").tag("Bordetella")
                            Text("Custom Vaccine...").tag("Custom Vaccine...")
                        }
                        if newVaccineName == "Custom Vaccine..." {
                            TextField("Enter Vaccine Title", text: $newRecordTitle)
                        }
                    } else {
                        TextField("Record Title (e.g. Annual Vet Checkup)", text: $newRecordTitle)
                    }

                    TextField("Clinic or location", text: $newDoctorLocation, prompt: Text("Clinic or home"))

                    Picker("Pet", selection: $newPetScopeId) {
                        Text("🐾 All Pets").tag(PetManager.allPetsId)
                        ForEach(petManager.pets) { pet in
                            Text("\(pet.avatarEmoji) \(pet.name)").tag(pet.id)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Dates") {
                    DatePicker("Date given", selection: $newRecordDate, displayedComponents: .date)

                    Toggle("Set next due date", isOn: $hasNextDueDate)

                    if hasNextDueDate {
                        DatePicker("Next due", selection: $newNextDueDate, displayedComponents: .date)

                        Toggle("Reminders", isOn: $scheduleReminderAlarm)
                    }
                }

                Section("Repeats") {
                    Picker("Frequency", selection: $newFrequency) {
                        ForEach(TaskFrequency.allCases) { freq in
                            Label(LocalizedStringKey(freq.rawValue), systemImage: freq.systemImage)
                                .tag(freq)
                        }
                    }

                    if newFrequency == .custom {
                        Picker("Unit", selection: $newCustomUnit) {
                            ForEach(FrequencyUnit.allCases) { unit in
                                Label(LocalizedStringKey(unit.rawValue), systemImage: unit.systemImage)
                                    .tag(unit)
                            }
                        }

                        Stepper(value: $newCustomInterval, in: 1...365) {
                            Text("Every \(newCustomInterval) \(newCustomUnit.rawValue.lowercased())\(newCustomInterval == 1 ? "" : "s")")
                        }
                    }

                    if newFrequency == .weekly {
                        weekdayPicker(selectedDays: $newSelectedDays)
                    }
                }

                Section("Notes") {
                    TextField("Batch number, dosage, reactions…", text: $newNotes)
                }
            }
            .navigationTitle("Add Health Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddHealthSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await saveNewRecord() }
                    }
                    .disabled(!canSaveNewRecord)
                    .bold()
                }
            }
        }
        .presentationDetents([.large])
    }

    private var editHealthRecordSheet: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    Picker("Type", selection: $editRecordType) {
                        ForEach(HealthRecordType.allCases) { type in
                            Text(LocalizedStringKey(type.rawValue)).tag(type)
                        }
                    }

                    if editRecordType == .vaccination {
                        Picker("Vaccine Name", selection: $editVaccineName) {
                            Text("DHPP Booster").tag("DHPP Booster")
                            Text("Rabies Vaccine").tag("Rabies Vaccine")
                            Text("Leptospirosis").tag("Leptospirosis")
                            Text("Bordetella").tag("Bordetella")
                            Text("Custom Vaccine...").tag("Custom Vaccine...")
                        }
                        if editVaccineName == "Custom Vaccine..." {
                            TextField("Enter Vaccine Title", text: $editRecordTitle)
                        }
                    } else {
                        TextField("Record Title (e.g. Annual Vet Checkup)", text: $editRecordTitle)
                    }

                    TextField("Clinic or location", text: $editDoctorLocation, prompt: Text("Clinic or home"))

                    Picker("Pet", selection: $editPetScopeId) {
                        Text("🐾 All Pets").tag(PetManager.allPetsId)
                        ForEach(petManager.pets) { pet in
                            Text("\(pet.avatarEmoji) \(pet.name)").tag(pet.id)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Dates") {
                    DatePicker("Date given", selection: $editRecordDate, displayedComponents: .date)

                    Toggle("Set next due date", isOn: $editHasNextDueDate)

                    if editHasNextDueDate {
                        DatePicker("Next due", selection: $editNextDueDate, displayedComponents: .date)

                        Toggle("Reminders", isOn: $editScheduleReminderAlarm)
                    }
                }

                Section("Repeats") {
                    Picker("Frequency", selection: $editFrequency) {
                        ForEach(TaskFrequency.allCases) { freq in
                            Label(LocalizedStringKey(freq.rawValue), systemImage: freq.systemImage)
                                .tag(freq)
                        }
                    }

                    if editFrequency == .custom {
                        Picker("Unit", selection: $editCustomUnit) {
                            ForEach(FrequencyUnit.allCases) { unit in
                                Label(LocalizedStringKey(unit.rawValue), systemImage: unit.systemImage)
                                    .tag(unit)
                            }
                        }

                        Stepper(value: $editCustomInterval, in: 1...365) {
                            Text("Every \(editCustomInterval) \(editCustomUnit.rawValue.lowercased())\(editCustomInterval == 1 ? "" : "s")")
                        }
                    }

                    if editFrequency == .weekly {
                        weekdayPicker(selectedDays: $editSelectedDays)
                    }
                }

                Section("Notes") {
                    TextField("Batch number, dosage, reactions…", text: $editNotes)
                }
            }
            .navigationTitle("Edit Health Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showEditHealthSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Changes") {
                        Task { await saveEditedRecord() }
                    }
                    .disabled(!canSaveEditedRecord)
                    .bold()
                }
            }
        }
    }

    private func saveEditedRecord() async {
        guard canSaveEditedRecord, var updated = editingRecord else { return }
        let finalTitle = (editRecordType == .vaccination && editVaccineName != "Custom Vaccine...")
            ? editVaccineName
            : editRecordTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if editScheduleReminderAlarm {
            _ = await HealthNotificationManager.shared.requestAuthorization()
        }
        updated.title = finalTitle
        updated.recordType = editRecordType
        updated.date = editRecordDate
        updated.nextDueDate = editHasNextDueDate ? editNextDueDate : nil
        updated.vaccineName = editRecordType == .vaccination ? finalTitle : nil
        updated.notes = editNotes
        updated.doctorOrLocation = editDoctorLocation.isEmpty ? nil : editDoctorLocation
        updated.isReminderSet = editScheduleReminderAlarm
        updated.frequency = editFrequency
        updated.customInterval = editCustomInterval
        updated.customUnit = editCustomUnit
        updated.selectedDays = editSelectedDays
        updated.petId = editPetScopeId == PetManager.allPetsId ? nil : editPetScopeId

        let df = DateFormatter()
        df.dateStyle = .medium
        updated.dateText = df.string(from: editRecordDate)
        if let dueDate = updated.nextDueDate {
            let components = Calendar.current.dateComponents([.day], from: Date(), to: dueDate)
            updated.upcomingDaysRemaining = max(0, components.day ?? 0)
        } else {
            updated.upcomingDaysRemaining = nil
        }
        healthStore.updateHealthRecord(updated)
        showEditHealthSheet = false
        editingRecord = nil
    }

    private func saveNewRecord() async {
        guard canSaveNewRecord else { return }
        let finalTitle = (newRecordType == .vaccination && newVaccineName != "Custom Vaccine...")
            ? newVaccineName
            : newRecordTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if scheduleReminderAlarm {
            _ = await HealthNotificationManager.shared.requestAuthorization()
        }
        healthStore.addHealthRecord(
            title: finalTitle,
            recordType: newRecordType,
            date: newRecordDate,
            nextDueDate: hasNextDueDate ? newNextDueDate : nil,
            vaccineName: newRecordType == .vaccination ? finalTitle : nil,
            notes: newNotes,
            doctorOrLocation: newDoctorLocation.isEmpty ? nil : newDoctorLocation,
            isReminderSet: scheduleReminderAlarm,
            petId: newPetScopeId == PetManager.allPetsId ? nil : newPetScopeId,
            frequency: newFrequency,
            customInterval: newCustomInterval,
            customUnit: newCustomUnit,
            selectedDays: newSelectedDays
        )
        showAddHealthSheet = false
        newRecordTitle = ""
        newNotes = ""
        newDoctorLocation = ""
    }

    private var canSaveNewRecord: Bool {
        if newRecordType == .vaccination && newVaccineName != "Custom Vaccine..." { return true }
        return !newRecordTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canSaveEditedRecord: Bool {
        if editRecordType == .vaccination && editVaccineName != "Custom Vaccine..." { return true }
        return !editRecordTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func petName(for record: HealthRecord) -> String? {
        guard selectedPetScopeId == PetManager.allPetsId else { return nil }
        guard let petId = record.petId else { return "All pets" }
        return petManager.pets.first(where: { $0.id == petId })?.name
    }

    private func weekdayPicker(selectedDays: Binding<Set<Int>>) -> some View {
        let days: [(Int, String)] = [
            (1, "S"), (2, "M"), (3, "T"), (4, "W"), (5, "T"), (6, "F"), (7, "S")
        ]

        return HStack(spacing: 10) {
            ForEach(days, id: \.0) { day in
                let isSelected = selectedDays.wrappedValue.contains(day.0)
                Button(action: {
                    var newSet = selectedDays.wrappedValue
                    if newSet.contains(day.0) {
                        newSet.remove(day.0)
                    } else {
                        newSet.insert(day.0)
                    }
                    selectedDays.wrappedValue = newSet
                }) {
                    Text(day.1)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(isSelected ? .white : AppTheme.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(isSelected ? AppTheme.primary : AppTheme.cardBackground)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(isSelected ? AppTheme.primary : AppTheme.textSecondary.opacity(0.2), lineWidth: 1)
                        )
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct HealthRecordRow: View {
    let record: HealthRecord
    var petName: String? = nil
    var emphasizeDueDate: Bool = false

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(record.title))
                    .font(.body.weight(.medium))
                HStack(spacing: 6) {
                    Text(record.dateText)
                    if let petName, !petName.isEmpty {
                        Text("·")
                        Text(petName)
                    }
                    if let location = record.doctorOrLocation, !location.isEmpty {
                        Text("·")
                        Text(location)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                if !record.notes.isEmpty && !emphasizeDueDate {
                    Text(record.notes)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                if let next = record.nextDueDate {
                    Text(dueLabel(for: next))
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(dueTint(for: next))
                }
            }
        } icon: {
            Image(systemName: record.recordType.icon)
                .foregroundStyle(dueTint(for: record.nextDueDate))
        }
    }

    private func dueLabel(for next: Date) -> String {
        let days = daysUntil(next)
        let reminder = record.isReminderSet == true ? " · reminder on" : ""
        if days < 0 {
            let overdue = abs(days)
            return overdue == 1 ? "Overdue by 1 day\(reminder)" : "Overdue by \(overdue) days\(reminder)"
        }
        if days == 0 { return "Due today\(reminder)" }
        if days == 1 { return "Due tomorrow\(reminder)" }
        if days <= 14 { return "Due in \(days) days\(reminder)" }
        return "Due \(next.formatted(date: .abbreviated, time: .omitted))\(reminder)"
    }

    private func dueTint(for next: Date?) -> Color {
        guard let next else { return AppTheme.health }
        let days = daysUntil(next)
        if days < 0 { return AppTheme.danger }
        if days <= 7 { return AppTheme.warning }
        return AppTheme.health
    }

    private func daysUntil(_ date: Date) -> Int {
        let calendar = Calendar.current
        return calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: Date()),
            to: calendar.startOfDay(for: date)
        ).day ?? 0
    }
}

#Preview {
    HealthMemoriesView()
        .environmentObject(PetManager.shared)
        .environmentObject(HealthRecordStore.shared)
        .environmentObject(HouseholdSync.shared)
        .environmentObject(AuthSession.shared)
}
