//
//  OnboardingViewModel.swift
//  CatEmotionAI
//

import SwiftUI
import Combine

struct OnboardingPage: Identifiable {
    let id = UUID()
    let systemImage: String?
    let imageName: String?
    let title: String
    let description: String
}

struct OnboardingQuestion: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let options: [String]
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentPage: Int = 0
    @Published var selectedAnswers: [Int: String] = [:]

    let pages: [OnboardingPage] = [
        OnboardingPage(
            systemImage: nil,
            imageName: "AppLogo",
            title: "Welcome to Patios",
            description: "Your warm, modern companion for daily pet care—health, tasks, and understanding how your pet feels."
        ),
        OnboardingPage(
            systemImage: "waveform.circle.fill",
            imageName: nil,
            title: "Voice & emotion insights",
            description: "Record sounds and get friendly AI interpretations of mood and behavior patterns."
        ),
        OnboardingPage(
            systemImage: "heart.circle.fill",
            imageName: nil,
            title: "Care that fits your routine",
            description: "Smart reminders, health timelines, and an assistant that knows your pets."
        )
    ]

    let questions: [OnboardingQuestion] = [
        OnboardingQuestion(
            title: "What type of pet do you have?",
            subtitle: "Helps us customize the experience for your pet.",
            options: ["Cat 🐱", "Dog 🐶", "Both 🐱🐶"]
        ),
        OnboardingQuestion(
            title: "How many pets do you have?",
            subtitle: "Helps us customize your multi-pet management experience.",
            options: ["1 Pet 🐾", "2 Pets 🐾🐾", "3+ Pets 🐈‍⬛"]
        ),
        OnboardingQuestion(
            title: "What is your main care goal?",
            subtitle: "We'll tailor your daily dashboard and smart reminders.",
            options: ["Health & Vaccines 💉", "Behavior & Mood 🧠"]
        )
    ]

    var totalSteps: Int {
        pages.count + questions.count
    }

    var isQuestionPage: Bool {
        currentPage >= pages.count
    }

    var isLastPage: Bool { currentPage == totalSteps - 1 }

    func selectOption(_ option: String) {
        let questionIndex = currentPage - pages.count
        selectedAnswers[questionIndex] = option
    }

    func advance() {
        if isLastPage {
            complete()
        } else {
            withAnimation(.easeInOut) {
                currentPage += 1
            }
        }
    }

    func skip() {
        complete()
    }

    var onComplete: (() -> Void)?

    private func complete() {
        onComplete?()
    }
}

extension Array {
    subscript(indices index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
