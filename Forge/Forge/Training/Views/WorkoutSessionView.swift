import SwiftUI
import SwiftData
import Combine
import UIKit

/// The live logging screen. Shows each exercise in the session with its
/// sets; the user fills in weight/reps and checks sets off, then taps Finish.
struct WorkoutSessionView: View {

    // @Bindable lets edits to the session's exercises/sets flow straight
    // back into SwiftData as the user types and toggles.
    @Bindable var session: WorkoutSession

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @StateObject private var restTimer = IntervalTimer()
    @AppStorage("compoundRestSeconds") private var compoundRest = 120
    @AppStorage("isolationRestSeconds") private var isolationRest = 90

    var body: some View {
        List {
            ForEach(sortedExercises) { logged in
                Section {
                    ForEach(sortedSets(of: logged)) { set in
                        LoggedSetRow(set: set, onComplete: { completeSet(set, in: logged) })
                    }
                    Button {
                        WorkoutSessionBuilder.addSet(to: logged, in: context)
                    } label: {
                        Label("Add set", systemImage: "plus.circle")
                            .font(.subheadline)
                    }
                } header: {
                    Text(logged.exercise?.name ?? "Exercise")
                } footer: {
                    if let pe = logged.programExercise {
                        Text("Target: \(pe.targetSets) × \(pe.repRangeLow)–\(pe.repRangeHigh)")
                    }
                }
                .listRowBackground(PanelBackground())
            }
        }
        .frostedList()
        .onAppear {
            PhoneSessionManager.shared.activeSession = session
            PhoneSessionManager.shared.send(PhoneSessionManager.makeWorkout(from: session))
        }
        .navigationTitle(session.date.formatted(date: .abbreviated, time: .shortened))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Finish") {
                    WorkoutSessionBuilder.finish(session, in: context)
                    dismiss()
                }
                .bold()
            }
            // Number pads have no return key, so give the keyboard an explicit
            // dismiss button (top-right above the keyboard).
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button {
                    dismissKeyboard()
                } label: {
                    Image(systemName: "keyboard.chevron.compact.down")
                }
            }
        }
        .onDisappear { restTimer.stop() }
        .safeAreaInset(edge: .bottom) { timerBar }
        .onReceive(PhoneSessionManager.shared.incomingEvents) { event in
            applyFromWatch(event)
        }
    }

    /// Bottom bar: session elapsed time (always) + rest countdown when active.
    private var timerBar: some View {
        HStack(spacing: 12) {
            TimelineView(.periodic(from: session.date, by: 1)) { context in
                Label(elapsed(context.date), systemImage: "clock")
                    .monospacedDigit()
            }
            Spacer()
            if restTimer.isRunning {
                Label(hms(restTimer.secondsRemaining), systemImage: "timer")
                    .monospacedDigit()
                    .foregroundStyle(.orange)
                Button("Skip") {
                    restTimer.stop()
                    PhoneSessionManager.shared.send(WorkoutSyncEvent(kind: .restSkipped, source: "phone"))
                }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .font(.subheadline)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    /// User checked a set off ON THE PHONE: start rest locally and tell the
    /// watch to tick the same box and run the same rest (with a haptic at the
    /// end). The set's weight/reps are whatever the user has entered/pre-filled.
    private func completeSet(_ set: LoggedSet, in logged: LoggedExercise) {
        let seconds = restSeconds(for: set)
        restTimer.onFinish = {}
        restTimer.start(seconds: seconds)
        let exIdx = sortedExercises.firstIndex { $0 === logged } ?? 0
        let setIdx = sortedSets(of: logged).firstIndex { $0 === set } ?? 0
        PhoneSessionManager.shared.send(
            WorkoutSyncEvent(kind: .setCompleted, exerciseIndex: exIdx,
                             setIndex: setIdx, seconds: seconds, source: "phone")
        )
    }

    /// Dismisses the number pad (which has no return key of its own).
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    /// Rest duration for a set, per the compound/isolation setting.
    private func restSeconds(for set: LoggedSet) -> Int {
        let compound = set.loggedExercise?.exercise?.isCompound ?? true
        return compound ? compoundRest : isolationRest
    }

    /// Applies a live event that came FROM the watch: a set checked off on the
    /// wrist marks that set complete here (at its pre-filled suggested weight —
    /// adjust it afterward) and starts rest; a skip clears rest. Never
    /// re-broadcasts, so there's no echo back to the watch.
    private func applyFromWatch(_ event: WorkoutSyncEvent) {
        switch event.kind {
        case .setCompleted:
            if let ex = event.exerciseIndex, ex < sortedExercises.count {
                let sets = sortedSets(of: sortedExercises[ex])
                if let si = event.setIndex, si < sets.count {
                    let set = sets[si]
                    if !set.isCompleted {
                        set.isCompleted = true
                        set.completedAt = .now
                        try? context.save()
                    }
                }
            }
            restTimer.onFinish = {}
            restTimer.start(seconds: event.seconds ?? isolationRest)
        case .restSkipped:
            restTimer.stop()
        case .roundCompleted:
            break   // conditioning-only; handled by ConditioningSessionView
        }
    }

    private func elapsed(_ now: Date) -> String {
        hms(Int(now.timeIntervalSince(session.date)))
    }

    private func hms(_ seconds: Int) -> String {
        let s = max(0, seconds)
        if s >= 3600 {
            return String(format: "%d:%02d:%02d", s / 3600, (s % 3600) / 60, s % 60)
        }
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    private var sortedExercises: [LoggedExercise] {
        session.exercises.sorted { $0.order < $1.order }
    }

    private func sortedSets(of logged: LoggedExercise) -> [LoggedSet] {
        logged.sets.sorted { ($0.order, $0.side.sortRank) < ($1.order, $1.side.sortRank) }
    }
}

/// One editable set row: set number, weight, reps, and a completion toggle.
private struct LoggedSetRow: View {

    @Bindable var set: LoggedSet
    var onComplete: () -> Void = {}
    @Environment(\.modelContext) private var context

    /// Which cell's long-press wheel is open (nil = none).
    @State private var wheel: WheelTarget?
    private enum WheelTarget: Int, Identifiable { case weight, reps; var id: Int { rawValue } }

    /// Bridges the Int reps to the wheel's Double values.
    private var repsAsDouble: Binding<Double> {
        Binding(get: { Double(set.reps) }, set: { set.reps = Int($0.rounded()) })
    }

    private func resignKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Tap the set number to choose the side (Left / Both / Right).
            Menu {
                ForEach(SetSide.allCases) { option in
                    Button {
                        selectSide(option)
                    } label: {
                        if set.side == option {
                            Label(option.label, systemImage: "checkmark")
                        } else {
                            Text(option.label)
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text("Set \(set.order + 1)")
                    if let badge = set.side.badge {
                        Text(badge)
                            .font(.caption2.bold())
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.accentColor.opacity(0.2), in: Capsule())
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 72, alignment: .leading)
            }
            .buttonStyle(.plain)

            HStack(spacing: 4) {
                TextField("0", value: $set.weightKg, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 56)
                    .simultaneousGesture(LongPressGesture(minimumDuration: 0.4).onEnded { _ in
                        resignKeyboard(); wheel = .weight
                    })
                // Long-press "kg" to log an assistance band (e.g. banded chin-ups).
                Text("kg")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .contextMenu { bandMenu }
                if let band = set.assistBand {
                    Circle()
                        .fill(color(for: band))
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(.secondary.opacity(0.4), lineWidth: 0.5))
                        .accessibilityLabel("\(band.label) assist band")
                }
            }

            HStack(spacing: 4) {
                TextField("0", value: $set.reps, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 40)
                    .simultaneousGesture(LongPressGesture(minimumDuration: 0.4).onEnded { _ in
                        resignKeyboard(); wheel = .reps
                    })
                Text("reps").font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                set.isCompleted.toggle()
                set.completedAt = set.isCompleted ? .now : nil
                if set.isCompleted { onComplete() }   // kick off the rest timer
            } label: {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(set.isCompleted ? Color.accentColor : Color.secondary)
            }
            .buttonStyle(.plain)
        }
        .textFieldStyle(.roundedBorder)
        .sheet(item: $wheel) { target in
            switch target {
            case .weight:
                WheelPickerSheet(title: "Weight", unit: "kg",
                                 values: Array(stride(from: 0.0, through: 300.0, by: 0.5)),
                                 fractionDigits: 1, value: $set.weightKg)
            case .reps:
                WheelPickerSheet(title: "Reps", unit: "",
                                 values: Array(stride(from: 0.0, through: 60.0, by: 1.0)),
                                 fractionDigits: 0, value: repsAsDouble)
            }
        }
    }

    /// Sets the side for this row. When a `both` set is switched to Left or
    /// Right, we spawn a companion set for the OPPOSITE side at the same set
    /// number — so "Set 1 → Right" produces a paired "Set 1 → Left" row. The
    /// companion copies the weight (usually identical per side) but starts
    /// with empty reps. Guarded so it only splits once, never runaway.
    private func selectSide(_ newSide: SetSide) {
        let wasBoth = (set.side == .both)
        set.side = newSide

        if wasBoth, newSide != .both, let parent = set.loggedExercise {
            let opposite: SetSide = (newSide == .left) ? .right : .left
            let alreadyPaired = parent.sets.contains {
                $0 !== set && $0.order == set.order && $0.side == opposite
            }
            if !alreadyPaired {
                let companion = LoggedSet(
                    order: set.order,
                    weightKg: set.weightKg,
                    reps: 0,
                    side: opposite,
                    isCompleted: false
                )
                parent.sets.append(companion)
            }
        }

        try? context.save()
    }

    /// Long-press menu on "kg" to attach/remove an assistance band.
    @ViewBuilder private var bandMenu: some View {
        Button {
            set.assistBand = nil
            try? context.save()
        } label: {
            Label("No band", systemImage: set.assistBand == nil ? "checkmark" : "circle")
        }
        ForEach(BandColor.allCases) { band in
            Button {
                set.assistBand = band
                try? context.save()
            } label: {
                if set.assistBand == band {
                    Label(band.label, systemImage: "checkmark")
                } else {
                    Text(band.label)
                }
            }
        }
    }

    private func color(for band: BandColor) -> Color {
        switch band {
        case .red: return .red
        case .blue: return .blue
        case .purple: return .purple
        case .black: return .primary
        case .green: return .green
        }
    }
}

/// A spinning number wheel for weight/reps, shown on long-press of a cell. Opens
/// on the value that's already in the field; the keyboard tap-to-type path is
/// unchanged. Applies the chosen value on Done.
private struct WheelPickerSheet: View {
    let title: String
    let unit: String
    let values: [Double]
    let fractionDigits: Int
    @Binding var value: Double

    @Environment(\.dismiss) private var dismiss
    @State private var selection: Double = 0

    var body: some View {
        NavigationStack {
            Picker("", selection: $selection) {
                ForEach(values, id: \.self) { v in
                    Text(unit.isEmpty
                         ? v.formatted(.number.precision(.fractionLength(fractionDigits)))
                         : "\(v.formatted(.number.precision(.fractionLength(fractionDigits)))) \(unit)")
                        .tag(v)
                }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { value = selection; dismiss() }
                }
            }
        }
        .presentationDetents([.height(260)])
        .onAppear {
            // Start on the value already in the field (snapped to the nearest step).
            selection = values.min(by: { abs($0 - value) < abs($1 - value) }) ?? (values.first ?? 0)
        }
    }
}
