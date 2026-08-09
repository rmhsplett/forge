import SwiftUI
import SwiftData

/// The Progress tab: a fast-scan list of every lift you've actually logged,
/// each showing its recent trend and a trophy + bold best-e1RM readout.
/// Tap a lift for its full chart. (Named ...TabView to avoid colliding with
/// SwiftUI's built-in `ProgressView` spinner.)
struct ProgressTabView: View {

    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    /// Only exercises with logged history, newest-trained first.
    private var loggedLifts: [(exercise: Exercise, series: [ProgressPoint])] {
        exercises.compactMap { exercise in
            let series = ExerciseProgress.series(for: exercise)
            return series.isEmpty ? nil : (exercise: exercise, series: series)
        }
        .sorted { ($0.series.last?.date ?? .distantPast) > ($1.series.last?.date ?? .distantPast) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(loggedLifts, id: \.exercise.id) { item in
                    NavigationLink {
                        ExerciseProgressDetailView(exercise: item.exercise)
                    } label: {
                        ProgressLiftRow(exercise: item.exercise, series: item.series)
                    }
                }
                .listRowBackground(PanelBackground())
            }
            .frostedList()
            .navigationTitle("Progress")
            .overlay {
                if loggedLifts.isEmpty {
                    ContentUnavailableView(
                        "No progress yet",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("Log a workout and your lifts start charting here.")
                    )
                }
            }
        }
    }
}

/// A single lift row: name + trend on the left, trophy + bold best e1RM on
/// the right (the PWA-style personal-best readout).
private struct ProgressLiftRow: View {

    let exercise: Exercise
    let series: [ProgressPoint]

    private var bestE1RM: Double { series.map(\.estimatedOneRepMax).max() ?? 0 }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(exercise.name).font(.headline)
                trendCaption
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "trophy.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
                Text("\(Int(bestE1RM.rounded())) kg")
                    .font(.headline.weight(.bold))
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder private var trendCaption: some View {
        switch ExerciseProgress.trend(from: series) {
        case .improving(let percent):
            Label("Up \(Int(percent.rounded()))% · 6 wk", systemImage: "arrow.up.right")
                .font(.caption).foregroundStyle(.green)
        case .declining(let percent):
            Label("Down \(Int(percent.rounded()))% · 6 wk", systemImage: "arrow.down.right")
                .font(.caption).foregroundStyle(.orange)
        case .stalled:
            Label("Stalled · 6 wk", systemImage: "arrow.right")
                .font(.caption).foregroundStyle(.secondary)
        case .notEnoughData:
            Text("Best: \(bestSetCaption)")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var bestSetCaption: String {
        guard let best = series.max(by: { $0.estimatedOneRepMax < $1.estimatedOneRepMax }) else { return "—" }
        return "\(best.bestWeightKg.formatted(.number.precision(.fractionLength(0...1)))) kg × \(best.bestReps)"
    }
}
