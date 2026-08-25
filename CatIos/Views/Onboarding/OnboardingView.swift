//
//  OnboardingView.swift
//  CatEmotionAI
//
//  3-step onboarding flow with a swipeable TabView, custom page indicators,
//  a Skip option, and a Continue / Get Started button.
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()

    var onFinished: () -> Void

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    if !viewModel.isLastPage {
                        Button("Skip") {
                            viewModel.skip()
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.trailing, AppTheme.spacingL)
                        .padding(.top, AppTheme.spacingS)
                    }
                }
                .frame(height: 44)

                TabView(selection: $viewModel.currentPage) {
                    ForEach(0..<viewModel.pages.count, id: \.self) { index in
                        OnboardingPageView(page: viewModel.pages[index])
                            .tag(index)
                    }

                    ForEach(0..<viewModel.questions.count, id: \.self) { qIdx in
                        let question = viewModel.questions[qIdx]
                        let tagIndex = viewModel.pages.count + qIdx
                        VStack(spacing: AppTheme.spacingL) {
                            Text(question.title)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(AppTheme.textPrimary)
                                .multilineTextAlignment(.center)

                            Text(question.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, AppTheme.spacingM)

                            VStack(spacing: 12) {
                                ForEach(question.options, id: \.self) { opt in
                                    let isSelected = viewModel.selectedAnswers[qIdx] == opt
                                    Button {
                                        viewModel.selectOption(opt)
                                    } label: {
                                        HStack {
                                            Text(opt)
                                                .font(.headline.weight(.semibold))
                                            Spacer()
                                            if isSelected {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(AppTheme.primary)
                                            }
                                        }
                                        .padding(AppTheme.spacingM)
                                        .background(isSelected ? AppTheme.primary.opacity(0.12) : AppTheme.cardBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(isSelected ? AppTheme.primary : Color.clear, lineWidth: 2)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.top, AppTheme.spacingM)
                        }
                        .padding(AppTheme.spacingL)
                        .tag(tagIndex)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: viewModel.currentPage)

                HStack(spacing: 8) {
                    ForEach(0..<viewModel.totalSteps, id: \.self) { index in
                        Capsule()
                            .fill(index == viewModel.currentPage ? AppTheme.primary : AppTheme.primary.opacity(0.2))
                            .frame(width: index == viewModel.currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.currentPage)
                    }
                }
                .padding(.bottom, AppTheme.spacingL)

                PrimaryButton(
                    title: viewModel.isLastPage ? "Get Started" : (viewModel.isQuestionPage ? "Next Question" : "Continue"),
                    systemImage: viewModel.isLastPage ? "checkmark" : "arrow.right"
                ) {
                    viewModel.advance()
                }
                .padding(.horizontal, AppTheme.spacingL)
                .padding(.bottom, AppTheme.spacingL)
            }
        }
        .onAppear {
            viewModel.onComplete = onFinished
        }
    }
}

#Preview {
    OnboardingView(onFinished: {})
}
