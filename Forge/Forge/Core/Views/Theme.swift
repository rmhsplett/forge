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
                .background {
                    BackgroundView()
                }
        } else {
            content
        }
    }
}

extension View {
    /// Apply to a `List` to make it frosted over the background photo. Handles
    /// the photo + transparent scroll area; row translucency is set separately
    /// via `.listRowBackground(PanelBackground())` on the rows themselves
    /// (SwiftUI ignores listRowBackground applied to the List container).
    func frostedList() -> some View { modifier(FrostedListModifier()) }
}

/// Background for content panels (list rows) over a photo: frosted glass with
/// a user-adjustable opacity (0 = clear, 1 = solid/opaque). Falls back to the
/// normal grouped color when no background photo is set.
struct PanelBackground: View {
    @AppStorage(BackgroundStore.hasImageKey) private var hasImage = false
    @AppStorage(ThemeStorage.panelOpacityKey) private var opacity = 0.5

    var body: some View {
        if hasImage {
            ZStack {
                // Frost fades out toward 0 (fully clear photo)…
                Rectangle().fill(.ultraThinMaterial)
                    .opacity(min(1, opacity * 2))
                // …and a solid tint grows in toward 1 (opaque like before).
                Color(.secondarySystemGroupedBackground)
                    .opacity(max(0, opacity * 2 - 1))
            }
        } else {
            Color(.secondarySystemGroupedBackground)
        }
    }
}

/// Section headers and footers sit OUTSIDE the frosted panels, directly over
/// the background photo, so their default faint-grey styling can be unreadable
/// on a busy image. This brightens the text and adds a soft dark shadow for
/// contrast when a photo is set; a no-op (normal look) otherwise.
struct CaptionOverPhotoModifier: ViewModifier {
    @AppStorage(BackgroundStore.hasImageKey) private var hasImage = false

    func body(content: Content) -> some View {
        if hasImage {
            content
                .foregroundStyle(.white.opacity(0.92))
                .shadow(color: .black.opacity(0.75), radius: 3, y: 1)
        } else {
            content
        }
    }
}

extension View {
    /// Apply to a Section `header:` / `footer:` Text so it stays legible over a
    /// background photo (they render outside the frosted panels).
    func captionOverPhoto() -> some View { modifier(CaptionOverPhotoModifier()) }
}

/// Central keys + small resolvers so views don't repeat the AppStorage keys.
enum ThemeStorage {
    static let accentKey = "accentTheme"
    static let fontKey = "fontDesign"
    static let panelOpacityKey = "panelOpacity"

    static func accent(_ raw: String) -> Color {
        (AccentTheme(rawValue: raw) ?? .blue).color
    }
    static func design(_ raw: String) -> Font.Design {
        (AppFontDesign(rawValue: raw) ?? .standard).design
    }
}
