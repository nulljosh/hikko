# Hikko roadmap

Only what is still open. History lives in git and `CHANGELOG.md`.

## Waiting on Apple
- [ ] 3.0 is waiting for review on iPhone and Mac. The iPhone build was bounced once (2.3.3, stale 6.5-inch and iPad Pro 2nd gen screenshots), the screenshots were replaced and it went back in on 2026-10-05. The store name flips from Sparkjar to Hikko when it is approved. Check with `asc versions list --app 6785162492`.

## Sign-in and mail
- [ ] Sign in with Apple has never had a real round trip on a physical device. Needs a phone in hand.
- [ ] Confirm a password-reset email lands in a real inbox. The endpoint returns the same 200 whether or not the send worked.
- [ ] Add `/api/health/mail`. It should ask Resend whether the key is valid without sending anything. A dead key stayed hidden for months because reset swallows send errors.
- [ ] GitHub and Google sign-in on iOS, plus forgot-password on iOS. Code is done on the web. Blocked on the console registrations.
- [ ] Sign in with Apple on the web. Native only today. Needs a Services ID.
- [ ] The authmail worker still lists this app as "Sparkjar" with a blue accent (`authmail/src/index.js`). That repo is mid-branch, so it was left alone.

## Cleanup
- [ ] iPhone post detail shows no body, spec or plan. The feed list leaves them out on purpose and `PostDetailView` never asks for the single post (`GET /api/posts?id=...`, which the web uses). Fetch it on open, then retake the idea-open screenshot (`ios/scripts/appstore-shots.sh` already captures it as `02-idea`). Check the Mac app for the same gap.
- [ ] Idea Base shows `&quot;` literally in "A Cloud for Small Software". Decode HTML entities where the YC text is loaded.
- [ ] Two probe accounts in Supabase from August: `probe1786367989`, `probe1786367990b`.
- [ ] The Mac listing has one screenshot. Three or four would sell it better.

## Ideas, no deadline
- [ ] A second model that filters the daily idea before it posts.
- [ ] Trademark and prior-art lookup on an idea.
