import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var membership = MembershipStore.shared
    @StateObject private var authSession = AuthSession.shared
    @State private var selection = AppPlan.basic

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Basic is free and includes ads. Pet Care+ lifts them away, and costs less than 11pets and Petio.")
                        .foregroundStyle(AppTheme.textSecondary)
                    if let statusMessage = membership.statusMessage {
                        Text(statusMessage)
                            .foregroundStyle(AppTheme.warning)
                    }
                }

                Section("Plans") {
                    ForEach(AppPlan.allCases) { plan in
                        planRow(plan)
                    }
                }

                Section("What you get") {
                    featureRow("Pets, tasks, and health records", basic: true, plus: true)
                    featureRow("Care assistant", basic: true, plus: true)
                    featureRow("Reminders on this iPhone", basic: true, plus: true)
                    featureRow("Account sync", basic: true, plus: true)
                    featureRow("Ads on Tasks, Health, and Assistant", basic: true, plus: false)
                }

                Section {
                    PrimaryButton(title: confirmTitle) {
                        Task { await confirm() }
                    }
                    .disabled(confirmDisabled)
                    SecondaryButton(title: "Restore Purchases") {
                        Task { await membership.restore() }
                    }
                } footer: {
                    Text("Pet Care+ Monthly is \(PlanPricing.usd(PlanPricing.plusMonthly)). Pet Care+ Yearly is \(PlanPricing.usd(PlanPricing.plusYearly)). 11pets Premium is about \(PlanPricing.usd(PlanPricing.elevenPetsMonthly)) a month. Petio Plus is \(PlanPricing.usd(PlanPricing.petioMonthly)) a month or \(PlanPricing.usd(PlanPricing.petioYearly)) a year. A plan change is an App Store purchase, checked by Pet Care before ads go away.")
                }
            }
            .navigationTitle("Plans and Pricing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                selection = membership.plan
                await membership.loadProducts()
            }
        }
    }

    private var confirmDisabled: Bool {
        if selection == .basic { return false }
        return membership.purchasesUnavailable || membership.product(for: selection) == nil
    }

    private var confirmTitle: String {
        if selection == .basic { return "Stay on Basic" }
        if membership.purchasesUnavailable || membership.product(for: selection) == nil {
            return "Purchases are unavailable"
        }
        if !authSession.isSignedIn { return "Sign in to subscribe" }
        return selection == membership.plan ? "Keep \(selection.title)" : "Subscribe to \(selection.title)"
    }

    private func confirm() async {
        if selection == .basic {
            dismiss()
            return
        }
        if await membership.purchase(selection) {
            dismiss()
        }
    }

    private func planRow(_ plan: AppPlan) -> some View {
        Button {
            selection = plan
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: AppTheme.spacingS) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: AppTheme.spacingS) {
                        Text(LocalizedStringKey(plan.title))
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                        if plan == .plusYearly {
                            Text("Best value")
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppTheme.success.opacity(0.15), in: Capsule())
                                .foregroundStyle(AppTheme.success)
                        }
                    }
                    Text(plan.priceLabel)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.tint)
                    Text(plan.detail)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: AppTheme.spacingS)
                Image(systemName: selection == plan ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selection == plan ? Color.accentColor : AppTheme.textSecondary)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selection == plan ? .isSelected : [])
    }

    private func featureRow(_ title: String, basic: Bool, plus: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
            HStack(spacing: AppTheme.spacingM) {
                mark("Basic", included: basic)
                mark("Pet Care+", included: plus)
            }
            .font(.caption)
            .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private func mark(_ name: String, included: Bool) -> some View {
        Label(name, systemImage: included ? "checkmark" : "xmark")
            .foregroundStyle(included ? AppTheme.success : AppTheme.textSecondary)
    }
}

#Preview {
    PaywallView()
}
