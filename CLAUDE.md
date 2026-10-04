# Hikko

Version: v3.0.0 (web, iOS, macOS share one version from 3.0 on)

Was Sparkjar, then Hotaru for a day, Hikko since 2026-10-04. Open work lives in `roadmap.md`.

## What did not get renamed, on purpose
- Cloudflare Pages project is `sparkjar`. Deploy with `npm run deploy`.
- `sparkjar.heyitsmejosh.com` still serves. Shipped binaries call it. Never retire it.
- Bundle ids `com.heyitsmejosh.spark`, Xcode targets `Spark` / `SparkMac`, the `spark_*` localStorage keys.

## Money
Free, plus a $1 one-time unlock on the web through Stripe (live since 2026-09-06). Nothing sold in the native apps.

## Rules

- No emojis
- No build step -- everything runs from index.html
- Mobile-first layout
- Respect the existing visual language; keep UI minimal and fast to scan
- Seed data fallback when Supabase is unreachable

## Run

```bash
npx serve .
npm test
npx wrangler deploy --config worker/wrangler.jsonc   # deploy the cron worker
```

## Layout

Feed uses CSS grid (`repeat(auto-fill, minmax(320px, 1fr))`), 3-line content clamp. No box-shadows anywhere.

## Theme

One preference for the whole site: `spark_theme` in localStorage, `dark` by
default. `theme.js` loads synchronously in every page's `<head>`, stamps
`data-theme` on `<html>` before first paint, wires any `[data-theme-toggle]`
button, and swaps any `[data-shot-dark][data-shot-light]` image. Pages declare
both palettes under `:root[data-theme="dark"]` and `:root[data-theme="light"]`
-- a token defined in only one block silently drops the declaration that uses
it, so keep the two blocks symmetric.

Hero screenshots are captured per theme:

```bash
npm i --no-save playwright && node scripts/screenshots.mjs
```

## Key Files

- index.html (marketing landing page: HTML + CSS + JS)
- theme.js (shared light/dark control for every page -- see Theme below)
- api/posts.js (GET/POST posts, seed data fallback)
- api/ai.js (?type=generate|enrich|idea-base|notes|rfs -- all the AI paths, server-side)
- api/_lib/supabase.js (Supabase REST wrapper)
- worker/worker.js (cron trigger only -- calls the API above, holds no logic)
- sw.js

## Content engine

The feed generates and enriches itself server-side. There is no local daemon and no
API key -- `callGemma` in `api/ai.js` runs Cloudflare Workers AI through the `AI`
binding, the same way nimble does.

- `POST /api/ai?type=generate` writes one idea to Supabase as author `gemma`.
- `POST /api/ai?type=enrich` with `{id}` fills its spec + build plan.
- Both accept `Authorization: Bearer $SPARK_DAEMON_SECRET`; enrich also accepts a
  signed-in user token.

Cloudflare Pages cannot hold a cron trigger, so the daily 09:00 schedule lives in a
sidecar Worker (`worker/`) that does nothing but call those two endpoints. Deploy it
with `npx wrangler deploy --config worker/wrangler.jsonc`, and set its secret with
`npx wrangler secret put SPARK_DAEMON_SECRET --config worker/wrangler.jsonc` -- the
value must match the one on the Pages project.

To fire it by hand, POST `/` on the worker with the same bearer.

Backlog: `SPARK_DAEMON_SECRET=... bash scripts/backfill-enrich.sh` enriches every
post that has no spec yet. One-off, not scheduled.

## Native Companions

| Platform | Dir | Bundle ID | Status |
|---|---|---|---|
| iOS | ios/ | com.heyitsmejosh.spark | 1.0.1 live. 3.0 waiting for review (submitted 2026-10-04) |
| macOS | macos/ | com.heyitsmejosh.spark | 1.0.2 live. 3.0 waiting for review (submitted 2026-10-04) |
| watchOS | watchos/ | com.heyitsmejosh.spark.watchos | Bundled with iOS; no login UI (view-only without iOS pre-auth) |

Build with `xcodegen generate` in each platform dir. Screenshots in `screenshots/`.

## Release
`asc workflow run ship-ios VERSION:x.y` and `ship-mac`. Both submit for review. The bump step only
edits the generated `.xcodeproj`, so copy the new version and build number into `project.yml`
afterwards or the next `xcodegen generate` reverts them. iOS screenshots: `cd ios && fastlane snapshot`
(it hangs after writing the files; the PNGs are done when they appear).
