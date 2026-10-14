import SwiftUI
import Combine

struct OnboardingPage: Identifiable {
    let id = UUID()
    let systemImage: String?
    let imageName: String?
    let title: String
    let description: String
    let tintIndex: Int
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentPage: Int = 0
    @Published var petName: String = ""
    @Published var petType: PetType = .cat
    @Published var petGender: PetGender = .female

    let pages: [OnboardingPage] = [
        OnboardingPage(
            systemImage: nil,
            imageName: "AppLogo",
            title: "Welcome to Patios",
            description: "Keep meals, medication, walks, and vet dates in one place — for every pet in your household.",
            tintIndex: 0
        ),
        OnboardingPage(
            systemImage: "cross.case.fill",
            imageName: nil,
            title: "Health you can act on",
            description: "Log vaccines and visits, then get reminders before the next due date so nothing slips.",
            tintIndex: 2
        ),
        OnboardingPage(
            systemImage: "icloud.fill",
            imageName: nil,
            title: "Works on this iPhone first",
            description: "Your household stays on device. Sign in later from You to sync with family and other devices.",
            tintIndex: 4
        )
    ]

    var totalSteps: Int { pages.count + 1 }

    var isPetPage: Bool { currentPage >= pages.count }

    var isLastPage: Bool { currentPage == totalSteps - 1 }

    var canFinish: Bool {
        !petName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func advance() {
        if isLastPage {
            guard canFinish else { return }
            complete(createPet: true)
        } else {
            withAnimation(.easeInOut) {
                currentPage += 1
            }
        }
    }

    func skip() {
        complete(createPet: false)
    }

    var onComplete: (() -> Void)?

    private func complete(createPet: Bool) {
        if createPet {
            let name = petName.trimmingCharacters(in: .whitespacesAndNewlines)
            PetManager.shared.adoptOnboardingPet(name: name, petType: petType, gender: petGender)
        }
        Task {
            _ = await HealthNotificationManager.shared.requestAuthorization()
            CareReminderScheduler.shared.reschedule(tasks: CareTaskStore.shared.tasks)
        }
        onComplete?()
    }
}
