import SwiftUI
import SwiftData
import Charts

/// Aggregate analytics tab: this week's volume per muscle, and the body-weight
/// trend. (Per-lift strength lives in the separate Progress tab.)
struct InsightsView: View {

    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \BodyWeightEntry.date) private var weights: [BodyWeightEntry]
    @Environment(\.modelContext) private var context

    @State private var showingAddWeight = false

    var body: some View {
        NavigationStack {
            List {
                volumeSection
                    .listRowBackground(PanelBackground())
                bodyWeightSection
                    .listRowBackground(PanelBackground())
            }
            .frostedList()
            .navigationTitle("Insights")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddWeight = true
                    } label: {
                        Label("Add weigh-in", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddWeight) {
                AddBodyWeightSheet(suggestedWeightKg: weights.last?.weightKg)
            }
        }
    }

    // MARK: Weekly volume

    private var volumeSection: some View {
        let volumes = VolumeStats.currentWeek(in: sessions).sorted { $0.sets > $1.sets }
        let total = volumes.reduce(0) { $0 + $1.sets }

        return Section {
            if total == 0 {
                Text("No sets logged this week yet.")
                    .foregroundStyle(.secondary)
            } else {
                Chart(volumes) { item in
                    BarMark(
                        x: .value("Hard sets", item.sets),
                        y: .value("Muscle", item.muscle.label)
                    )
                    .foregroundStyle(color(forSets: item.sets))
                    .annotation(position: .trailing) {
                        if item.sets > 0 {
                            Text(setsText(item.sets))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .chartXAxisLabel("hard sets")
                .frame(height: CGFloat(volumes.count) * 30 + 24)
            }
        } header: {
            Text("This week's volume")
        } footer: {
            Text("Hard sets per muscle. Green = 10–20/week range, orange = under, yellow = over. Secondary muscles count half; a Left/Right pair counts once.")
        }
    }

    private func color(forSets sets: Double) -> Color {
        switch sets {
        case ..<10: return .orange
        case 10...20: return .green
        default: return .yellow
        }
    }

    private func setsText(_ sets: Double) -> String {
        sets.formatted(.number.precision(.fractionLength(0...1)))
    }

    // MARK: Body weight

    private var bodyWeightSection: some View {
        Section {
            if weights.isEmpty {
                Text("No weigh-ins yet. Tap ＋ to add one.")
                    .foregroundStyle(.secondary)
            } else {
                Chart {
                    ForEach(weights) { entry in
                        LineMark(
                            x: .value("Date", entry.date),
                            y: .value("kg", entry.weightKg),
                            series: .value("Series", "raw")
                        )
                        .foregroundStyle(.gray.opacity(0.5))
                        .symbol(.circle)
                    }
                    ForEach(movingAverage) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("kg", point.value),
                            series: .value("Series", "avg")
                        )
                        .foregroundStyle(Color.accentColor)
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartYScale(domain: weightDomain)
                .chartYAxisLabel("kg")
                .frame(height: 200)

                if let latest = weights.last {
                    LabeledContent("Latest", value: "\(latest.weightKg.formatted(.number.precision(.fractionLength(0...1)))) kg")
                }

                ForEach(recentWeights) { entry in
                    HStack {
                        Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(entry.weightKg.formatted(.number.precision(.fractionLength(0...1)))) kg")
                            .monospacedDigit()
                    }
                }
                .onDelete(perform: deleteWeights)
            }
        } header: {
            Text("Body weight")
        } footer: {
            if !weights.isEmpty {
                Text("Grey dots are weigh-ins; the accent line is a 7-day average that smooths daily noise.")
            }
        }
    }

    /// Trailing 7-day average at each weigh-in — smooths the daily bounce so
    /// the real trend (key for recomp: weight flat/down while lifts climb) is
    /// readable.
    /// Y-axis range that hugs the actual weigh-ins tightly (±2 kg, whole
    /// numbers) so slow, 1–2 kg movements are clearly visible instead of being
    /// flattened. Recomputes as weights change, so the window follows you.
    /// A minimum 6 kg window keeps it from looking cramped when readings are
    /// nearly identical.
    private var weightDomain: ClosedRange<Double> {
        let values = weights.map(\.weightKg)
        guard let minValue = values.min(), let maxValue = values.max() else {
            return 60...110
        }
        var lower = (minValue - 2).rounded(.down)
        var upper = (maxValue + 2).rounded(.up)
        if upper - lower < 6 {
            let mid = (minValue + maxValue) / 2
            lower = (mid - 3).rounded(.down)
            upper = (mid + 3).rounded(.up)
        }
        lower = max(0, lower)
        return lower...upper
    }

    private var movingAverage: [TrendPoint] {
        let window: TimeInterval = 7 * 24 * 3600
        return weights.map { entry in
            let start = entry.date.addingTimeInterval(-window)
            let inWindow = weights.filter { $0.date > start && $0.date <= entry.date }
            let average = inWindow.map(\.weightKg).reduce(0, +) / Double(max(inWindow.count, 1))
            return TrendPoint(date: entry.date, value: average)
        }
    }

    /// The most recent weigh-ins shown under the chart (newest first).
    private var recentWeights: [BodyWeightEntry] {
        Array(weights.reversed().prefix(8))
    }

    private func deleteWeights(at offsets: IndexSet) {
        for index in offsets {
            context.delete(recentWeights[index])
        }
        try? context.save()
    }
}

private struct TrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}
