# Architecture

Hikko is a self-regulating idea forum. Users post ideas, comment, vote, and browse. An AI daemon (Gemma model via Cloudflare Workers AI) auto-generates new ideas daily and enriches them with specs and build plans. No build step. Web app runs from plain HTML/JS. Native iOS/macOS/watchOS companions. Supabase backend. Future monetization: paid accounts get unlimited posting and 24h pinned visibility.

## How it runs

1. **Web entry**: User lands on `index.html` (landing page with theme toggle, hero, features, CTA). Clicks to `app.html` or authenticates. Authenticated users see the feed (grid of idea cards) and can create, comment, vote.
2. **Backend**: Cloudflare Pages + Supabase + Resend. `/api/posts` is the main feed endpoint. `/api/ai` handles generation and enrichment. `/api/auth/*` handles login, register, GitHub OAuth, password reset, email verification.
3. **AI Daemon**: Cron worker (`worker/`) fires twice daily (09:00 UTC). Calls `/api/ai?type=generate` to create one new idea, then `/api/ai?type=enrich` on all unenriched posts. Uses Gemma small model.
4. **Native apps**: iOS, macOS, watchOS share the same backend API. iOS is live on App Store (v1.0). macOS v1.0 in submission. watchOS bundled (view-only).

## Web

### Pages

