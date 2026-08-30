<div align="center">

<img src="docs/assets/banner.svg" alt="Vehicle Selector Pro" width="100%">

# Vehicle Selector Pro

### Fitment intelligence for Shopify automotive stores

[![Live Demo](https://img.shields.io/badge/Live_Storefront_Demo-008060?style=flat-square&logo=shopify&logoColor=white)](https://vehicle-selector-pro.fly.dev/demo)
[![Admin Preview](https://img.shields.io/badge/Live_Admin_Preview-1f6feb?style=flat-square)](https://vehicle-selector-pro.fly.dev/demo/admin)
[![GitHub](https://img.shields.io/badge/View_on_GitHub-181717?style=flat-square&logo=github&logoColor=white)](https://github.com/ai-dev-2024/vehicle-selector-pro)
[![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)](LICENSE)
[![Rails](https://img.shields.io/badge/Rails-7.1-CC0000?style=flat-square&logo=rubyonrails&logoColor=white)](https://rubyonrails.org/)

</div>

---

Automotive merchants assign **Year / Make / Model / Trim / Engine** fitment data to their products. Customers filter the catalog with cascading dropdowns and see **"Guaranteed Exact Fit"** badges on product pages — powered by Shopify App Proxy, Product Metafields, and a Theme App Extension.

**[Live storefront demo](https://vehicle-selector-pro.fly.dev/demo)** · **[Live admin preview](https://vehicle-selector-pro.fly.dev/demo/admin)** · **[Demo video](#demo)** · **[Setup guide](docs/SETUP.md)** · **[Architecture](#architecture)**

> **Installing on your own store** — this is a custom (unlisted) app, so Shopify requires installation through the Partners distribution link. Open an issue or request access and we will generate an install link for your store. The live demo above needs no installation.

---

## Demo

<div align="center">

<video src="demo/Vehicle_Selector_Pro_Demo_v3.mp4" controls width="100%" poster="docs/assets/screenshot-hero.png">
  Your browser does not support the video tag — <a href="demo/Vehicle_Selector_Pro_Demo_v3.mp4">download the .mp4</a>.
</video>

**[▶ Watch the 2.5-minute walkthrough](demo/Vehicle_Selector_Pro_Demo_v3.mp4)** — real screen recording of the working app with studio AI voiceover and background score · [script](docs/DEMO_SCRIPT.md) · [interactive walkthrough](demo/index.html)

</div>

---

## Features

- **Cascading storefront widget** — Year, Make, Model, Trim, Engine dropdowns driven by HMAC-signed App Proxy queries
- **Product fitment badges** — Guaranteed Exact Fit / Does NOT Fit / Universal Fit on any product page
- **My Garage** — shoppers save multiple vehicles and switch between them across pages
- **Merchant admin** — fitment matrix, vehicle library, bulk CSV import, sync monitor, widget settings
- **Metafield sync** — fitment JSON synced to `custom.vehicle_fitment` via `metafieldsSet` in batches of 25
- **Webhook pipeline** — `products/*`, `app/uninstalled`, `shop/update` processed asynchronously via Sidekiq
- **Multi-tenant** — per-shop data isolation, encrypted tokens, HMAC-SHA256 verification on every request

---

## Screenshots

<div align="center">

**Merchant Admin Dashboard**

<img src="demo/autoplay/frames_live/01_dashboard.png" alt="Admin dashboard with 100% catalog coverage, 7 mapped products, and live sync status" width="100%">

**Vehicle Library (YMMTE Database)**

<img src="demo/autoplay/frames_live/02_vehicles.png" alt="Vehicle database with 33 vehicles across BMW, Chevrolet, Ford, and Jeep with cascading filters" width="100%">

**Product Fitment Matrix**

<img src="demo/autoplay/frames_live/03_fitment_rules.png" alt="Fitment rules matrix with 35 product-to-vehicle mappings, sync status, and edit controls" width="100%">

**Widget Configuration**

<img src="demo/autoplay/frames_live/05_settings.png" alt="Widget and Garage configuration with brand color, selector depth, and My Garage settings" width="100%">

**Bulk CSV Import**

<img src="demo/autoplay/frames_live/06_bulk_imports.png" alt="Bulk CSV fitment import with file upload and paste options" width="100%">

</div>

---

## Architecture

```mermaid
graph TB
    subgraph Storefront ["Shopify Online Store"]
        TAE["Theme App Extension<br/>vehicle_selector_filter.liquid"]
        PFC["Product Fitment Badge<br/>product_fitment_badge.liquid"]
        StoreJS["vehicle-selector.js<br/>LocalStorage Garage + DOM Sync"]
    end

    subgraph Shopify ["Shopify Platform"]
        Proxy["App Proxy<br/>/apps/vehicle-selector"]
        GQL["GraphQL Admin API<br/>metafieldsSet"]
        WH["Webhook Engine"]
    end

    subgraph App ["Vehicle Selector Pro — Fly.io"]
        subgraph ProxyLayer ["App Proxy API (HMAC Verified)"]
            Auth["AppProxySignatureVerifier"]
            Filters["VehicleFiltersController"]
            Fitments["FitmentsController"]
            Cache["Redis Cache"]
        end

        subgraph Admin ["Admin Dashboard"]
            Dashboard["DashboardController"]
            FitCtrl["ProductFitmentsController"]
            Vehicles["VehiclesController"]
            Bulk["BulkImportsController"]
        end

        subgraph Jobs ["Sidekiq Background Jobs"]
            Batch["BatchSyncJob"]
            Product["ProductMetafieldSyncJob"]
            WebhookJobs["Webhooks::*Job"]
        end

        subgraph Data ["PostgreSQL (multi-tenant)"]
            Shop["Shop"]
            Vehicle["Vehicle"]
            Fitment["VehicleProductFitment"]
            SyncLog["MetafieldSyncLog"]
        end
    end

    TAE --> StoreJS
    PFC --> StoreJS
    StoreJS -->|GET /apps/vehicle-selector/*| Proxy
    Proxy --> Auth
    Auth --> Filters
    Auth --> Fitments
    Filters <--> Cache
    Filters <--> Data
    FitCtrl -->|enqueues| Batch
    Batch -->|metafieldsSet| GQL
    WH --> WebhookJobs
    WebhookJobs --> Data
```

Full system diagrams, data model, and request lifecycles: **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)**

---

## Quick start

### Try it now — no install required

**[Live storefront demo →](https://vehicle-selector-pro.fly.dev/demo)** — cascading Year/Make/Model/Trim/Engine widget with guaranteed-fit badges against live data.

**[Live admin preview →](https://vehicle-selector-pro.fly.dev/demo/admin)** — fitment matrix, vehicle library, sync monitor, and bulk CSV import.

### Local development

```bash
git clone https://github.com/ai-dev-2024/vehicle-selector-pro.git
cd vehicle-selector-pro
bundle install
cp .env.example .env    # fill in SHOPIFY_API_KEY / SHOPIFY_API_SECRET / SHOPIFY_STORE_DOMAIN
bundle exec rails db:prepare db:seed
bundle exec rails server
```

Then open `http://localhost:3000` for the admin dashboard, or `http://localhost:3000/storefront_preview` to see the Theme App Extension widget against live data.

---

## Tech stack

| Layer | Technology |
|---|---|
| Framework | Ruby on Rails 7.1 |
| Database | PostgreSQL (production) / SQLite (dev) |
| Background jobs | Sidekiq + Redis |
| Shopify integration | Theme App Extension (OS 2.0), App Proxy, GraphQL Admin API (`metafieldsSet`) |
| Security | HMAC-SHA256 verification, Rack::Attack throttling, ActiveRecord Encryption |
| Hosting | Fly.io (Puma + Sidekiq + Postgres + private Redis) |

---

## Documentation

| | |
|---|---|
| [Setup guide](docs/SETUP.md) | Local development environment |
| [Deployment](docs/DEPLOYMENT.md) | Fly.io runbook with provisioning commands |
| [API reference](docs/API.md) | App Proxy endpoints and webhook topics |
| [Architecture](docs/ARCHITECTURE.md) | System diagrams and data model |
| [Demo script](docs/DEMO_SCRIPT.md) | Voiceover narration for the walkthrough video |
| [Changelog](CHANGELOG.md) | Release history |

---

## License

[MIT](LICENSE) © 2026 Vehicle Selector Pro contributors.

<div align="center">

[Report an issue](https://github.com/ai-dev-2024/vehicle-selector-pro/issues) · [Request a feature](https://github.com/ai-dev-2024/vehicle-selector-pro/issues/new)

</div>
