import Foundation

enum APIMapping {
    static let allPetsId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

    static func petIDForAPI(_ id: UUID) -> UUID? {
        id == allPetsId ? nil : id
    }

    static func petIDFromAPI(_ id: UUID?) -> UUID {
        id ?? allPetsId
    }

    static func apiPet(from pet: PetProfile) -> APIPet {
        APIPet(
            id: pet.id,
            name: pet.name,
            species: pet.petType.rawValue,
            breed: pet.breed,
            sex: pet.gender.rawValue,
            ageYears: pet.age.years,
            ageMonths: pet.age.months,
            avatarEmoji: pet.avatarEmoji,
            colorHex: pet.petColorHex,
            birthDate: pet.birthDate,
            customSpecies: pet.customPetTypeName,
            wellnessScore: pet.wellnessScore,
            playfulness: pet.playfulness,
            social: pet.social,
            vocal: pet.vocal,
            statusSummary: pet.statusSummary,
            todayMoodEmoji: pet.todayMoodEmoji,
            todayMoodTitle: pet.todayMoodTitle,
            moodConfidence: pet.moodConfidence,
            moodTrendPercentage: pet.moodTrendPercentage,
            isTrendPositive: pet.isTrendPositive,
            needsAttention: pet.needsAttention,
            memberRole: pet.userRole.rawValue,
            soundPatterns: pet.soundPatterns.map {
                APISoundPattern(timeOfDay: $0.timeOfDay, description: $0.description, icon: $0.icon)
            },
            memories: pet.memories.map {
                APIMemory(
                    id: $0.id,
                    time: $0.time,
                    title: $0.title,
                    emoji: $0.emoji,
                    category: $0.category,
                    dateLabel: $0.dateLabel
                )
            }
        )
    }

    static func pet(from remote: APIPet, existing: PetProfile? = nil) -> PetProfile {
        let type = PetType(rawValue: remote.species) ?? .other
        return PetProfile(
            id: remote.id,
            name: remote.name,
            age: AgeValue(years: remote.ageYears, months: remote.ageMonths),
            breed: remote.breed,
            gender: PetGender(rawValue: remote.sex) ?? .unknown,
            petType: type,
            customPetTypeName: remote.customSpecies,
            wellnessScore: remote.wellnessScore,
            avatarEmoji: remote.avatarEmoji,
            statusSummary: remote.statusSummary,
            todayMoodEmoji: remote.todayMoodEmoji ?? existing?.todayMoodEmoji ?? "😊",
            todayMoodTitle: remote.todayMoodTitle ?? existing?.todayMoodTitle ?? remote.statusSummary,
            moodConfidence: remote.moodConfidence ?? existing?.moodConfidence ?? remote.wellnessScore,
            moodTrendPercentage: remote.moodTrendPercentage ?? existing?.moodTrendPercentage ?? 0,
            isTrendPositive: remote.isTrendPositive ?? existing?.isTrendPositive ?? true,
            needsAttention: remote.needsAttention ?? existing?.needsAttention ?? (remote.wellnessScore < 70),
            userRole: UserRole(rawValue: remote.memberRole ?? "") ?? existing?.userRole ?? .owner,
            birthDate: remote.birthDate,
            petColorHex: remote.colorHex,
            playfulness: remote.playfulness,
            social: remote.social,
            vocal: remote.vocal,
            soundPatterns: remote.soundPatterns?.map {
                SoundPattern(timeOfDay: $0.timeOfDay, description: $0.description, icon: $0.icon)
            } ?? existing?.soundPatterns ?? [],
            memories: remote.memories?.map {
                MemoryItem(
                    id: $0.id,
                    time: $0.time,
                    title: $0.title,
                    emoji: $0.emoji,
                    category: $0.category,
                    dateLabel: $0.dateLabel
                )
            } ?? existing?.memories ?? []
        )
    }

