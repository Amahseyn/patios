//
//  HealthMemoriesView.swift
//  CatEmotionAI
//

import SwiftUI

enum HealthSubTab: String, CaseIterable, Identifiable {
    case healthTimeline = "Timeline"

    var id: String { rawValue }
}

struct HealthMemoriesView: View {
    @StateObject private var companionVM = PetCompanionViewModel()
    @EnvironmentObject private var petManager: PetManager
    @State private var selectedTab: HealthSubTab = .healthTimeline

    @State private var selectedPetScopeId: UUID = PetManager.allPetsId

    @State private var showAddHealthSheet = false
    @State private var showEditHealthSheet = false
    @State private var editingRecord: HealthRecord?

    @State private var newRecordTitle: String = ""
    @State private var newRecordType: HealthRecordType = .vaccination
    @State private var newVaccineName: String = "DHPP Booster 💉"
    @State private var newRecordDate: Date = Date()
    @State private var hasNextDueDate: Bool = true
    @State private var newNextDueDate: Date = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var newDoctorLocation: String = "Happy Paws Vet Clinic 🩺"
    @State private var newNotes: String = ""
    @State private var scheduleReminderAlarm: Bool = true
    @State private var newFrequency: TaskFrequency = .yearly
    @State private var newCustomInterval: Int = 1
    @State private var newCustomUnit: FrequencyUnit = .day
    @State private var newSelectedDays: Set<Int> = [2, 3, 4, 5, 6]
    @State private var newPetScopeId: UUID = PetManager.allPetsId

