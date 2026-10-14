import SwiftUI

struct TaskBlueprintChip: View {
    let template: CareTaskTemplate
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(template.emojiIcon)
                    .font(.title2)
                Text(LocalizedStringKey(template.title))
                    .font(AppTheme.captionFont().weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text("\(template.timeText) · \(template.petScopeLabel)")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }
            .frame(width: 118, alignment: .leading)
            .padding(AppTheme.spacingM)
            .cardStyle(cornerRadius: AppTheme.cornerRadiusMedium)
        }
        .buttonStyle(.plain)
    }
}

struct TaskBlueprintManagerView: View {
    @EnvironmentObject private var taskStore: CareTaskStore
    @EnvironmentObject private var petManager: PetManager
    @EnvironmentObject private var householdSync: HouseholdSync
    @Environment(\.dismiss) private var dismiss

    @State private var editingTemplate: CareTaskTemplate?
    @State private var showEditor = false

    var body: some View {
        NavigationStack {
            List {
                if taskStore.templates.isEmpty {
                    EmptyStateView(
                        systemImage: "bookmark.fill",
                        title: "No saved templates",
                        message: "Save tasks you repeat so you can add them in one tap.",
                        actionTitle: householdSync.canMutate ? "Create template" : nil,
                        action: householdSync.canMutate ? { startNew() } : nil
                    )
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                } else {
                    ForEach(taskStore.templates) { template in
                        Button {
                            editingTemplate = template
                            showEditor = true
                        } label: {
                            HStack(spacing: AppTheme.spacingM) {
                                Text(template.emojiIcon).font(.title2)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(LocalizedStringKey(template.title))
                                        .font(AppTheme.headlineFont())
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Text("\(template.taskKind.rawValue) · \(template.timeText) · \(template.petScopeLabel)")
                                        .font(AppTheme.captionFont())
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.forward")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppTheme.textSecondary.opacity(0.7))
                            }
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: householdSync.canMutate) {
                            if householdSync.canMutate {
                                Button("Delete", role: .destructive) {
                                    taskStore.templates.removeAll { $0.id == template.id }
                                }
                            }
                        }
                    }
                }
            }
            .fantasyScreen()
            .navigationTitle("Task templates")
            .fantasyNavigation()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                if householdSync.canMutate {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Add", systemImage: "plus") { startNew() }
                    }
                }
            }
            .sheet(isPresented: $showEditor) {
                if let editingTemplate {
                    TaskBlueprintEditorView(template: editingTemplate) { saved in
                        if let index = taskStore.templates.firstIndex(where: { $0.id == saved.id }) {
                            taskStore.templates[index] = saved
                        } else {
                            taskStore.templates.insert(saved, at: 0)
                        }
                    }
                    .environmentObject(petManager)
                }
            }
        }
    }

    private func startNew() {
        editingTemplate = CareTaskTemplate(title: "")
        showEditor = true
    }
}

struct TaskBlueprintEditorView: View {
    @EnvironmentObject private var petManager: PetManager
    @Environment(\.dismiss) private var dismiss

    @State private var draft: CareTaskTemplate
    let onSave: (CareTaskTemplate) -> Void

    @State private var taskTime = Date()

    init(template: CareTaskTemplate, onSave: @escaping (CareTaskTemplate) -> Void) {
        _draft = State(initialValue: template)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Template") {
                    TextField("Name", text: $draft.title)
                    Picker("Emoji", selection: $draft.emojiIcon) {
                        ForEach(["🍗", "💧", "🚽", "💊", "🛁", "🎾", "🚶", "🌾", "🪺", "🧠", "🐾"], id: \.self) { emoji in
                            Text(emoji).tag(emoji)
                        }
                    }
                    Picker("Kind", selection: $draft.taskKind) {
                        ForEach(CareTaskKind.allCases) { kind in
                            Label(LocalizedStringKey(kind.rawValue), systemImage: kind.symbol).tag(kind)
                        }
                    }
                }

                Section("Pets") {
                    Toggle("All pets", isOn: $draft.appliesToAllPets)
                    if !draft.appliesToAllPets {
                        ForEach(petManager.pets) { pet in
                            Toggle(isOn: Binding(
                                get: { draft.petIds.contains(pet.id) },
                                set: { selected in
                                    if selected {
                                        if !draft.petIds.contains(pet.id) {
                                            draft.petIds.append(pet.id)
                                        }
                                    } else {
                                        draft.petIds.removeAll { $0 == pet.id }
                                    }
                                }
                            )) {
                                Text("\(pet.avatarEmoji) \(pet.name)")
                            }
                        }
                    }
                }

                Section("Schedule") {
                    DatePicker("Time", selection: $taskTime, displayedComponents: .hourAndMinute)
                    Picker("Frequency", selection: $draft.frequency) {
                        ForEach(TaskFrequency.allCases) { freq in
                            Text(LocalizedStringKey(freq.rawValue)).tag(freq)
                        }
                    }
                    if draft.frequency == .custom {
                        Stepper("Every \(draft.customInterval) \(draft.customUnit.rawValue.lowercased())", value: $draft.customInterval, in: 1...365)
                    }
                    Toggle("Reminders", isOn: $draft.alarmEnabled)
                }
            }
            .navigationTitle(draft.title.isEmpty ? "New blueprint" : "Edit blueprint")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        draft.timeText = formatTime(taskTime)
                        onSave(draft)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                taskTime = parseTime(draft.timeText)
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func parseTime(_ timeText: String) -> Date {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.date(from: timeText) ?? Date()
    }

    private var canSave: Bool {
        let hasTitle = !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasPets = draft.appliesToAllPets || !draft.petIds.isEmpty
        return hasTitle && hasPets
    }
}
