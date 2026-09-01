# Changelog

All notable changes to Vehicle Selector Pro are documented here.

## [1.3.2] — 2026-09-01

Presentation and demo-experience polish; catalog wave 4.

### Added
- **Catalog wave 4**: 20 new products (54 total) across Maintenance, Electrical, Wipers,
  Filters, Interior, Exterior, Armor, Towing, Chassis and Lighting — each with full
  descriptions, vehicle fitment mappings (318 fitments total) and manufacturer-style
  spec sheets on the product page. 19 freely-licensed photos fetched from Wikimedia
  Commons with curated picks and attribution in `public/demo-products/CREDITS.md`.
- **Demo billing walkthrough** (`/demo/admin/billing`): plan buttons now open an overlay
  explaining exactly what happens on a real store (Shopify's native plan-confirmation
  checkout, 14-day trial) and offer a clearly-labeled **simulated plan switch** so the
  CURRENT badge and import limits can be demonstrated without a Shopify session.
  A "DEMO PREVIEW" pill marks the page everywhere it appears.

### Fixed
- **README videos**: the inline players pointed at stale `user-attachments` uploads that
  no longer matched the final renders. Both videos now stream from GitHub Pages
  (`video/mp4`, byte-identical to the current renders, faststart for instant playback).
- **Seed bug**: the Mustang 2.3L intake matched `engine LIKE '%EcoBoost%'` (the trim, not
  the engine), leaving the product with zero fitments and invisible on the storefront.

### Changed
- **Merchant UI motion polish**: shared easing curve, hover/focus/active transitions on
  buttons, nav, cards, stat tiles and table rows, a soft page-entrance animation and a
  breathing live-status dot — all disabled under `prefers-reduced-motion`.

### Verification
- 103 RSpec examples, 0 failures · RuboCop clean (134 files) · zeitwerk green.

## [1.3.1] — 2026-09-01

Rails 7.1.6 → 7.2.3.2 security upgrade.

### Changed
- **Rails 7.1.6 → 7.2.3.2**: resolves GHSA-v55j-83pf-r9cq (actionview XSS),
  GHSA-89vf-4333-qx8v (activesupport ReDoS) and GHSA-2j26-frm8-cmj9
  (activesupport SafeBuffer#% XSS) — removed from the bundler-audit whitelist.
  Framework defaults bumped to 7.2; the app's custom config (Sidekiq adapter,
  Active Record encryption, CSP, Solid Cache) preserved and verified.
- **Branch protection**: `main` now requires the CI check to pass and forbids
  force-pushes/deletions.

### Verification
- 101 RSpec examples, 0 failures · 12 integration runs · zeitwerk green ·
  RuboCop clean · bundler-audit: no vulnerabilities.

## [1.3.0] — 2026-09-01

Storefront analytics dashboard.

### Analytics
- **Admin analytics dashboard** (`/admin/analytics`) in the command-center UI: metric tiles
  (checks, guarantees fits, fit rate, no-fit, universal) and a zero-filled daily checks chart
  with a 7/30/90-day range selector.
- **Per-make breakdown**: the storefront check path now records a `make` dimension alongside
  the overall total, and the dashboard renders a checks-by-make bar list with per-make fit rates.
- **`FitmentAnalytic` query helpers** (`total`, `series`, `by_make`) over the daily aggregates,
  and a new `dimension_value` column so makes/values are stored as their own rows instead of
  colliding under a bare dimension name. All reads stay per-shop scoped.
- **Public demo routes** for the new pages: `/demo/admin/analytics`, `/demo/admin/billing`,
  and `/demo/admin/oe-numbers` render the real admin views read-only against the demo shop
  (billing never touches Shopify from the demo path).

## [1.2.0] — 2026-09-01

Shopify Billing API subscription flow with free trial + paid tiers.

### Billing
- **Multi-tier plan catalogue** (`BillingPlan`): Free (0, capped), Pro ($9.99, 14-day trial),
  and Pro Plus ($29.99, 14-day trial), each with a Shopify-native recurring subscription
  charge and a fitment ceiling for bulk imports.
- **`Shopify::BillingService`** creates subscriptions via the Shopify Billing GraphQL API
  (`appSubscriptionCreate`), redirects the merchant to Shopify's native checkout
  (`confirmationUrl`), and reconciles `shops.billing_plan` from the shop's
  `currentAppInstallation.activeSubscriptions` (test-mode aware).
- **Billing admin page** (`/admin/billing`): plan cards with price/trial, start-subscription
  CTA, and a return callback that marks the shop paid after checkout. Refuses to stack a
  second charge when a shop already has an active billable subscription.
- **Bulk import gating**: `Admin::BulkImportsController` rejects (and routes to billing) any
  import that would push the shop past its tier's plan ceiling; upgrading raises the limit.

## [1.1.0] — 2026-09-01

Production-grade hardening pass (Phases 1–5).

### Reliability
- **Solid Cache** (Postgres-backed) is now the production cache default when
  `REDIS_URL` is unset, replacing the per-machine memory fallback so
  `FitmentSearchService` cache invalidation stays correct across machines.
- **Webhook dedup**: every delivery is recorded against a unique
  `(shop_domain, webhook_id)` index, so Shopify replays ack with 200 without
  double-processing. Stale rows pruned automatically (7-day retention).
