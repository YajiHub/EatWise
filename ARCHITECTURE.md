# EatWise - Architecture & Directory Structure

> **EatWise** is an offline-first, AI-augmented nutrition, fitness, and macro tracker tailored for Filipino cuisine, built with Flutter, Riverpod, SQLite, and Google Gemini API.

---

## 🏛️ Architecture Overview

EatWise follows **Feature-First Clean Architecture** principles:
- **Core Layer (`lib/core/`)**: Cross-cutting infrastructure including database persistence (SQLite), encrypted API key storage (`flutter_secure_storage`), multi-model AI services (Google Gemini Flash), declarative routing (`go_router`), and Material 3 design tokens.
- **Features Layer (`lib/features/`)**: Self-contained domain modules, each containing data sources/repositories, domain models/entities, Riverpod state providers, and Flutter presentation widgets/screens.
- **Services Layer (`lib/services/`)**: Lightweight orchestration services bridging presentation with AI and persistence (e.g. food logging and network status).

---

## 📁 Repository Directory Structure

```
macro_pinoy/
├── lib/
│   ├── main.dart                          # App initialization, secure storage bootstrap
│   ├── app.dart                           # MaterialApp.router configuration & theme bindings
│   ├── loading_screen.dart                # Splash & initialization sequence
│   │
│   ├── core/
│   │   ├── ai/
│   │   │   ├── ai_config.dart             # API key resolution (SecureStorage, Env, Dart-Define)
│   │   │   ├── gemini_vision_service.dart # Multimodal meal image recognition
│   │   │   └── gemini_chat_service.dart   # Conversational food parsing & multi-turn advice
│   │   ├── constants/
│   │   │   ├── app_colors.dart            # Semantic color palette & gradients
│   │   │   └── api_keys.dart              # Secure storage key constants
│   │   ├── database/
│   │   │   ├── app_database.dart          # SQLite schema (v7 migration) & CRUD operations
│   │   │   └── local_foods_data.dart      # Curated Filipino food nutrition database
│   │   ├── errors/
│   │   │   └── failures.dart              # Typed domain failure & exception definitions
│   │   ├── router/
│   │   │   ├── app_router.dart            # Declarative GoRouter configuration
│   │   │   └── bottom_nav_bar.dart        # 5-tab persistent bottom navigation bar
│   │   ├── storage/
│   │   │   └── secure_storage_service.dart# Encrypted key storage (AES / KeyStore / Keychain)
│   │   └── theme/
│   │       ├── app_theme.dart             # Material 3 light/dark themes
│   │       └── text_styles.dart           # Typography scale
│   │
│   ├── features/
│   │   ├── dashboard/                     # Core analytics & daily summaries
│   │   │   ├── data/                      # Dashboard & food log repositories
│   │   │   ├── models/                    # DailySummary, WeeklyStats, RemainingMacros
│   │   │   ├── presentation/
│   │   │   │   ├── providers/             # Daily insights & snack suggestion state
│   │   │   │   ├── screens/               # DashboardScreen, HistoryScreen, ProfileScreen
│   │   │   │   └── widgets/               # CalorieRing, MacroProgress, FastingTimer, etc.
│   │   │   └── providers/                 # Filter, selected date, and weight providers
│   │   │
│   │   ├── food_ai/                       # AI meal logging & barcode recognition
│   │   │   ├── data/                      # Gemini vision & food log repositories
│   │   │   ├── domain/                    # FoodItem and FoodLogEntry models
│   │   │   └── presentation/
│   │   │       ├── providers/             # AI vision scanning state
│   │   │       ├── screens/               # FoodAiScreen (Camera/Barcode), ResultReviewScreen
│   │   │       └── widgets/               # Camera capture preview & manual review cards
│   │   │
│   │   ├── chat_log/                      # Natural language conversational logging
│   │   │   ├── data/                      # Chat message repository & SQLite sync
│   │   │   ├── domain/                    # ChatMessage model & intent enums
│   │   │   └── presentation/
│   │   │       ├── providers/             # ChatLogNotifier & streaming state
│   │   │       ├── screens/               # ChatLogScreen
│   │   │       └── widgets/               # MessageBubble, SuggestedPrompts
│   │   │
│   │   ├── planner/                       # Daily fitness & routine management
│   │   │   ├── data/                      # Workout presets & default fitness routines
│   │   │   ├── domain/                    # PlannerTask entity with category headers
│   │   │   ├── presentation/
│   │   │   │   ├── screens/               # PlannerScreen
│   │   │   │   └── widgets/               # PlannerSummaryCard, TaskItemTile
│   │   │   └── providers/                 # PlannerStateNotifier with SQLite persistence
│   │   │
│   │   └── settings/                      # User configuration & API key management
│   │       └── presentation/
│   │           └── screens/               # SettingsScreen
│   │
│   └── services/                          # Orchestration & utility services
│       ├── ask_ai_service.dart            # Quick AI snack & nutrition query dispatch
│       ├── connectivity_provider.dart     # Real-time network reachability provider
│       └── food_log_service.dart          # Aggregation helper for food item logs
│
├── assets/
│   └── images/                            # Portfolio screenshots & brand assets
│
├── test/
│   └── unit/
│       └── profile_data_test.dart         # Mifflin-St Jeor equation & target unit tests
│
├── pubspec.yaml                           # Dependency manifest
├── analysis_options.yaml                  # Flutter analyzer rules
└── README.md                              # User guide and quick start
```

