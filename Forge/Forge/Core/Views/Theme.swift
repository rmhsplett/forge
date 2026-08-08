//
//  Theme.swift
//  Forge
//
//  App-wide appearance options, persisted in UserDefaults via @AppStorage.
//  We store a stable String raw value for each choice and map it to a
//  SwiftUI Color / Font.Design at render time (Color isn't directly
//  storable, and strings stay valid across app updates).
//

import SwiftUI

/// Curated accent colors. `.tint(...)` at the root paints buttons, links,
/// checkmarks, the tab bar selection, etc.
enum AccentTheme: String, CaseIterable, Identifiable {
    case blue, red, orange, green, teal, indigo, purple, pink

    var id: String { rawValue }
    var label: String { rawValue.capitalized }

    var color: Color {
        switch self {
        case .blue: return .blue
        case .red: return .red
        case .orange: return .orange
        case .green: return .green
        case .teal: return .teal
        case .indigo: return .indigo
        case .purple: return .purple
        case .pink: return .pink
        }
    }
}

/// System font designs — distinct looks with zero bundled files, and they
/// keep Dynamic Type / accessibility working. Custom bundled fonts can be
/// added later without changing how this is consumed.
enum AppFontDesign: String, CaseIterable, Identifiable {
    // `rounded` removed — too close to `standard`. Distinct system designs only.
    case standard, serif, monospaced

    var id: String { rawValue }
    var label: String { rawValue.capitalized }

    var design: Font.Design {
        switch self {
        case .standard: return .default
        case .serif: return .serif
        case .monospaced: return .monospaced
        }
    }
}

/// Makes a List frosted when a background photo is set: hides the opaque
/// scroll background and gives rows a translucent material so the photo shows
/// through. A no-op (normal opaque look) when there's no background image.
struct FrostedListModifier: ViewModifier {
    @AppStorage(BackgroundStore.hasImageKey) private var hasImage = false

    func body(content: Content) -> some View {
        if hasImage {
            content
                .scrollContentBackground(.hidden)
                .listRowBackground(Rectangle().fill(.ultraThinMaterial))
        } else {
            content
        }
    }
}

extension View {
    /// Apply to a `List` to make it frosted over the background photo.
    func frostedList() -> some View { modifier(FrostedListModifier()) }
}

/// Central keys + small resolvers so views don't repeat the AppStorage keys.
enum ThemeStorage {
    static let accentKey = "accentTheme"
    static let fontKey = "fontDesign"

    static func accent(_ raw: String) -> Color {
        (AccentTheme(rawValue: raw) ?? .blue).color
    }
    static func design(_ raw: String) -> Font.Design {
        (AppFontDesign(rawValue: raw) ?? .standard).design
    }
}
