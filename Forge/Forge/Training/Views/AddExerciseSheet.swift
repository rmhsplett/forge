import SwiftUI
import SwiftData

/// Form for creating a custom exercise, saved straight into the library.
/// Custom exercises get a `custom_…` id so the seeder never overwrites or
/// re-adds them, keeping them separate from the bundled seed movements.
struct AddExerciseSheet: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var primaryMuscle: MuscleGroup = .chest
    @State private var equipment: ExerciseDisplayType = .barbell
    @State private var isUnilateral = false
    @State private var repLow = 8
    @State private var repHigh = 12
    @State private var restSeconds = 90

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    TextField("Name", text: $name)

                    Picker("Primary muscle", selection: $primaryMuscle) {
                        ForEach(MuscleGroup.allCases, id: \.self) { muscle in
                            Text(muscle.label).tag(muscle)
                        }
                    }

                    Picker("Equipment", selection: $equipment) {
                        ForEach(ExerciseDisplayType.allCases, id: \.self) { type in
                            Text(type.pickerLabel).tag(type)
                        }
                    }

                    Toggle("Single-arm / single-leg", isOn: $isUnilateral)
                }

                Section("Defaults") {
                    Stepper("Rep range low: \(repLow)", value: $repLow, in: 1...50)
                    Stepper("Rep range high: \(repHigh)", value: $repHigh, in: 1...50)
                    Stepper("Rest: \(restSeconds)s", value: $restSeconds, in: 15...300, step: 15)
                }
            }
            .navigationTitle("New exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(trimmedName.isEmpty)
                }
            }
        }
    }

    private func save() {
        let increment: Double
        switch equipment {
        case .kettlebell: increment = 4
        case .dumbbell: increment = 2
        default: increment = 2.5
        }

        let exercise = Exercise(
            id: "custom_" + UUID().uuidString,
            name: trimmedName,
            primaryMuscle: primaryMuscle,
            secondaryMuscles: [],
            displayType: equipment,
            isUnilateral: isUnilateral,
            defaultRestSeconds: restSeconds,
            progressionIncrementKg: increment,
            barWeightKg: equipment == .barbell ? 20 : nil,
            defaultRepRangeLow: min(repLow, repHigh),
            defaultRepRangeHigh: max(repLow, repHigh),
            notes: nil
        )
        context.insert(exercise)
        try? context.save()
        dismiss()
    }
}
