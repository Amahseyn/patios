//
//  CareLogHubView.swift
//  CatIos
//

import SwiftUI

enum TaskFrequency: String, CaseIterable, Identifiable, Codable {
    case hourly = "Hourly"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
    case custom = "Custom"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .hourly: return "clock.fill"
        case .daily: return "sun.fill"
        case .weekly: return "calendar"
        case .monthly: return "calendar.circle"
        case .yearly: return "calendar.circle.fill"
        case .custom: return "slider.horizontal.3"
        }
    }
}

enum FrequencyUnit: String, CaseIterable, Identifiable, Codable {
    case hour = "Hour"
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .hour: return "clock"
        case .day: return "sun"
        case .week: return "calendar"
        case .month: return "calendar.circle"
        case .year: return "calendar.circle.fill"
        }
    }
}

enum TaskStatus: String, CaseIterable, Identifiable {
    case all = "All"
    case pending = "To Do"
    case completed = "Completed"
    case overdue = "Overdue"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .all: return "list.bullet"
        case .pending: return "circle"
        case .completed: return "checkmark.circle.fill"
        case .overdue: return "exclamationmark.triangle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .all: return .blue
        case .pending: return .orange
        case .completed: return .green
        case .overdue: return .red
        }
    }
}

struct CustomCareTask: Identifiable {
    let id = UUID()
    var petId: UUID
    var title: String
    var timeText: String
    var frequency: TaskFrequency
    var customInterval: Int = 1
    var customUnit: FrequencyUnit = .day
    var selectedDays: Set<Int> = [1, 2, 3, 4, 5]
    var isCompleted: Bool
    var alarmEnabled: Bool
    var emojiIcon: String
    var completedForPetIds: [UUID] = []
    var startDate: Date
    var completedDateOffset: Int? = nil
    var completedPetDateOffsets: [UUID: Int] = [:]

    var timeComponents: (time: String, period: String)? {
        let parts = timeText.split(separator: " ")
        guard parts.count == 2 else { return nil }
        return (String(parts[0]), String(parts[1]))
    }
}

struct ExpandedTaskItem: Identifiable {
    let id: String
    let task: CustomCareTask
    let displayPetId: UUID?

    init(task: CustomCareTask, displayPetId: UUID?) {
        self.id = "\(task.id)-\(displayPetId?.uuidString ?? "all")"
        self.task = task
        self.displayPetId = displayPetId
    }
}

struct CareLogHubView: View {
    @EnvironmentObject private var petManager: PetManager
    @StateObject private var companionVM = PetCompanionViewModel()

    @State private var selectedPetScopeId: UUID = PetManager.allPetsId
    @State private var selectedDate: Date = Date()
    @State private var selectedDateOffset: Int = 0
    @State private var selectedTaskStatus: TaskStatus = .pending
    @State private var showDatePicker = false
    @State private var showAddPetModal = false

