//
//  SmartReminderModalSheet.swift
//  CatIos
//

import SwiftUI

enum RepeatFrequency: String, CaseIterable, Identifiable {
    case everyDay = "Every Day 🔁"
    case weekdays = "Weekdays (Mon-Fri) 💼"
    case weekends = "Weekends (Sat-Sun) ☀️"
    case weekly = "Weekly 🗓️"
    case oneTime = "One-Time 📌"

    var id: String { rawValue }
}

struct SmartReminderModalSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var petManager: PetManager

    var onSave: (ReminderItem) -> Void

    @State private var title: String = ""
    @State private var category: ReminderCategory = .feeding
    @State private var selectedTime: Date = Date()
    @State private var selectedDate: Date = Date()
    @State private var repeatFrequency: RepeatFrequency = .everyDay
    @State private var selectedPetTarget: String = "All Pets 🐾"

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Reminder Details")) {
                    TextField("Reminder title (e.g., Morning Salmon Feast)", text: $title)

                    Picker("Category", selection: $category) {
                        ForEach(ReminderCategory.allCases.filter { $0 != .all }) { cat in
                            Text(LocalizedStringKey(cat.rawValue)).tag(cat)
                        }
                    }

                    Picker("Target Pet", selection: $selectedPetTarget) {
                        Text("All Pets 🐾").tag("All Pets 🐾")
                        ForEach(petManager.pets) { pet in
                            Text("\(pet.avatarEmoji) \(pet.name)").tag(pet.name)
                        }
                    }
                }

                Section(header: Text("Schedule & Time")) {
                    DatePicker("Clock Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    DatePicker("Starting Date", selection: $selectedDate, displayedComponents: .date)

                    Picker("Repeat Frequency", selection: $repeatFrequency) {
                        ForEach(RepeatFrequency.allCases) { freq in
                            Text(LocalizedStringKey(freq.rawValue)).tag(freq)
                        }
                    }
                }

                Section(header: Text("Notification Preview")) {
                    HStack(spacing: 12) {
                        Text(categoryIcon(category))
                            .font(.title2)
                            .padding(10)
                            .background(AppTheme.primary.opacity(0.12))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(title.isEmpty ? "Reminder Title" : title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("\(formattedTime) • \(repeatFrequency.rawValue)")
                                .font(.caption)
                                .foregroundStyle(AppTheme.primary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("New Care Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newItem = ReminderItem(
                            title: title.isEmpty ? "\(category.rawValue) Reminder" : title,
                            category: category,
                            timeText: formattedTime,
                            dayText: repeatFrequency == .everyDay ? "Every Day" : "Scheduled",
                            isDone: false
                        )
                        onSave(newItem)
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: selectedTime)
    }

    private func categoryIcon(_ cat: ReminderCategory) -> String {
        switch cat {
        case .feeding: return "🍗"
        case .water: return "💧"
        case .litter: return "🚽"
        case .medicine: return "💊"
        case .grooming: return "🧼"
        case .activity: return "🎾"
        case .vet: return "🩺"
        case .all: return "🔔"
        }
    }
}
