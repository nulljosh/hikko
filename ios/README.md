![Spark iOS](icon.svg)
# Spark iOS
![version](https://img.shields.io/badge/version-v2.1.1-blue)
Native iOS companion for [Spark](https://hotaru.heyitsmejosh.com) -- idea sharing with voting.
## Features
- Browse posts with pull-to-refresh, search, and category filter
- Upvote / downvote with optimistic UI
- Create posts with category picker
- Login / register with JWT stored in Keychain
- Profile with stats, own posts, swipe-to-delete
## Run
```bash
xcodegen generate && open Spark.xcodeproj
# Deploy: TestFlight via Xcode Archive.
```
## Roadmap
- [ ] Push notifications for votes
- [ ] Infinite scroll pagination
- [ ] Haptic feedback on votes and deep links
## Changelog

### v2.1.0 (2026-03-28)
- New app icon

### v2.0.0 (2026-03-27)
- Comments on posts
- User profiles with stats
- Sort options and badges
- 60+ tests

### v1.0.0
- Feed browsing with search, filters, and pull-to-refresh
- Auth flow with Keychain-backed JWT storage
- Post creation, voting, and profile management
## License
MIT 2026 Joshua Trommel
