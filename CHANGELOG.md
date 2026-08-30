# Changelog

All notable changes to Vehicle Selector Pro are documented here.

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
