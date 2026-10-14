//
//  CareView.swift
//  CatIos
//

import SwiftUI

struct CareView: View {
    @StateObject private var viewModel = CareViewModel()
    @State private var showingAddSheet = false
    @State private var selectedCalendarMonth = "August 2026"
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // 1. Wellness Dashboard Section
                    wellnessDashboardCard
                    
                    // 2. Smart AI Suggestions Section
                    aiSuggestionsSection
                    
                    // 3. Care Calendar Section
                    careCalendarSection
                    
                    // 4. Smart Care Reminders Section
                    careRemindersSection
                    
                    // 5. Notification Design Previews Section
                    notificationPreviewsSection
                    
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Pet Care Assistant")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(AppTheme.primary)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddReminderSheet(viewModel: viewModel)
            }
        }
    }
    
    // MARK: - 1. Wellness Dashboard UI
    private var wellnessDashboardCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(viewModel.wellness.petName)'s Wellness")
                        .font(.title2.weight(.bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Daily Health & Activity Summary")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
                
                // Overall Score Badge
                VStack(spacing: 2) {
                    Text("\(viewModel.wellness.overallScore)")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.primary)
                    Text("/ 100")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(AppTheme.primary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            Divider()
                .background(AppTheme.secondary.opacity(0.2))
            
            // Score Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                wellnessMetricTile(
                    emoji: "😊",
                    title: "Mood",
                    score: viewModel.wellness.moodScore,
                    color: Color.orange
                )
                wellnessMetricTile(
                    emoji: "🍖",
                    title: "Nutrition",
                    score: viewModel.wellness.nutritionScore,
                    color: AppTheme.secondary
                )
                wellnessMetricTile(
                    emoji: "🎮",
                    title: "Activity",
                    score: viewModel.wellness.activityScore,
                    color: Color.purple
                )
                wellnessMetricTile(
                    emoji: "🧼",
                    title: "Grooming",
                    score: viewModel.wellness.groomingScore,
                    color: Color.teal
                )
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    private func wellnessMetricTile(emoji: String, title: String, score: Int, color: Color) -> some View {
        HStack(spacing: 10) {
            Text(emoji)
                .font(.title3)
                .padding(8)
                .background(color.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(title): \(score)%")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppTheme.textPrimary)
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(color.opacity(0.2))
                            .frame(height: 6)
                        Capsule()
                            .fill(color)
                            .frame(width: geo.size.width * CGFloat(score) / 100.0, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(10)
        .background(AppTheme.background.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    // MARK: - 2. Smart AI Suggestions UI
    private var aiSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(AppTheme.primary)
                Text("Smart AI Suggestions")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
            }
            
            if viewModel.aiSuggestions.isEmpty {
                Text("All caught up with AI recommendations!")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(viewModel.aiSuggestions) { suggestion in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(suggestion.icon)
                                        .font(.title2)
                                    Text(LocalizedStringKey(suggestion.title))
                                        .font(.subheadline.weight(.bold))
                                        .foregroundColor(AppTheme.textPrimary)
                                    Spacer()
                                    Button(action: {
                                        withAnimation {
                                            viewModel.dismissSuggestion(suggestion)
                                        }
                                    }) {
                                        Image(systemName: "xmark")
                                            .font(.caption.weight(.bold))
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                }
                                
                                Text("\"\(suggestion.message)\"")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .lineLimit(3)
                                
                                Spacer()
                                
                                Button(action: {
                                    showingAddSheet = true
                                }) {
                                    HStack {
                                        Spacer()
                                        Text(suggestion.actionTitle)
                                            .font(.caption.weight(.semibold))
                                        Image(systemName: "arrow.right")
                                            .font(.caption2)
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                    .background(suggestion.category.themeColor.opacity(0.15))
                                    .foregroundColor(suggestion.category.themeColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                            .padding(16)
                            .frame(width: 260, height: 160)
                            .background(AppTheme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(suggestion.category.themeColor.opacity(0.3), lineWidth: 1.5)
                            )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 3. Care Calendar UI
    private var careCalendarSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(AppTheme.primary)
                Text("Care Calendar")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Text(selectedCalendarMonth)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(AppTheme.primary)
            }
            
            VStack(spacing: 10) {
                // Calendar Events List Mockup (Aug 3, Aug 10, Aug 15, Aug 20)
                calendarEventRow(dateText: "Aug 3", emoji: "🍖", title: "Breakfast schedule", category: .feeding, status: "Completed")
                calendarEventRow(dateText: "Aug 10", emoji: "🪮", title: "Grooming & Fur Brushing", category: .grooming, status: "Upcoming")
                calendarEventRow(dateText: "Aug 15", emoji: "🛁", title: "Bath reminder", category: .grooming, status: "Scheduled")
                calendarEventRow(dateText: "Aug 20", emoji: "💉", title: "Vet appointment & Vaccination", category: .health, status: "Upcoming")
            }
            .padding(16)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
    
    private func calendarEventRow(dateText: String, emoji: String, title: String, category: CareCategory, status: String) -> some View {
        HStack(spacing: 14) {
            VStack {
                Text(dateText)
                    .font(.caption.weight(.bold))
                    .foregroundColor(category.themeColor)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(category.themeColor.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            Text(emoji)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppTheme.textPrimary)
                Text(LocalizedStringKey(category.rawValue))
                    .font(.caption2)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
            
            Text(status)
                .font(.caption2.weight(.medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(status == "Completed" ? Color.green.opacity(0.15) : AppTheme.secondary.opacity(0.15))
                .foregroundColor(status == "Completed" ? Color.green : AppTheme.textSecondary)
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - 4. Smart Care Reminders UI
    private var careRemindersSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(AppTheme.primary)
                Text("Smart Care Reminders")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
            }
            
            // Category Filter Bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    categoryFilterChip(title: "All", category: nil)
                    ForEach(CareCategory.allCases) { cat in
                        categoryFilterChip(title: "\(cat.icon) \(cat.rawValue)", category: cat)
                    }
                }
            }
            
            VStack(spacing: 10) {
                ForEach(viewModel.filteredReminders) { reminder in
                    HStack(spacing: 12) {
                        Button(action: {
                            withAnimation {
                                viewModel.toggleReminderCompletion(reminder)
                            }
                        }) {
                            Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.title2)
                                .foregroundColor(reminder.isCompleted ? .green : AppTheme.secondary)
                        }
                        
                        Text(reminder.category.icon)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(LocalizedStringKey(reminder.title))
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(reminder.isCompleted ? AppTheme.textSecondary : AppTheme.textPrimary)
                                .strikethrough(reminder.isCompleted)
                            
                            HStack(spacing: 6) {
                                Text(LocalizedStringKey(reminder.category.rawValue))
                                Text("•")
                                Text(reminder.frequency)
                            }
                            .font(.caption2)
                            .foregroundColor(AppTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Text(reminder.timeString)
                            .font(.caption.weight(.bold))
                            .foregroundColor(reminder.category.themeColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(reminder.category.themeColor.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .padding(12)
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }
    
    private func categoryFilterChip(title: String, category: CareCategory?) -> some View {
        let isSelected = viewModel.selectedCategory == category
        return Button(action: {
            withAnimation {
                viewModel.selectedCategory = category
            }
        }) {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? AppTheme.primary : AppTheme.cardBackground)
                .foregroundColor(isSelected ? .white : AppTheme.textPrimary)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - 5. Notification Design Previews UI
    private var notificationPreviewsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "app.badge.fill")
                    .foregroundColor(AppTheme.primary)
                Text("Notification Design Preview")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(viewModel.notificationPreviews) { notif in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(notif.category.themeColor.opacity(0.15))
                                .frame(width: 42, height: 42)
                            Text(notif.icon)
                                .font(.title3)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(LocalizedStringKey(notif.title))
                                    .font(.subheadline.weight(.bold))
                                    .foregroundColor(AppTheme.textPrimary)
                                Spacer()
                                Text(notif.timeAgoText)
                                    .font(.caption2)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            
                            Text("\"\(notif.message)\"")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    .padding(14)
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(AppTheme.secondary.opacity(0.15), lineWidth: 1)
                    )
                }
            }
        }
    }
}

#Preview {
    CareView()
}