    private var displayedDate: Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: selectedDateOffset, to: today) ?? today
    }

    private var dateRangeOffsets: [Int] {
        Array(-30...30)
    }

    @State private var careTasks: [CustomCareTask] = [
        CustomCareTask(petId: PetProfile.mockLuna.id, title: "Morning Wet Salmon Pouch", timeText: "08:00 AM", frequency: .daily, isCompleted: true, alarmEnabled: true, emojiIcon: "🍗", startDate: Date(), completedDateOffset: 0),
        CustomCareTask(petId: PetProfile.mockLuna.id, title: "Fresh Water Fountain Refill", timeText: "09:00 AM", frequency: .daily, isCompleted: true, alarmEnabled: true, emojiIcon: "💧", startDate: Date(), completedDateOffset: 0),
        CustomCareTask(petId: PetProfile.mockMilo.id, title: "Litter Box Scoop & Clean", timeText: "08:30 AM", frequency: .daily, isCompleted: true, alarmEnabled: true, emojiIcon: "🚽", startDate: Date(), completedDateOffset: 0),
        CustomCareTask(petId: PetProfile.mockMilo.id, title: "Afternoon Insulin / Medicine", timeText: "02:00 PM", frequency: .daily, isCompleted: false, alarmEnabled: true, emojiIcon: "💊", startDate: Date(), completedDateOffset: nil),
        CustomCareTask(petId: PetManager.allPetsId, title: "Evening Crunchy Kibble", timeText: "07:00 PM", frequency: .daily, isCompleted: false, alarmEnabled: true, emojiIcon: "🥣", completedForPetIds: [PetProfile.mockLuna.id], startDate: Date(), completedPetDateOffsets: [PetProfile.mockLuna.id: 0]),
        CustomCareTask(petId: PetManager.allPetsId, title: "Vaccination Booster", timeText: "10:00 AM", frequency: .monthly, customInterval: 1, isCompleted: false, alarmEnabled: true, emojiIcon: "💉", startDate: Date(), completedDateOffset: nil, completedPetDateOffsets: [:]),
        CustomCareTask(petId: PetProfile.mockLuna.id, title: "Warm Sponge Bath & Brush", timeText: "05:00 PM", frequency: .weekly, selectedDays: [2, 4, 6], isCompleted: false, alarmEnabled: true, emojiIcon: "🛁", startDate: Date(), completedDateOffset: nil),
        CustomCareTask(petId: PetProfile.mockMilo.id, title: "Feather Wand Play Session", timeText: "06:30 PM", frequency: .daily, isCompleted: false, alarmEnabled: true, emojiIcon: "🪶", startDate: Date(), completedDateOffset: nil)
    ]

    @State private var showAddTaskSheet = false
    @State private var showEditTaskSheet = false
    @State private var editingTask: CustomCareTask?

    @State private var taskTitle: String = ""
    @State private var taskEmoji: String = "🐾"
    @State private var taskPetScopeId: UUID = PetManager.allPetsId
    @State private var taskTime: Date = Date()
    @State private var taskFrequency: TaskFrequency = .daily
    @State private var taskCustomInterval: Int = 1
    @State private var taskCustomUnit: FrequencyUnit = .day
    @State private var taskSelectedDays: Set<Int> = [2, 3, 4, 5, 6]
    @State private var taskAlarmEnabled: Bool = true

    @State private var completionPetIds: [UUID] = []

    @State private var showPetCompletionPicker = false
    @State private var pendingCompletionTaskId: UUID?
    @State private var pendingCompletionPetIds: [UUID] = []

    var filteredTasks: [CustomCareTask] {
        let calendar = Calendar.current
        let startOfSelectedDate = calendar.startOfDay(for: displayedDate)

        let tasksForDate = careTasks.filter { task in
            let taskStartDay = calendar.startOfDay(for: task.startDate)
            guard displayedDate >= taskStartDay else { return false }

            switch task.frequency {
            case .daily:
                return true
            case .weekly:
                let selectedWeekday = calendar.component(.weekday, from: displayedDate)
                return task.selectedDays.contains(selectedWeekday)
            case .monthly:
                let selectedDay = calendar.component(.day, from: displayedDate)
                let startDay = calendar.component(.day, from: task.startDate)
                return selectedDay == startDay
            case .yearly:
                let selectedMonth = calendar.component(.month, from: displayedDate)
                let startMonth = calendar.component(.month, from: task.startDate)
                let selectedDay = calendar.component(.day, from: displayedDate)
                let startDay = calendar.component(.day, from: task.startDate)
                return selectedMonth == startMonth && selectedDay == startDay
            case .hourly:
                return true
            case .custom:
                let daysBetween = calendar.dateComponents([.day], from: taskStartDay, to: startOfSelectedDate).day ?? 0
                let unitCount: Int
                switch task.customUnit {
                case .hour:
                    let hoursBetween = calendar.dateComponents([.hour], from: task.startDate, to: displayedDate).hour ?? 0
                    unitCount = hoursBetween
                case .day:
                    unitCount = daysBetween
                case .week:
                    unitCount = daysBetween / 7
                case .month:
                    let monthsBetween = calendar.dateComponents([.month], from: task.startDate, to: displayedDate).month ?? 0
                    unitCount = monthsBetween
                case .year:
                    let yearsBetween = calendar.dateComponents([.year], from: task.startDate, to: displayedDate).year ?? 0
                    unitCount = yearsBetween
                }
                return unitCount >= 0 && unitCount % task.customInterval == 0
            }
        }

        if selectedPetScopeId == PetManager.allPetsId {
            if selectedTaskStatus == .overdue {
                return overdueTasks
            }
            var result = tasksForDate
            if selectedTaskStatus != .all {
                result = tasksForDate.filter { task in
                    switch selectedTaskStatus {
                    case .pending:
                        if task.petId == PetManager.allPetsId {
                            return petManager.pets.contains { pet in
                                task.completedPetDateOffsets[pet.id] != selectedDateOffset
                            }
                        }
                        return !task.isCompleted || task.completedDateOffset != selectedDateOffset
                    case .completed:
                        if task.petId == PetManager.allPetsId {
                            return petManager.pets.contains { pet in
                                task.completedPetDateOffsets[pet.id] == selectedDateOffset
                            }
                        }
                        return task.isCompleted && task.completedDateOffset == selectedDateOffset
                    case .overdue:
                        return false
                    case .all:
                        return true
                    }
                }
            }
            return result
        } else {
            if selectedTaskStatus == .overdue {
                return overdueTasks.filter { $0.petId == selectedPetScopeId || $0.petId == PetManager.allPetsId }
            }
            var result = tasksForDate.filter { $0.petId == selectedPetScopeId || $0.petId == PetManager.allPetsId }
            if selectedTaskStatus != .all {
                result = result.filter { task in
                    switch selectedTaskStatus {
                    case .pending:
                        if task.petId == PetManager.allPetsId {
                            return task.completedPetDateOffsets[selectedPetScopeId] != selectedDateOffset
                        }
                        return !task.isCompleted || task.completedDateOffset != selectedDateOffset
                    case .completed:
                        if task.petId == PetManager.allPetsId {
                            return task.completedPetDateOffsets[selectedPetScopeId] == selectedDateOffset
                        }
                        return task.isCompleted && task.completedDateOffset == selectedDateOffset
                    case .overdue:
                        return false
                    case .all:
                        return true
                    }
                }
            }
            return result
        }
    }

    var overdueTasks: [CustomCareTask] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let now = Date()

        let checkDate: Date
        if displayedDate >= today {
            checkDate = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        } else {
            checkDate = displayedDate
        }

        let checkOffset = calendar.dateComponents([.day], from: today, to: checkDate).day ?? 0

        var result = careTasks.filter { task in
            let taskStartDay = calendar.startOfDay(for: task.startDate)
            guard checkDate >= taskStartDay else { return false }
            guard isTask(task, scheduledFor: checkDate) else { return false }

            if task.petId == PetManager.allPetsId {
                let petId = selectedPetScopeId == PetManager.allPetsId ? petManager.currentPet.id : selectedPetScopeId
                return task.completedPetDateOffsets[petId] != checkOffset
            } else {
                return task.completedDateOffset != checkOffset
            }
        }

        if displayedDate >= today {
            let todayOffset = 0
            let nowMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
            var seen = Set(result.map { $0.id })

            let todayPastDue = careTasks.filter { task in
                guard !seen.contains(task.id) else { return false }

                let taskStartDay = calendar.startOfDay(for: task.startDate)
                guard displayedDate >= taskStartDay else { return false }
                guard isTask(task, scheduledFor: displayedDate) else { return false }

                let taskMinutes = timeToMinutes(task.timeText)
                guard nowMinutes > taskMinutes else { return false }

                if task.petId == PetManager.allPetsId {
                    let petId = selectedPetScopeId == PetManager.allPetsId ? petManager.currentPet.id : selectedPetScopeId
                    return task.completedPetDateOffsets[petId] != todayOffset
                } else {
                    return task.completedDateOffset != todayOffset
                }
            }
            result.append(contentsOf: todayPastDue)
        }

        return result
    }

    private func isTask(_ task: CustomCareTask, scheduledFor date: Date) -> Bool {
        let calendar = Calendar.current
        let taskStartDay = calendar.startOfDay(for: task.startDate)
        guard date >= taskStartDay else { return false }

        switch task.frequency {
        case .daily, .hourly:
            return true
        case .weekly:
            let selectedWeekday = calendar.component(.weekday, from: date)
            let startWeekday = calendar.component(.weekday, from: task.startDate)
            return selectedWeekday == startWeekday
        case .monthly:
            let selectedDay = calendar.component(.day, from: date)
            let startDay = calendar.component(.day, from: task.startDate)
            return selectedDay == startDay
        case .yearly:
            let selectedMonth = calendar.component(.month, from: date)
            let startMonth = calendar.component(.month, from: task.startDate)
            let selectedDay = calendar.component(.day, from: date)
            let startDay = calendar.component(.day, from: task.startDate)
            return selectedMonth == startMonth && selectedDay == startDay
        case .custom:
            let daysBetween = calendar.dateComponents([.day], from: taskStartDay, to: date).day ?? 0
            let unitCount: Int
            switch task.customUnit {
            case .hour:
                let hoursBetween = calendar.dateComponents([.hour], from: task.startDate, to: date).hour ?? 0
                unitCount = hoursBetween
            case .day:
                unitCount = daysBetween
            case .week:
                unitCount = daysBetween / 7
            case .month:
                let monthsBetween = calendar.dateComponents([.month], from: task.startDate, to: date).month ?? 0
                unitCount = monthsBetween
            case .year:
                let yearsBetween = calendar.dateComponents([.year], from: task.startDate, to: date).year ?? 0
                unitCount = yearsBetween
            }
            return unitCount >= 0 && unitCount % task.customInterval == 0
        }
    }

    var completedCount: Int {
        expandedTaskItems.filter { item in
            isTaskCompleted(item.task, for: item.displayPetId, at: selectedDateOffset)
        }.count
    }

    var progressRatio: Double {
        guard allTaskCount > 0 else { return 0.0 }
        return Double(completedCount) / Double(allTaskCount)
    }

    var allTaskCount: Int { expandedTaskItems.count }

    var pendingTaskCount: Int {
        expandedTaskItems.filter { item in
            !isTaskCompleted(item.task, for: item.displayPetId, at: selectedDateOffset)
        }.count
    }

    var completedTaskCount: Int {
        expandedTaskItems.filter { item in
            isTaskCompleted(item.task, for: item.displayPetId, at: selectedDateOffset)
        }.count
    }

    var overdueTaskCount: Int {
        expandedTaskItems.filter { item in
            isTaskOverdue(item.task, for: item.displayPetId)
        }.count
    }

    private func isTaskCompleted(_ task: CustomCareTask, for petId: UUID?, at offset: Int) -> Bool {
        if task.petId == PetManager.allPetsId {
            let targetPetId = petId ?? (selectedPetScopeId == PetManager.allPetsId ? petManager.currentPet.id : selectedPetScopeId)
            return task.completedPetDateOffsets[targetPetId] == offset
        }
        return task.isCompleted && task.completedDateOffset == offset
    }

    private func isTaskOverdue(_ task: CustomCareTask, for petId: UUID?) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let now = Date()

        let checkDate: Date
        if displayedDate >= today {
            checkDate = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        } else {
            checkDate = displayedDate
        }

        let checkOffset = calendar.dateComponents([.day], from: today, to: checkDate).day ?? 0
        let taskStartDay = calendar.startOfDay(for: task.startDate)

        if checkDate >= taskStartDay && isTask(task, scheduledFor: checkDate) {
            if task.petId == PetManager.allPetsId {
                let targetPetId = petId ?? (selectedPetScopeId == PetManager.allPetsId ? petManager.currentPet.id : selectedPetScopeId)
                return task.completedPetDateOffsets[targetPetId] != checkOffset
            } else {
                return task.completedDateOffset != checkOffset
            }
        }

        if displayedDate >= today {
            let todayOffset = 0
            let nowMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)

            guard displayedDate >= taskStartDay else { return false }
            guard isTask(task, scheduledFor: displayedDate) else { return false }

            let taskMinutes = timeToMinutes(task.timeText)
            guard nowMinutes > taskMinutes else { return false }

            if task.petId == PetManager.allPetsId {
                let targetPetId = petId ?? (selectedPetScopeId == PetManager.allPetsId ? petManager.currentPet.id : selectedPetScopeId)
                return task.completedPetDateOffsets[targetPetId] != todayOffset
            } else {
                return task.completedDateOffset != todayOffset
            }
        }

        return false
    }

    private func timeToMinutes(_ timeText: String) -> Int {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        guard let date = formatter.date(from: timeText) else { return 0 }
        let calendar = Calendar.current
        return calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
    }

    private var sortedFilteredTasks: [CustomCareTask] {
        filteredTasks.sorted { taskA, taskB in
            let minutesA = timeToMinutes(taskA.timeText)
            let minutesB = timeToMinutes(taskB.timeText)
            return minutesA < minutesB
        }
    }

    private var expandedFilteredTasks: [(task: CustomCareTask, displayPetId: UUID?)] {
        var tasks: [(CustomCareTask, UUID?)] = []
        if selectedPetScopeId == PetManager.allPetsId {
            for task in sortedFilteredTasks {
                if task.petId == PetManager.allPetsId {
                    for pet in petManager.pets {
                        tasks.append((task, pet.id))
                    }
                } else {
                    tasks.append((task, task.petId))
                }
            }
        } else {
            for task in sortedFilteredTasks {
                tasks.append((task, selectedPetScopeId))
            }
        }
        return tasks
    }

    private var expandedTaskItems: [ExpandedTaskItem] {
        expandedFilteredTasks.map { item in
            ExpandedTaskItem(task: item.task, displayPetId: item.displayPetId)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    petScopeSelectorBar

                    dateSwitcherBar

                    taskStatusFilterBar

                    Divider()

                    ScrollView {
                        VStack(spacing: AppTheme.spacingL) {
                            careScopeHeaderCard
                            customTasksListCard
                        }
                        .padding(AppTheme.spacingM)
                        .padding(.bottom, 80)
                    }
                }
                .background(AppTheme.background.ignoresSafeArea())

                Menu {
                    Button {
                        taskPetScopeId = selectedPetScopeId
                        showAddTaskSheet = true
                    } label: {
                        Label("Add Task", systemImage: "checklist")
                    }

                    Button {
                        showAddPetModal = true
                    } label: {
                        Label("Add Pet", systemImage: "plus.circle")
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.accentColor, in: Circle())
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .padding(.trailing, AppTheme.spacingM)
                .padding(.bottom, AppTheme.spacingM)
            }
            .navigationTitle("Tasks & Alarms")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAddTaskSheet) {
                addTaskModalSheet
            }
            .sheet(isPresented: $showEditTaskSheet) {
                editTaskModalSheet
            }
            .sheet(isPresented: $showPetCompletionPicker) {
                petCompletionPickerSheet
            }
            .sheet(isPresented: $showAddPetModal) {
                AddPetModalView()
                    .environmentObject(petManager)
            }
        }
    }

    private var dateSwitcherBar: some View {
        HStack(spacing: 6) {
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    selectedDateOffset -= 1
                }
            } label: {
                dateCard(for: selectedDateOffset - 1)
                    .frame(width: 56, height: 48)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())

            ZStack {
                TabView(selection: $selectedDateOffset) {
                    ForEach(dateRangeOffsets, id: \.self) { offset in
                        dateCard(for: offset)
                            .tag(offset)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(width: 56, height: 52)
                .onChange(of: selectedDateOffset) { _, _ in
                    updateSelectedDateFromOffset()
                }
                .onTapGesture(count: 2) {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        selectedDateOffset = 0
                    }
                }
            }
            .frame(width: 56)

            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    selectedDateOffset += 1
                }
            } label: {
                dateCard(for: selectedDateOffset + 1)
                    .frame(width: 56, height: 48)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())

            Button {
                showDatePicker = true
            } label: {
                Image(systemName: "calendar")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(4)
            }
            .sheet(isPresented: $showDatePicker) {
                datePickerSheet
            }

            Menu {
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        selectedDateOffset -= 1
                    }
                } label: {
                    Label("One Day Before", systemImage: "chevron.left")
                }

                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        selectedDateOffset += 1
                    }
                } label: {
                    Label("One Day After", systemImage: "chevron.right")
                }

                Button {
                    showDatePicker = true
                } label: {
                    Label("Pick Date", systemImage: "calendar")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.primary)
                    .padding(4)
                    .background(AppTheme.primary.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppTheme.cardBackground)
                .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
        )
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    private var taskStatusFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TaskStatus.allCases) { status in
                    let count: Int = {
                        switch status {
                        case .all: return allTaskCount
                        case .pending: return pendingTaskCount
                        case .completed: return completedTaskCount
                        case .overdue: return overdueTaskCount
                        }
                    }()

                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            selectedTaskStatus = status
                        }
                    } label: {
        HStack(spacing: 1) {
                            Image(systemName: status.systemImage)
                                .font(.caption2)
                            Text(status.rawValue)
                                .font(.caption.weight(.bold))
                            Text("\(count)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(selectedTaskStatus == status ? status.tint.opacity(0.9) : AppTheme.textSecondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedTaskStatus == status ? status.tint.opacity(0.15) : AppTheme.cardBackground)
                        .foregroundStyle(selectedTaskStatus == status ? status.tint : AppTheme.textPrimary)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(status.tint.opacity(selectedTaskStatus == status ? 0.4 : 0), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private func updateSelectedDateFromOffset() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        selectedDate = calendar.date(byAdding: .day, value: selectedDateOffset, to: today) ?? today
    }

    private func dateCard(for offset: Int) -> some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let date = calendar.date(byAdding: .day, value: offset, to: today) ?? today
        let isToday = offset == 0
        let isSelected = offset == selectedDateOffset
        let weekday = calendar.weekdaySymbols[calendar.component(.weekday, from: date) - 1]
        let dayNumber = calendar.component(.day, from: date)
        let month = calendar.monthSymbols[calendar.component(.month, from: date) - 1]

        return VStack(spacing: 2) {
            Text(weekday)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(isSelected ? .white : AppTheme.textSecondary)
                .lineLimit(1)

            Text("\(dayNumber)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? .white : AppTheme.textPrimary)

            Text(month)
                .font(.caption2)
                .foregroundStyle(isSelected ? .white.opacity(0.85) : AppTheme.textSecondary)
                .lineLimit(1)
        }
        .frame(width: 56, height: 48)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? AppTheme.primary : (isToday ? AppTheme.primary.opacity(0.12) : .clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isToday && !isSelected ? AppTheme.primary.opacity(0.6) : .clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
    }

    private func dateLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d")
        return formatter.string(from: date)
    }

    private var datePickerSheet: some View {
        NavigationStack {
            Form {
                Section("Select Date") {
                    DatePicker("Date", selection: Binding(
                        get: { displayedDate },
                        set: { newDate in
                            let calendar = Calendar.current
                            let today = calendar.startOfDay(for: Date())
                            let newDay = calendar.startOfDay(for: newDate)
                            if let offset = calendar.dateComponents([.day], from: today, to: newDay).day {
                                selectedDateOffset = offset
                            }
                        }
                    ), displayedComponents: .date)
                }
            }
            .navigationTitle("Pick Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showDatePicker = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showDatePicker = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var petScopeSelectorBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    withAnimation {
                        selectedPetScopeId = PetManager.allPetsId
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("🐾")
                        Text("All Pets")
                    }
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(selectedPetScopeId == PetManager.allPetsId ? AppTheme.primary : AppTheme.cardBackground)
                    .foregroundStyle(selectedPetScopeId == PetManager.allPetsId ? .white : AppTheme.textPrimary)
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                }

                ForEach(petManager.pets) { pet in
                    Button {
                        withAnimation {
                            selectedPetScopeId = pet.id
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(pet.avatarEmoji)
                            Text(pet.name)
                        }
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(selectedPetScopeId == pet.id ? Color(hex: pet.petColorHex) : AppTheme.cardBackground)
                        .foregroundStyle(selectedPetScopeId == pet.id ? .white : AppTheme.textPrimary)
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private var careScopeHeaderCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(statusTitle)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Text("\(displayedTaskCount) Tasks")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(AppTheme.primary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppTheme.primary.opacity(0.15))
                        .frame(height: 8)
                    Capsule()
                        .fill(LinearGradient(colors: [AppTheme.primary, Color.green], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(progressRatio), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(AppTheme.spacingM)
        .cardStyle()
    }

    private var displayedTaskCount: Int {
        switch selectedTaskStatus {
        case .all: return allTaskCount
        case .pending: return pendingTaskCount
        case .completed: return completedTaskCount
        case .overdue: return overdueTaskCount
        }
    }

    private var statusTitle: String {
        switch selectedTaskStatus {
        case .all:
            return "\(dateLabel(for: displayedDate)) Care Completion"
        case .pending:
            return "Pending Tasks"
        case .completed:
            return "Completed Tasks"
        case .overdue:
            return "Overdue Tasks ⚠️"
        }
    }

    private var customTasksListCard: some View {
    VStack(alignment: .leading, spacing: 12) {
        HStack {
            Text(statusTitle)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)
            Spacer()
            Text("\(displayedTaskCount) Tasks")
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
        }

        if selectedTaskStatus != .overdue && !overdueTasks.isEmpty {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
                    .foregroundStyle(.white)
                Text("\(overdueTasks.count) Overdue Task(s)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
                Button("View") {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        selectedTaskStatus = .overdue
                    }
                }
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.8))
                .clipShape(Capsule())
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red.opacity(0.9))
            )
        }

        if filteredTasks.isEmpty {
            VStack(spacing: 8) {
                Text(emptyStateText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(emptyStateSubtext)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .cardStyle()
        } else {
            ForEach(expandedTaskItems) { item in
                let currentTask = item.task
                TaskRowView(
                    task: currentTask,
                    petManager: petManager,
                    selectedDateOffset: selectedDateOffset,
                    selectedPetScopeId: selectedPetScopeId,
                    displayPetId: item.displayPetId,
                        onToggleComplete: {
                            if let idx = careTasks.firstIndex(where: { $0.id == currentTask.id }) {
                                let petId = item.displayPetId ?? (selectedPetScopeId == PetManager.allPetsId ? petManager.currentPet.id : selectedPetScopeId)
                                withAnimation {
                                    var updatedTasks = careTasks
                                    if currentTask.petId == PetManager.allPetsId {
                                        if updatedTasks[idx].completedPetDateOffsets[petId] == selectedDateOffset {
                                            updatedTasks[idx].completedPetDateOffsets.removeValue(forKey: petId)
                                        } else {
                                            updatedTasks[idx].completedPetDateOffsets[petId] = selectedDateOffset
                                        }
                                    } else {
                                        if updatedTasks[idx].isCompleted && updatedTasks[idx].completedDateOffset == selectedDateOffset {
                                            updatedTasks[idx].isCompleted = false
                                            updatedTasks[idx].completedDateOffset = nil
                                        } else {
                                            updatedTasks[idx].isCompleted = true
                                            updatedTasks[idx].completedDateOffset = selectedDateOffset
                                        }
                                    }
                                    careTasks = updatedTasks
                                }
                            }
                        },
                    onToggleAlarm: {
                        if let idx = careTasks.firstIndex(where: { $0.id == currentTask.id }) {
                            withAnimation {
                                var updatedTasks = careTasks
                                updatedTasks[idx].alarmEnabled.toggle()
                                careTasks = updatedTasks
                            }
                        }
                    },
                    onDelete: {
                        withAnimation {
                            careTasks.removeAll(where: { $0.id == currentTask.id })
                        }
                    },
                    onEdit: {
                        editingTask = currentTask
                        taskTitle = currentTask.title
                        taskEmoji = currentTask.emojiIcon
                        taskPetScopeId = currentTask.petId
                        taskTime = parseTime(currentTask.timeText)
                        taskFrequency = currentTask.frequency
                        taskCustomInterval = currentTask.customInterval
                        taskCustomUnit = currentTask.customUnit
                        taskSelectedDays = currentTask.selectedDays
                        taskAlarmEnabled = currentTask.alarmEnabled
                        completionPetIds = currentTask.completedForPetIds
                        showEditTaskSheet = true
                    }
                )
            }
        }
    }
    .padding(AppTheme.spacingM)  // This padding + cardStyle gives the card its size
    .cardStyle()  // This applies the card appearance
}
    private var emptyStateText: String {
        switch selectedTaskStatus {
        case .all:
            return "No care tasks defined for this date."
        case .pending:
            return "No pending tasks."
        case .completed:
            return "No completed tasks yet."
        case .overdue:
            return "No overdue tasks! Great job!"
        }
    }

    private var emptyStateSubtext: String {
        switch selectedTaskStatus {
        case .all:
            return "Tap 'Add Task' to create custom feeding, grooming, medicine or playtime schedules!"
        case .pending:
            return "All tasks are completed for this date."
        case .completed:
            return "Complete some tasks to see them here."
        case .overdue:
            return "You're staying on top of everything."
        }
    }

    private func parseTime(_ timeText: String) -> Date {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        if let date = formatter.date(from: timeText) {
            return date
        }
        return Date()
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private var addTaskModalSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task Name (e.g. Salmon Meal, Medication)", text: $taskTitle)

                    Picker("Emoji Icon", selection: $taskEmoji) {
                        Text("🍗 Meal / Food").tag("🍗")
                        Text("💧 Water Refill").tag("💧")
                        Text("🚽 Litter Box").tag("🚽")
                        Text("💊 Medicine / Drops").tag("💊")
                        Text("🛁 Grooming / Bath").tag("🛁")
                        Text("🎾 Play & Exercise").tag("🎾")
                        Text("🧠 Behavioral Check").tag("🧠")
                        Text("🐾 General Care").tag("🐾")
                    }

                    Picker("Target Pet Scope", selection: $taskPetScopeId) {
                        Text("🐾 All Pets").tag(PetManager.allPetsId)
                        ForEach(petManager.pets) { pet in
                            Text("\(pet.avatarEmoji) \(pet.name)").tag(pet.id)
                        }
                    }
                }

                Section(header: Text("Alarm Time & Frequency")) {
                    DatePicker("Alarm Clock Time", selection: $taskTime, displayedComponents: .hourAndMinute)

                    Picker("Frequency", selection: $taskFrequency) {
                        ForEach(TaskFrequency.allCases) { freq in
                            Label(freq.rawValue, systemImage: freq.systemImage)
                                .tag(freq)
                        }
                    }

                    if taskFrequency == .custom {
                        Picker("Unit", selection: $taskCustomUnit) {
                            ForEach(FrequencyUnit.allCases) { unit in
                                Label(unit.rawValue, systemImage: unit.systemImage)
                                    .tag(unit)
                            }
                        }

                        Stepper(value: $taskCustomInterval, in: 1...365) {
                            Text("Every \(taskCustomInterval) \(taskCustomUnit.rawValue.lowercased())\(taskCustomInterval == 1 ? "" : "s")")
                        }
                    }

                    if taskFrequency == .weekly {
                        weekdayPicker(selectedDays: $taskSelectedDays)
                    }

                    Toggle("Enable Sound & Push Alarm ⏰", isOn: $taskAlarmEnabled)
                }
            }
            .navigationTitle("Define Custom Care Task 🐾")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddTaskSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Task") {
                        let newTask = CustomCareTask(
                            petId: taskPetScopeId,
                            title: taskTitle.isEmpty ? "Custom Care Task" : taskTitle,
                            timeText: formatTime(taskTime),
                            frequency: taskFrequency,
                            customInterval: taskCustomInterval,
                            customUnit: taskCustomUnit,
                            selectedDays: taskSelectedDays,
                            isCompleted: false,
                            alarmEnabled: taskAlarmEnabled,
                            emojiIcon: taskEmoji,
                            startDate: Date(),
                            completedDateOffset: nil,
                            completedPetDateOffsets: [:]
                        )

                        withAnimation {
                            careTasks.insert(newTask, at: 0)
                        }
                        showAddTaskSheet = false
                        taskTitle = ""
                    }
                    .bold()
                }
            }
        }
    }

    private var editTaskModalSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task Name", text: $taskTitle)

                    Picker("Emoji Icon", selection: $taskEmoji) {
                        Text("🍗 Meal / Food").tag("🍗")
                        Text("💧 Water Refill").tag("💧")
                        Text("🚽 Litter Box").tag("🚽")
                        Text("💊 Medicine / Drops").tag("💊")
                        Text("🛁 Grooming / Bath").tag("🛁")
                        Text("🎾 Play & Exercise").tag("🎾")
                        Text("🧠 Behavioral Check").tag("🧠")
                        Text("🐾 General Care").tag("🐾")
                    }

                    Picker("Target Pet Scope", selection: $taskPetScopeId) {
                        Text("🐾 All Pets").tag(PetManager.allPetsId)
                        ForEach(petManager.pets) { pet in
                            Text("\(pet.avatarEmoji) \(pet.name)").tag(pet.id)
                        }
                    }
                }

                Section(header: Text("Alarm Time & Frequency")) {
                    DatePicker("Alarm Clock Time", selection: $taskTime, displayedComponents: .hourAndMinute)

                    Picker("Frequency", selection: $taskFrequency) {
                        ForEach(TaskFrequency.allCases) { freq in
                            Label(freq.rawValue, systemImage: freq.systemImage)
                                .tag(freq)
                        }
                    }

                    if taskFrequency == .custom {
                        Picker("Unit", selection: $taskCustomUnit) {
                            ForEach(FrequencyUnit.allCases) { unit in
                                Label(unit.rawValue, systemImage: unit.systemImage)
                                    .tag(unit)
                            }
                        }

                        Stepper(value: $taskCustomInterval, in: 1...365) {
                            Text("Every \(taskCustomInterval) \(taskCustomUnit.rawValue.lowercased())\(taskCustomInterval == 1 ? "" : "s")")
                        }
                    }

                    if taskFrequency == .weekly {
                        weekdayPicker(selectedDays: $taskSelectedDays)
                    }

                    Toggle("Enable Sound & Push Alarm ⏰", isOn: $taskAlarmEnabled)
                }
            }
            .navigationTitle("Edit Care Task 🐾")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showEditTaskSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Update Task") {
                        guard let task = editingTask,
                              let idx = careTasks.firstIndex(where: { $0.id == task.id }) else { return }

                        careTasks[idx] = CustomCareTask(
                            petId: taskPetScopeId,
                            title: taskTitle.isEmpty ? "Custom Care Task" : taskTitle,
                            timeText: formatTime(taskTime),
                            frequency: taskFrequency,
                            customInterval: taskCustomInterval,
                            customUnit: taskCustomUnit,
                            selectedDays: taskSelectedDays,
                            isCompleted: careTasks[idx].isCompleted,
                            alarmEnabled: taskAlarmEnabled,
                            emojiIcon: taskEmoji,
                            completedForPetIds: careTasks[idx].completedForPetIds,
                            startDate: careTasks[idx].startDate,
                            completedDateOffset: careTasks[idx].completedDateOffset,
                            completedPetDateOffsets: careTasks[idx].completedPetDateOffsets
                        )
                        showEditTaskSheet = false
                        taskTitle = ""
                    }
                    .bold()
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var petCompletionPickerSheet: some View {
        NavigationStack {
            Form {
                Section("Select Pets") {
                    ForEach(petManager.pets) { pet in
                        Toggle(isOn: Binding(
                            get: { pendingCompletionPetIds.contains(pet.id) },
                            set: { newValue in
                                if newValue {
                                    if !pendingCompletionPetIds.contains(pet.id) {
                                        pendingCompletionPetIds.append(pet.id)
                                    }
                                } else {
                                    pendingCompletionPetIds.removeAll { $0 == pet.id }
                                }
                            }
                        )) {
        HStack(spacing: -6) {
                                Text(pet.avatarEmoji)
                                    .font(.title3)
                                Text(pet.name)
                                    .font(.body)
                            }
                        }
                    }
                }

                Section {
                    Button("Done") {
                        if let taskId = pendingCompletionTaskId,
                           let idx = careTasks.firstIndex(where: { $0.id == taskId }) {
                            withAnimation {
                                var updatedTasks = careTasks
                                if pendingCompletionPetIds.isEmpty {
                                    updatedTasks[idx].completedPetDateOffsets.removeAll()
                                } else {
                                    for petId in pendingCompletionPetIds {
                                        updatedTasks[idx].completedPetDateOffsets[petId] = selectedDateOffset
                                    }
                                }
                                careTasks = updatedTasks
                            }
                        }
                        showPetCompletionPicker = false
                        pendingCompletionTaskId = nil
                        pendingCompletionPetIds = []
                    }
                    .frame(maxWidth: .infinity)
                    .font(.body.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.vertical, 12)
                    .background(AppTheme.primary)
                    .clipShape(Capsule())
                }
            }
            .navigationTitle("Complete For Pets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showPetCompletionPicker = false
                        pendingCompletionTaskId = nil
                        pendingCompletionPetIds = []
                    }
                }
            }
        }
        .presentationDetents([.medium])
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

