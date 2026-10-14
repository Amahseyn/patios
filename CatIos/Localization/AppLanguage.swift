//
//  AppLanguage.swift
//  CatIos — in-app language selection (English / Persian) with RTL support.
//

import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case persian = "fa"

    static let storageKey = "appLanguage"

    var id: String { rawValue }

    /// Name shown in the picker, always in the language's own script.
    var displayName: String {
        switch self {
        case .system: return L("System")
        case .english: return "English"
        case .persian: return "فارسی"
        }
    }

    /// Current selection from UserDefaults.
    static var current: AppLanguage {
        AppLanguage(rawValue: UserDefaults.standard.string(forKey: storageKey) ?? "") ?? .system
    }

    /// Language code actually used to render the UI.
    var resolvedCode: String {
        switch self {
        case .english: return "en"
        case .persian: return "fa"
        case .system:
            let preferred = Locale.preferredLanguages.first ?? "en"
            return preferred.hasPrefix("fa") ? "fa" : "en"
        }
    }

    var locale: Locale {
        resolvedCode == "fa" ? Locale(identifier: "fa_IR") : Locale(identifier: "en_US")
    }

    var layoutDirection: LayoutDirection {
        resolvedCode == "fa" ? .rightToLeft : .leftToRight
    }

    /// Bundle holding the compiled strings for the resolved language.
    var bundle: Bundle {
        if let path = Bundle.main.path(forResource: resolvedCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return .main
    }
}

/// Localizes a runtime string using the in-app language selection.
/// Use for values built in code (titles passed as `String`, enum labels, etc.).
func L(_ key: String) -> String {
    let value = AppLanguage.current.bundle.localizedString(forKey: key, value: nil, table: nil)
    return value
}

/// Localized format string helper, e.g. `LF("%lld of %lld done", 2, 5)`.
func LF(_ key: String, _ args: CVarArg...) -> String {
    String(format: L(key), locale: AppLanguage.current.locale, arguments: args)
}

extension View {
    /// Applies locale and layout direction for the chosen app language.
    func appLanguage(_ language: AppLanguage) -> some View {
        environment(\.locale, language.locale)
            .environment(\.layoutDirection, language.layoutDirection)
            .id(language.resolvedCode) // rebuild views so L() strings refresh
    }
}

struct LanguagePicker: View {
    @AppStorage(AppLanguage.storageKey) private var language = AppLanguage.system.rawValue

    var body: some View {
        Picker("Language", selection: $language) {
            ForEach(AppLanguage.allCases) { option in
                Text(verbatim: option.displayName).tag(option.rawValue)
            }
        }
        .pickerStyle(.menu)
        .tint(AppTheme.primary)
    }
}