    static func apiTask(from task: CustomCareTask) -> APICareTask {
        APICareTask(
            id: task.id,
            petId: petIDForAPI(task.petId),
            title: task.title,
            timeText: task.timeText,
            frequency: task.frequency.rawValue,
            alarmEnabled: task.alarmEnabled,
            emoji: task.emojiIcon,
            customInterval: task.customInterval,
            customUnit: task.customUnit.rawValue,
            selectedDays: Array(task.selectedDays).sorted(),
            isCompleted: task.isCompleted,
            completedForPetIds: task.completedForPetIds,
            startDate: task.startDate,
            completedDateOffset: task.completedDateOffset,
            completedPetDateOffsets: Dictionary(
                uniqueKeysWithValues: task.completedPetDateOffsets.map { ($0.key.uuidString, $0.value) }
            ),
            taskKind: task.taskKind.rawValue,
            snoozedUntil: task.snoozedUntil,
            occurrenceLog: task.occurrenceLog.map {
                APITaskOccurrence(
                    id: $0.id,
                    status: $0.status,
                    occurredAt: $0.occurredAt,
                    petId: $0.petId,
                    amountGrams: $0.amountGrams,
                    calories: $0.calories,
                    foodName: $0.foodName
                )
            }
        )
    }

    static func task(from remote: APICareTask) -> CustomCareTask {
        CustomCareTask(
            id: remote.id,
            petId: petIDFromAPI(remote.petId),
            title: remote.title,
            timeText: remote.timeText,
            frequency: TaskFrequency(rawValue: remote.frequency) ?? .daily,
            customInterval: remote.customInterval,
            customUnit: FrequencyUnit(rawValue: remote.customUnit) ?? .day,
            selectedDays: Set(remote.selectedDays),
            isCompleted: remote.isCompleted,
            alarmEnabled: remote.alarmEnabled,
            emojiIcon: remote.emoji,
            completedForPetIds: remote.completedForPetIds,
            startDate: remote.startDate ?? Date(),
            completedDateOffset: remote.completedDateOffset,
            completedPetDateOffsets: Dictionary(
                uniqueKeysWithValues: remote.completedPetDateOffsets.compactMap { key, value in
                    UUID(uuidString: key).map { ($0, value) }
                }
            ),
            taskKind: CareTaskKind(rawValue: remote.taskKind ?? "") ?? .custom,
            snoozedUntil: remote.snoozedUntil,
            occurrenceLog: (remote.occurrenceLog ?? []).map {
                TaskOccurrence(
                    id: $0.id,
                    status: $0.status,
                    occurredAt: $0.occurredAt,
                    petId: $0.petId,
                    amountGrams: $0.amountGrams,
                    calories: $0.calories,
                    foodName: $0.foodName
                )
            }
        )
    }

    static func apiTaskTemplate(from template: CareTaskTemplate) -> APITaskTemplate {
        APITaskTemplate(
            id: template.id,
            title: template.title,
            emoji: template.emojiIcon,
            taskKind: template.taskKind.rawValue,
            timeText: template.timeText,
            frequency: template.frequency.rawValue,
            customInterval: template.customInterval,
            customUnit: template.customUnit.rawValue,
            selectedDays: Array(template.selectedDays).sorted(),
            alarmEnabled: template.alarmEnabled,
            appliesToAllPets: template.appliesToAllPets,
            petIds: template.petIds
        )
    }

    static func taskTemplate(from remote: APITaskTemplate) -> CareTaskTemplate {
        CareTaskTemplate(
            id: remote.id,
            title: remote.title,
            emojiIcon: remote.emoji,
            taskKind: CareTaskKind(rawValue: remote.taskKind) ?? .custom,
            timeText: remote.timeText,
            frequency: TaskFrequency(rawValue: remote.frequency) ?? .daily,
            customInterval: remote.customInterval,
            customUnit: FrequencyUnit(rawValue: remote.customUnit) ?? .day,
            selectedDays: Set(remote.selectedDays),
            alarmEnabled: remote.alarmEnabled,
            appliesToAllPets: remote.appliesToAllPets,
            petIds: remote.petIds
        )
    }

    static func apiFood(from food: FoodItem) -> APIFood {
        APIFood(
            id: food.id,
            petId: food.petId.flatMap(petIDForAPI),
            name: food.name,
            brand: food.brand,
            productName: food.productName,
            category: food.category.rawValue,
            caloriesPer100g: food.caloriesPer100g,
            protein: food.protein,
            fat: food.fat,
            fiber: food.fiber,
            notes: food.notes,
            isFavorite: food.isFavorite
        )
    }

    static func food(from remote: APIFood) -> FoodItem {
        FoodItem(
            id: remote.id,
            petId: remote.petId,
            name: remote.name,
            brand: remote.brand,
            productName: remote.productName,
            category: NutritionCategory(rawValue: remote.category) ?? .other,
            caloriesPer100g: remote.caloriesPer100g,
            protein: remote.protein,
            fat: remote.fat,
            fiber: remote.fiber,
            notes: remote.notes,
            isFavorite: remote.isFavorite
        )
    }

