# 🍽️ EatWise — AI-Powered Nutrition & Fitness Tracker

> **Smart calorie counting and macro tracking for Filipino cuisine. Use food scale for more accurate results.**

---

## 📖 Table of Contents
1. [What is EatWise?](#what-is-eatwise)
2. [App Screens & Navigation](#app-screens--navigation)
3. [How to Run](#how-to-run)
4. [Project Structure](#project-structure)
5. [How Code Works (Layer by Layer)](#how-code-works)
6. [State Management (Riverpod)](#state-management)
7. [AI Integration Flow](#ai-integration-flow)
8. [Database Schema](#database-schema)
9. [How to Develop a Feature](#develop-feature)
10. [Commands & Troubleshooting](#commands)

---

## What is EatWise?

EatWise is a Flutter app that helps you track daily food, macros, calories, and weight using AI.

| Feature | What It Does |
|---|---|
| **Dashboard** | Daily summary — calories ring, macro bars, weight chart, weekly stats |
| **AI Scanner** | Photo → AI estimates food name + macros |
| **Chat Log** | Type "I ate..." → AI parses into nutrition data |
| **Barcode Scan** | Scan product → local food database lookup |
| **History** | Past logs with calendar month view |
| **Profile** | Set your details → auto BMI/BMR/TDEE targets |
| **Fasting** | Intermittent fasting timer with eating window |
| **Weight** | Log weight daily, see trend over time |
EatWise - AI-Powered Nutrition & Fitness Tracker


Overview
---

## App Screens & Navigation

5-tab bottom navigation:

```
┌─────────┬────────┬────────┬─────────┬─────────┐
│  Home   │  Scan  │  Log   │ History │ Profile │
└─────────┴────────┴────────┴─────────┴─────────┘
```

**Home** — Calorie ring, macro rings, weight card, weekly chart
**Scan** — Photo (AI Vision) or Barcode scanner modes
**Log** — Type food description → AI parses into editable items
**History** — List view + calendar view with date navigation
**Profile** — Name/age/weight/goal → auto-calculates targets → apply to dashboard

---

## How to Run

### Prerequisites
- Flutter 3.22+
- Android Studio or VS Code + Flutter extensions
- Android phone/emulator

---

## Project Structure

```
lib/
├── main.dart                    # Entry → loads .env → ProviderScope(EatWiseApp)
├── app.dart                     # MaterialApp.router with theming
├── core/                        # 🧠 Shared infrastructure
│   ├── ai/                      # Gemini, Groq, OpenRouter services
│   ├── constants/               # Colors, keys
│   ├── database/                # SQLite (app_database.dart)
│   ├── router/                  # GoRouter with 5-tab bottom nav
│   ├── storage/                 # Secure API key storage
│   └── theme/                   # Light/dark themes
├── features/                    # 🏠 Feature modules
│   ├── dashboard/               # Home + History + Profile + Manual Log
│   │   ├── data/                # Repository classes
│   │   ├── models/              # DailySummary, WeeklyStats, etc.
│   │   ├── providers/           # Riverpod state providers
│   │   └── presentation/        # Screens + widgets
│   ├── food_ai/                 # Camera scan + barcode
│   ├── chat_log/                # Text chat for food logging
│   └── settings/                # Settings screen
└── services/                    # 🔗 Bridging business logic
```

---

## How Code Works

### Entry Point Flow
```
main() → LoadingScreen → init(.env, keys) → ProviderScope(EatWiseApp)
```

### Dashboard Data Flow
```
DashboardScreen
  watches targetCaloriesProvider    → AppDatabase (settings table)
  watches dailyTotalsProvider       → AppDatabase (logs table)
  watches profileProvider           → AppDatabase (settings)
  watches weightProvider            → AppDatabase (weights table)
  watches weeklyChartProvider       → DashboardRepository → SQL
    → Models: DailySummary, WeeklyStats
      → Widgets: CalorieRingChart, MacroRingsRow, WeightCard
```

### Profile Data Flow
```
ProfileScreen
  → User enters name/age/weight/goal → profileProvider.update()
    → ProfileData calculates: BMI, BMR, TDEE, recommendedCalories
      → "Apply Targets" → saves to settings table
        → Dashboard reads targets from providers
```

---

## AI Integration Flow

### Photo Scanning
```
Photo → food_ai_screen._pickAndAnalyze()
  → gemini_vision_service.analyzeImage(file)
    → Base64 encode → Gemini Vision API
      → ai_json_parser: clean markdown → validate JSON
        → MealAnalysis { foods, totals, summary }
          → Editable cards → confirm → save to DB
```

### Chat Logging (with Fallback)
```
Text → chat_log_screen._send()
  → ask_ai_service → ai_fallback_orchestrator
    ├─ Gemini (primary) — gemini_chat_service.dart
    ├─ Groq (fallback 1) — groq_provider.dart
    └─ OpenRouter (fallback 2) — openrouter_provider.dart
      → ai_json_parser → FoodItem list → editable cards → save
```

### Barcode Scanning
```
Barcode → mobile_scanner → barcode[0].rawValue
  → local_food_db.search(barcode)
    → Found: build FoodItem from match data
    → Not found: "Not in database" dialog
```

---

## Database Schema

### `logs` — Food entries
```sql
CREATE TABLE logs (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    name       TEXT NOT NULL,
    log_date   TEXT NOT NULL,     -- 'YYYY-MM-DD'
    meal_type  TEXT NOT NULL,     -- breakfast/lunch/dinner/snack
    calories   REAL DEFAULT 0,
    protein_g  REAL DEFAULT 0,
    carbs_g    REAL DEFAULT 0,
    fats_g     REAL DEFAULT 0,
    portion_g  REAL,             -- grams
    portion_desc TEXT            -- "1 cup"
);
```

### `settings` — Key-value store
```sql
CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT);
-- Keys: profile_name, profile_age, target_calories, etc.
```

### `weights` — Weight history
```sql
CREATE TABLE weights (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    date       TEXT NOT NULL,
    weight_kg  REAL NOT NULL,
    notes      TEXT
);
```

---

## How to Develop a Feature

Example: Add Water Tracking

1. **Create table** in `app_database.dart`
2. **Add methods**: `logWater(date, ml)` and `getDailyWater(date)`
3. **Create provider**: `dailyWaterProvider = FutureProvider.autoDispose`
4. **Build widget**: add water card to dashboard
5. **Add button**: quick "+" button for logging

---

## Common Commands
```bash
flutter run --release            # Run on device
flutter build apk                # Build Android APK
flutter analyze                  # Code check
flutter test                     # Run tests
flutter clean && flutter pub get # Full rebuild
dart run build_runner build --delete-conflicting-outputs  # Generate code
```

## Troubleshooting
| Problem | Solution |
|---|---|
| API key error | Add keys to `.env` |
| Barcode crash | Check camera permissions |
| White screen | Verify `.env` exists |
| Image not saving | Fixed — syncs before save |
| Long decimals | Fixed — `.toStringAsFixed(0)` |

---

> **Built for tracking Filipino food. Eat wisely!** 🍽️
