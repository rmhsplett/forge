//
//  ContentView.swift
//  ForgeWatch Watch App
//

import SwiftUI

struct ContentView: View {

    @ObservedObject private var manager = WatchSessionManager.shared

    var body: some View {
        NavigationStack {
            if let workout = manager.workout {
                WatchWorkoutView(workout: workout)
            } else {
                noWorkout
            }
        }
        .tint(watchAccent(manager.workout?.accent))   // match the phone's theme
        .onAppear { manager.reload() }
    }

    /// Maps the phone's accent raw value to a watch tint color.
    private func watchAccent(_ name: String?) -> Color {
        switch name {
        case "red": return .red
        case "orange": return .orange
        case "green": return .green
        case "teal": return .teal
        case "indigo": return .indigo
        case "purple": return .purple
        case "pink": return .pink
        default: return .blue
        }
    }

    private var noWorkout: some View {
        ScrollView {
            VStack(spacing: 8) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title2)
                Text("No workout")
                    .font(.headline)
                Text("Start one on your phone")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Divider()

                // Connection diagnostics (temporary — helps debug the sim link).
                Text(manager.status)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Reload") { manager.reload() }

                Divider()
                Text("Load demo").font(.caption2).foregroundStyle(.secondary)
                Button("Strength") { manager.loadDemoStrength() }
                Button("Circuit") { manager.loadDemoCircuit() }
                Button("AMRAP") { manager.loadDemoAMRAP() }
            }
            .font(.caption)
            .padding(.horizontal, 6)
        }
    }
}

#Preview {
    ContentView()
}