struct TaskRowView: View {
    let task: CustomCareTask
    let petManager: PetManager
    let selectedDateOffset: Int
    let selectedPetScopeId: UUID
    let displayPetId: UUID?
    let onToggleComplete: () -> Void
    let onToggleAlarm: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void

    var isCurrentPetCompleted: Bool {
        if task.petId == PetManager.allPetsId {
            let targetPetId = displayPetId ?? (selectedPetScopeId == PetManager.allPetsId ? petManager.currentPet.id : selectedPetScopeId)
            return task.completedPetDateOffsets[targetPetId] == selectedDateOffset
        }
        return task.isCompleted && task.completedDateOffset == selectedDateOffset
    }

    private var taskPetColor: Color {
        if task.petId == PetManager.allPetsId {
            if let displayPetId = displayPetId, let p = petManager.pets.first(where: { $0.id == displayPetId }) {
                return Color(hex: p.petColorHex)
            }
            if selectedPetScopeId != PetManager.allPetsId, let p = petManager.pets.first(where: { $0.id == selectedPetScopeId }) {
                return Color(hex: p.petColorHex)
            }
            return AppTheme.primary
        }
        if let p = petManager.pets.first(where: { $0.id == task.petId }) {
            return Color(hex: p.petColorHex)
        }
        return AppTheme.primary
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button(action: onToggleComplete) {
                    Image(systemName: isCurrentPetCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isCurrentPetCompleted ? .green : taskPetColor)
                        .frame(width: 24, height: 24)
                }

                Text(task.emojiIcon)
                    .font(.title3)

                Text(task.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isCurrentPetCompleted ? AppTheme.textSecondary : AppTheme.textPrimary)
                    .strikethrough(isCurrentPetCompleted)

                Spacer()

                HStack(spacing: 14) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSecondary)
                            .padding(4)
                    }

                    Button(action: onToggleAlarm) {
                        Image(systemName: task.alarmEnabled ? "bell.fill" : "bell.slash")
                            .font(.caption2)
                            .foregroundStyle(task.alarmEnabled ? AppTheme.textSecondary : AppTheme.textSecondary.opacity(0.6))
                            .padding(4)
                    }

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSecondary.opacity(0.8))
                            .padding(4)
                    }
                }
            }
            .padding(.top, 10)
            .padding(.horizontal, 12)

            HStack(spacing: 6) {
                Image(systemName: task.frequency.systemImage)
                    .font(.caption2)
                    .foregroundStyle(taskPetColor)
                if let components = task.timeComponents {
                    Text(components.time)
                        .font(.caption.weight(.bold))
                    Text(components.period)
                        .font(.caption2)
                        .foregroundStyle(taskPetColor.opacity(0.8))
                } else {
                    Text(task.timeText)
                        .font(.caption.weight(.bold))
                }
                Text("•")
                Text(frequencyLabel(for: task))
                    .font(.caption2)
            }
            .foregroundStyle(taskPetColor)
            .padding(.bottom, 10)
            .padding(.leading, 48)
            .padding(.trailing, 12)
        }
        .frame(height: 72)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                .fill(taskPetColor.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                .stroke(taskPetColor.opacity(0.15), lineWidth: 1)
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)

            Button {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
                onToggleComplete()
            } label: {
                Label(isCurrentPetCompleted ? "Mark Undone" : "Mark Done", systemImage: isCurrentPetCompleted ? "circle" : "checkmark.circle.fill")
            }
            .tint(.green)
        }
    }

    private func frequencyLabel(for task: CustomCareTask) -> String {
        switch task.frequency {
        case .hourly:
            return task.customInterval == 1 ? "Every Hour" : "Every \(task.customInterval) Hours"
        case .daily:
            return "Every Day"
        case .weekly:
            return "Every Week"
        case .monthly:
            return task.customInterval == 1 ? "Every Month" : "Every \(task.customInterval) Months"
        case .yearly:
            return task.customInterval == 1 ? "Every Year" : "Every \(task.customInterval) Years"
        case .custom:
            let unit = task.customUnit.rawValue.lowercased()
            return task.customInterval == 1 ? "Every \(unit)" : "Every \(task.customInterval) \(unit)s"
        }
    }

}

#Preview {
    CareLogHubView()
        .environmentObject(PetManager.shared)
}
