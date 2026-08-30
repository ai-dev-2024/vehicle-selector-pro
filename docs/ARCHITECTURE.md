# Architecture

## System overview

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

## Data model

```mermaid
erDiagram
    Shop ||--o{ VehicleProductFitment : "owns"
    Shop ||--o{ MetafieldSyncLog : "logs"
    Shop ||--|| AppSetting : "configures"
    Vehicle ||--o{ VehicleProductFitment : "matches"

    Shop {
        integer id PK
        string shopify_domain UK
        string shopify_token "encrypted"
        boolean active
    }

    Vehicle {
        integer id PK
        integer year
        string make
        string model
        string trim
        string engine
    }

    VehicleProductFitment {
        integer id PK
        integer shop_id FK
        integer vehicle_id FK
        string product_id "GraphQL GID"
        boolean universal_fit
        string fitment_type
    }

    MetafieldSyncLog {
        integer id PK
        integer shop_id FK
        string status
        integer synced_products
    }

    AppSetting {
        integer id PK
        integer shop_id FK
        string widget_title
        boolean enable_garage
    }
```

## Request flow

1. **Storefront widget** calls `/apps/vehicle-selector/years` (or `makes`, `models`, etc.)
2. **Shopify App Proxy** forwards the request with an HMAC-SHA256 signature
3. **AppProxySignatureVerifier** validates the signature using constant-time comparison
4. **VehicleFiltersController** queries the normalized PG cache (or Redis cache for cascading trees)
5. Response cached with `Cache-Control: public, max-age=180`

## Metafield sync flow

1. Merchant assigns fitment via admin dashboard
2. `after_commit` callback enqueues `BatchSyncJob`
3. Job batches products in groups of 25
4. `metafieldsSet` GraphQL mutation writes `$app.vehicle_fitment` JSON
5. `MetafieldSyncLog` records status for the sync monitor

## Security layers

| Layer | Mechanism |
|---|---|
| App Proxy | HMAC-SHA256 hex signature on every request, constant-time compare |
| Webhooks | `X-Shopify-Hmac-Sha256` Base64 signature on raw body |
| Rate limiting | Rack::Attack throttling (10 req/30s per shop) |
| Tokens | ActiveRecord Encryption at rest (`encrypts :shopify_token`) |
| Multi-tenancy | `ShopScoped` concern on every query — explicit `shop_id` scoping |
