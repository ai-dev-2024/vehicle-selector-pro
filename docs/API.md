# API Reference

All storefront requests route through Shopify App Proxy at `/apps/vehicle-selector/*`. Shopify signs every forwarded request with an HMAC-SHA256 signature. Requests with missing or invalid signatures receive `401`.

---

## App Proxy Endpoints

| Endpoint | Params | Description |
|---|---|---|
| `GET /years` | — | Distinct years in the shop's catalog |
| `GET /makes` | `year` | Makes for that year |
| `GET /models` | `year, make` | Models for year + make |
| `GET /trims` | `year, make, model` | Trims for year + make + model |
| `GET /engines` | `year, make, model[, trim]` | Engines for the selected combination |
| `GET /search` | `year, make, model[, trim, engine, limit, page]` | Matching product IDs/handles + Shopify filter token |
| `GET /check_fitment` | `product_id` (numeric or GraphQL GID) `+ vehicle params` | Fit verdict (`exact_fit`, `universal`, `none`), badge text/color, notes |
| `GET /product_fitments` | `product_id` | All fitment records for a product |
| `GET /garage` | `vehicle_ids=1,2,3` | Vehicle details for stored IDs |

### Response caching

Responses are cached per-shop with `Cache-Control: public, max-age=180, stale-while-revalidate=360`. Cache is invalidated when fitment data changes via `FitmentSearchService.invalidate_shop_cache`.

---

## Webhooks

All webhook endpoints verify `X-Shopify-Hmac-Sha256` (Base64 HMAC-SHA256 of the raw body) with constant-time comparison, then enqueue work to Sidekiq (`queue: webhooks`, priority 3).

| Topic | Endpoint | Async job |
|---|---|---|
| `products/create` | `POST /webhooks/products_create` | `Webhooks::ProductsCreateJob` |
| `products/update` | `POST /webhooks/products_update` | `Webhooks::ProductsUpdateJob` |
| `products/delete` | `POST /webhooks/products_delete` | `Webhooks::ProductsDeleteJob` |
| `app/uninstalled` | `POST /webhooks/app_uninstalled` | `Webhooks::AppUninstalledJob` |
| `shop/update` | `POST /webhooks/shop_update` | Handled inline |
| `customers/data_request` | `POST /webhooks/customers_data_request` | Handled inline (GDPR) |
| `customers/redact` | `POST /webhooks/customers_redact` | Handled inline (GDPR) |
| `shop/redact` | `POST /webhooks/shop_redact` | Handled inline (GDPR) |

---

## Metafield schema

Fitment data is synced to Shopify Product Metafields under the `custom.vehicle_fitment` namespace (JSON type, pinned, storefront `PUBLIC_READ`):

```json
{
  "universal": false,
  "total_vehicles": 4,
  "fitments": [
    {
      "year": 2024,
      "make": "Ford",
      "model": "F-150",
      "trim": "Lariat",
      "engine": "3.5L EcoBoost V6",
      "notes": "Direct bolt-on replacement",
      "position": "Engine Bay",
      "fitment_type": "direct_fit"
    }
  ],
  "ymm_keys": ["2024|ford|f-150", "2023|ford|f-150"],
  "last_updated": "2026-08-29T12:00:00Z"
}
```

Metafields are written in batches of 25 via the `metafieldsSet` GraphQL mutation.

---

## Privacy webhooks

`customers/data_request`, `customers/redact`, and `shop/redact` cannot be registered via CLI. Configure them in the Partners Dashboard under **Customer privacy**:

```
/webhooks/customers_data_request
/webhooks/customers_redact
/webhooks/shop_redact
```
