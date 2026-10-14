//
//  PatiosAppearance.swift
//  Patios (CatIos)
//

import SwiftUI
import UIKit

enum PatiosAppearance {
    static func configure() {
        let tabBar = UITabBarAppearance()
        tabBar.configureWithDefaultBackground()
        tabBar.backgroundColor = UIColor(AppTheme.cardBackground)
        UITabBar.appearance().standardAppearance = tabBar
        UITabBar.appearance().scrollEdgeAppearance = tabBar

        let navBar = UINavigationBarAppearance()
        navBar.configureWithDefaultBackground()
        navBar.backgroundColor = UIColor(AppTheme.background)
        UINavigationBar.appearance().standardAppearance = navBar
        UINavigationBar.appearance().scrollEdgeAppearance = navBar
        UINavigationBar.appearance().tintColor = UIColor(AppTheme.primary)
    }
}
