# Requirements Verification Report

**Date:** 2026-09-02 (refreshed) · **Environment:** production (Fly.io) + live Shopify dev store
**App:** https://vehicle-selector-pro.fly.dev · **Store:** vehicle-selector-pro.myshopify.com
**Current version:** 1.3.2 (see CHANGELOG.md)

This report maps every requirement from the client brief to verified evidence.
"Verified" means exercised against the deployed app, the live store, or the
current automated test suite — not just present in code.

## Core spec requirements vs. evidence

| # | Requirement | Status | Evidence |
|---|---|---|---|
| 1 | Rails engine/application, latest stable (7.x+) | ✅ Verified | Rails 7.2.3.2 boots on Fly (upgraded from 7.1.6 in v1.3.1); `rails zeitwerk:check` passes (eager-load safe) |
| 2 | OAuth via `shopify_app`, secure isolated per-shop storage | ✅ Verified | Real OAuth install on dev store; token stored encrypted; all queries shop-scoped (`ShopScoped`) |
| 3 | Admin dashboard, Rails views styled with Polaris | ✅ Verified | `Admin::` controllers + ERB views; Polaris token styling in `public/command-center.css` |
| 4 | Data in Shopify Metafields + normalized local PostgreSQL cache | ✅ Verified | `metafieldsSet` wrote fitment JSON to 7 real products (35 records, read-back confirmed); Postgres cache with indexed YMMTE queries |
| 5 | Theme App Extension (no deprecated ScriptTag) | ✅ Verified | `extensions/vehicle-selector-pro-extension` released via `shopify app deploy` (2 blocks, section targets) |
| 6 | App Proxy endpoints (filter options + matching product IDs) | ✅ Verified | All 8 endpoints returned correct data with valid HMAC signatures; invalid/missing signatures → 401 |
| 7 | GraphQL Admin API for syncing | ✅ Verified | `Shopify::GraphQLClient` with retry/throttle handling; product creation + metafield sync executed live |
| 8 | Webhooks processed asynchronously (ActiveJob + Sidekiq) | ✅ Verified | Signed POST → 200; tampered → 401; jobs run on the Sidekiq queue; replayed deliveries deduped via `webhook_deliveries` |
| 9 | Git repository containing app + extension | ✅ Verified | https://github.com/ai-dev-2024/vehicle-selector-pro |
| 10 | README with setup instructions | ✅ Verified | `README.md` + `docs/SETUP.md` + `docs/DEPLOYMENT.md` |
| 11 | 2–3 minute screen recording | ✅ Verified | Two narrated walkthroughs (`demo/vehicle-selector-pro-merchant.mp4` 1:29, `demo/vehicle-selector-pro-shopper.mp4` 1:35) playable directly from the repo home page |

## Post-spec feature verification (v1.1.0 – v1.3.2)

These features go beyond the original brief; each is verified by the current
automated suite and, where noted, against the live deployment.

### Production hardening (v1.1.0)

| Feature | Status | Evidence |
|---|---|---|
| Solid Cache as production default | ✅ Verified | `solid_cache` 0.7.0; `/health/deep` on the live app returns `{"status":"ok","checks":{"database":true,"cache":true}}` |
| Webhook dedup (replay protection) | ✅ Verified | `webhook_deliveries` table, unique `(shop_domain, webhook_id)` index; `spec/models/webhook_delivery_spec.rb` + replay tests in `spec/requests/webhooks_spec.rb` |
| Metafield sync batch resilience | ✅ Verified | Per-batch sync marking + pending-only replay in `Shopify::MetafieldSyncService`; `spec/services/metafield_sync_service_spec.rb` |
| Sync debounce | ✅ Verified | 30s cache coalescing window with re-enqueue tail in `vehicle_product_fitment.rb` / `ProductMetafieldSyncJob` |
| SQL-level search pagination + indexes | ✅ Verified | OR-combined specific/universal query with LIMIT/OFFSET in `FitmentSearchService`; 5 composite indexes; live `search` endpoint returns paged results (11 products for 2024 Ford) |
| ETag caching on App Proxy | ✅ Verified | Strong ETags + `Cache-Control: stale-while-revalidate` in `AppProxy::BaseController` |
| Observability | ✅ Verified | lograge JSON logging; `GET /health/deep` on the live app returns `{"status":"ok","checks":{"database":true,"cache":true}}`; Sentry gated on `SENTRY_DSN` with `GIT_SHA` release tags |
| Security hardening | ✅ Verified | CSP + security headers on every response (`spec/requests/security_headers_spec.rb`); bundler-audit CI job with documented whitelist (`.bundler-audit.yml`); Dependabot config |
| Ops runbook | ✅ Verified | `docs/OPERATIONS.md` (backups, restore, monitoring, incident procedure) |

### OE part numbers (v1.1.x)

