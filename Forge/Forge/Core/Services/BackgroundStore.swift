//
//  BackgroundStore.swift
//  Forge
//
//  Persists the user's chosen background photo. The image file lives in
//  Application Support; two UserDefaults flags (mirrored by @AppStorage in
//  views) track whether one is set and a token that bumps on every change so
//  SwiftUI reloads the image.
//

import UIKit

enum BackgroundStore {

    static let hasImageKey = "hasBackgroundImage"
    static let tokenKey = "backgroundImageToken"

    private static var fileURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("forge_background.jpg")
    }

    /// Saves picked image data (downscaled to keep memory reasonable) and
    /// flips the flags so the UI updates.
    static func save(_ data: Data) {
        guard let image = UIImage(data: data) else { return }
        let jpeg = downscaled(image, maxDimension: 1600).jpegData(compressionQuality: 0.8) ?? data
        do {
            try jpeg.write(to: fileURL, options: .atomic)
            let defaults = UserDefaults.standard
            defaults.set(true, forKey: hasImageKey)
            defaults.set(defaults.integer(forKey: tokenKey) + 1, forKey: tokenKey)
        } catch {
            // Non-fatal: a failed save just means no background changes.
        }
    }

    static func remove() {
        try? FileManager.default.removeItem(at: fileURL)
        let defaults = UserDefaults.standard
        defaults.set(false, forKey: hasImageKey)
        defaults.set(defaults.integer(forKey: tokenKey) + 1, forKey: tokenKey)
    }

    static func loadImage() -> UIImage? {
        guard UserDefaults.standard.bool(forKey: hasImageKey) else { return nil }
        return UIImage(contentsOfFile: fileURL.path)
    }

    private static func downscaled(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > maxDimension else { return image }
        let scale = maxDimension / longest
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
