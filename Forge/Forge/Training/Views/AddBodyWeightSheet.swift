import SwiftUI
import SwiftData

/// Sheet for recording a manual weigh-in. HealthKit-sourced entries will come
/// later; these are `.manual`.
struct AddBodyWeightSheet: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// Prefill with the most recent weight so a small change is a quick edit.
    let suggestedWeightKg: Double?

    @State private var weightKg: Double = 0
    @State private var date: Date = .now

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: .date)

                HStack {
                    Text("Weight")
                    Spacer()
                    TextField("0", value: $weightKg, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 90)
                    Text("kg").foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add weigh-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(weightKg <= 0)
                }
            }
            .onAppear {
                if weightKg == 0, let suggested = suggestedWeightKg { weightKg = suggested }
            }
        }
    }

    private func save() {
        let entry = BodyWeightEntry(date: date, weightKg: weightKg, source: .manual)
        context.insert(entry)
        try? context.save()

        // Mirror the weigh-in to Apple Health (no-op if not authorized).
        let kg = weightKg
        let when = date
        Task { await HealthKitService.saveBodyMass(kg, date: when) }

        dismiss()
    }
}
