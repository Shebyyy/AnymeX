# AGENTS.md — AnymeX Engineering & Architectural Guidelines

Welcome to the **AnymeX** codebase. This document establishes the architectural principles, component guidelines, state management patterns, and workflow constraints for developers and AI coding assistants contributing to the AnymeX project.

---

## 1. Project Overview

**AnymeX** is an all-in-one, cross-platform media hub designed for streaming anime, reading manga and light novels, tracking progress across multiple services, and managing personal offline libraries.

- **Target Platforms**: Android, Windows, Linux, macOS, iOS
- **Language & Framework**: Dart 3+, Flutter 3.x
- **Core Philosophy**: Performance-first, unified media consumption across all media types (Anime, Manga, Novels), fully customizable UI, and deep tracker synchronization.

---

## 2. Core Tech Stack & Systems

### 2.1. State Management & Dependency Injection
- **Framework**: [GetX](https://pub.dev/packages/get)
- **Controller Lifecycle**: Controllers extend `GetxController` and are instantiated via `Get.put()` or lazy-loaded via `Get.lazyPut()`.
- **Reactivity**: Prefer reactive state variables (`RxBool`, `RxString`, `RxInt`, `RxList`, etc.) and surgical UI rendering with `Obx(() => ...)`. Avoid local `setState()` inside complex screens where controller state already exists.
- **Service Locator**: Global singletons (theme, storage, sources, network, tracker controllers) are accessed via `Get.find<T>()`.

### 2.2. Database & Persistence Layers
- **Isar Database** (`isar_community`):
  - Primary embedded NoSQL storage for media library entries, offline episodes, watch/reading history, and download queues (`lib/database/isar_models/`).
  - Schema updates require running the Isar code generator: `dart run build_runner build`.
- **Key-Value Store (`KvHelper`)**:
  - Light-weight preference store (`lib/database/kv_helper.dart`).
  - All storage keys must be typed and maintained inside `lib/database/data_keys/keys.dart` (e.g., `PlayerKeys`, `ThemeKeys`, `SourceKeys`). Never use raw arbitrary string keys.

### 2.3. Media & Playback Engines
- **Video Engine (`media_kit`)**:
  - Low-latency multi-platform video engine (`lib/screens/anime/watch/`).
  - Supports dynamic control layouts via the JSON theme engine (`setup/json_player_control_theme.dart`), gesture-based seeking, aspect ratio handling, audio track switching, and multiple themes (Netflix, iOS, Desktop).
- **Casting Subsystem**:
  - Custom Google Cast (Cast v2) implementation with an embedded local HTTP proxy server (`lib/services/cast/cast_proxy_server.dart`, `cast_v2_client.dart`) to bridge local/network streams to Chromecast devices.
- **Manga & Light Novel Readers**:
  - Virtualized reading engines supporting vertical webtoon scrolling, single-page, dual-page landscape, page transitions, and reading direction toggles (`lib/screens/manga/reading_page.dart`, `lib/screens/novel/reader/`).

### 2.4. Extensions & Source Architecture
- **Source Management**:
  - Dynamic media scraping and streaming bridge managed by `SourceController` (`lib/controllers/source/source_controller.dart`) and `SourceMapper`.
  - Supports extensions for anime streams, manga chapter extraction, and novel text scraping.

### 2.5. Trackers & Metadata Services
- **AniList**: GraphQL integration for authentication, media metadata, user anime/manga lists, release calendar, and activity feeds.
- **SIMKL & MyAnimeList (MAL)**: Supported tracking sync platforms (`lib/controllers/services/`).

---

## 3. Design System & UI Standards

### 3.1. The Container Rule (CRITICAL)
> [!IMPORTANT]
> **ALWAYS use `AnymeXContainer`** (`package:anymex/widgets/anymex_widgets/anymex_container.dart`) instead of Flutter's standard `Container` for cards, preview boxes, bottom sheets, dialogs, and decorated wrappers.
> - `AnymeXContainer` binds directly to dynamic user themes, border radiuses, outline borders, and glassmorphic styling tokens across the application.
> - **DO NOT** create ad-hoc raw containers with custom borders or hardcoded decorations when an established widget exists.

### 3.2. Canonical AnymeX UI Widgets
All screens should use standard components from `lib/widgets/anymex_widgets/` and `lib/widgets/common/`:

| Component | Usage |
| :--- | :--- |
| `AnymeXContainer` | Primary surface container with automatic theme stroke, radius, and glow. |
| `AnymeXText` / `AnymeXTextSpan` | Themed typography with automatic contrast and font scaling. |
| `AnymeXScaffold` | Platform-aware page scaffold with adaptive padding, safe areas, and titlebar support. |
| `AnymeXButton` / `AnymeXImageButton` | Interactive themed action buttons with hover and press feedback. |
| `AnymeXDialog` / `AnymeXBottomSheet` | Standard modal dialogs and slide-up sheets. |
| `AnymeXExpansionTile` | Expandable accordion sections (used throughout settings pages). |
| `AnymeXImage` | Cached remote and asset image loader with shimmer placeholders and error fallbacks. |
| `PlatformBuilder` | Platform-aware layout switcher (renders Desktop vs Mobile layouts cleanly). |
| `MarqueeText` | Smooth scrolling text for overflowing media titles and artist credits. |

### 3.3. Desktop vs Mobile Responsiveness
AnymeX is cross-platform. UI components must adapt to both form factors:
- **Desktop (Windows/macOS/Linux)**: Mouse hover states, keyboard shortcuts, multi-column grids, collapsible sidebars, and titlebar controls.
- **Mobile (Android/iOS)**: Touch-optimized targets, bottom navigation bars, gesture dismissals, and draggable bottom sheets.

---

## 4. Codebase Directory Structure

```
lib/
├── ai/                      # AI recommendation models & assistants
├── constants/               # Global layout constants, dimensions, and static assets
├── controllers/             # GetX controllers:
│   ├── source/              # Extension sources & source mapping
│   ├── services/            # AniList, MAL, SIMKL, community APIs
│   ├── theme.dart           # Theme mode, seed colors, dynamic palette controller
│   ├── offline/             # Offline downloads & local media state
│   └── sync/                # Cloud synchronization & backup/restore
├── database/                # Local data layers:
│   ├── isar_models/         # Isar schemas (episodes, library, history, bookmarks)
│   ├── data_keys/           # Typed storage keys (keys.dart)
│   └── kv_helper.dart       # Hive / SharedPreferences abstraction
├── models/                  # Data transfer objects (Anilist, Media, Player, Offline)
├── screens/                 # Application views:
│   ├── anime/               # Anime home, details, watch view, player controls
│   ├── manga/               # Manga home, details, reader view
│   ├── novel/               # Light novel reader & library
│   ├── library/             # Local & online user library, watch history, stats
│   ├── extensions/          # Extension manager & source repositories
│   ├── downloads/           # Download queue and offline media manager
│   ├── settings/            # Sub-settings pages (player, appearance, tracker, common)
│   └── search/              # Unified search across anime, manga, and novels
├── services/                # Background services (cast proxy, FCM, notifications)
├── utils/                   # Helpers, URL launchers, formatters, deeplinks
└── widgets/                 # Reusable UI component library:
    ├── anymex_widgets/      # Core design system widgets
    └── common/              # Layout helpers, scaffolds, marquees, carousels
```

---

## 5. Development & Code Quality Standards

### 5.1. Static Analysis & Verification
Before committing or submitting changes, ensure the codebase passes static analysis cleanly:
```bash
flutter analyze --no-fatal-infos
```
- **Zero Errors Policy**: No unresolved syntax errors, broken types, or broken imports.
- **Dependency Integrity**: Run `flutter pub get` when dependencies or lockfiles are updated.
- **Code Preservation**: Maintain existing comments, documentation, and formatting style across untouched sections.

### 5.2. Code Style & Best Practices
- **Null Safety**: Follow sound null safety patterns; avoid force-unwrapping (`!`) unless guaranteed non-null.
- **Performance**: Avoid large rebuilds by scoping `Obx` widgets tightly to only the widgets that depend on reactive variables.
- **Resource Cleanup**: Properly dispose of controllers, animation controllers, focus nodes, and stream subscriptions in `onClose()` or `dispose()`.
