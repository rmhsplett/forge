import SwiftUI
import SwiftData
import Charts

/// Full progress detail for one lift: an estimated-1RM line chart with
/// trophy markers on PR sessions, a personal-best summary, and a session log.
struct ExerciseProgressDetailView: View {

    let exercise: Exercise

    private var series: [ProgressPoint] { ExerciseProgress.series(for: exercise) }
    private var prPoints: [ProgressPoint] { series.filter(\.isPR) }

    var body: some View {
        List {
            if series.isEmpty {
                ContentUnavailableView("No data yet", systemImage: "chart.line.uptrend.xyaxis")
            } else {
                Section("Estimated 1RM over time") {
                    Chart {
                        ForEach(series) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("e1RM (kg)", point.estimatedOneRepMax)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(Color.accentColor)
                        }
                        // Trophy markers on PR sessions.
                        ForEach(prPoints) { point in
                            PointMark(
                                x: .value("Date", point.date),
                                y: .value("e1RM (kg)", point.estimatedOneRepMax)
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

                Section("Personal best") {
                    if let best = series.max(by: { $0.estimatedOneRepMax < $1.estimatedOneRepMax }) {
                        LabeledContent("Est. 1RM") {
                            HStack(spacing: 4) {
                                Image(systemName: "trophy.fill").font(.caption).foregroundStyle(.yellow)
                                Text("\(Int(best.estimatedOneRepMax.rounded())) kg").fontWeight(.bold)
                            }
                        }
                        LabeledContent("Best set", value: "\(best.bestWeightKg.formatted(.number.precision(.fractionLength(0...1)))) kg × \(best.bestReps)")
                    }
                    LabeledContent("PRs hit", value: "\(prPoints.count)")
                }

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
                            Text("\(Int(point.estimatedOneRepMax.rounded())) kg")
                                .monospacedDigit()
                        }
                    }
                }
            }
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
