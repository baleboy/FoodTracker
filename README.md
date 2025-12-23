# FoodTracker

An iOS app that uses AI vision to analyze your meals. Take a photo of your food and get instant calorie estimates and nutritional ratings.

## Features

- **Photo-based meal logging** - Use your camera or photo library
- **AI-powered analysis** - Get calorie estimates and health ratings (green/yellow/red)
- **Multiple AI providers** - Choose between Claude or OpenAI
- **Daily calorie tracking** - Meals grouped by day with totals
- **Meal history** - Browse and review past meals

## Requirements

- iOS 17.0+
- Xcode 16+
- An API key from [Anthropic](https://console.anthropic.com/) or [OpenAI](https://platform.openai.com/api-keys)

## Setup

1. Clone the repository
2. Open `FoodTracker.xcodeproj` in Xcode
3. Build and run on a simulator or device
4. Go to Settings (gear icon) and enter your API key
5. Select your preferred AI provider (Claude or OpenAI)

## Usage

1. Tap the camera icon to add a meal
2. Take a photo or select from your library
3. The AI analyzes the image automatically
4. View the result with calorie estimate and rating
5. Browse your meal history grouped by day

## Build

```bash
# Build for iOS Simulator
xcodebuild -project FoodTracker.xcodeproj -scheme FoodTracker \
  -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run tests
xcodebuild -project FoodTracker.xcodeproj -scheme FoodTrackerTests \
  -destination 'platform=iOS Simulator,name=iPhone 16' test
```

## Architecture

- **SwiftUI** for the UI layer
- **SwiftData** for persistence
- **LLMService protocol** abstracts Claude/OpenAI implementations
- **Keychain** for secure API key storage

## License

Free for non-commercial use. See [LICENSE](LICENSE) for details.