---

## ⚙️ Core Architectural Patterns

### 1. Offline-First SQLite Storage
All food entries, profile information, daily chat logs, and planner tasks persist locally via `AppDatabase` (SQLite). The database schema features automated version migration (`onUpgrade`), safely bringing the schema to version 7 without data loss.

### 2. Multi-tier AI Service & Secret Isolation
- `AiConfig` resolves Gemini API keys dynamically from `FlutterSecureStorage`, system environment, and `--dart-define` compile-time flags.
- Plaintext `.env` is omitted from bundled Flutter assets to prevent reverse-engineering of secrets from production binaries.
- The AI pipeline supports:
  - **Gemini 1.5 Flash**: Multimodal vision analysis for estimating portions and macros from food photos.
  - **OpenFoodFacts REST API**: Barcode scanning with local fallback to the embedded Filipino food database.
  - **Conversational Parsing**: Extracts structured JSON from natural language descriptions ("I had 2 cups of sinigang with rice").

### 3. State Management with Riverpod
Riverpod is used without brittle build runners or code-generation overhead. Providers isolate UI side effects:
- `DailyInsightProvider` computes remaining daily macros and triggers AI snack tips only when macronutrient balance changes.
- `PlannerNotifier` manages daily workout tasks, excluding section headers from progress calculations.
- `DashboardProvider` drives real-time summary calculations and weight trend graphs.

### 4. Mifflin-St Jeor Metabolic Engine
Profile calculations follow clinical formulas:
- **BMR (Basal Metabolic Rate)**: Gender-specific Mifflin-St Jeor formula based on weight, height, and age.
- **TDEE (Total Daily Energy Expenditure)**: Derived via standard physical activity multipliers (1.2x sedentary to 1.9x extreme).
- **Macro Distribution**: Caloric goal adjustments based on surplus/deficit targets (Cutting: -500 kcal, Bulking: +300 kcal).

---

## 🔮 Future Roadmap

Features planned for upcoming milestones:
1. **User Authentication & Cloud Backup**:
   - Optional sign-in via Supabase Auth or Firebase.
   - Cross-device sync and cloud backup for SQLite databases.
2. **Pedometer & Step Tracking**:
   - Background pedometer integration using Apple HealthKit and Google Health Connect.
   - Calorie expenditure offset factoring active step burn into daily remaining calories.
3. **Micro-nutrient Tracking**:
   - Sodium, potassium, and cholesterol monitoring specifically targeted at Filipino dietary health concerns.

