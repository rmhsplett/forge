# FORGE — Launch Runbook

The ordered path to getting FORGE (iOS + Apple Watch) onto the App Store.
Recommended route: **TestFlight beta first**, then flip to public review.

Legend: 🧑 = you do it · 🤖 = already done in the repo · ⏳ = waiting on something

---

## Phase 0 — Accounts (critical path, start now)

- [ ] 🧑 **Enrol in the Apple Developer Program** — $99/yr at
      https://developer.apple.com/programs/enroll/. Approval can take 24–48h,
      so start this first; everything else can be prepped in parallel.
- [ ] 🧑 Sign in to **App Store Connect** (https://appstoreconnect.com) once
      approved.

Bundle IDs already set in the project (Apple will register them for you the
first time you archive with automatic signing):
- iOS app: `com.github.rmhsplett.forge`
- Watch app: `com.github.rmhsplett.forge.watchkitapp`
- Team ID: `PW6Y6KMNDK`

---

## Phase 1 — Repo readiness (mostly done)

- [x] 🤖 **Privacy manifests** added for both targets (`PrivacyInfo.xcprivacy`)
      — declares no tracking, no data collected off-device, UserDefaults reason.
- [x] 🤖 **HealthKit usage strings** fixed (the watch had blank ones, which
      would have been an automatic rejection).
- [x] 🤖 HealthKit entitlement present on both targets; watch background mode
      (`workout-processing`) declared.
- [x] 🤖 Local-only data store (no CloudKit container to configure for v1).
- [ ] 🧑 **Xcode 26 / iOS 26 SDK.** From **28 April 2026** every submission must
      be built with the iOS 26 / watchOS 26 SDK. Update Xcode if needed (the
      watch target is already on watchOS 26.5).
- [ ] 🧑 **App icon.** Add a 1024×1024 icon to the asset catalog (`AppIcon`).
      Xcode 16 generates the smaller sizes from the single 1024 image. A watch
      icon set is also needed. (Ask me to generate a starter icon.)
- [ ] 🧑 **Export compliance.** FORGE makes no custom-encrypted network calls,
      so add `ITSAppUsesNonExemptEncryption = NO` to the iOS Info.plist settings
      to skip the encryption questionnaire on every upload.

---

## Phase 2 — Create the app record 🧑

In App Store Connect → **Apps → +**:
- [ ] Platform: iOS. Name: **Forge** (must be globally unique — have a backup
      name ready in case "Forge" is taken, e.g. "Forge Lifting").
- [ ] Primary language, bundle ID `com.github.rmhsplett.forge`, SKU (any string,
      e.g. `forge-ios-001`).
- [ ] Fill the **App Privacy** section → **Data Not Collected** (see
      `app-store-listing.md`).
- [ ] Set **Age rating** via the questionnaire (all "None" → 4+).

---

## Phase 3 — First build to TestFlight 🧑

1. [ ] In Xcode: set the run destination to **Any iOS Device (arm64)**.
2. [ ] Bump the build number if re-uploading (`CURRENT_PROJECT_VERSION`).
3. [ ] **Product → Archive** (this builds iOS + the embedded watch app).
4. [ ] In the **Organizer**, select the archive → **Distribute App → App Store
       Connect → Upload**. Automatic signing will create the distribution
       certificate + provisioning profiles for you.
5. [ ] Wait for the build to finish **processing** in App Store Connect
       (minutes to ~1h), then it appears under **TestFlight**.
6. [ ] Add yourself as an **Internal Tester** (no beta review needed) and
       install via the TestFlight app on your iPhone — the watch app installs
       alongside it.

---

## Phase 4 — Real-device validation (the reason for a beta) 🧑

Test the things the simulator can't:
- [ ] Start a strength workout on the phone → confirm it appears on the watch.
- [ ] Complete sets on the watch → rest timer counts the **exact** phone
      duration (compound vs. isolation) and haptics fire.
- [ ] Live **heart rate** shows on the watch during a workout.
- [ ] Finish on the watch → rounds / HR flow back to the phone session.
- [ ] Circuit + AMRAP formats drive correctly from the wrist.
- [ ] HealthKit prompts show your usage strings and body-weight sync works.
- [ ] Background photo + frosted panels look right on a real screen.

Fix anything that surfaces, re-archive, upload a new build, repeat.

---

## Phase 5 — Store listing 🧑

- [ ] Paste description, keywords, promo text from `app-store-listing.md`.
- [ ] Upload **screenshots**: 6.9" iPhone (1320×2868) is required; add Apple
      Watch screenshots since the app includes a watch app. Capture from the
      simulator (File → Save Screen) or a real device.
- [ ] Support URL + (optional) marketing URL. A privacy policy URL is required
      for health apps — a short page stating "data stays on your device / your
      iCloud, nothing is collected" is enough.

---

## Phase 6 — Ship it 🧑

- [ ] Select the tested build on the app's **iOS App** version page.
- [ ] **Submit for Review.** For a health app, add a **Review note** explaining
      that HealthKit is used only to read heart rate/body weight and write
      workouts, all on-device (pre-written in `app-store-listing.md`).
- [ ] Review typically lands in ~24–48h. Address any rejection, resubmit.
- [ ] On approval, **Release** (manually or automatically).

Optional before Phase 6: add **External testers** in TestFlight (requires a
one-time beta app review) if you want friends to try it first.

---

## Known follow-ups (post-v1)

- Milestone 6: **Nutrition** module (meal templates + daily macro roll-up).
- Enable **CloudKit sync** (models are already shaped for it — add an iCloud
  container entitlement + `cloudKitDatabase` on the ModelConfiguration).
- Garmin on-watch Connect IQ app (reading via Apple Health already works).
