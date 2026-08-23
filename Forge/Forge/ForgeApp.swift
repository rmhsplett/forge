import SwiftUI
import SwiftData

@main
struct ForgeApp: App {

    /// We own the ModelContainer explicitly (rather than the
    /// `.modelContainer(for:)` convenience) so we have access to a context
    /// during app init and can seed the exercise library before the first
    /// view appears.
    let container: ModelContainer

    init() {
        do {
            // Registers the SwiftData schema and creates the on-disk store.
            // All eight entities are listed explicitly; SwiftData would
            // discover most via relationships, but an explicit list is the
            // clearest source of truth and avoids "unknown model" surprises.
            //
            // No CloudKit container is configured, so this is a LOCAL-only
            // store for v1 — exactly as planned. The models are already
            // CloudKit-shaped (optional/defaulted properties, explicit
            // inverses, no unique constraints), so enabling sync later is a
            // config change, not a schema rewrite.
            let schema = Schema([
                Exercise.self,
                BodyWeightEntry.self,
                Program.self,
                ProgramDay.self,
                ProgramExercise.self,
                WorkoutSession.self,
                LoggedExercise.self,
                LoggedSet.self,
            ])
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            container = try ModelContainer(for: schema, configurations: configuration)
        } catch {
            // If the store can't be created the app can't function; crashing
            // here surfaces the problem immediately in development.
            fatalError("Failed to create ModelContainer: \(error)")
        }

        // Populate the exercise library on launch (safe/idempotent — see
        // ExerciseSeeder). Runs on the container's main context.
        ExerciseSeeder.seedIfNeeded(container.mainContext)

        // Then seed the starter program. Order matters: this links to
        // exercises the line above just inserted. Also idempotent — it only
        // runs when no program exists yet.
        ProgramSeeder.seedIfNeeded(container.mainContext)

        // Activate the phone↔watch link at launch.
        _ = PhoneSessionManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // Inject the same container we seeded into the view hierarchy, so
        // @Query and @Environment(\.modelContext) work in every view.
        .modelContainer(container)
    }
}
