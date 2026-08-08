import SwiftUI
import UIKit

/// The app-wide backdrop: the user's photo (with a legibility scrim) when one
/// is set, otherwise the normal grouped-background color so the UI looks
/// standard. Sits behind the TabView; transparent lists let it show through.
struct BackgroundView: View {

    @AppStorage(BackgroundStore.hasImageKey) private var hasImage = false
    @AppStorage(BackgroundStore.tokenKey) private var token = 0

    var body: some View {
        Group {
            if hasImage, let image = BackgroundStore.loadImage() {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .overlay(scrim)
                    .ignoresSafeArea()
            } else {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
            }
        }
        // Reload when the chosen image changes.
        .id(token)
    }

    /// A soft top-to-bottom dark scrim so frosted pills and text stay legible
    /// over bright photos.
    private var scrim: some View {
        LinearGradient(
            colors: [.black.opacity(0.15), .black.opacity(0.35)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
