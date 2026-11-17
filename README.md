# 🇳🇵 FitNepal — Offline-First Android Nutrition, Macro & Hydration Tracker

**FitNepal** (`Eat Healthy • Live Better`) is an offline-first, local-only Android nutrition, calorie, macro, and hydration tracking application built with **Flutter**, **Material 3**, **Riverpod**, **GoRouter**, and **Drift + SQLite**.

It recreates the exact five-screen FitNepal specification and visual mockup (`Welcome`, `Home Dashboard`, `Add Food`, `Your Progress`, and `Profile`, plus an offline `Tips` guide in the persistent bottom navigation shell) with zero cloud dependencies, zero Firebase/analytics SDKs, and 100% on-device privacy.

---

## ✨ Five-Screen Product Architecture

1. **Welcome Screen (`/welcome`)**
   - Custom-painted **FitNepal Heart + Active Person + Green Leaves** emblem and **Nepal Himalayan Peaks & Multi-Tiered Pagoda Temple** illustration.
   - `Get Started →` primary pill CTA starting with a clean personal log (as required for production first launch), plus an optional `Units & Goals` pre-setup sheet and a 1-tap `Or explore with Mockup Sample Data →` option that seeds the exact numbers from the reference mockup (`720 / 2000 kcal`, `36%`, `62g Protein`, `84g Carbs`, `28g Fats`, `1.8 / 2.5L Water`, and `1,920 kcal` weekly chart).
2. **Home Dashboard (`/home`)**
   - Personalized greeting (`Namaste! Rahul Shah 👋`), interactive calendar date pill, and profile avatar.
   - **Calories Today** berry-red hero card (`720 / 2000 kcal`, remaining/over-by indicator, and animated `36%` progress ring clamped visually at `100%`).
   - **Three Macro Cards** (`Protein 62g`, `Carbs 84g`, `Fats 28g`) with distinct pastel tints, icons, and progress bars.
   - **On-Track Status Banner** (`You're on track! Keep going for your goal.`).
   - **Quick Actions** (`Add Food`, `Track Water`, `View Progress`, `Set Goal`) + **Hydration Today** quick-add strip (`+150 ml`, `+250 ml`, `+500 ml`) + **Today's Logged Meals** list with instant delete/undo.
3. **Add Food (`/add-food`)**
   - Instant case-insensitive offline search (`Search food...`) and horizontal pill category chips (`All`, `Fruits`, `Meals`, `Snacks`, `Drinks`, `Dairy`, `Custom`).
   - Seeded with the exact mockup items (`Apple`, `Banana`, `Dal Bhat`, `Chicken Curry`, `Veg Salad`) plus traditional Nepali meals (`Steamed Momo`, `Veg Momo`, `Whole Wheat Roti`, `Steamed Rice (Bhat)`, `Mixed Tarkari`, `Kalo Dal`, `Sel Roti`, `Bhatmas Sadeko`, `Milk`, `Masala Chiya`, `Juju Dhau`, `Kwati`, etc.) marked with nutrition estimate notes.
   - One-tap `+` quick-add or tap any row to open the **Serving Quantity & Meal Type Sheet** (`Breakfast`, `Lunch`, `Dinner`, `Snack`).
   - **Custom Food Creator** (with optional Android Photo Picker image copied into app-private storage) and bottom **Scan Food** offline barcode/nutrition lookup card.
4. **Your Progress (`/progress`)**
   - Calendar date picker and segmented pill tabs (`Overview`, `Nutrition`, `Trends`).
   - **Goal Met Card** with animated `72% Goal Met` circular progress ring and colored dot legend (`Calories 1,440 / 2,000`, `Protein 62 / 120g`, `Water 1.8 / 2.5L`).
   - **Interactive Bar Chart** (`Today`, `This Week`, `This Month`) with `Mon`–`Sun` berry gradient bars and floating dark-plum tooltip (`1,920 kcal`).
   - **Insights Card** (`You're 72% towards your weekly goal.`).
5. **Profile (`/profile`)**
   - Avatar with Android Photo Picker (`image_picker`) persisted in app-private storage, editable name (`Rahul Shah`) and tagline (`Healthy Mind, Healthy Life ❤️`).
   - **Stat Cards** (`🔥 124 Streak`, `⭐ 1.2k Points`, `🏆 7 Goals`).
   - **Settings Menu**: `My Goals`, `Notifications` (with active reminder badge `2`), `Theme` (`Light` / `Dark` / `System`), `Language` (`English` / `नेपाली`), `Privacy & Security` (Backup, Restore & Granular Delete Controls), `About FitNepal`, and local session `Log Out`.

