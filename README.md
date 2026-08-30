<div align="center">

<img src="docs/assets/banner.svg" alt="Vehicle Selector Pro" width="100%">

# Vehicle Selector Pro

### Fitment intelligence for Shopify automotive stores

[![Live App](https://img.shields.io/badge/Live_App-008060?style=flat-square&logo=shopify&logoColor=white)](https://vehicle-selector-pro.fly.dev/)
[![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)](LICENSE)
[![Rails](https://img.shields.io/badge/Rails-7.1-CC0000?style=flat-square&logo=rubyonrails&logoColor=white)](https://rubyonrails.org/)

</div>

---

Automotive merchants assign **Year / Make / Model / Trim / Engine** fitment data to their products. Customers filter the catalog with cascading dropdowns and see **"Guaranteed Exact Fit"** badges on product pages — powered by Shopify App Proxy, Product Metafields, and a Theme App Extension.

**[Live app](https://vehicle-selector-pro.fly.dev/)** · **[Install on your store](https://vehicle-selector-pro.fly.dev/login?shop=vehicle-selector-pro.myshopify.com)** · **[2.5 min demo video](#demo)** · **[Setup guide](docs/SETUP.md)**

---

## Features

- **Cascading storefront widget** — Year, Make, Model, Trim, Engine dropdowns driven by HMAC-signed App Proxy queries
- **Product fitment badges** — Guaranteed Exact Fit / Does NOT Fit / Universal Fit on any product page
- **My Garage** — shoppers save multiple vehicles and switch between them across pages
- **Merchant admin** — fitment matrix, vehicle library, bulk CSV import, sync monitor, widget settings
- **Metafield sync** — fitment JSON synced to `$app.vehicle_fitment` via `metafieldsSet` in batches of 25
- **Webhook pipeline** — `products/*`, `app/uninstalled`, `shop/update` processed asynchronously via Sidekiq
- **Multi-tenant** — per-shop data isolation, encrypted tokens, HMAC-SHA256 verification on every request

---

## Demo

<video src="demo/video/Vehicle_Selector_Pro_2.5min_Demo.webm" controls width="100%" poster="demo/video/frame-000.png">
  Your browser does not support the video tag — <a href="demo/video/Vehicle_Selector_Pro_2.5min_Demo.webm">download the .webm</a> or <a href="https://github.com/ai-dev-2024/vehicle-selector-pro/blob/main/demo/video/Vehicle_Selector_Pro_2.5min_Demo.webm">watch on GitHub</a>.
</video>

<sup>2.5-minute narrated walkthrough · [script](docs/DEMO_SCRIPT.md) · [raw video](https://github.com/ai-dev-2024/vehicle-selector-pro/raw/main/demo/video/Vehicle_Selector_Pro_2.5min_Demo.webm)</sup>

---

## Quick start

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
