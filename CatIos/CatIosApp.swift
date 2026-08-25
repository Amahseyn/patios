//
//  CatIosApp.swift
//  CatIos
//

import SwiftUI

@main
struct CatIosApp: App {
    @AppStorage("prefersDarkMode") private var prefersDarkMode: Bool = false

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(prefersDarkMode ? .dark : nil)
        }
    }
}