    @State private var editRecordTitle: String = ""
    @State private var editRecordType: HealthRecordType = .vaccination
    @State private var editVaccineName: String = "DHPP Booster 💉"
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
            companionVM.healthTimeline
        } else {
            companionVM.healthTimeline.filter { $0.petId == selectedPetScopeId || $0.petId == nil }
        }
        // Sort by date, most recent first
        return records.sorted { ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Tab", selection: $selectedTab) {
                    ForEach(HealthSubTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(AppTheme.spacingM)

                Divider()

                ScrollView {
                    VStack(spacing: AppTheme.spacingL) {
                    switch selectedTab {
                    case .healthTimeline:
                        healthTimelineView
                    }
                    }
                    .padding(AppTheme.spacingM)
                    .padding(.bottom, 40)
                }
            }
            .patiosScreenBackground()
            .navigationTitle("Health")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAddHealthSheet) {
                addHealthRecordSheet
            }
            .sheet(isPresented: $showEditHealthSheet) {
                editHealthRecordSheet
            }
        }
    }

    private func loadEditDraft(from record: HealthRecord) {
        editRecordTitle = record.title
        editRecordType = record.recordType
        editVaccineName = record.vaccineName ?? "DHPP Booster 💉"
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

    private var petScopeSelectorBar: some View {
        PetScopeChipBar(selectedPetScopeId: $selectedPetScopeId)
    }

    private var healthTimelineView: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingM) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: "syringe.fill")
                            .font(.subheadline)
                            .foregroundStyle(.purple)
                            .padding(6)
                            .background(Color.purple.opacity(0.12))
                            .clipShape(Circle())

                        Text("Vaccination & Medical Care")
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    Text("Schedule boosters, track dates & set vet reminders")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                Button {
                    showAddHealthSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add")
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(AppTheme.primary)
                    .clipShape(Capsule())
                }
            }

            petScopeSelectorBar

            ForEach(companionVM.healthReminders, id: \.self) { rem in
                HStack(spacing: 12) {
                    Image(systemName: "bell.badge.fill")
                        .foregroundStyle(Color.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Upcoming Scheduled Reminder ⏰")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.orange)
                        Text(rem)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            if filteredHealthRecords.isEmpty {
                EmptyStateView(
                    systemImage: "syringe",
                    title: "No health records yet",
                    message: "Track vaccines, vet visits, and medications. Your reminders will show up here too.",
                    actionTitle: "Add record",
                    action: { showAddHealthSheet = true }
                )
                .cardStyle()
            }

            ForEach(filteredHealthRecords) { rec in
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(rec.recordType == .vaccination ? Color.purple.opacity(0.15) : AppTheme.primary.opacity(0.15))
                            .frame(width: 46, height: 46)
                        Image(systemName: rec.recordType.icon)
                            .font(.title3)
                            .foregroundStyle(rec.recordType == .vaccination ? Color.purple : AppTheme.primary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(rec.title)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(AppTheme.textPrimary)
                            Spacer()
                            Text(rec.dateText)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AppTheme.primary)
                        }

                        Text(rec.notes)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)

                        if let doc = rec.doctorOrLocation {
                            Text("📍 \(doc)")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary.opacity(0.8))
                        }

                        if let nextDate = rec.nextDueDate {
                            let df = DateFormatter()
                            let _ = df.dateStyle = .medium
                            HStack(spacing: 4) {
                                Image(systemName: "calendar.badge.clock")
                                Text("Next Due Date: \(df.string(from: nextDate))")
                            }
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.purple)
                            .padding(.top, 2)
                        }

                        if rec.frequency != .yearly || rec.customInterval != 1 {
                            HStack(spacing: 4) {
                                Image(systemName: rec.frequency.systemImage)
                                    .font(.caption2)
                                Text(frequencyLabel(for: rec))
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(Color.purple)
                            }
                            .padding(.top, 2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 14) {
                        Button(action: {
                            loadEditDraft(from: rec)
                            editingRecord = rec
                            showEditHealthSheet = true
                        }) {
                            Image(systemName: "pencil")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary)
                                .padding(4)
                        }

                        Button(action: {
                            var updated = rec
                            updated.isReminderSet = (updated.isReminderSet == true) ? false : true
                            companionVM.updateHealthRecord(updated)
                        }) {
                            Image(systemName: rec.isReminderSet == true ? "bell.fill" : "bell.slash")
                                .font(.caption2)
                                .foregroundStyle(rec.isReminderSet == true ? AppTheme.textSecondary : AppTheme.textSecondary.opacity(0.6))
                                .padding(4)
                        }

                        Button(action: {
                            companionVM.removeHealthRecord(rec)
                        }) {
                            Image(systemName: "trash")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary.opacity(0.8))
                                .padding(4)
                        }
                    }
                }
                .padding(14)
                .cardStyle()
            }
        }
    }

    private func frequencyLabel(for record: HealthRecord) -> String {
        switch record.frequency {
        case .hourly:
            return record.customInterval == 1 ? "Every Hour" : "Every \(record.customInterval) Hours"
        case .daily:
            return "Every Day"
        case .weekly:
            return "Every Week"
        case .monthly:
            return record.customInterval == 1 ? "Every Month" : "Every \(record.customInterval) Months"
        case .yearly:
            return record.customInterval == 1 ? "Every Year" : "Every \(record.customInterval) Years"
        case .custom:
            return "Every \(record.customInterval) interval(s)"
        }
    }

    private var addHealthRecordSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("Record Details")) {
                    Picker("Record Category", selection: $newRecordType) {
                        ForEach(HealthRecordType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }

                    if newRecordType == .vaccination {
                        Picker("Vaccine Name", selection: $newVaccineName) {
                            Text("DHPP Booster 💉").tag("DHPP Booster 💉")
                            Text("Rabies Vaccine 🦠").tag("Rabies Vaccine 🦠")
                            Text("Leptospirosis 🛡️").tag("Leptospirosis 🛡️")
                            Text("Bordetella 🧪").tag("Bordetella 🧪")
                            Text("Custom Vaccine...").tag("Custom Vaccine...")
                        }
                        if newVaccineName == "Custom Vaccine..." {
                            TextField("Enter Vaccine Title", text: $newRecordTitle)
                        }
                    } else {
                        TextField("Record Title (e.g. Annual Vet Checkup)", text: $newRecordTitle)
                    }

                    TextField("Vet Clinic / Location", text: $newDoctorLocation)

                    Picker("Pet", selection: $newPetScopeId) {
                        Text("🐾 All Pets").tag(PetManager.allPetsId)
                        ForEach(petManager.pets) { pet in
                            Text("\(pet.avatarEmoji) \(pet.name)").tag(pet.id)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section(header: Text("Dates & Schedule Alarms 📅")) {
                    DatePicker("Administered / Given Date", selection: $newRecordDate, displayedComponents: .date)

                    Toggle("Set Next Due Date / Booster", isOn: $hasNextDueDate)

                    if hasNextDueDate {
                        DatePicker("Next Booster / Due Date", selection: $newNextDueDate, displayedComponents: .date)

                        Toggle("Schedule Alarm & Smart Reminder ⏰", isOn: $scheduleReminderAlarm)
                    }
                }

                Section(header: Text("Recurrence Frequency")) {
                    Picker("Frequency", selection: $newFrequency) {
                        ForEach(TaskFrequency.allCases) { freq in
                            Label(freq.rawValue, systemImage: freq.systemImage)
                                .tag(freq)
                        }
                    }

                    if newFrequency == .custom {
                        Picker("Unit", selection: $newCustomUnit) {
                            ForEach(FrequencyUnit.allCases) { unit in
                                Label(unit.rawValue, systemImage: unit.systemImage)
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

                Section(header: Text("Notes & Dosage")) {
                    TextField("Notes (e.g. Batch #4092, batch details, reactions)", text: $newNotes)
                }
            }
            .navigationTitle("Add Vaccination & Care 💉")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddHealthSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save & Schedule") {
                        let finalTitle = (newRecordType == .vaccination && newVaccineName != "Custom Vaccine...")
                            ? newVaccineName
                            : newRecordTitle

                        companionVM.addHealthRecord(
                            title: finalTitle,
                            recordType: newRecordType,
                            date: newRecordDate,
                            nextDueDate: hasNextDueDate ? newNextDueDate : nil,
                            vaccineName: newRecordType == .vaccination ? finalTitle : nil,
                            notes: newNotes,
                            doctorOrLocation: newDoctorLocation,
                            isReminderSet: scheduleReminderAlarm,
                            petId: newPetScopeId == PetManager.allPetsId ? nil : newPetScopeId,
                            frequency: newFrequency,
                            customInterval: newCustomInterval,
                            customUnit: newCustomUnit,
                            selectedDays: newSelectedDays
                        )
                        showAddHealthSheet = false
                        newRecordTitle = ""
                    }
                    .bold()
                }
            }
        }
    }

    private var editHealthRecordSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("Record Details")) {
                    Picker("Record Category", selection: $editRecordType) {
                        ForEach(HealthRecordType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }

                    if editRecordType == .vaccination {
                        Picker("Vaccine Name", selection: $editVaccineName) {
                            Text("DHPP Booster 💉").tag("DHPP Booster 💉")
                            Text("Rabies Vaccine 🦠").tag("Rabies Vaccine 🦠")
                            Text("Leptospirosis 🛡️").tag("Leptospirosis 🛡️")
                            Text("Bordetella 🧪").tag("Bordetella 🧪")
                            Text("Custom Vaccine...").tag("Custom Vaccine...")
                        }
                        if editVaccineName == "Custom Vaccine..." {
                            TextField("Enter Vaccine Title", text: $editRecordTitle)
                        }
                    } else {
                        TextField("Record Title (e.g. Annual Vet Checkup)", text: $editRecordTitle)
                    }

                    TextField("Vet Clinic / Location", text: $editDoctorLocation)

                    Picker("Pet", selection: $editPetScopeId) {
                        Text("🐾 All Pets").tag(PetManager.allPetsId)
                        ForEach(petManager.pets) { pet in
                            Text("\(pet.avatarEmoji) \(pet.name)").tag(pet.id)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section(header: Text("Dates & Schedule Alarms 📅")) {
                    DatePicker("Administered / Given Date", selection: $editRecordDate, displayedComponents: .date)

                    Toggle("Set Next Due Date / Booster", isOn: $editHasNextDueDate)

                    if editHasNextDueDate {
                        DatePicker("Next Booster / Due Date", selection: $editNextDueDate, displayedComponents: .date)

                        Toggle("Schedule Alarm & Smart Reminder ⏰", isOn: $editScheduleReminderAlarm)
                    }
                }

                Section(header: Text("Recurrence Frequency")) {
                    Picker("Frequency", selection: $editFrequency) {
                        ForEach(TaskFrequency.allCases) { freq in
                            Label(freq.rawValue, systemImage: freq.systemImage)
                                .tag(freq)
                        }
                    }

                    if editFrequency == .custom {
                        Picker("Unit", selection: $editCustomUnit) {
                            ForEach(FrequencyUnit.allCases) { unit in
                                Label(unit.rawValue, systemImage: unit.systemImage)
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

                Section(header: Text("Notes & Dosage")) {
                    TextField("Notes (e.g. Batch #4092, batch details, reactions)", text: $editNotes)
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
                        let finalTitle = (editRecordType == .vaccination && editVaccineName != "Custom Vaccine...")
                            ? editVaccineName
                            : editRecordTitle

                        var updated = editingRecord!
                        updated.title = finalTitle
                        updated.recordType = editRecordType
                        updated.date = editRecordDate
                        updated.nextDueDate = editHasNextDueDate ? editNextDueDate : nil
                        updated.vaccineName = editRecordType == .vaccination ? finalTitle : nil
                        updated.notes = editNotes
                        updated.doctorOrLocation = editDoctorLocation
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

                        companionVM.updateHealthRecord(updated)
                        showEditHealthSheet = false
                        editingRecord = nil
                    }
                    .bold()
                }
            }
        }
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

#Preview {
    HealthMemoriesView()
}
