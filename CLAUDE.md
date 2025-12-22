# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FoodTracker is an iOS app built with SwiftUI for AI-powered meal tracking. Users photograph meals to receive calorie estimates and nutritional ratings (red/yellow/green) via Claude API integration.

## Build Commands

```bash
# Build for iOS Simulator
xcodebuild -project FoodTracker.xcodeproj -scheme FoodTracker -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run tests
xcodebuild -project FoodTracker.xcodeproj -scheme FoodTrackerTests -destination 'platform=iOS Simulator,name=iPhone 16' test

# Run single test (example)
xcodebuild -project FoodTracker.xcodeproj -scheme FoodTrackerTests -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:FoodTrackerTests/TestClassName/testMethodName
```

Or open `FoodTracker.xcodeproj` in Xcode and use Cmd+B (build) / Cmd+R (run) / Cmd+U (test).

## Architecture

- **Platform**: iOS 17.0+, Swift 5.0, SwiftUI
- **Persistence**: SwiftData with `Meal` model
- **LLM Integration**: Claude API and OpenAI API (switchable in Settings)

### Code Structure
```
FoodTracker/
├── Models/Meal.swift           # SwiftData model + MealRating enum
├── Services/
│   ├── LLMService.swift        # Protocol + shared types (LLMProvider, LLMError)
│   ├── ClaudeAPIService.swift  # Claude vision API client (actor)
│   ├── OpenAIService.swift     # OpenAI vision API client (actor)
│   ├── APIKeyManager.swift     # Keychain storage + provider selection
│   └── CameraService.swift     # Camera authorization
├── Views/
│   ├── MealListView.swift      # Grouped by day with calorie totals
│   ├── MealRowView.swift       # List row component
│   ├── MealDetailView.swift    # Full meal details
│   ├── PhotoCaptureView.swift  # Photo selection + auto-analysis
│   └── SettingsView.swift      # Provider toggle + API keys
└── Utilities/ImageHelpers.swift # Image resize/compress
```

### Key Patterns
- `LLMService` protocol abstracts Claude/OpenAI implementations
- Both API services are `actor` types for thread-safe calls
- API keys stored in Keychain, provider selection in UserDefaults
- `APIKeyManager.shared.createSelectedService()` returns the active provider
- Images resized to max 1024px and JPEG-compressed before API calls

### Targets
- `FoodTracker` - Main app
- `FoodTrackerTests` - Unit tests (Swift Testing framework)
- `FoodTrackerUITests` - UI tests (XCTest)
