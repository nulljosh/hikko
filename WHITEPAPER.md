# Hikko Technical Whitepaper

**v2.2.0 web / 1.0 iOS / 1.0 macOS** | August 2026

A jar of ideas.

Most ideas die because turning "someone should build X" into an actual plan
is the part nobody wants to do. Hikko exists to close that gap: post one, vote on others, argue in the comments. A model turns the good ones into
build plans, so an idea does not need its poster to already know how to
scope it, and every morning a new idea shows up on its own, so the feed
is never empty even before anyone else contributes. Live at
[hikko.heyitsmejosh.com](https://hikko.heyitsmejosh.com), with native iOS,
macOS, and watchOS companions.

## Core Mechanic: Ideas as First-Class Objects

An idea is a post with a category, tags, votes, and comment threads, plus two
AI-generated attachments:

- **Enrichment (SPEC + PLAN)**: a Claude daemon
  (`daemon/spark-daemon.js`) picks up new ideas and writes a product spec and
  an implementation plan for each, turning a one-liner into something
  buildable, because the gap between "someone should build X" and actually
  starting is usually just nobody having written the plan down.
- **Idea Bases**: AI-generated idea clusters seeded from a topic, so an empty
  feed can bootstrap itself instead of asking the first visitor to populate it.

Ranking is Hot/New with optimistic-UI upvotes; category and tag filters
(tech, design, business, random) slice the feed. New users see curated seed
ideas, and the frontend falls back to seed data if Supabase is unreachable.

## Architecture

- **Frontend**: one `index.html`, all HTML, CSS, and JS, no build step.
  Responsive CSS grid feed (auto-fill, 320px min columns), PWA with offline
  support, dark/light toggle.
- **API**: Cloudflare Pages Functions. The site moved off Vercel on
  2026-08-17, which retired the old 12-function Hobby-plan cap that had forced
  auth into consolidated shared handlers; the consolidation stayed because it
  is simpler than splitting endpoints back out for no functional gain, but new endpoints are no longer budgeted against a limit.
- **Auth**: JWT with sign up/login, GitHub OAuth, ToS gate on register, and
  Face ID / Touch ID on iOS.
- **Database**: Supabase PostgreSQL with RLS enabled. This project is the
  shared free-tier database, lexly and other apps ride on it, so migrations
  here are effectively multi-tenant changes.
- **Daemon**: `spark-daemon.js` runs on demand (`--once`) rather than as a
  resident process, per the no-background-automation house rule, since a
  process nobody is watching is a process that can silently misbehave.

## Platforms

| Platform | Version | Status |
|---|---|---|
| Web (PWA) | v2.2.0 | Live on Cloudflare Pages |
| iOS | v1.0 | Live on the App Store |
| macOS | v1.0 | Live on the App Store |
| watchOS | v1.0 | Bundled with iOS |

## Security

- RLS on every table; JWT secret rotated 2026-05-09.
- Known debt: an old `.env` lives in three historical commits (no longer
  tracked), purge via `git filter-repo` is on the roadmap.
- Transactional email is wired to Resend but not yet sending: the domain is
  unverified, so signup/reset mail is the open blocker on the hosted flows.
