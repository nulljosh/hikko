# Hikko Money

How Hikko makes money. The fleet-wide ledger is `GTM.md` in the Code root.

## Price

Free. Spark Pro is $1 once, on the web.

## Rail

Stripe Checkout. `api/posts.js`, `users.is_pro`, the `proBanner` and `unlockPro()` in `app.html`.

## Why

A forum needs people before it needs a price. Pro is a tip jar with perks.

## Next

Nothing until it has posters. The iOS build must not mention the paid tier; App Review requires IAP for that.

## Change it

`STRIPE_PRICE_ID` secret on the Cloudflare Pages project, then redeploy.

Anyone who got Hikko while it was free keeps it free. Only new customers pay.

*ASC 6785162492. Set 2026-09-20.*
