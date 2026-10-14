//
//  CatIosApp.swift
//  CatIos
//

import SwiftUI

@main
struct CatIosApp: App {
    @AppStorage("prefersDarkMode") private var prefersDarkMode: Bool = false

    init() {
        PatiosAppearance.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(prefersDarkMode ? .dark : nil)
                .tint(AppTheme.primary)
        }
    }
}
