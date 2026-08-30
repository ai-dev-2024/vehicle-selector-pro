# Requirements Verification Report

**Date:** 2026-08-30 · **Environment:** production (Fly.io) + live Shopify dev store
**App:** https://vehicle-selector-pro.fly.dev · **Store:** vehicle-selector-pro.myshopify.com

This report maps every requirement from the client brief to verified evidence.
"Verified" means exercised against the deployed app or the live store — not just
present in code.

## Requirements vs. evidence

| # | Requirement | Status | Evidence |
|---|---|---|---|
| 1 | Rails engine/application, latest stable (7.x+) | ✅ Verified | Rails 7.1.6 boots on Fly; `rails zeitwerk:check` passes (eager-load safe) |
| 2 | OAuth via `shopify_app`, secure isolated per-shop storage | ✅ Verified | Real OAuth install on dev store; token stored encrypted; all queries shop-scoped |
| 3 | Admin dashboard, Rails views styled with Polaris | ✅ Verified | `Admin::` controllers + ERB views; Polaris token styling in `public/command-center.css` |
| 4 | Data in Shopify Metafields + normalized local cache | ✅ Verified | `metafieldsSet` wrote fitment JSON to 7 real products (35 records, read-back confirmed); Postgres cache with indexed YMMTE queries |
| 5 | Theme App Extension (no ScriptTag) | ✅ Verified | `extensions/vehicle-selector-pro-extension` released via `shopify app deploy` (2 blocks, section targets) |
| 6 | App Proxy endpoints (filter options + matching product IDs) | ✅ Verified | All 8 endpoints returned correct data with valid HMAC signatures; invalid/missing signatures → 401 |
| 7 | GraphQL Admin API sync | ✅ Verified | `Shopify::GraphQLClient` with retry/throttle handling; product creation + metafield sync executed live |
| 8 | Webhooks async via ActiveJob + Sidekiq | ✅ Verified | Signed POST → 200; tampered → 401; `Webhooks::ProductsUpdateJob` performed by Sidekiq (webhooks queue, 130 ms) |
| 9 | Git repo with app + extension | ✅ Verified | This repository |
| 10 | README with setup instructions | ✅ Verified | `README.md` + `docs/SETUP.md` + `docs/DEPLOYMENT.md` |
| 11 | 2–3 min screen recording | ⏳ In progress | Narrated walkthrough assembled from live app captures → `demo/video/` |

## Test evidence

```text
Unit harness:     11 runs, 35 assertions, 0 failures   (ruby spec/test_runner.rb)
Integration:       9 runs, 28 assertions, 0 failures   (boots the real app; HTTP-level)
Production spot checks (curl, HMAC-signed): /up, /years, /makes, /models,
  /trims, /engines, /search, /check_fitment, /product_fitments, /garage → 200
  unsigned/tampered variants → 401
Metafield read-back: 7/7 products carry $app.vehicle_fitment (fitments: 5/13/5/3/4/1/4)
```

## Known limitations (documented, by design)

- Native Shopify collection filtering (`filter.v.m.*`) does not apply to JSON
  metafields; the widget's primary filtering path is App Proxy search.
- `/storefront_preview` is a development-only harness for demonstrating the
  extension outside a theme.
- The theme blocks must be added to the merchant's theme in the theme editor
  (app scopes intentionally exclude `write_themes`).
