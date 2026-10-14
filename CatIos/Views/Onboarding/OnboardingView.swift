import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    var onFinished: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                FantasyScreenBackground().ignoresSafeArea()

                VStack(spacing: 0) {
                    TabView(selection: $viewModel.currentPage) {
                        ForEach(0..<viewModel.pages.count, id: \.self) { index in
                            OnboardingPageView(page: viewModel.pages[index])
                                .tag(index)
                        }
                        petSetup
                            .tag(viewModel.pages.count)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))

                    PrimaryButton(
                        title: viewModel.isLastPage ? "Start caring" : "Continue",
                        systemImage: viewModel.isLastPage ? "checkmark" : "arrow.right"
                    ) {
                        viewModel.advance()
                    }
                    .disabled(viewModel.isLastPage && !viewModel.canFinish)
                    .padding()
                }
            }
            .navigationTitle("Patios")
            .fantasyNavigation()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(viewModel.isLastPage ? "Keep sample pets" : "Skip") {
                        viewModel.skip()
                    }
                    .foregroundStyle(AppTheme.primary)
                }
            }
        }
        .onAppear {
            viewModel.onComplete = onFinished
        }
    }

    private var petSetup: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacingM) {
                FantasyHeroHeader(
                    title: "Add your first pet",
                    subtitle: "Cats, dogs, birds, rabbits, and any other pet can join later.",
                    systemImage: "pawprint.fill"
                )

                VStack(spacing: AppTheme.spacingM) {
                    TextField("Pet name", text: $viewModel.petName)
                        .textInputAutocapitalization(.words)
                        .padding()
                        .cardStyle()
                    PetKindPicker(selection: $viewModel.petType)
                        .padding()
                        .cardStyle()
                    Picker("Sex", selection: $viewModel.petGender) {
                        ForEach(PetGender.allCases) { gender in
                            Text(gender.rawValue).tag(gender)
                        }
                    }
                    .padding()
                    .cardStyle()
                }

                Text("Start caring replaces the sample household with this pet and three daily tasks. Keep sample pets leaves Luna, Milo, and Buddy so you can explore first.")
                    .font(AppTheme.captionFont())
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(AppTheme.spacingL)
        }
    }
}

#Preview {
    OnboardingView(onFinished: {})
}