| File | What it owns |
|---|---|
| `index.html` | Marketing landing page (432 lines). Hero section, feature list, CTA buttons to `/app` and app store links. Lazy-loads video background. Mobile-first responsive layout. Theme toggle in header. No login required. |
| `app.html` | Main app single-page (1301 lines). Feed grid layout (CSS Grid auto-fill), feed infinite scroll, auth UI (login/register forms, OAuth buttons), create post modal (title/content/tags), post detail modal (full content, comments thread, voting), user profile section (avatar, bio, user's posts), settings panel, onboarding carousel (on first visit). All vanilla JavaScript, no framework. Handles auth token in localStorage. |
| `user.html` | User profile page. Displays target user's name, avatar, bio, follower/following counts. Shows user's posts chronologically. Link to user's idea base. |
| `reset.html` | Password reset form. Accepts token from email link. New password input with confirmation. Validation. Success/error messaging. |
| `tos.html` | Terms of service. Legal text. Shown during registration signup (user must check checkbox to proceed). Static content, no interactivity. |
| `support.html` | Support/contact page. Contact form (name, email, message) or email address/support links. Submission via API. |

### Styling & Theme

| File | What it owns |
|---|---|
| `theme.js` | Light/dark theme control. Loaded in every page's `<head>` synchronously. Sets `data-theme` on `<html>` before first paint. Wires `[data-theme-toggle]` buttons. Persists to localStorage (`spark_theme`). Default: dark. |
| `tokens.css` | Jaybulb design system alias layer. Imports canonical heyitsmejosh.com/tokens.css. |
| `devices.css` | Responsive device frames (iPhone, Android, Mac) for landing demo. Canonical copy synced from portfolio. |
| Root CSS in `index.html` + `app.html` | Inline styles. Grid layout for feed (`repeat(auto-fill, minmax(320px, 1fr))`), card styling, forms, no box-shadows. Minimal, fast to scan. Mobile-first. |

### Utilities

| File | What it owns |
|---|---|
| `onboarding.js` | Reusable first-run carousel (145 lines). Shows to new users. Shared across web + native. Slides with title/body/artwork. Stores seen version in localStorage. |
| `sw.js` | Service worker. Caches static assets, API responses. Offline fallback. Serves cached data when network is unreachable. |
| `webmcp.js` | WebMCP tool registration. Exposes feed, posting, comments to in-browser agents via document.modelContext. |

## Backend API (api/)

Cloudflare Pages Functions. Calls Supabase REST API + Resend for email. All functions are in `api/_lib/auth/`, `api/*.js` (data layer), and routed via `functions/api/[[route]].js` (dynamic catch-all).

### Core Endpoints

| File | What it owns |
|---|---|
| `api/posts.js` | GET feed (paginated, filtered by tag/sort), POST create post (rate-limited 10 per 60s), GET single post. Seed data fallback when Supabase is down. |
| `api/comments.js` | GET post comments, POST add comment, DELETE comment. |
| `api/ai.js` | POST ?type=generate (create new idea as "gemma" author), ?type=enrich (fill spec+build plan on existing idea), ?type=idea-base (fetch idea base prompts), ?type=notes (fetch enrichment notes), ?type=rfs (fetch RFS data). Uses Cloudflare Workers AI binding. |
| `api/user.js` | GET current user, PUT update profile (avatar, bio, settings). |
| `api/users.js` | GET user by ID, GET public profile. |
| `api/avatar.js` | POST generate avatar, GET user's avatar. Returns SVG or image blob. |
| `api/notifications.js` | GET unread notifications, PUT mark read. |
| `api/stripe.js` | Stub. POST checkout session creation. Not yet implemented. |
| `api/stripe-webhook.js` | Stripe event handler. Not yet live. |
| `api/auth.js` | Router. Delegates to `_lib/auth/*.js`. |

### Auth (api/_lib/auth/)

| File | What it owns |
|---|---|
| `api/_lib/auth/register.js` | Email + password registration. Validates, creates user, sends verification email. Requires TOS checkbox. |
| `api/_lib/auth/login.js` | Email + password login. Returns session token. |
| `api/_lib/auth/github.js` | GitHub OAuth start. Redirects to GitHub. |
| `api/_lib/auth/github-callback.js` | GitHub OAuth callback. Creates/updates user with GitHub ID and avatar. |
| `api/_lib/auth/apple.js` | Apple Sign In start. |
| `api/_lib/auth/apple.selfcheck.js` | Apple Sign In test. |
| `api/_lib/auth/password-reset.js` | Send password reset email with token. |
| `api/_lib/auth/verify-email.js` | Email verification endpoint (clicked from email). Marks user verified. |
| `api/_lib/auth/verify-email.selfcheck.js` | Email verification test. |
| `api/_lib/auth/delete-account.js` | Delete user and all data. |

### Utilities (api/_lib/)

| File | What it owns |
|---|---|
| `api/_lib/supabase.js` | REST wrapper for Supabase. Exposes query(), insert(), update(), delete() with auth header. |
| `api/_lib/supabase.selfcheck.js` | Supabase connectivity test. |
| `api/_lib/auth/` | Shared auth logic (see above). |
| `api/_lib/mail.js` | Email sending via Resend API. Used for verification, password reset, notifications. |
| `api/_lib/mail.selfcheck.js` | Mail delivery test. |
| `api/_lib/ratelimit.js` | Rate limiting per IP (10 posts per 60s) + per user. Checks request headers. |
| `api/_lib/store.js` | KV store abstraction. Caches feed, enrichment results. |

## Background Job (worker/)

Cron trigger for daily idea generation and enrichment.

| File | What it owns |
|---|---|
| `worker/worker.js` | Scheduled handler. Fires at 09:00 UTC (and second trigger time). Calls `/api/ai?type=generate`, then `/api/ai?type=enrich` on all unenriched posts. Bearer token: SPARK_DAEMON_SECRET. |
| `worker/wrangler.jsonc` | Cloudflare Workers config. Cron triggers, env vars, binding to the main Pages project. |

## Deployment

| File | What it owns |
|---|---|
| `functions/_adapter.js` | Cloudflare Pages Functions adapter. Exports handler for catching all routes via `[[route]]`. |
| `functions/api/[[route]].js` | Dynamic route handler. Routes `/api/*` requests to `api/*.js` modules. |
| `dist/` | Build output directory (generated, not checked in). Contains processed HTML, CSS, JS for deployment. |
| `package.json` | npm scripts: `npm start` (local dev via `serve`), `npm test` (vitest), `npm run deploy` (wrangler deploy for worker). |
| `.vercelignore` or similar | Ignore patterns for Cloudflare deployment. |

## iOS

App Store live (v1.0). Companion to web app. Authentication via email or GitHub/Apple Sign In. View-only and post browsing; creating posts requires the web app or full signup flow not yet implemented natively.

### App Shell

| File | What it owns |
|---|---|
| `ios/SparkApp.swift` | App entry. WindowGroup, environment setup. |
| `ios/ContentView.swift` | Root shell. Auth UI vs feed. Tab shell when authenticated. TabView with feed, create, idea base, profile tabs. |
| `ios/OnboardingView.swift` + `OnboardingSlides.swift` | First-run carousel. Three slides: "Ideas, out loud", "Upvote & comment", "Build yours". Shows to new users, stored in localStorage. |

### State & API

| File | What it owns |
|---|---|
| `ios/Models/AppState.swift` | Observable state container. Auth status, current user, feed cache, notification state, selected post detail. Observable bindings to Views. |
| `ios/API/SparkAPI.swift` | HTTP client for /api endpoints. Handles login, fetch posts, post creation, comments, voting. Error handling with retry logic. |
| `ios/API/KeychainHelper.swift` | Keychain access for storing auth token. Secure storage, requires Face/Touch ID unlock on sensitive operations. |
| `ios/Models/Post.swift` | Post shape: id, title, content, author, votes, comment count, tags, created_at, enriched_at. Codable. |
| `ios/Models/Comment.swift` | Comment shape: id, content, author, votes, created_at. Nested replies supported. |
| `ios/Models/User.swift` + `UserProfile.swift` | User (minimal) and UserProfile (full). UserProfile includes bio, followers, following, posts. |
| `ios/Models/IdeaBase.swift` | Idea spec structure: spec (how it works), build_plan (steps to implement). Synced from API. |
| `ios/Models/RFSEntry.swift` | Request for Startup entry: title, description, category. Archive of past RFS calls. |

### Views & UI

| File | What it owns |
|---|---|
| `ios/Views/FeedView.swift` | Feed grid display. CSS Grid-like layout with auto-fill columns. Infinite scroll via pagination. Pull-to-refresh via RefreshControl. Shows idea cards in 3-line clamp. Tap to detail view. Search/filter bar. |
| `ios/Views/PostDetailView.swift` | Full post detail. Shows entire content, spec if enriched, build plan if available. Below: comments section with nested reply threads. Vote buttons at top. Share button. |
| `ios/Views/CommentsView.swift` | Threaded comment display. Nested replies indented. Vote on each comment. Reply text field. Link to parent post. |
| `ios/Views/IdeaBaseView.swift` | Idea base library. Tab-based or list view showing all enriched ideas, past RFS entries, reference specs. Search by title/keyword. |
| `ios/Views/UserProfileView.swift` | Profile card. Avatar, name, bio, follower count, following count. Shows user's recent posts in a grid. Edit profile button (if own profile). |
| `ios/Views/` (other views) | Any additional UI components not individually listed. |
| `ios/View+Glass.swift` | Glass morphism modifier. Applies frosted glass effect to floating UI elements. Conditional on iOS version (14+). |
| `ios/WhatsNewSheet.swift` | What's New modal. Shows per-version changelog. Stored in UserDefaults to avoid repeat showing. |

### Tests & Screenshots

| File | What it owns |
|---|---|
| `ios/SparkTests/PostTests.swift` | Post model unit tests. Verifies JSON decoding from API responses, vote count updates, timestamp parsing, creation date handling. |
| `ios/SparkTests/CommentTests.swift` | Comment model tests. Nested reply chain structure, reply-to parent links, vote tallying. |
| `ios/SparkTests/UserProfileTests.swift` | User and UserProfile model tests. Avatar URL, follower/following counts, bio text handling. |
| `ios/SparkTests/VotingTests.swift` | Voting logic tests. Vote increment/decrement, vote direction (up/down), vote cancellation. |
| `ios/SparkTests/AuthResponseTests.swift` | OAuth response parsing. GitHub OAuth token + user info extraction. Apple Sign In token validation. |
| `ios/SparkTests/AppStateTests.swift` | AppState observable tests. Auth state transitions (login/logout), feed cache updates, notification badges. |
| `ios/SparkTests/SparkAPITests.swift` | SparkAPI client tests. Network error handling, HTTP status code mapping, JSON decoding errors, retry logic. |
| `ios/SparkTests/MockSparkAPI.swift` | Mock SparkAPI for testing. Stub responses for posts, comments, user profiles. Allows deterministic testing without network. |
| `ios/SparkTests/IntegrationTests.swift` | Integration tests. Full flow: authenticate -> fetch feed -> upvote post -> comment -> refresh. Uses MockSparkAPI. |
| `ios/UITests/PreviewScreenshot.swift` | App Store screenshot tests via fastlane snapshot. Captures at correct screen dimensions (iPhone 11 Pro Max, iPhone 14 Plus). Includes dark/light variants. |
| `ios/UITests/SnapshotHelper.swift` | Snapshot capture helper (auto-generated by fastlane fastlane-plugin-snapshot). Handles safe area insets, status bar stripping, multi-language capture. |

## macOS

v1.0 in submission. Desktop client with sidebar navigation + multi-window support. Similar data layer to iOS, different UI layout optimized for larger screens.

### App Shell

| File | What it owns |
|---|---|
| `macos/SparkApp.swift` | App entry. WindowGroup for main window. Menu bar extras. Theme preference. App delegate hooks. |
| `macos/ContentView.swift` | Root shell with sidebar. Four sections: Feed (read-only grid), Create (post new idea, admin-only UI), Idea Bases (reference material), Profile (user bio + history). Auth UI overlaid when signed out. |
| `macos/OnboardingView.swift` + `OnboardingSlides.swift` | Onboarding carousel. Same three slides as iOS. Shown to first-time users, skipped for returning visitors. |

### State & API

| File | What it owns |
|---|---|
| `macos/Models/AppState.swift` | Observable state container. Feed data, current user, sidebar selection state, theme preference. Mirrors iOS but adds window state (selected post detail panel, sidebar visibility). |
| `macos/API/SparkAPI.swift` | HTTP client. Same endpoints as iOS. Error handling + retry logic. Longer timeouts for desktop (assume stable network). |
| `macos/API/KeychainHelper.swift` | Keychain access. Stores auth token. Requires Cmd+Lock or authentication dialog on first access. |
| `macos/Models/Post.swift` + `User.swift` | Data shapes (Post, User, Comment). Matches iOS structures. |

### Views & UI

| File | What it owns |
|---|---|
| `macos/Views/FeedView.swift` | Grid of idea cards. Infinite scroll, pull-to-refresh. Keyboard shortcuts (arrow keys to navigate, Enter to expand). |
| `macos/Views/PostDetailView.swift` | Full post + comments in split panel or modal sheet. Shows spec + build plan if enriched. Comment input field. Voting buttons. |
| `macos/Views/IdeaBaseView.swift` | Reference library. Shows all idea base entries (specs, build plans, past RFS calls) in a list. Search by keyword. |
| `macos/Views/ProfileView.swift` | User's own profile + account settings. Edit bio, change avatar, show activity history. Sign out button. |
| `macos/Views/CreateView.swift` | New idea form (admin-only, for now; future: open to all Pro users). Title, description, tags. Submit button. Validation. |
| `macos/Views/AuthSheet.swift` | OAuth login sheet. Email + password OR GitHub/Apple sign-in. Shows after app launch if signed out. |

### Build

| File | What it owns |
|---|---|
| `macos/project.yml` | xcodegen manifest. Defines macOS app target, settings, entitlements, build phases. Same as iOS pattern (xcodegen generate, no committed xcodeproj). |

## watchOS

Bundled with iOS app. View-only companion. No login UI (requires iOS pre-auth via app group shared defaults).

### App

| File | What it owns |
|---|---|
| `watchos/ContentView.swift` | Root view. TabView (vertical page) with feed, idea base, notifications. Minimal UI optimized for small watch screen. |

### Data Access

| File | What it owns |
|---|---|
| (Shared with iOS) | watchOS accesses the same API endpoints as iOS. Auth token stored in shared app group UserDefaults. No separate Keychain store on watch. |

## iOS Widgets

Home screen widgets for iOS. Three widget types: Hot posts, New posts, and stats summary. Shared app group storage for auth token and cached data.

| Dir | What it owns |
|---|---|
| `widgets-ios/SparkWidgets.swift` | Widget bundle entry point. Declares the three available widgets. |
| `widgets-ios/Models/` | WidgetAPI (fetches posts and stats from API, caches to UserDefaults), WidgetModels (SparkPost, SparkStats data shapes). |
| `widgets-ios/Providers/` | Timeline providers for each widget: HotPostsProvider, NewPostsProvider, StatsProvider. Fetch, cache, and refresh on schedule. |
| `widgets-ios/Views/` | Widget UI: HotPostsWidget, NewPostsWidget, StatsWidget. Each renders timeline entries with proper sizing. |

## macOS Widgets

Home screen widgets for macOS. Same three types as iOS (Hot, New, Stats) with layouts optimized for larger widget sizes and additional interaction patterns.

| Dir | What it owns |
|---|---|
| `widgets-macos/SparkWidgets.swift` | Widget bundle entry point. |
| `widgets-macos/Models/` | SparkWidgetAPI (fetch posts and stats, cache to UserDefaults), WidgetModels (WidgetPost, SparkStats). |
| `widgets-macos/Providers/` | Timeline providers: HotPostsProvider, NewPostsProvider, StatsProvider. Same refresh patterns as iOS. |
| `widgets-macos/Views/` | Widget UI: HotPostsWidget, NewPostsWidget, StatsWidget. SmallPostRow, mediumPostRow, largePostRow layouts for macOS sizes. SharedComponents defines Spark brand colors and category pills. |

## Kotlin Multiplatform (Android)

Not yet shipped. Gradle-based project with shared common code + platform-specific UI (Compose).

### Project Structure

| Dir | What it owns |
|---|---|
| `kmp/shared/src/commonMain/kotlin/` | Shared business logic: HikkoClient (Ktor HTTP client), Models (Post, Comment, User), constants. Platform-agnostic. |
| `kmp/shared/src/commonTest/kotlin/` | Shared tests (unit tests for models, parsing). |
| `kmp/composeApp/src/androidMain/kotlin/` | Android-specific: MainActivity (entry point, setContent with Compose root). Launches into the shared App composable. |
| `kmp/composeApp/src/commonMain/kotlin/` | App.kt (shared Compose UI). Screens for feed, detail, profile. Uses Compose Material 3 theme. |
| `kmp/composeApp/src/desktopMain/kotlin/` | Desktop preview app (Main.kt). Allows running on macOS for testing. Window management via Compose Window API. |
| `kmp/build.gradle.kts` | KMP Gradle config. Targets: Android, iOS (future), Desktop. Dependencies: Ktor client, Compose, serialization. |

### Build

| File | What it owns |
|---|---|
| `kmp/gradle.properties` | Gradle properties. JVM version, Compose version, plugin versions. |
| `kmp/settings.gradle.kts` | Root settings. Includes composeApp and shared modules. Declares plugin versions (Kotlin, Compose, Android). |

## Database Schema & Migrations

Database migrations define schema changes applied in order. Two copies exist for historical reasons.

| Dir/File | What it owns |
|---|---|
| `schema.sql` | Legacy base schema. Replaced by migrations system but kept for reference. |
| `migrations/` | 8 historical SQL migration files (001 through 008). Copy of supabase/migrations for backup. Rarely used now. |
| `supabase/migrations/` | Authoritative Supabase migrations, version-dated. Run via `supabase db push`. Covers: password reset tokens, comments table, RLS policies, score increment RPC, GitHub OAuth columns, Apple signin columns, email verification, LLM enrichment (idea bases, spec/plan columns), avatar URL, date/time fields, anon-key security tightening. |

## Database (Supabase)

| Table | Purpose |
|---|---|
| `users` | User accounts (email, hashed password, github_id, avatar_url, verified, created_at). |
| `posts` | Ideas (id, author_id, title, content, spec, build_plan, tags, created_at, updated_at, enriched_at). |
| `comments` | Post comments (id, post_id, author_id, content, created_at). |
| `votes` | Post/comment votes (id, user_id, post_id, comment_id, direction [1 or -1]). |
| `notifications` | User notifications (id, user_id, type, related_id, message, read, created_at). |
| `idea_base` | Enrichment prompts and inspiration data (id, category, title, content). |

## Testing

Vitest for backend/adapter testing. Playwright for browser-based onboarding verification. Some tests skip if env vars are not set.

| File | What it owns |
|---|---|
| `tests/adapter.test.mjs` | Verifies Cloudflare Pages adapter translation contract. Tests that (req, res) doubles are built and handled correctly. |
| `tests/ai.test.mjs` | Tests AI generation and enrichment endpoints. Mocks Supabase and mail transport to exercise business logic. |
| `tests/auth.test.mjs` | Tests login, registration, GitHub/Apple OAuth flows, tokens, sessions, password reset. Verifies auth state correctness. |
| `tests/comments.test.mjs` | Tests comment creation, retrieval, and thread nesting. Verifies rate limiting on comment posts. |
| `tests/full-workflow.test.mjs` | End-to-end test: signup, create post, vote, comment. Runs against live API (skipped if API_URL not set). |
| `tests/posts.test.mjs` | Tests post creation, feed pagination, voting, deletion. Covers seed data fallback and rate limiting. |
| `tests/theme.test.mjs` | Tests theme.js DOM behavior. Stubbed browser APIs verify light/dark toggle, localStorage persistence, selector queries. |
| `tests/user-workflow.test.mjs` | Tests user creation flow and posting workflow. Creates dummy user, posts ideas, verifies retrieval. |
| `tests/onboarding.check.mjs` | Playwright-based test. Verifies onboarding.js carousel shows/hides correctly for new vs returning users. |
| `vitest.config.js` | Vitest configuration. Runs tests in parallel (except where sequential is required). Sets JWT_SECRET for tests. |

## Scripts & Build

Utility scripts for development, deployment, and screenshot capture.

| File | What it owns |
|---|---|
| `scripts/build-static.sh` | Assembles `dist/` directory for Cloudflare Pages deployment. Copies publishable files (HTML, JS, CSS, icons) from repo root that also contains node_modules/ and native platform folders. |
| `scripts/make-appicon.sh` | Regenerates all app icon PNGs from `icon.svg`. Renders at 1024 full-bleed, flattens onto icon background, then scales down for macOS, iOS, and watchOS sizes. Must use this script, never hand-export. |
| `scripts/screenshots.mjs` | Captures hero screenshots in light and dark themes. Serves repo over localhost, uses Playwright to navigate and screenshot the feed view. Outputs PNG files for landing page and app store. |
| `scripts/set-resend-key.sh` | Validates Resend API key against Resend API before storing it. Prevents silent failures from invalid keys lingering in production. |
| `scripts/backfill-enrich.sh` | One-off enrichment backfill. Enriches every post that never got a spec or build plan. Not scheduled, run manually when needed. |
| `scripts/simplify.sh` | Ensures standard folder structure. Creates docs/, scripts/, src/, tests/, assets/ directories if missing. |

## Deployment & Secrets

- **Web**: Cloudflare Pages + Functions. Serves HTML/JS from Pages, routes `/api/*` to Functions.
- **AI**: Cloudflare Workers AI binding (Gemma model).
- **Email**: Resend API (RESEND_API_KEY).
- **Database**: Supabase (SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY).
- **Auth**: GitHub OAuth (GITHUB_CLIENT_ID, GITHUB_CLIENT_SECRET), Apple Sign In (keys from ASC).
- **Stripe** (future): STRIPE_SECRET_KEY, STRIPE_PUBLISHABLE_KEY, STRIPE_WEBHOOK_SECRET.
- **Cron Worker**: SPARK_DAEMON_SECRET (matches Pages project secret). Triggers daily generation/enrichment.

## Monetization (Not Yet Built)

Current state: all features free, 10 posts per 60s rate limit (spam protection only).

Planned (no timeline):
- **Spark Pro**: Unlimited posting, 24h pinned/priority visibility on new posts.
- **Implementation hooks**: Supabase `is_pro`/`tier` column, Stripe product/checkout, auth session wiring, Stripe webhook handler.
- **Reference**: See Epiphany's `server/api/stripe.js` and `gates.js` for the pattern to copy.

## Performance & Caching

- **Feed caching**: Stored in KV, served stale-while-revalidate (client gets cached, server refreshes in background).
- **Seed data fallback**: When Supabase is unreachable, `api/posts.js` returns hardcoded example posts so the app doesn't fully break.
- **Service worker**: Static assets cached on install, API responses cached with Network-First strategy for pages, Cache-First for hashed assets.
- **Theme sync**: localStorage (`spark_theme`) + browser preference (`prefers-color-scheme`).

## Key Gotchas

- **No build step**: Everything runs from source HTML/JS. Updates to `app.html` are live immediately after push.
- **Onboarding.js is a template**: Copy-pasted into other projects. Changes here must be synced to consumers.
- **AI generation is async**: The cron worker calls generate/enrich asynchronously; posts may appear unenriched for a few minutes after creation.
- **Rate limiting is per-IP + per-user**: Anon IPs share a bucket (10 posts per 60s). Signed-in users have their own bucket (unlimited or Pro-limited when that ships).
- **Keychain**: Both iOS and macOS use Keychain for token storage. Test on real devices; simulator Keychain is not persistent across app reinstalls.
- **GitHub OAuth**: GITHUB_CLIENT_ID + GITHUB_CLIENT_SECRET must be set in production environment. Local dev can use test credentials or comment out OAuth.
