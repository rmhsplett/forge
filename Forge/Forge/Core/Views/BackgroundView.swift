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

    /// A dark scrim, stronger at the very top and bottom (where the nav-bar
    /// title and tab bar sit) so their text stays legible over bright photos.
    private var scrim: some View {
        LinearGradient(
            stops: [
                // Dark enough across the whole title strip to keep white text
                // legible even over a bright/white photo, then fades fast so
                // the middle of the photo stays vivid.
                .init(color: .black.opacity(0.55), location: 0.0),
                .init(color: .black.opacity(0.45), location: 0.14),
                .init(color: .black.opacity(0.18), location: 0.30),
                .init(color: .black.opacity(0.18), location: 0.82),
                .init(color: .black.opacity(0.45), location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
