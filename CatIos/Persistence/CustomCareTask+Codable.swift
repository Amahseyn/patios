//
//  CustomCareTask+Codable.swift
//  CatIos
//
//  JSON object keys must be strings, so pet-id maps are encoded as UUID strings.
//

import Foundation

extension CustomCareTask: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case petId
        case title
        case timeText
        case frequency
        case customInterval
        case customUnit
        case selectedDays
        case isCompleted
        case alarmEnabled
        case emojiIcon
        case completedForPetIds
        case startDate
        case completedDateOffset
        case completedPetDateOffsets
        case taskKind
        case snoozedUntil
        case occurrenceLog
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        petId = try container.decode(UUID.self, forKey: .petId)
        title = try container.decode(String.self, forKey: .title)
        timeText = try container.decode(String.self, forKey: .timeText)
        frequency = try container.decode(TaskFrequency.self, forKey: .frequency)
        customInterval = try container.decodeIfPresent(Int.self, forKey: .customInterval) ?? 1
        customUnit = try container.decodeIfPresent(FrequencyUnit.self, forKey: .customUnit) ?? .day
        selectedDays = try container.decodeIfPresent(Set<Int>.self, forKey: .selectedDays) ?? [1, 2, 3, 4, 5]
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        alarmEnabled = try container.decode(Bool.self, forKey: .alarmEnabled)
        emojiIcon = try container.decode(String.self, forKey: .emojiIcon)
        completedForPetIds = try container.decodeIfPresent([UUID].self, forKey: .completedForPetIds) ?? []
        startDate = try container.decode(Date.self, forKey: .startDate)
        completedDateOffset = try container.decodeIfPresent(Int.self, forKey: .completedDateOffset)
        let rawOffsets = try container.decodeIfPresent([String: Int].self, forKey: .completedPetDateOffsets) ?? [:]
        var offsets: [UUID: Int] = [:]
        for (key, value) in rawOffsets {
            if let petId = UUID(uuidString: key) {
                offsets[petId] = value
            }
        }
        completedPetDateOffsets = offsets
        taskKind = try container.decodeIfPresent(CareTaskKind.self, forKey: .taskKind) ?? .custom
        snoozedUntil = try container.decodeIfPresent(Date.self, forKey: .snoozedUntil)
        occurrenceLog = try container.decodeIfPresent([TaskOccurrence].self, forKey: .occurrenceLog) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(petId, forKey: .petId)
        try container.encode(title, forKey: .title)
        try container.encode(timeText, forKey: .timeText)
        try container.encode(frequency, forKey: .frequency)
        try container.encode(customInterval, forKey: .customInterval)
        try container.encode(customUnit, forKey: .customUnit)
        try container.encode(selectedDays, forKey: .selectedDays)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(alarmEnabled, forKey: .alarmEnabled)
        try container.encode(emojiIcon, forKey: .emojiIcon)
        try container.encode(completedForPetIds, forKey: .completedForPetIds)
        try container.encode(startDate, forKey: .startDate)
        try container.encodeIfPresent(completedDateOffset, forKey: .completedDateOffset)
        let rawOffsets = Dictionary(uniqueKeysWithValues: completedPetDateOffsets.map { ($0.key.uuidString, $0.value) })
        try container.encode(rawOffsets, forKey: .completedPetDateOffsets)
        try container.encode(taskKind, forKey: .taskKind)
        try container.encodeIfPresent(snoozedUntil, forKey: .snoozedUntil)
        try container.encode(occurrenceLog, forKey: .occurrenceLog)
    }
}
