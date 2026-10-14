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

enum CareTaskKind: String, CaseIterable, Identifiable, Codable {
    case feeding = "Feeding"
    case medication = "Medication"
    case walking = "Walking"
    case park = "Park visit"
    case training = "Training"
    case grooming = "Grooming"
    case weight = "Weight tracking"
    case vet = "Vet appointment"
    case custom = "Custom"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .feeding: return "fork.knife"
        case .medication: return "pills"
        case .walking: return "figure.walk"
        case .park: return "tree"
        case .training: return "graduationcap"
        case .grooming: return "comb"
        case .weight: return "scalemass"
        case .vet: return "cross.case"
        case .custom: return "checkmark.circle"
        }
    }
}

struct TaskOccurrence: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var status: String
    var occurredAt: Date
    var petId: UUID?
    var amountGrams: Double?
    var calories: Double?
    var foodName: String?
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
        case .all: return AppTheme.sky
        case .pending: return AppTheme.honey
        case .completed: return AppTheme.meadow
        case .overdue: return AppTheme.coral
        }
    }
}

struct CustomCareTask: Identifiable {
    var id: UUID = UUID()
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
    var taskKind: CareTaskKind = .custom
    var snoozedUntil: Date?
    var occurrenceLog: [TaskOccurrence] = []

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
    @EnvironmentObject private var taskStore: CareTaskStore
    @EnvironmentObject private var householdSync: HouseholdSync
    @EnvironmentObject private var wellness: WellnessStore
    @EnvironmentObject private var auth: AuthSession

    @State private var selectedPetScopeId: UUID = PetManager.allPetsId
    @State private var selectedDateOffset: Int = 0
    @State private var selectedTaskStatus: TaskStatus = .pending

