import SwiftUI

/// Shared row content for an exercise: equipment icon + name, with an optional
/// muscle subtitle. Used by both the Library and the exercise picker so they
/// look identical.
struct ExerciseRowLabel: View {
    let exercise: Exercise
    var showMuscle: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            ExerciseIconView(displayType: exercise.displayType)
                .frame(width: 30, height: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.headline)
                if showMuscle {
                    Text(exercise.primaryMuscle.label)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

/// Muscle-grouped sections with a dedicated Kettlebell section at the end.
/// Place inside a `List`. The `row` closure receives each exercise and a flag
/// for whether it's in the Kettlebell section (so callers can show the muscle
/// subtitle only where it's not redundant). Empty groups are omitted.
struct GroupedExerciseSections<Row: View>: View {
    let exercises: [Exercise]
    @ViewBuilder let row: (Exercise, Bool) -> Row

    var body: some View {
        ForEach(MuscleGroup.allCases, id: \.self) { muscle in
            let items = exercises.filter { $0.displayType != .kettlebell && $0.primaryMuscle == muscle }
            if !items.isEmpty {
                Section(muscle.label) {
                    ForEach(items) { row($0, false) }
                }
            }
        }

        let kettlebell = exercises.filter { $0.displayType == .kettlebell }
        if !kettlebell.isEmpty {
            Section("Kettlebell") {
                ForEach(kettlebell) { row($0, true) }
            }
        }
    }
}
