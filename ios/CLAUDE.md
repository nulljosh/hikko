# Hotaru iOS
v2.2.0
## Rules
- Portrait-only, UIRequiresFullScreen
- Apple Liquid Glass: .ultraThinMaterial, blur, rounded corners, system font
- Accent: #b5502c terracotta (house accent, matches the landing)
- No emojis
- Error banner system for auth and API failures
- Optimistic voting with debounce and error revert
## Run
```bash
xcodegen generate && open Spark.xcodeproj
xcodebuild -scheme Spark -destination 'platform=iOS Simulator,name=iPhone 16' build
xcodebuild -scheme Spark -destination 'platform=iOS Simulator,name=iPhone 16' test
```
## Key Files
- SparkApp.swift: App entry point with splash and root scene setup.
- ContentView.swift: Root tab navigation, feed/create/profile views, and auth sheet wiring.
- Models/AppState.swift: Observable app state for auth, posts, voting, and error handling.
- API/SparkAPI.swift: HTTP client for Spark auth and posts APIs, including token handling.
- Tabs: native TabView (custom floating bar removed 2026-10-04, taps were unreliable). Order: Feed, Create, Ideas, Profile.
