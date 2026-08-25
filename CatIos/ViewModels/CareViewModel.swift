//
//  CareViewModel.swift
//  CatIos
//

import Foundation
import SwiftUI
import Combine

class CareViewModel: ObservableObject {
    @Published var wellness: WellnessScore = WellnessScore(
        petName: "Luna",
        moodScore: 92,
        nutritionScore: 85,
        activityScore: 78,
        groomingScore: 90
    )

    @Published var selectedCategory: CareCategory? = nil
    @Published var selectedDate: Date = Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 10)) ?? Date()

    @Published var aiSuggestions: [AISuggestion] = [
        AISuggestion(
            title: "Smart Feeding Routine",
            message: "Luna usually eats around 8:00 AM. Would you like to create a feeding reminder?",
            category: .feeding,
            actionTitle: "Add 8:00 AM Reminder",
            icon: "🐟"
        ),
        AISuggestion(
            title: "Grooming Suggestion",
            message: "Luna's grooming schedule suggests a bath soon.",
            category: .grooming,
            actionTitle: "Schedule Bath",
            icon: "🛁"
        ),
        AISuggestion(
            title: "Playtime Alert",
            message: "You haven't tracked play time recently. Interactive play boosts mood score!",
            category: .activities,
            actionTitle: "Start Play Session",
            icon: "🎮"
        )
    ]

    @Published var notificationPreviews: [NotificationPreviewCard] = [
        NotificationPreviewCard(
            title: "Feeding Reminder",
            message: "Luna's dinner time is in 30 minutes.",
            timeAgoText: "In 30 min",
            category: .feeding,
            icon: "🐱"
        ),
        NotificationPreviewCard(
            title: "Grooming Reminder",
            message: "Luna's bath is scheduled for tomorrow.",
            timeAgoText: "Tomorrow, 10:00 AM",
            category: .grooming,
            icon: "🛁"
        ),
        NotificationPreviewCard(
            title: "Activity Reminder",
            message: "Time for play session.",
            timeAgoText: "Today, 6:00 PM",
            category: .activities,
            icon: "🎮"
        )
    ]

    @Published var reminders: [CareReminder] = [
        CareReminder(
            title: "Breakfast schedule",
            category: .feeding,
            subcategory: "Breakfast",
            scheduledDate: Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 3, hour: 8, minute: 0))!,
            timeString: "8:00 AM",
            isCompleted: true,
            frequency: "Daily"
        ),
        CareReminder(
            title: "Lunch kibble & water refill",
            category: .feeding,
            subcategory: "Lunch",
            scheduledDate: Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 3, hour: 13, minute: 0))!,
            timeString: "1:00 PM",
            isCompleted: true,
            frequency: "Daily"
        ),
        CareReminder(
            title: "Salmon Treat & Dinner",
            category: .feeding,
            subcategory: "Dinner",
            scheduledDate: Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 3, hour: 19, minute: 30))!,
            timeString: "7:30 PM",
            isCompleted: false,
            frequency: "Daily"
        ),

        CareReminder(
            title: "Fur Brushing Session",
            category: .grooming,
            subcategory: "Brushing",
            scheduledDate: Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 10, hour: 11, minute: 0))!,
            timeString: "11:00 AM",
            isCompleted: false,
            frequency: "Weekly"
        ),
        CareReminder(
            title: "Bath reminder",
            category: .grooming,
            subcategory: "Bath",
            scheduledDate: Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 15, hour: 14, minute: 0))!,
            timeString: "2:00 PM",
            isCompleted: false,
            frequency: "Monthly"
        ),
        CareReminder(
            title: "Nail Trimming",
            category: .grooming,
            subcategory: "Nail trimming",
            scheduledDate: Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 18, hour: 16, minute: 0))!,
            timeString: "4:00 PM",
            isCompleted: false,
            frequency: "Bi-weekly"
        ),

        CareReminder(
            title: "Vet appointment",
            category: .health,
            subcategory: "Vet appointment",
            scheduledDate: Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 20, hour: 10, minute: 30))!,
            timeString: "10:30 AM",
            isCompleted: false,
            frequency: "Yearly"
        ),
        CareReminder(
            title: "Annual Vaccination",
            category: .health,
            subcategory: "Vaccination",
            scheduledDate: Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 20, hour: 11, minute: 15))!,
            timeString: "11:15 AM",
            isCompleted: false,
            frequency: "Yearly"
        ),

        CareReminder(
            title: "Feather Wand Play Time",
            category: .activities,
            subcategory: "Play time",
            scheduledDate: Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 10, hour: 18, minute: 0))!,
            timeString: "6:00 PM",
            isCompleted: false,
            frequency: "Daily"
        ),
        CareReminder(
            title: "Agility & Trick Training",
            category: .activities,
            subcategory: "Training",
            scheduledDate: Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 12, hour: 17, minute: 0))!,
            timeString: "5:00 PM",
            isCompleted: false,
            frequency: "3x / week"
        )
    ]

    var filteredReminders: [CareReminder] {
        if let category = selectedCategory {
            return reminders.filter { $0.category == category }
        }
        return reminders
    }

    func toggleReminderCompletion(_ reminder: CareReminder) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index].isCompleted.toggle()
        }
    }

    func dismissSuggestion(_ suggestion: AISuggestion) {
        aiSuggestions.removeAll { $0.id == suggestion.id }
    }

    func addReminder(title: String, category: CareCategory, subcategory: String, date: Date, timeString: String, frequency: String) {
        let newReminder = CareReminder(
            title: title,
            category: category,
            subcategory: subcategory,
            scheduledDate: date,
            timeString: timeString,
            isCompleted: false,
            frequency: frequency
        )
        reminders.append(newReminder)
    }
}