| Feature | Status | Evidence |
|---|---|---|
| OE registry admin UI | ✅ Verified | `Admin::OeNumbersController` + `spec/requests/admin_oe_numbers_spec.rb` (7 specs: add, list/search, remove, CSV import, template) |
| OE-number storefront search | ✅ Verified | `?oe=` parameter on the App Proxy search endpoint resolves product IDs via the `oe_numbers` table |
| CSV bulk import with dedup | ✅ Verified | Duplicate skipping + per-row error reporting; downloadable CSV template endpoint |

### Shopify Billing (v1.2.0)

| Feature | Status | Evidence |
|---|---|---|
| Multi-tier plan catalogue | ✅ Verified | `BillingPlan`: Free ($0, 500 fitments), Pro ($9.99/mo, 14-day trial, 5,000), Pro Plus ($29.99/mo, 14-day trial, 100,000) |
| Subscription creation via Billing API | ✅ Verified | `appSubscriptionCreate` mutation returns Shopify's native `confirmationUrl`; `spec/services/billing_service_spec.rb` (6 specs) |
| Native checkout + return reconciliation | ✅ Verified | `/admin/billing` plan cards + start-subscription CTA; `/admin/billing/return` reconciles `shops.billing_plan` from `currentAppInstallation.activeSubscriptions`; `spec/requests/admin_billing_spec.rb` |
| Plan-gated bulk import | ✅ Verified | Import exceeding the tier ceiling redirects to billing with a clear message; paid tiers raise the ceiling; covered in `admin_billing_spec.rb` |

### Storefront analytics (v1.3.0)

| Feature | Status | Evidence |
|---|---|---|
| Analytics dashboard | ✅ Verified | `Admin::AnalyticsController` + `spec/requests/admin_analytics_spec.rb` (5 specs: empty state, daily aggregates, per-make breakout, shop isolation, range validation) |
| Per-day series | ✅ Verified | `FitmentAnalytic.series` zero-fills the daily series; `spec/models/fitment_analytic_spec.rb` |
| Per-make breakdown | ✅ Verified | `dimension_value` column (migration `20260901000007`); per-make rows recorded from the check path; `spec/models/fitment_analytic_spec.rb` |
| Async, hot-path-safe recording | ✅ Verified | `Vehicles::RecordFitmentAnalyticJob` on the `low_priority` queue; no synchronous analytics writes in the proxy path |

### Search correctness & dead-code audit (v1.3.2)

| Feature | Status | Evidence |
|---|---|---|
| OE-number search dedupe + page cap | ✅ Verified | `render_oe_search` collapses multi-vehicle fitments to one card per product and caps at `FitmentSearchService::MAX_PAGE_SIZE`; `product_payload` made public for reuse; covered by a new integration test (product fitted to two vehicles renders once) |
| Page-consistent `product_ids` on vehicle search | ✅ Verified | Sort + cap applied to the id list so `product_ids` / `numeric_product_ids` / `products` describe the same page (DB-level pagination, `f707ac2`) |
| Dead routes / code removed | ✅ Verified | Removed no-op `bulk_delete`/`search_products` admin routes, duplicate `demo/admin/*` routes, orphaned `spec/spec_helper.rb` and `bulk_import_job.rb`, non-halting 304 short-circuit, dead `extract_restore_rate` |
| Featured demo grid ordering | ✅ Verified | `featured=1` returns curated SKUs in `FEATURED_SKUS` order; RSpec example pins exact set/order/count |

## Test evidence (2026-09-02)

```text
RSpec:            112 examples, 0 failures  (ruby spec/test_runner.rb)
  - Billing (service + request):        13 examples
  - Analytics (model + request):        11 examples
  - OE numbers (model + request):       7 request specs + model specs
  - Webhook dedup + security headers:   covered in feature specs
  - App Proxy integration:             13 runs, 52 assertions, 0 failures
RuboCop:          133 files inspected, no offenses detected
Zeitwerk:         eager-load check passes
CI (GitHub Actions): success (CI + Pages — Report + Deploy)
```

Live deployment checks (2026-09-02):

```text
GET /up                  → 200
GET /health/deep         → {"status":"ok","checks":{"database":true,"cache":true}}
Signed /apps/vehicle-selector/years   → 200 {"years":[2024..2020],"count":5}
Signed /apps/vehicle-selector/makes   → 200 {"makes":[BMW,Chevrolet,Ford,Honda,Jeep,RAM,Subaru,Toyota]}
Signed /apps/vehicle-selector/search  → 200 {"total_count":11,"page":1,...} for 2024 Ford
Unsigned/tampered proxy requests      → 401
```

## Known limitations (documented, by design)

- Native Shopify collection filtering (`filter.v.m.*`) does not apply to JSON
  metafields; the widget's primary filtering path is App Proxy search.
- `/storefront_preview` is a development-only harness for demonstrating the
  extension outside a theme.
- The theme blocks must be added to the merchant's theme in the theme editor
  (app scopes intentionally exclude `write_themes`).
- Billing subscriptions run in test mode unless `SHOPIFY_BILLING_TEST=false`
  is set in production; charges only activate through Shopify's native checkout.
- Remaining bundler-audit advisories require