---

## 🗄️ Database Location & Schema Policy

- **Engine**: Drift (`drift` + `drift_flutter` + `sqlite3_flutter_libs`) over SQLite.
- **Storage Location**: Stored strictly inside the Android **app-private internal directory** (`fitnepal_local_db.sqlite` via `driftDatabase(name: 'fitnepal_local_db')`). The raw SQLite database is never exposed in shared external storage.
- **Tables**:
  - `profile`: `id`, `display_name`, `avatar_path`, `created_at`, `language`, `theme_mode`, `units`, `tagline`
  - `goals`: `id`, `effective_from`, `calorie_target`, `protein_target_g`, `carbs_target_g`, `fat_target_g`, `water_target_ml`
  - `foods`: `id`, `name`, `normalized_name`, `category`, `serving_label`, `serving_amount`, `kcal`, `protein_g`, `carbs_g`, `fat_g`, `image_asset_path`, `is_custom`, `estimate_note`
  - `food_logs`: `id`, `food_id` (nullable `ON DELETE SET NULL`), `food_name_snapshot`, `logged_at`, `meal_type`, `quantity`, `serving_label`, `kcal_snapshot`, `protein_snapshot`, `carbs_snapshot`, `fat_snapshot`
  - `water_logs`: `id`, `logged_at`, `amount_ml`
  - `reminder_settings`: `id`, `enabled`, `days_of_week`, `start_minute`, `end_minute`, `interval_minutes`, `reminder_type`
  - `app_settings`: `key`, `value`
- **Historical Snapshot Integrity**: Each `food_logs` entry stores immutable snapshots of food name, serving label, calories, and macros at the moment of logging. Editing or deleting a custom food later never corrupts historical daily totals.

---

## 📦 Backup Format & Safety Policy

FitNepal exports and imports versioned JSON backups via the Android **Storage Access Framework (SAF)** system document picker:
```json
{
  "app": "FitNepal",
  "schemaVersion": 1,
  "exportedAt": "2026-11-17T10:30:00.000Z",
  "profile": { ... },
  "goals": [ ... ],
  "customFoods": [ ... ],
  "foodLogs": [ ... ],
  "waterLogs": [ ... ],
  "reminders": [ ... ],
  "appSettings": { ... }
}
```
- **Import Validation & Preview**: Validates file size (<15 MB), JSON syntax, `"app": "FitNepal"` identifier, and `schemaVersion`. Displays a preview of record counts before asking the user to **Merge** or **Replace**.
- **Automatic Rollback Safety**: Before executing a destructive restore, FitNepal captures an in-memory rollback snapshot and restores it automatically inside a transaction if any import error occurs.
- **Granular Delete Controls**: Separate confirmation-protected actions for `Clear Today's Logs`, `Clear All Log History`, `Reset Goals to Default`, and `Delete All Local Data`.

---

## 🔒 Android Permissions Rationale

FitNepal follows strict Android scoped-access principles:
- **No `INTERNET` permission**: Omitted from `AndroidManifest.xml` — the app cannot transmit personal data over the network.
- **No `MANAGE_EXTERNAL_STORAGE` / all-files access**: Uses Android Storage Access Framework (`file_picker`) for user-initiated backup/restore and Android Photo Picker (`image_picker`) for profile/food photos.
- **No Location, Contacts, or Microphone permissions**.
- **`POST_NOTIFICATIONS` (Android 13+)**: Requested contextually only when the user enables a local meal or hydration reminder, preceded by an in-app explanation dialog.
- **`CAMERA` (optional)**: Marked `android:required="false"` and requested contextually only when the user taps **Scan Food**, with a non-blocking manual lookup fallback if denied.

---

## 🚀 Setup, Code Generation & Build Commands

```bash
# 1. Fetch dependencies
flutter pub get

# 2. Generate / refresh Drift database code
dart run build_runner build --delete-conflicting-outputs

# 3. Run static analysis and unit tests
flutter analyze
flutter test

# 4. Build Debug APK, Release APK, and Release AppBundle (AAB)
flutter build apk --debug
flutter build apk --release
flutter build appbundle --release
```

> **Release Signing Note**: To sign release builds with your production keystore, create an untracked `android/key.properties` file containing `storePassword`, `keyPassword`, `keyAlias`, and `storeFile`. Keep private credentials and keystores out of source control (`.gitignore` excludes `key.properties`, `*.jks`, and `*.keystore`).
