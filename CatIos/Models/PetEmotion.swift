//
//  PetEmotion.swift
//  CatIos
//
//  Domain model describing a detected pet emotion.
//  Pure data + presentation helpers — no networking or AI logic.
//

import SwiftUI

enum PetEmotion: String, CaseIterable, Identifiable, Codable {
    case happy
    case hungry
    case anxious
    case relaxed
    case playful
    case annoyed
    case curious

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .happy: return "Happy"
        case .hungry: return "Hungry"
        case .anxious: return "Anxious"
        case .relaxed: return "Relaxed"
        case .playful: return "Playful"
        case .annoyed: return "Annoyed"
        case .curious: return "Curious"
        }
    }

    var emoji: String {
        switch self {
        case .happy: return "😊"
        case .hungry: return "🍽️"
        case .anxious: return "😰"
        case .relaxed: return "😌"
        case .playful: return "😺"
        case .annoyed: return "😾"
        case .curious: return "🧐"
        }
    }

    var symbolName: String {
        switch self {
        case .happy: return "face.smiling"
        case .hungry: return "fork.knife"
        case .anxious: return "waveform.path.ecg"
        case .relaxed: return "leaf"
        case .playful: return "pawprint"
        case .annoyed: return "exclamationmark.bubble"
        case .curious: return "questionmark.circle"
        }
    }

    var tint: Color {
        switch self {
        case .happy: return AppTheme.success
        case .hungry: return AppTheme.warning
        case .anxious: return AppTheme.danger
        case .relaxed: return .mint
        case .playful: return AppTheme.primary
        case .annoyed: return .orange
        case .curious: return .teal
        }
    }

    var sampleDescription: String {
        switch self {
        case .happy:
            return "Your pet sounds relaxed and comfortable."
        case .hungry:
            return "Your pet may be asking for food or a snack."
        case .anxious:
            return "Your pet might be feeling stressed or unsettled."
        case .relaxed:
            return "Your pet seems calm and at ease right now."
        case .playful:
            return "Your pet is in a playful, energetic mood."
        case .annoyed:
            return "Your pet could be signaling irritation — maybe give some space."
        case .curious:
            return "Your pet sounds alert and curious about something nearby."
        }
    }
}
