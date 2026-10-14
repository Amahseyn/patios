//
//  RemindersView.swift
//  CatIos
//

import SwiftUI

enum ReminderCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case feeding = "Feeding 🍗"
    case water = "Water 💧"
    case litter = "Litter 🚽"
    case medicine = "Medicine 💊"
    case grooming = "Grooming 🧼"
    case activity = "Activity 🎾"
    case vet = "Vet 🩺"

    var id: String { rawValue }
}

struct ReminderItem: Identifiable {
    let id = UUID()
    let title: String
    let category: ReminderCategory
    let timeText: String
    let dayText: String
    var isDone: Bool
}

struct RemindersView: View {
    @State private var selectedCategory: ReminderCategory = .all
    @State private var showAddSheet = false
    @State private var reminders: [ReminderItem] = [
        ReminderItem(title: "Dinner feeding", category: .feeding, timeText: "7:00 PM", dayText: "Every Day", isDone: false),
        ReminderItem(title: "Fresh water bowl refill", category: .water, timeText: "8:00 PM", dayText: "Every Day", isDone: false),
        ReminderItem(title: "Playtime session", category: .activity, timeText: "9:30 PM", dayText: "Today", isDone: false),
        ReminderItem(title: "Bath & grooming reminder", category: .grooming, timeText: "10:00 AM", dayText: "Tomorrow", isDone: false),
        ReminderItem(title: "Scoop litter box", category: .litter, timeText: "11:00 AM", dayText: "Every Day", isDone: false),
        ReminderItem(title: "DHPP Vaccination booster", category: .vet, timeText: "2:00 PM", dayText: "In 8 days", isDone: false),
        ReminderItem(title: "Flea & Tick spot-on medicine", category: .medicine, timeText: "09:00 AM", dayText: "In 12 days", isDone: false)
    ]

    var filteredReminders: [ReminderItem] {
        if selectedCategory == .all {
            return reminders
        }
        return reminders.filter { $0.category == selectedCategory }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ReminderCategory.allCases) { cat in
                            Button {
                                withAnimation {
                                    selectedCategory = cat
                                }
                            } label: {
                                Text(LocalizedStringKey(cat.rawValue))
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == cat ? AppTheme.primary : AppTheme.cardBackground)
                                    .foregroundStyle(selectedCategory == cat ? .white : AppTheme.textPrimary)
                                    .clipShape(Capsule())
                                    .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }

                Divider()

                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.spacingL) {
                        reminderGroupSection(title: "Today & Daily Recurring", items: filteredReminders.filter { $0.dayText == "Today" || $0.dayText == "Every Day" })

                        reminderGroupSection(title: "Tomorrow", items: filteredReminders.filter { $0.dayText == "Tomorrow" })

                        reminderGroupSection(title: "Upcoming Schedules", items: filteredReminders.filter { $0.dayText != "Today" && $0.dayText != "Every Day" && $0.dayText != "Tomorrow" })
                    }
                    .padding(AppTheme.spacingM)
                    .padding(.bottom, 40)
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Smart Reminders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AppTheme.primary)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                SmartReminderModalSheet { newItem in
                    withAnimation {
                        reminders.insert(newItem, at: 0)
                    }
                }
            }
        }
    }

    private func reminderGroupSection(title: String, items: [ReminderItem]) -> some View {
        Group {
            if !items.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)

                    ForEach(items) { item in
                        HStack(spacing: 12) {
                            Button {
                                if let idx = reminders.firstIndex(where: { $0.id == item.id }) {
                                    withAnimation {
                                        reminders[idx].isDone.toggle()
                                    }
                                }
                            } label: {
                                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                                    .font(.title2)
                                    .foregroundStyle(item.isDone ? .green : AppTheme.secondary)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(LocalizedStringKey(item.title))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(item.isDone ? AppTheme.textSecondary : AppTheme.textPrimary)
                                    .strikethrough(item.isDone)

                                Text(LocalizedStringKey(item.category.rawValue))
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(item.timeText)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(AppTheme.primary)
                                Text(item.dayText)
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppTheme.primary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .padding(14)
                        .cardStyle()
                    }
                }
            }
        }
    }
}

#Preview {
    RemindersView()
}
