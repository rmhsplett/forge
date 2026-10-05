import SwiftUI
import SwiftData
import Charts

/// Full progress detail for one lift: a line chart (estimated 1RM or heaviest
/// weight, per the Settings choice) with trophy markers on PR sessions, a
/// personal-best summary, and a session log. All weights are the real total
/// lifted (barbell per-side is counted as weight × 2 + bar).
struct ExerciseProgressDetailView: View {

    let exercise: Exercise

    @AppStorage("progressMetric") private var metricRaw = ProgressMetric.e1rm.rawValue
    private var metric: ProgressMetric { ProgressMetric(rawValue: metricRaw) ?? .e1rm }

    private var series: [ProgressPoint] { ExerciseProgress.series(for: exercise, metric: metric) }
    private var prPoints: [ProgressPoint] { series.filter(\.isPR) }

    var body: some View {
        List {
            if series.isEmpty {
                ContentUnavailableView("No data yet", systemImage: "chart.line.uptrend.xyaxis")
            } else {
                Section("\(metric.label) over time") {
                    Chart {
                        ForEach(series) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("kg", point.value)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(Color.accentColor)
                        }
                        // Trophy markers on PR sessions.
                        ForEach(prPoints) { point in
                            PointMark(
                                x: .value("Date", point.date),
                                y: .value("kg", point.value)
                            )
                            .foregroundStyle(.yellow)
                            .annotation(position: .top) {
                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.yellow)
                            }
                        }
                    }
                    .frame(height: 220)
                    .chartYAxisLabel("kg")
                }
                .listRowBackground(PanelBackground())

                Section("Personal best") {
                    if let best = series.max(by: { $0.value < $1.value }) {
                        LabeledContent(metric == .e1rm ? "Est. 1RM" : "Heaviest") {
                            HStack(spacing: 4) {
                                Image(systemName: "trophy.fill").font(.caption).foregroundStyle(.yellow)
                                Text("\(Int(best.value.rounded())) kg").fontWeight(.bold)
                            }
                        }
                        LabeledContent("Best set", value: "\(best.bestWeightKg.formatted(.number.precision(.fractionLength(0...1)))) kg × \(best.bestReps)")
                    }
                    LabeledContent("PRs hit", value: "\(prPoints.count)")
                }
                .listRowBackground(PanelBackground())

                Section("Sessions") {
                    ForEach(series.reversed()) { point in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(point.date.formatted(date: .abbreviated, time: .omitted))
                                Text("\(point.bestWeightKg.formatted(.number.precision(.fractionLength(0...1)))) kg × \(point.bestReps)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if point.isPR {
                                Image(systemName: "trophy.fill")
                                    .font(.caption)
                                    .foregroundStyle(.yellow)
                            }
                            Text("\(Int(point.value.rounded())) kg")
                                .monospacedDigit()
                        }
                    }
                }
                .listRowBackground(PanelBackground())
            }
        }
        .frostedList()
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
