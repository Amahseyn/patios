//
//  CatIosApp.swift
//  CatIos
//

import SwiftUI
import UserNotifications

@main
struct CatIosApp: App {
    @AppStorage("appearance") private var appearance = ""
    @AppStorage("prefersDarkMode") private var prefersDarkMode: Bool = false

    private var colorScheme: ColorScheme? {
        if let mode = AppAppearance(rawValue: appearance) {
            return mode.colorScheme
        }
        return prefersDarkMode ? .dark : nil
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(AppTheme.primary)
                .preferredColorScheme(colorScheme)
                .onAppear {
                    migrateAppearance()
                    UNUserNotificationCenter.current().delegate = CareNotificationBridge.shared
                }
        }
    }

    private func migrateAppearance() {
        guard appearance.isEmpty else { return }
        appearance = prefersDarkMode ? AppAppearance.dark.rawValue : AppAppearance.system.rawValue
    }
}