    private var displayedDate: Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: selectedDateOffset, to: today) ?? today
    }

    @State private var showAddTaskSheet = false
    @State private var showAddPetModal = false
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
    @State private var taskKind: CareTaskKind = .custom

    @State private var completionPetIds: [UUID] = []

    @State private var showPetCompletionPicker = false
    @State private var pendingCompletionTaskId: UUID?
    @State private var pendingCompletionPetIds: [UUID] = []
    @State private var showMealLogSheet = false
    @State private var pendingFeedingTask: CustomCareTask?
    @State private var pendingFeedingPetId: UUID?
    @State private var showBlueprintManager = false
    @State private var saveAsBlueprint = false
    @State private var selectedBlueprintId: UUID?

    var filteredTasks: [CustomCareTask] {
        let tasksForDate = taskStore.tasks.filter { task in
            CareSchedule.occurs(task, on: displayedDate)
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

        var result = taskStore.tasks.filter { task in
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

            let todayPastDue = taskStore.tasks.filter { task in
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
        CareSchedule.occurs(task, on: date)
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
        CareSchedule.minutes(from: timeText)
    }

    private var dayTaskItems: [(CustomCareTask, UUID?)] {
        let tasks = taskStore.tasks
            .filter { task in
                CareSchedule.occurs(task, on: displayedDate)
                    && (selectedPetScopeId == PetManager.allPetsId || task.petId == selectedPetScopeId || task.petId == PetManager.allPetsId)
            }
            .sorted { timeToMinutes($0.timeText) < timeToMinutes($1.timeText) }
        var rows: [(CustomCareTask, UUID?)] = []
        if selectedPetScopeId == PetManager.allPetsId {
            for task in tasks {
                if task.petId == PetManager.allPetsId {
                    for pet in petManager.pets {
                        rows.append((task, pet.id))
                    }
                } else {
                    rows.append((task, task.petId))
                }
            }
        } else {
            for task in tasks {
                rows.append((task, selectedPetScopeId))
            }
        }
        return rows
    }

    private var dayCompletedCount: Int {
        dayTaskItems.filter { isTaskCompleted($0.0, for: $0.1, at: selectedDateOffset) }.count
    }

    private var dayProgress: Double {
        guard !dayTaskItems.isEmpty else { return 0 }
        return Double(dayCompletedCount) / Double(dayTaskItems.count)
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
            List {
                if householdSync.lastError != nil {
                    Section {
                        SyncStatusBanner()
                        Button("Try Again") {
                            Task { await householdSync.pushNow() }
                        }
                    }
                }

                Section {
                    DayStrip(selectedDateOffset: $selectedDateOffset, summary: daySummary(offset:))
                    PetScopePicker(selection: $selectedPetScopeId, pets: petManager.pets)
                    Picker("Status", selection: $selectedTaskStatus) {
                        ForEach(TaskStatus.allCases) { status in
                            Text(LocalizedStringKey(status.rawValue)).tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
                } footer: {
                    Text("\(displayedTaskCount) \(statusTitle.lowercased()). Tap a task to mark it done.")
                }

                Section {
                    CareSummaryCard(
                        headline: careSummaryHeadline,
                        detail: careSummaryDetail,
                        remaining: max(0, dayTaskItems.count - dayCompletedCount),
                        overdue: overdueTasks.count,
                        progress: dayProgress,
                        total: dayTaskItems.count
                    )
                }

                if !taskStore.templates.isEmpty {
                    Section {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppTheme.spacingS) {
                                ForEach(taskStore.templates) { template in
                                    TaskBlueprintChip(template: template) {
                                        guard householdSync.canMutate else { return }
                                        addTasks(from: template)
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    } header: {
                        HStack {
                            Text("Saved templates")
                            Spacer()
                            Button("Manage") { showBlueprintManager = true }
                                .font(AppTheme.captionFont().weight(.semibold))
                        }
                    } footer: {
                        Text("Tap a template to add that task without retyping.")
                    }
                }

                if selectedTaskStatus != .overdue && !overdueTasks.isEmpty {
                    Section {
                        Button {
                            selectedTaskStatus = .overdue
                        } label: {
                            Label("\(overdueTasks.count) overdue — review these first", systemImage: "exclamationmark.triangle.fill")
                        }
                        .foregroundStyle(AppTheme.danger)
                    }
                }

                Section {
                    if filteredTasks.isEmpty {
                        EmptyStateView(
                            systemImage: selectedTaskStatus == .overdue ? "checkmark.seal.fill" : "checklist",
                            title: emptyStateText,
                            message: emptyStateSubtext,
                            actionTitle: selectedTaskStatus == .pending && householdSync.canMutate ? "Add Task" : nil,
                            action: selectedTaskStatus == .pending && householdSync.canMutate ? { showAddTaskSheet = true } : nil
                        )
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                    } else {
                        ForEach(expandedTaskItems) { item in
                            let currentTask = item.task
                            TaskRowView(
                                task: currentTask,
                                petManager: petManager,
                                selectedDateOffset: selectedDateOffset,
                                selectedPetScopeId: selectedPetScopeId,
                                displayPetId: item.displayPetId,
                                mealSummary: mealSummary(for: currentTask, petId: item.displayPetId),
                                isOverdue: isTaskOverdue(currentTask, for: item.displayPetId),
                                onToggleComplete: {
                                    let petId = item.displayPetId ?? (selectedPetScopeId == PetManager.allPetsId ? petManager.currentPet.id : selectedPetScopeId)
                                    handleToggleComplete(task: currentTask, petId: petId)
                                },
                                onToggleAlarm: {
                                    if let idx = taskStore.tasks.firstIndex(where: { $0.id == currentTask.id }) {
                                        withAnimation {
                                            var updatedTasks = taskStore.tasks
                                            updatedTasks[idx].alarmEnabled.toggle()
                                            taskStore.tasks = updatedTasks
                                        }
                                    }
                                },
                                canChange: householdSync.canMutate,
                                onDelete: {
                                    withAnimation {
                                        taskStore.tasks.removeAll(where: { $0.id == currentTask.id })
                                    }
                                },
                                onSnooze: {
                                    if let idx = taskStore.tasks.firstIndex(where: { $0.id == currentTask.id }) {
                                        var updatedTasks = taskStore.tasks
                                        updatedTasks[idx].snoozedUntil = Date().addingTimeInterval(60 * 60)
                                        updatedTasks[idx].occurrenceLog.append(
                                            TaskOccurrence(status: "snoozed", occurredAt: Date(), petId: currentTask.petId)
                                        )
                                        taskStore.tasks = updatedTasks
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
                                    taskKind = currentTask.taskKind
                                    completionPetIds = currentTask.completedForPetIds
                                    showEditTaskSheet = true
                                }
                            )
                        }
                    }
                }
            }
            .refreshable {
                await householdSync.pullNow()
            }
            .fantasyScreen()
            .fantasyNavigation()
            .navigationTitle("Today")
            .toolbar {
                if householdSync.canMutate {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Add Task", systemImage: "checklist") {
                            resetTaskForm()
                            taskPetScopeId = selectedPetScopeId
                            showAddTaskSheet = true
                        }
                        Button("Task templates", systemImage: "bookmark.fill") {
                            showBlueprintManager = true
                        }
                        Button("Add Pet", systemImage: "pawprint") {
                            showAddPetModal = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add")
                }
                }
            }
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
            .sheet(isPresented: $showBlueprintManager) {
                TaskBlueprintManagerView()
                    .environmentObject(taskStore)
                    .environmentObject(petManager)
                    .environmentObject(householdSync)
            }
            .sheet(isPresented: $showMealLogSheet, onDismiss: {
                pendingFeedingTask = nil
                pendingFeedingPetId = nil
            }) {
                MealLogSheet(
                    petId: pendingFeedingPetId,
                    title: pendingFeedingTask.map { "Log \($0.title)" } ?? "Log Meal",
                    when: displayedDate
                ) { entry in
                    completeFeedingTask(with: entry)
                }
                .environmentObject(wellness)
                .environmentObject(petManager)
                .environmentObject(auth)
            }
        }
    }

    private func handleToggleComplete(task: CustomCareTask, petId: UUID) {
        let alreadyCompleted = isTaskCompleted(task, for: petId, at: selectedDateOffset)

        if task.taskKind == .feeding && !alreadyCompleted {
            pendingFeedingTask = task
            pendingFeedingPetId = petId
            showMealLogSheet = true
            return
        }

        guard let idx = taskStore.tasks.firstIndex(where: { $0.id == task.id }) else { return }

        withAnimation {
            var updatedTasks = taskStore.tasks
            if task.petId == PetManager.allPetsId {
                if updatedTasks[idx].completedPetDateOffsets[petId] == selectedDateOffset {
                    updatedTasks[idx].completedPetDateOffsets.removeValue(forKey: petId)
                } else {
                    updatedTasks[idx].completedPetDateOffsets[petId] = selectedDateOffset
                }
            } else if updatedTasks[idx].isCompleted && updatedTasks[idx].completedDateOffset == selectedDateOffset {
                updatedTasks[idx].isCompleted = false
                updatedTasks[idx].completedDateOffset = nil
            } else {
                updatedTasks[idx].isCompleted = true
                updatedTasks[idx].completedDateOffset = selectedDateOffset
                if task.taskKind != .feeding {
                    updatedTasks[idx].occurrenceLog.append(
                        TaskOccurrence(status: "completed", occurredAt: displayedDate, petId: task.petId)
                    )
                }
            }
            taskStore.tasks = updatedTasks
        }
    }

    private func completeFeedingTask(with entry: FeedingEntry) {
        wellness.feedings.insert(entry, at: 0)

        guard let task = pendingFeedingTask,
              let petId = pendingFeedingPetId,
              let idx = taskStore.tasks.firstIndex(where: { $0.id == task.id }) else { return }

        withAnimation {
            var updatedTasks = taskStore.tasks
            if task.petId == PetManager.allPetsId {
                updatedTasks[idx].completedPetDateOffsets[petId] = selectedDateOffset
            } else {
                updatedTasks[idx].isCompleted = true
                updatedTasks[idx].completedDateOffset = selectedDateOffset
            }
            updatedTasks[idx].occurrenceLog.append(
                TaskOccurrence(
                    status: "completed",
                    occurredAt: entry.fedAt,
                    petId: petId,
                    amountGrams: entry.amountGrams,
                    calories: entry.calories,
                    foodName: entry.foodName
                )
            )
            taskStore.tasks = updatedTasks
        }

        pendingFeedingTask = nil
        pendingFeedingPetId = nil
    }

    private func mealSummary(for task: CustomCareTask, petId: UUID?) -> String? {
        guard task.taskKind == .feeding,
              isTaskCompleted(task, for: petId, at: selectedDateOffset) else { return nil }

        let calendar = Calendar.current
        if let occurrence = task.occurrenceLog.last(where: { occurrence in
            occurrence.status == "completed"
                && calendar.isDate(occurrence.occurredAt, inSameDayAs: displayedDate)
                && (occurrence.petId == nil || occurrence.petId == petId)
                && occurrence.amountGrams != nil
                && occurrence.calories != nil
        }), let grams = occurrence.amountGrams, let calories = occurrence.calories {
            let food = occurrence.foodName ?? "Meal"
            return "\(food) · \(MeasureText.mass(grams: grams)) · \(MeasureText.calories(calories))"
        }

        let targetPetId = petId ?? (selectedPetScopeId == PetManager.allPetsId ? petManager.currentPet.id : selectedPetScopeId)
        if let feeding = wellness.feedings.first(where: { entry in
            entry.petId == targetPetId && calendar.isDate(entry.fedAt, inSameDayAs: displayedDate)
        }), let calories = feeding.calories {
            return "\(feeding.foodName) · \(MeasureText.mass(grams: feeding.amountGrams)) · \(MeasureText.calories(calories))"
        }

        return nil
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
            return "\(dateLabel(for: displayedDate)) · all tasks"
        case .pending:
            return "to do"
        case .completed:
            return "completed"
        case .overdue:
            return "overdue"
        }
    }

    private func daySummary(offset: Int) -> (total: Int, done: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { return (0, 0) }
        let tasks = taskStore.tasks.filter { task in
            let inScope = selectedPetScopeId == PetManager.allPetsId
                || task.petId == selectedPetScopeId
                || task.petId == PetManager.allPetsId
            return inScope && CareSchedule.occurs(task, on: date)
        }
        let done = tasks.filter { task in
            if task.petId == PetManager.allPetsId {
                if selectedPetScopeId == PetManager.allPetsId {
                    guard !petManager.pets.isEmpty else { return false }
                    return petManager.pets.allSatisfy { task.completedPetDateOffsets[$0.id] == offset }
                }
                return task.completedPetDateOffsets[selectedPetScopeId] == offset
            }
            return task.isCompleted && task.completedDateOffset == offset
        }.count
        return (tasks.count, done)
    }

    private func dateLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d")
        return formatter.string(from: date)
    }

    private var nextPendingTitle: String? {
        expandedTaskItems.first { item in
            !isTaskCompleted(item.task, for: item.displayPetId, at: selectedDateOffset)
        }?.task.title
    }

    private var careSummaryHeadline: String {
        if overdueTasks.count > 0 {
            return overdueTasks.count == 1 ? "1 task is overdue" : "\(overdueTasks.count) tasks are overdue"
        }
        if dayTaskItems.isEmpty {
            return "Nothing scheduled"
        }
        if dayCompletedCount == dayTaskItems.count {
            return "All done for this day"
        }
        if let next = nextPendingTitle {
            return "Next: \(next)"
        }
        return "\(dayTaskItems.count - dayCompletedCount) remaining"
    }

    private var careSummaryDetail: String {
        if overdueTasks.count > 0 {
            return "Finish overdue care first, then continue with the rest of the day."
        }
        if dayTaskItems.isEmpty {
            return "Add feeding, medication, walks, or appointments for this day."
        }
        if dayCompletedCount == dayTaskItems.count {
            return "Every scheduled task is complete."
        }
        return "\(dayCompletedCount) of \(dayTaskItems.count) complete. Tap a row to mark it done."
    }

    private var emptyStateText: String {
        switch selectedTaskStatus {
        case .all:
            return "Nothing scheduled"
        case .pending:
            return "You're all caught up"
        case .completed:
            return "No completed tasks yet"
        case .overdue:
            return "Nothing overdue"
        }
    }

    private var emptyStateSubtext: String {
        switch selectedTaskStatus {
        case .all:
            return "Add feeding, medication, walks, grooming, or a vet visit for this day."
        case .pending:
            return "Every scheduled task for this day is done."
        case .completed:
            return "Completed care for this day will appear here."
        case .overdue:
            return "You're on schedule for the current filters."
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

    private func resetTaskForm() {
        taskTitle = ""
        taskEmoji = "🐾"
        taskPetScopeId = PetManager.allPetsId
        taskTime = Date()
        taskFrequency = .daily
        taskCustomInterval = 1
        taskCustomUnit = .day
        taskSelectedDays = [2, 3, 4, 5, 6]
        taskAlarmEnabled = true
        taskKind = .custom
        saveAsBlueprint = false
        selectedBlueprintId = nil
    }

    private func applyBlueprintToForm(_ template: CareTaskTemplate) {
        taskTitle = template.title
        taskEmoji = template.emojiIcon
        taskKind = template.taskKind
        taskTime = parseTime(template.timeText)
        taskFrequency = template.frequency
        taskCustomInterval = template.customInterval
        taskCustomUnit = template.customUnit
        taskSelectedDays = template.selectedDays
        taskAlarmEnabled = template.alarmEnabled
        if template.appliesToAllPets {
            taskPetScopeId = PetManager.allPetsId
        } else if let first = template.petIds.first {
            taskPetScopeId = first
        }
    }

    private func addTasks(from template: CareTaskTemplate) {
        let newTasks = taskStore.applyTemplate(template)
        guard !newTasks.isEmpty else { return }
        withAnimation {
            taskStore.tasks.insert(contentsOf: newTasks, at: 0)
        }
    }

    private var addTaskModalSheet: some View {
        NavigationStack {
            Form {
                if !taskStore.templates.isEmpty {
                    Section("Start from a template") {
                        Picker("Template", selection: $selectedBlueprintId) {
                            Text("Custom task").tag(Optional<UUID>.none)
                            ForEach(taskStore.templates) { template in
                                Text("\(template.emojiIcon) \(template.title)").tag(Optional(template.id))
                            }
                        }
                        .onChange(of: selectedBlueprintId) { _, newValue in
                            guard let id = newValue,
                                  let template = taskStore.templates.first(where: { $0.id == id }) else { return }
                            applyBlueprintToForm(template)
                        }
                    }
                }

                Section("Details") {
                    TextField("Task name (e.g. Breakfast, Walk, Medication)", text: $taskTitle)

                    Picker("Icon", selection: $taskEmoji) {
                        Text("🍗 Meal / Food").tag("🍗")
                        Text("💧 Water Refill").tag("💧")
                        Text("🚽 Litter Box").tag("🚽")
                        Text("💊 Medicine / Drops").tag("💊")
                        Text("🛁 Grooming / Bath").tag("🛁")
                        Text("🎾 Play & Exercise").tag("🎾")
                        Text("🚶 Walk").tag("🚶")
                        Text("🌾 Hay & Greens").tag("🌾")
                        Text("🪺 Habitat").tag("🪺")
                        Text("🧠 Check-in").tag("🧠")
                        Text("🐾 General Care").tag("🐾")
                    }

                    Picker("Pet", selection: $taskPetScopeId) {
                        Text("🐾 All Pets").tag(PetManager.allPetsId)
                        ForEach(petManager.pets) { pet in
                            Text("\(pet.avatarEmoji) \(pet.name)").tag(pet.id)
                        }
                    }

                    Picker("Kind", selection: $taskKind) {
                        ForEach(CareTaskKind.allCases) { kind in
                            Label(LocalizedStringKey(kind.rawValue), systemImage: kind.symbol).tag(kind)
                        }
                    }
                }

                Section("Schedule") {
                    DatePicker("Time", selection: $taskTime, displayedComponents: .hourAndMinute)

                    Picker("Frequency", selection: $taskFrequency) {
                        ForEach(TaskFrequency.allCases) { freq in
                            Label(LocalizedStringKey(freq.rawValue), systemImage: freq.systemImage)
                                .tag(freq)
                        }
                    }

                    if taskFrequency == .custom {
                        Picker("Unit", selection: $taskCustomUnit) {
                            ForEach(FrequencyUnit.allCases) { unit in
                                Label(LocalizedStringKey(unit.rawValue), systemImage: unit.systemImage)
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

                    Toggle("Reminders", isOn: $taskAlarmEnabled)
                }

                if householdSync.canMutate {
                    Section {
                        Toggle("Save as a template", isOn: $saveAsBlueprint)
                    } footer: {
                        Text("Templates let you add this task again without retyping.")
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddTaskSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Task") {
                        guard !taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        let newTask = CustomCareTask(
                            petId: taskPetScopeId,
                            title: taskTitle.trimmingCharacters(in: .whitespacesAndNewlines),
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
                            completedPetDateOffsets: [:],
                            taskKind: taskKind
                        )

                        withAnimation {
                            taskStore.tasks.insert(newTask, at: 0)
                        }
                        if saveAsBlueprint {
                            taskStore.addTemplate(from: newTask)
                        }
                        showAddTaskSheet = false
                        resetTaskForm()
                    }
                    .disabled(taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .bold()
                }
            }
        }
    }

    private var editTaskModalSheet: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Task name (e.g. Breakfast, Walk, Medication)", text: $taskTitle)

                    Picker("Icon", selection: $taskEmoji) {
                        Text("🍗 Meal / Food").tag("🍗")
                        Text("💧 Water Refill").tag("💧")
                        Text("🚽 Litter Box").tag("🚽")
                        Text("💊 Medicine / Drops").tag("💊")
                        Text("🛁 Grooming / Bath").tag("🛁")
                        Text("🎾 Play & Exercise").tag("🎾")
                        Text("🚶 Walk").tag("🚶")
                        Text("🌾 Hay & Greens").tag("🌾")
                        Text("🪺 Habitat").tag("🪺")
                        Text("🧠 Check-in").tag("🧠")
                        Text("🐾 General Care").tag("🐾")
                    }

                    Picker("Pet", selection: $taskPetScopeId) {
                        Text("🐾 All Pets").tag(PetManager.allPetsId)
                        ForEach(petManager.pets) { pet in
                            Text("\(pet.avatarEmoji) \(pet.name)").tag(pet.id)
                        }
                    }

                    Picker("Kind", selection: $taskKind) {
                        ForEach(CareTaskKind.allCases) { kind in
                            Label(LocalizedStringKey(kind.rawValue), systemImage: kind.symbol).tag(kind)
                        }
                    }
                }

                Section("Schedule") {
                    DatePicker("Time", selection: $taskTime, displayedComponents: .hourAndMinute)

                    Picker("Frequency", selection: $taskFrequency) {
                        ForEach(TaskFrequency.allCases) { freq in
                            Label(LocalizedStringKey(freq.rawValue), systemImage: freq.systemImage)
                                .tag(freq)
                        }
                    }

                    if taskFrequency == .custom {
                        Picker("Unit", selection: $taskCustomUnit) {
                            ForEach(FrequencyUnit.allCases) { unit in
                                Label(LocalizedStringKey(unit.rawValue), systemImage: unit.systemImage)
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

                    Toggle("Reminders", isOn: $taskAlarmEnabled)
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showEditTaskSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard !taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        guard let task = editingTask,
                              let idx = taskStore.tasks.firstIndex(where: { $0.id == task.id }) else { return }

                        taskStore.tasks[idx] = CustomCareTask(
                            id: task.id,
                            petId: taskPetScopeId,
                            title: taskTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                            timeText: formatTime(taskTime),
                            frequency: taskFrequency,
                            customInterval: taskCustomInterval,
                            customUnit: taskCustomUnit,
                            selectedDays: taskSelectedDays,
                            isCompleted: taskStore.tasks[idx].isCompleted,
                            alarmEnabled: taskAlarmEnabled,
                            emojiIcon: taskEmoji,
                            completedForPetIds: taskStore.tasks[idx].completedForPetIds,
                            startDate: taskStore.tasks[idx].startDate,
                            completedDateOffset: taskStore.tasks[idx].completedDateOffset,
                            completedPetDateOffsets: taskStore.tasks[idx].completedPetDateOffsets,
                            taskKind: taskKind,
                            snoozedUntil: taskStore.tasks[idx].snoozedUntil,
                            occurrenceLog: taskStore.tasks[idx].occurrenceLog
                        )
                        showEditTaskSheet = false
                        taskTitle = ""
                    }
                    .disabled(taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .bold()
                }
            }
        }
        .presentationDetents([.large])
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
                           let idx = taskStore.tasks.firstIndex(where: { $0.id == taskId }) {
                            withAnimation {
                                var updatedTasks = taskStore.tasks
                                if pendingCompletionPetIds.isEmpty {
                                    updatedTasks[idx].completedPetDateOffsets.removeAll()
                                } else {
                                    for petId in pendingCompletionPetIds {
                                        updatedTasks[idx].completedPetDateOffsets[petId] = selectedDateOffset
                                    }
                                }
                                taskStore.tasks = updatedTasks
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

private struct DayStrip: View {
    @Binding var selectedDateOffset: Int
    let summary: (Int) -> (total: Int, done: Int)
    @State private var showCalendar = false

    private var weekOffsets: [Int] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selected = calendar.date(byAdding: .day, value: selectedDateOffset, to: today) ?? today
        let weekday = calendar.component(.weekday, from: selected)
        var distanceFromWeekStart = weekday - calendar.firstWeekday
        if distanceFromWeekStart < 0 { distanceFromWeekStart += 7 }
        let startOfWeek = calendar.date(byAdding: .day, value: -distanceFromWeekStart, to: selected) ?? selected
        let startOffset = calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: startOfWeek)).day ?? 0
        return (0..<7).map { startOffset + $0 }
    }

    private var selectedDate: Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: selectedDateOffset, to: today) ?? today
    }

    private var dateSelection: Binding<Date> {
        Binding(
            get: { selectedDate },
            set: { newDate in
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let newDay = calendar.startOfDay(for: newDate)
                selectedDateOffset = calendar.dateComponents([.day], from: today, to: newDay).day ?? 0
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingS) {
            HStack(spacing: AppTheme.spacingS) {
                stepButton(systemImage: "chevron.backward", label: "Previous day", delta: -1)
                VStack(spacing: 2) {
                    Text(relativeTitle)
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                stepButton(systemImage: "chevron.forward", label: "Next day", delta: 1)
                if selectedDateOffset != 0 {
                    Button("Today") {
                        withAnimation { selectedDateOffset = 0 }
                    }
                    .font(.subheadline.weight(.semibold))
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                Button {
                    showCalendar = true
                } label: {
                    Image(systemName: "calendar")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityLabel("Choose a day")
            }

            HStack(spacing: 6) {
                ForEach(weekOffsets, id: \.self) { offset in
                    dayChip(offset)
                }
            }
        }
        .padding(.vertical, 4)
        .sensoryFeedback(.selection, trigger: selectedDateOffset)
        .sheet(isPresented: $showCalendar) {
            NavigationStack {
                DatePicker("Day", selection: dateSelection, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                    .navigationTitle("Choose a Day")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showCalendar = false }
                        }
                    }
            }
            .presentationDetents([.medium])
        }
    }

    private var relativeTitle: String {
        switch selectedDateOffset {
        case 0: return "Today"
        case 1: return "Tomorrow"
        case -1: return "Yesterday"
        default:
            return selectedDate.formatted(.dateTime.weekday(.wide))
        }
    }

    private func stepButton(systemImage: String, label: String, delta: Int) -> some View {
        Button {
            withAnimation { selectedDateOffset += delta }
        } label: {
            Image(systemName: systemImage)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .accessibilityLabel(label)
    }

    private func dayChip(_ offset: Int) -> some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let date = calendar.date(byAdding: .day, value: offset, to: today) ?? today
        let isSelected = offset == selectedDateOffset
        let load = summary(offset)
        return Button {
            withAnimation { selectedDateOffset = offset }
        } label: {
            VStack(spacing: 4) {
                Text(date.formatted(.dateTime.weekday(.narrow)))
                    .font(.caption2.weight(.semibold))
                Text(date.formatted(.dateTime.day()))
                    .font(.subheadline.weight(.bold))
                Circle()
                    .fill(dotColor(load, isSelected: isSelected))
                    .frame(width: 5, height: 5)
                    .opacity(load.total == 0 ? 0 : 1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? Color.white : AppTheme.textPrimary)
            .background(
                isSelected ? AnyShapeStyle(AppTheme.primary) : AnyShapeStyle(AppTheme.primary.opacity(offset == 0 ? 0.12 : 0.04)),
                in: RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(date.formatted(date: .complete, time: .omitted))
        .accessibilityValue(load.total == 0 ? "No tasks" : "\(load.done) of \(load.total) done")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func dotColor(_ load: (total: Int, done: Int), isSelected: Bool) -> Color {
        if load.total > 0 && load.done == load.total {
            return isSelected ? Color.white : AppTheme.success
        }
        return isSelected ? Color.white.opacity(0.85) : AppTheme.warning
    }
}

struct TaskRowView: View {
    let task: CustomCareTask
    let petManager: PetManager
    let selectedDateOffset: Int
    let selectedPetScopeId: UUID
    let displayPetId: UUID?
    var mealSummary: String?
    var isOverdue: Bool = false
    let onToggleComplete: () -> Void
    let onToggleAlarm: () -> Void
    var canChange: Bool = true
    let onDelete: () -> Void
    let onSnooze: () -> Void
    let onEdit: () -> Void

    var isCurrentPetCompleted: Bool {
        if task.petId == PetManager.allPetsId {
            let targetPetId = displayPetId ?? (selectedPetScopeId == PetManager.allPetsId ? petManager.currentPet.id : selectedPetScopeId)
            return task.completedPetDateOffsets[targetPetId] == selectedDateOffset
        }
        return task.isCompleted && task.completedDateOffset == selectedDateOffset
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isCurrentPetCompleted ? "checkmark.circle.fill" : (isOverdue ? "exclamationmark.circle.fill" : "circle"))
                .font(.title2)
                .foregroundStyle(checkboxTint)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(task.emojiIcon) \(task.title)")
                        .font(.body.weight(.medium))
                        .strikethrough(isCurrentPetCompleted)
                        .foregroundStyle(isCurrentPetCompleted ? .secondary : .primary)
                    Spacer(minLength: 8)
                    Text(task.timeText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isOverdue && !isCurrentPetCompleted ? AppTheme.danger : AppTheme.textSecondary)
                        .monospacedDigit()
                }
                Text(detailLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if isOverdue && !isCurrentPetCompleted {
                    Text("Overdue")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.danger)
                }
                if let mealSummary {
                    Text(mealSummary)
                        .font(.caption)
                        .foregroundStyle(AppTheme.nutrition)
                }
                if !task.alarmEnabled {
                    Text("Reminders off")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if canChange { onToggleComplete() }
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(task.title)
        .accessibilityValue(accessibilityValue)
        .swipeActions(edge: .trailing, allowsFullSwipe: canChange) {
            if canChange {
                Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
                Button("Edit", systemImage: "pencil", action: onEdit)
                    .tint(.blue)
            }
        }
        .swipeActions(edge: .leading) {
            if canChange {
                Button(isCurrentPetCompleted ? "Undo" : "Done", systemImage: isCurrentPetCompleted ? "arrow.uturn.backward" : "checkmark") {
                    onToggleComplete()
                }
                .tint(.green)
                Button(task.alarmEnabled ? "Mute" : "Remind", systemImage: task.alarmEnabled ? "bell.slash" : "bell") {
                    onToggleAlarm()
                }
                .tint(.orange)
                Button("Snooze 1h", systemImage: "clock") {
                    onSnooze()
                }
                .tint(AppTheme.tasks)
            }
        }
    }

    private var checkboxTint: Color {
        if isCurrentPetCompleted { return AppTheme.success }
        if isOverdue { return AppTheme.danger }
        return AppTheme.primary.opacity(0.55)
    }

    private var accessibilityValue: String {
        if isCurrentPetCompleted { return "Completed" }
        if isOverdue { return "Overdue, \(task.timeText)" }
        return "To do, \(task.timeText)"
    }

    private var detailLine: String {
        var parts = [task.taskKind.rawValue, frequencyLabel(for: task)]
        if let snoozedUntil = task.snoozedUntil, snoozedUntil > Date() {
            parts.append("Snoozed")
        }
        if selectedPetScopeId == PetManager.allPetsId,
           let displayPetId,
           let pet = petManager.pets.first(where: { $0.id == displayPetId }) {
            parts.append(pet.name)
        }
        return parts.joined(separator: " · ")
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
        .environmentObject(CareTaskStore.shared)
        .environmentObject(HouseholdSync.shared)
        .environmentObject(AuthSession.shared)
        .environmentObject(WellnessStore.shared)
        .environmentObject(AuthSession.shared)
}
