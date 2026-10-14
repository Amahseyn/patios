# Building Patios (CatIos) on macOS

This iOS app targets **SwiftUI** and requires **Xcode on a Mac** to compile and run in the simulator or on device. Linux CI agents cannot run `xcodebuild` or the iOS Simulator.

## Requirements

- macOS with Xcode 15+ (Swift 5.9+)
- Apple developer account (for device deployment; simulator does not require paid membership)

## Open the project

1. Clone the repository.
2. Open `CatIos.xcodeproj` in Xcode.
3. Wait for Swift Package Manager to resolve **Supabase** (see `Package.resolved`).

## Run

1. Select the **CatIos** scheme.
2. Choose an iPhone simulator (e.g. iPhone 16).
3. Press **Run** (⌘R).

## Capabilities to verify on device

- **Speech / microphone** — AI Assistant voice input and Voice Analysis recording need microphone permission.
- **Notifications** — Settings → Notifications toggles request `UNUserNotificationCenter` authorization.

## Reset onboarding

Delete the app from the simulator or clear `hasCompletedOnboarding` in User Defaults to see onboarding again.

## Branding assets

Semantic colors live in `Assets.xcassets` (`BrandPrimary`, `BrandSecondary`, etc.) and are mirrored in `Components/Theme.swift` fallbacks.
