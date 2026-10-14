//
//  TermsOfUseView.swift
//  CatIos
//

import SwiftUI

struct TermsOfUseView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacingL) {
                RealmLegalHero(
                    title: "Terms of Use",
                    subtitle: "Last updated: August 2026",
                    icon: "doc.text.fill"
                )

                termsSection(title: "1. Acceptance of Terms", content: """
By downloading, installing, or using the Pet Care mobile application ("App"), you agree to be bound by these Terms of Use ("Terms"). If you do not agree to these Terms, please do not download or use the App. These Terms apply to all visitors, users, and others who access or use the App.
""")

                termsSection(title: "2. Description of Service", content: """
Pet Care is a home for every pet you look after, in households of one pet or many. Core features include, but are not limited to:

• Multi-Pet Profile Management: Create and manage profiles for cats, dogs, birds, rabbits, horses, fish, hamsters, reptiles, and any other kind you name, with avatars, personality notes, and age tracking.
• Care Tracking & Task Management: Log feeding, water intake, bathroom events, grooming, medications, and custom care tasks with flexible scheduling (hourly, daily, weekly, monthly, yearly, or custom intervals).
• Health & Vaccination Records: Maintain vaccination timelines, vet visit history, medical notes, and automated reminders with configurable recurrence frequencies.
• AI Assistant & Behavioral Analysis: Interact with an on-device AI assistant trained on your pet's history; use voice input to receive behavioral insights, emotion analysis, and care suggestions.
• Social & Family Sharing: Invite family members or caregivers to view and update pet care tasks, share milestones, and coordinate care across multiple devices.
• Notifications & Alarms: Receive customizable push notifications for upcoming tasks, health milestones, and AI-generated suggestions.
• Photo & Media Management: Upload pet avatars and care photos with local storage and optional cloud backup.

We reserve the right to modify, suspend, or discontinue any aspect of the service at any time without prior notice.
""")

                termsSection(title: "3. Account Registration & Eligibility", content: """
To access certain features, you may create an account or use social login options. You represent and warrant that:

• You are at least 13 years of age, or if under 13, you have obtained parental consent to use the App.
• All registration information you provide is accurate, current, and complete.
• You will maintain the confidentiality of your account credentials and be responsible for all activities under your account.
• You will notify us immediately of any unauthorized use of your account or any other breach of security.
""")

                termsSection(title: "4. User Responsibilities & Acceptable Use", content: """
You agree to use the App only for lawful purposes and in a manner consistent with these Terms. You shall not:

• Provide false, misleading, or inaccurate information about your pets.
• Use the App to transmit harmful code, viruses, or malicious software.
• Attempt to reverse-engineer, decompile, disassemble, or exploit the App or its underlying code.
• Interfere with or disrupt the integrity or performance of the App or related services.
• Use the App to harass, abuse, or harm other users or their pets.
• Violate any applicable local, state, national, or international law.
""")

                termsSection(title: "5. AI-Generated Content Disclaimer", content: """
The AI Assistant and behavioral analysis features provide suggestions based on vocal patterns, care history, and general pet care knowledge. These suggestions are for informational purposes only and do not constitute professional veterinary advice, diagnosis, or treatment.

• Always consult a qualified veterinarian for medical concerns, emergency care, or before making changes to your pet's diet, medication, or treatment plan.
• The AI model may occasionally produce inaccurate or incomplete information. You are solely responsible for verifying and acting upon any AI-generated suggestions.
• We do not guarantee the accuracy, reliability, or completeness of any AI-generated content.
""")

                termsSection(title: "6. Intellectual Property Rights", content: """
• App Ownership: All content, features, functionality, trademarks, logos, and design elements of the App are owned by Pet Care or its licensors and are protected by international copyright, trademark, patent, and other intellectual property laws.
• User Content: You retain ownership of all data you input into the App (pet profiles, care logs, photos, etc.). By using the App, you grant us a limited, worldwide, royalty-free license to process and store your data solely to provide and improve the service.
• Feedback: Any feedback, suggestions, or ideas you provide about the App become our exclusive property, and we may use them without obligation or compensation to you.
""")

