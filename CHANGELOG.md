# Changelog

All notable changes to Vehicle Selector Pro are documented here.

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
