//
//  AddReminderSheet.swift
//  CatIos
//

import SwiftUI

struct AddReminderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: CareViewModel
    
    @State private var title: String = ""
    @State private var selectedCategory: CareCategory = .feeding
    @State private var selectedSubcategory: String = "Breakfast"
    @State private var selectedDate: Date = Date()
    @State private var frequency: String = "Daily"
    
    let frequencies = ["Daily", "Weekly", "Bi-weekly", "Monthly", "Once"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Category")) {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(CareCategory.allCases) { category in
                            HStack {
                                Text(category.icon)
                                Text(LocalizedStringKey(category.rawValue))
                            }
                            .tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedCategory) { newCategory in
                        selectedSubcategory = newCategory.subcategories.first ?? ""
                    }
                    
                    Picker("Task Type", selection: $selectedSubcategory) {
                        ForEach(selectedCategory.subcategories, id: \.self) { sub in
                            Text(sub).tag(sub)
                        }
                    }
                }
                
                Section(header: Text("Details")) {
                    TextField("Reminder Title (e.g. Luna's Morning Wet Food)", text: $title)
                    
                    DatePicker("Date & Time", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                    
                    Picker("Repeat", selection: $frequency) {
                        ForEach(frequencies, id: \.self) { freq in
                            Text(freq).tag(freq)
                        }
                    }
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
                        let formatter = DateFormatter()
                        formatter.timeStyle = .short
                        let timeStr = formatter.string(from: selectedDate)
                        
                        let finalTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? selectedSubcategory : title
                        viewModel.addReminder(
                            title: finalTitle,
                            category: selectedCategory,
                            subcategory: selectedSubcategory,
                            date: selectedDate,
                            timeString: timeStr,
                            frequency: frequency
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}
