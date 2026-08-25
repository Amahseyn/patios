//
//  PrivacyPolicyView.swift
//  CatIos
//

import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacingL) {
                Text("Privacy Policy")
                    .font(.title.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("Last updated: August 2026")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)

                policySection(title: "Introduction", content: """
At Gooli ("we," "our," or "us"), we are committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application. Please read this policy carefully. By using the app, you consent to the data practices described herein.
""")

                policySection(title: "Information We Collect", content: """
We collect information you provide directly to us and information derived from your use of the app, including:

• Pet Profiles: Name, species (cat, dog, or other), breed, age, weight, avatar image, and personality notes.
• Care & Health Data: Feeding logs, water intake, bathroom events, grooming records, health timeline entries (vaccinations, medications, vet visits), and custom care tasks with completion status.
• AI Interaction Data: Voice recordings and text inputs used for behavioral analysis, emotion detection, and AI-generated care suggestions. All voice processing is performed on-device; audio is not uploaded to our servers.
• Usage & Device Data: App preferences, notification settings, crash logs, and anonymized analytics to improve app stability and performance.
• Social Features: Optional sharing preferences and connection metadata if you use social features such as family sharing or care invitations.
""")

                policySection(title: "How We Use Your Information", content: """
Your information is used to:

• Deliver core app functionality, including personalized care tracking, scheduling, and reminders.
• Power on-device AI analysis to interpret pet vocalizations and generate actionable insights.
• Send push notifications and alarms for upcoming care tasks, vaccinations, and health milestones.
• Improve app functionality, fix bugs, and develop new features.
• Provide customer support and respond to inquiries.
• Enable optional social features, such as sharing pet updates with family members or caregivers.
• Comply with legal obligations and protect our rights and the safety of our users.
""")

                policySection(title: "Data Storage & Security", content: """
• Local-First Architecture: All pet profiles, care logs, health records, and AI interaction history are stored locally on your device by default. We do not automatically sync or upload your personal data to cloud servers unless you explicitly enable that feature.
• On-Device Processing: Voice analysis and emotion recognition are performed entirely on your device using Apple's native speech recognition frameworks. Recordings are transcribed locally and discarded after processing; they are never transmitted to external servers.
• Encryption: If you enable cloud backup or account features, all data in transit is encrypted using TLS 1.2+, and data at rest is protected using industry-standard encryption.
• Access Controls: We implement strict access controls and regular security audits. Only authorized personnel may access aggregated, anonymized data for product improvement.
• Data Minimization: We collect only the data necessary to provide and improve the app. We do not sell, rent, or trade your personal information to third parties.
""")

                policySection(title: "Permissions & System Features", content: """
The app may request the following permissions on your iOS device:

• Microphone Access: Used solely for voice input and on-device AI emotion analysis. The app does not record or store audio without your explicit initiation.
• Speech Recognition: Used to transcribe voice inputs for the AI Assistant and behavioral logs. Transcription occurs on-device.
• Notifications: Used to deliver care reminders, task alarms, and health milestone alerts. You can manage notification preferences at any time in Settings.
• Photo Library: Used for uploading pet avatars. Photos are stored locally unless you choose to enable cloud backup.
• HealthKit (Optional): If enabled, allows the app to read and write health-related data such as activity and weight, subject to your separate consent.
""")

                policySection(title: "Third-Party Services", content: """
We may use the following third-party services:

• Apple Speech Framework (SFSpeechRecognizer): For on-device voice transcription. Apple's privacy policy applies.
• Apple Push Notification Service (APNs): For delivering push notifications. Apple handles notification delivery and does not share content with us.
• Analytics Providers (Optional): Aggregate, anonymized usage data may be shared with analytics platforms to help us improve the app. No personally identifiable information is shared.
• Cloud Sync Providers (Optional): If you enable backup, data is stored with a trusted cloud provider subject to their privacy policy.
""")

                policySection(title: "Children's Privacy", content: """
The app is designed for pet owners of all ages but is not directed to children under 13. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us so we can delete the information.
""")

                policySection(title: "Your Rights & Choices", content: """
You have the following rights regarding your data:

• Access & Update: You can view and edit pet profiles, care logs, and health records at any time within the app.
• Delete Data: You can delete individual records, pets, or your entire local dataset through the app settings.
• Export Data: You can request an export of your stored data in a portable format.
• Opt Out: You may disable notifications, analytics, and optional cloud sync at any time in Settings.
• Account Deletion: If you have created an account, you may request permanent deletion of your account and associated data by contacting support.
""")

                policySection(title: "Data Sharing & Disclosure", content: """
We do not sell your personal information. We may disclose your data only in the following circumstances:

• With your explicit consent.
• To comply with legal obligations, such as subpoenas or court orders.
• To protect the safety, rights, or property of Pet Emotion AI, our users, or the public.
• In connection with a merger, acquisition, or sale of assets, where you will be notified via app notification or email.
""")

                policySection(title: "Changes to This Policy", content: """
We may update this Privacy Policy from time to time to reflect changes in our practices or legal requirements. We will notify you of material changes via in-app notification or email. Continued use of the app after changes constitutes acceptance of the updated policy.
""")

                policySection(title: "Contact Us", content: """
If you have questions, concerns, or requests regarding this Privacy Policy, please contact us:

• Email: privacy@petemotionai.app
• Support: support@petemotionai.app
• Website: www.petemotionai.app

We aim to respond to all inquiries within 5 business days.
""")
            }
            .padding(AppTheme.spacingM)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func policySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingS) {
            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            Text(content)
                .font(.body)
                .foregroundStyle(AppTheme.textSecondary)
                .lineSpacing(4)
        }
        .padding(AppTheme.spacingM)
        .cardStyle()
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