    static func apiFeeding(from entry: FeedingEntry) -> APIFeeding {
        APIFeeding(
            id: entry.id,
            petId: entry.petId.flatMap(petIDForAPI),
            foodId: entry.foodId,
            fedAt: entry.fedAt,
            foodName: entry.foodName,
            brand: entry.brand,
            amountGrams: entry.amountGrams,
            calories: entry.calories,
            notes: entry.notes
        )
    }

    static func feeding(from remote: APIFeeding) -> FeedingEntry {
        FeedingEntry(
            id: remote.id,
            petId: remote.petId,
            foodId: remote.foodId,
            fedAt: remote.fedAt,
            foodName: remote.foodName,
            brand: remote.brand,
            amountGrams: remote.amountGrams,
            calories: remote.calories,
            notes: remote.notes
        )
    }

    static func apiWeight(from entry: WeightEntry) -> APIWeight {
        APIWeight(id: entry.id, petId: entry.petId, weight: entry.weight, unit: entry.unit, loggedAt: entry.loggedAt, notes: entry.notes)
    }

    static func weight(from remote: APIWeight) -> WeightEntry {
        WeightEntry(id: remote.id, petId: remote.petId, weight: remote.weight, unit: remote.unit, loggedAt: remote.loggedAt, notes: remote.notes)
    }

    static func apiBehavior(from entry: BehaviorEntry) -> APIBehavior {
        APIBehavior(
            id: entry.id,
            petId: entry.petId,
            kind: entry.kind.rawValue,
            title: entry.title,
            occurredAt: entry.occurredAt,
            durationMinutes: entry.durationMinutes,
            notes: entry.notes,
            mood: entry.mood,
            severity: entry.severity,
            location: entry.location,
            icon: entry.icon,
            colorHex: entry.colorHex
        )
    }

    static func behavior(from remote: APIBehavior) -> BehaviorEntry {
        let kind = BehaviorKind(rawValue: remote.kind) ?? .other
        return BehaviorEntry(
            id: remote.id,
            petId: remote.petId,
            kind: kind,
            title: remote.title,
            occurredAt: remote.occurredAt,
            durationMinutes: remote.durationMinutes,
            notes: remote.notes,
            mood: remote.mood,
            severity: remote.severity,
            location: remote.location,
            icon: remote.icon.isEmpty ? kind.symbol : remote.icon,
            colorHex: remote.colorHex
        )
    }

    static func apiHealth(from record: HealthRecord) -> APIHealthRecord {
        APIHealthRecord(
            id: record.id,
            petId: record.petId.flatMap(petIDForAPI),
            title: record.title,
            recordType: record.recordType.rawValue,
            notes: record.notes,
            doctorOrLocation: record.doctorOrLocation ?? "",
            reminderEnabled: record.isReminderSet ?? false,
            dateText: record.dateText,
            date: record.date,
            nextDueDate: record.nextDueDate,
            vaccineName: record.vaccineName,
            upcomingDaysRemaining: record.upcomingDaysRemaining,
            frequency: record.frequency.rawValue,
            customInterval: record.customInterval,
            customUnit: record.customUnit.rawValue,
            selectedDays: Array(record.selectedDays).sorted()
        )
    }

    static func health(from remote: APIHealthRecord) -> HealthRecord {
        HealthRecord(
            id: remote.id,
            petId: remote.petId,
            dateText: remote.dateText,
            title: remote.title,
            recordType: HealthRecordType(rawValue: remote.recordType) ?? .vetVisit,
            notes: remote.notes,
            doctorOrLocation: remote.doctorOrLocation.isEmpty ? nil : remote.doctorOrLocation,
            upcomingDaysRemaining: remote.upcomingDaysRemaining,
            date: remote.date,
            nextDueDate: remote.nextDueDate,
            vaccineName: remote.vaccineName,
            isReminderSet: remote.reminderEnabled,
            frequency: TaskFrequency(rawValue: remote.frequency) ?? .yearly,
            customInterval: remote.customInterval,
            customUnit: FrequencyUnit(rawValue: remote.customUnit) ?? .day,
            selectedDays: Set(remote.selectedDays)
        )
    }
}
