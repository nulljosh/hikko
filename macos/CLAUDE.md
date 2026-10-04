# Hikko macOS
v1.0.0
## Rules
- macOS 14+, SwiftUI, @Observable
- Sidebar navigation: Feed, Create, Profile
- Accent: #0071e3 blue
- No emojis
- Keyboard shortcuts: Cmd-N (new post), Cmd-R (refresh), Cmd-Return (submit post)
- Error banner system for auth and API failures
- Optimistic voting with debounce and error revert
- Same API as iOS: https://hikko.heyitsmejosh.com
## Run
```bash
cd macos && xcodegen generate && open SparkMac.xcodeproj
xcodebuild -scheme SparkMac -destination 'platform=macOS' build
```
## Key Files
- SparkApp.swift: App entry point, WindowGroup, menu commands
- ContentView.swift: Sidebar navigation (Feed/Create/Profile), error banner
- Models/AppState.swift: Observable app state for auth, posts, voting
- API/SparkAPI.swift: HTTP client for Spark APIs, JWT token via Keychain
- Views/FeedView.swift: Post list with search, category filter, sort (hot/new)
- Views/PostDetailView.swift: Full post view with voting, delete, share
- Views/CreateView.swift: Create post form
- Views/ProfileView.swift: User profile, own posts, logout
- Views/AuthSheet.swift: Login/register sheet