                termsSection(title: "7. Subscription & Payments", content: """
Basic is free and shows ads on the main screens. Pet Care+ removes those ads. Pet Care+ Monthly is $3.99. Pet Care+ Yearly is $29.99. A paid plan is an App Store purchase that Pet Care verifies before the ads go away. If purchases are unavailable, the account stays on Basic.

When App Store billing is active, you agree to:

• Pay the fees (plus taxes) shown on the pricing page.
• Automatic renewal unless you cancel at least 24 hours before the end of the current billing period.
• Price changes: We may change subscription fees upon reasonable notice. Continued use after the price change constitutes acceptance of the new fee.
• Refunds: Subscription fees are non-refundable except as required by law or at our sole discretion.
""")

                termsSection(title: "8. Third-Party Services & Integrations", content: """
The App may integrate with or rely on third-party services, including but not limited to:

• Apple Speech Framework and SFSpeechRecognizer for voice transcription.
• Apple Push Notification Service (APNs) for notifications.
• Cloud storage providers for optional backup and sync.
• HealthKit for optional health data integration.

Your use of third-party services may be subject to their respective terms and privacy policies. We are not responsible for the practices or content of third-party services.
""")

                termsSection(title: "9. Limitation of Liability", content: """
To the fullest extent permitted by applicable law:

• Pet Care and its affiliates, officers, directors, employees, agents, and licensors shall not be liable for any indirect, incidental, special, consequential, or punitive damages, including but not limited to loss of profits, data, use, goodwill, or other intangible losses.
• Our total liability to you for any claim arising out of or relating to these Terms or the App shall not exceed the amount you paid us in the twelve (12) months preceding the claim, or one hundred dollars ($100), whichever is greater.
• Some jurisdictions do not allow the exclusion of certain warranties or limitation of liability. Accordingly, some of the above limitations may not apply to you.
""")

                termsSection(title: "10. Indemnification", content: """
You agree to indemnify, defend, and hold harmless Pet Care and its affiliates, officers, directors, employees, agents, and licensors from and against any and all claims, damages, losses, liabilities, costs, and expenses (including reasonable attorneys' fees) arising out of or in any way connected with your access to or use of the App, your violation of these Terms, or your violation of any rights of another party.
""")

                termsSection(title: "11. Termination", content: """
We may terminate or suspend your access to the App immediately, without prior notice or liability, for any reason, including if you breach these Terms. Upon termination, your right to use the App will immediately cease. Provisions of these Terms that by their nature should survive termination shall survive, including ownership provisions, warranty disclaimers, indemnity, and limitations of liability.
""")

                termsSection(title: "12. Changes to Terms", content: """
We reserve the right to update or modify these Terms at any time. Material changes will be communicated via in-app notification, email, or a prominent notice on our website. Your continued use of the App after the revised Terms become effective constitutes your acceptance of the revised Terms. We encourage you to review this page periodically for the latest information.
""")

                termsSection(title: "13. Governing Law & Dispute Resolution", content: """
These Terms shall be governed by and construed in accordance with the laws of the jurisdiction in which Pet Care operates, without regard to its conflict of law provisions. Any disputes arising out of these Terms or the use of the App shall be resolved through good-faith negotiation, and if unresolved, through binding arbitration or the courts of competent jurisdiction.
""")

                termsSection(title: "14. Contact Information", content: """
If you have any questions about these Terms of Use, please contact us:

• Email: legal@petemotionai.app
• Support: support@petemotionai.app
• Website: www.petemotionai.app

For legal notices, please send correspondence to:
Pet Care Legal Team
legal@petemotionai.app
""")
            }
            .padding(AppTheme.spacingM)
        }
        .fantasyScreen()
        .navigationTitle("Terms")
        .fantasyNavigation()
    }

    private func termsSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingS) {
            Text(title)
                .font(AppTheme.headlineFont())
                .foregroundStyle(AppTheme.textPrimary)

            Text(content)
                .font(AppTheme.bodyFont())
                .foregroundStyle(AppTheme.textSecondary)
                .lineSpacing(5)
        }
        .padding(AppTheme.spacingM)
        .cardStyle(cornerRadius: AppTheme.cornerRadiusLarge)
    }
}

#Preview {
    NavigationStack {
        TermsOfUseView()
    }
}