- **Metafield sync resilience**: each batch is marked synced immediately after
  it succeeds, and `sync_all` only replays `pending_sync` products — a partial
  failure never re-syncs the whole catalog. Sync logs now track failed counts.
- **Metafield sync debounce**: a 30s cache window coalesces per-product sync
  jobs during bulk imports, with a re-enqueue tail so the newest write always
  reaches Shopify.

### Performance
- Composite indexes on the fitment search hot paths (shop+universal+product,
  shop+synced+last_synced, product+shop, make+model, shop+fitment_type).
- Search pagination moved into SQL (`OR`-combined specific/universal query with
  LIMIT/OFFSET) so page requests no longer materialize the whole catalog.
- App Proxy responses now carry ETags so Shopify/browser caches return 304.

### Observability & security
- Structured JSON request logging via **lograge** (health checks excluded).
- `GET /health/deep` checks DB + cache; wired into Fly machine checks and the
  deploy workflow's post-deploy verification.
- **Sentry** error tracking (Rails + Sidekiq, dead-job alerts) when `SENTRY_DSN`
  is set; release tagged with `GIT_SHA`.
- Security headers on every response: CSP with Shopify frame-ancestors,
  nosniff, referrer policy, permissions policy.
- **bundler-audit** job in CI + **Dependabot** for Ruby and Actions deps.
- `docs/OPERATIONS.md` runbook: health checks, Fly Postgres backups, restore
  procedure, logs/Sentry, incident checklist.

### Beyond-spec foundations (growth path)
- **Fitment confidence scoring** per fitment type (oem 1.0 / direct 0.9 /
  modified 0.5 / universal 0.4), exposed in API payloads.
- **OE-number cross-reference** (`oe_numbers` table) with `?oe=` app proxy
  search so shoppers can find parts by factory part number.
- **Billing foundation** (`billing_plan` / expiry columns + `on_paid_plan?`).
- **Analytics foundation** (daily `fitment_analytics` aggregates written
  off-request by a background job).

### OE number admin UI
- New **OE part numbers** page in the merchant admin (sidebar → Configure):
  add a single OE number per product, search the registry, remove entries,
  and bulk-import from CSV (`product_id,oe_number`, duplicates skipped) with
  a downloadable template. Searchable in the storefront via the existing
  `?oe=` app proxy endpoint.

### Security
- Upgraded **sqlite3 1.7 → 2.9.6** fixing two use-after-free advisories
  (GHSA-mwm8-39rw-8826, GHSA-28hh-pr2h-2w89).
- Added `.bundler-audit.yml` documenting the remaining advisories that are
  not exploitable in this deployment (Active Storage unused, Puma PROXY
  protocol not enabled, `current_shopify_domain` helper never used) and the
  tracked Rails 7.1→7.2 / shopify_app 22→23 upgrade; the CI audit job still
  fails on any advisory not whitelisted.

## [1.0.0] — 2026-08-30

First production release — deployed and verified end-to-end on Fly.io against a
live Shopify development store.

### Added
- Rails 7.1 multi-tenant application with shop-scoped models and encrypted tokens.
- Storefront Theme App Extension: cascading YMMTE **Vehicle Selector Filter** block
  and live **Product Fitment Badge** block (vanilla JS, no ScriptTag APIs).
- HMAC-SHA256 verified App Proxy API (`/apps/vehicle-selector/*`): years, makes,
  models, trims, engines, search, check_fitment (numeric + GID product IDs),
  product_fitments, garage. Per-shop cache versioning and Rack::Attack throttling.
- GraphQL Admin API synchronization of fitment data to `custom.vehicle_fitment`
  product metafields (JSON, pinned, storefront PUBLIC_READ) via `metafieldsSet`
  in batches of 25, with retry/backoff for throttled queries.
- Async webhook pipeline: HMAC-verified endpoints enqueueing Sidekiq jobs for
  `products/create|update|delete`, `app/uninstalled`, `shop/update` and the
  mandatory privacy topics.
- Polaris-styled merchant admin: dashboard, fitment rules, vehicle library,
  bulk CSV import, sync activity monitor, widget settings.
- Fly.io deployment: Puma web + Sidekiq worker + Postgres cluster + private Redis;
  `rails db:migrate` release command; `/up` health check.
- Test suites: isolated unit harness (11 runs / 35 assertions) and full-stack
  integration tests booting the real app (9 runs / 28 assertions).
- Storefront preview harness (`/storefront_preview`, development only) rendering
  the real extension assets against the live API.

### Fixed during production hardening
- Pinned `connection_pool ~> 2.4` (3.x breaks Rails 7.1 redis cache store boot).
- Created `tmp/pids` in the image (Puma pidfile crash on boot).
- `CreateAppSettings` migration duplicate-index failure on Postgres (`index: false`).
- Dummy `DATABASE_URL` build arg so `assets:precompile` can boot during image build.
- Zeitwerk eager-load failures: per-file Shopify error classes + inflections;
  removed five unrouted skeleton controllers.
- Mounted `ShopifyApp::Engine` after application routes so webhook POSTs reach
  the app's controllers instead of raising `NoWebhookHandler`.

[1.0.0]: https://github.com/ai-dev-2024/vehicle-selector-pro/releases/tag/v1.0.0
