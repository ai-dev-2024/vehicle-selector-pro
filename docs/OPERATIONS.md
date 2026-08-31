# Operations Runbook — Vehicle Selector Pro

Live environment: `https://vehicle-selector-pro.fly.dev` (app `vehicle-selector-pro`, region `iad`).

- **Database:** Fly Postgres cluster `vehicle-selector-pro-db` (single node)
- **Queue/Cache:** dedicated Redis app `vsp-redis` (internal network only)
- **Processes:** `app` (Puma web) + `worker` (Sidekiq)

---

## 1. Health checks

| Endpoint | Purpose | Who calls it |
|----------|---------|--------------|
| `GET /up` | Process liveness (returns 200 when booted) | Fly machine checks (15s interval) |
| `GET /health/deep` | DB + cache connectivity (503 when degraded) | External uptime monitors, manual |

```bash
curl -s https://vehicle-selector-pro.fly.dev/health/deep
# {"status":"ok","checks":{"database":true,"cache":true},"time":"..."}
```

Point a free uptime monitor (UptimeRobot / Better Stack) at **both** endpoints
with alert thresholds (e.g. 2 consecutive failures → notify). Add a separate
monitor for the App Proxy search route so storefront-facing latency is tracked:

```
https://vehicle-selector-pro.fly.dev/apps/vehicle-selector/search?year=2024&make=Ford&model=F-150&shop=vehicle-selector-pro.myshopify.com
```

## 2. Backups (Fly Postgres)

Fly managed Postgres takes automatic daily snapshots and retains 7. The
`vehicle-selector-pro-db` cluster has snapshots enabled by default.

List snapshots:

```bash
flyctl postgres snapshots list -a vehicle-selector-pro-db
```

Manual snapshot before a risky migration:

```bash
flyctl postgres snapshot create -a vehicle-selector-pro-db
```

## 3. Restore procedure

1. **Identify the snapshot** to restore (`flyctl postgres snapshots list -a vehicle-selector-pro-db`).
2. **Create a fresh restore cluster** (never restore in-place over the live DB):

```bash
flyctl postgres restore vehicle-selector-pro-db -a vehicle-selector-pro-db --snapshot <SNAPSHOT_ID>
```

3. **Point the app at the restored cluster** temporarily if the live DB is lost:
   update `DATABASE_URL` via `flyctl secrets set` on the app, then redeploy.
4. **Verify** with `curl https://vehicle-selector-pro.fly.dev/health/deep` and a
   smoke test of the App Proxy search endpoint.

Full recovery runbook (new cluster from scratch):

```bash
flyctl postgres create --name vehicle-selector-pro-db-restored
flyctl postgres restore vehicle-selector-pro-db -a vehicle-selector-pro-db-restored --snapshot <SNAPSHOT_ID>
flyctl secrets set -a vehicle-selector-pro "DATABASE_URL=$(flyctl postgres connect -a vehicle-selector-pro-db-restored --url)"
flyctl deploy -a vehicle-selector-pro
```

## 4. Redis / Sidekiq

- Cache + queue live on `vsp-redis` (internal network, not publicly exposed).
- **Sidekiq Web UI** is mounted at `/sidekiq` behind Shopify session auth
  (admin-only) — see `config/initializers/sidekiq.rb`.
- If the queue backs up: check the worker machine is running
  (`flyctl machines list -a vehicle-selector-pro`), then watch dead jobs in
  the Sidekiq UI. `retry_on Shopify::ThrottledError` retries 429/THROTTLED
  with polynomial backoff before jobs hit the dead set.
- **Cache warm-up after a fresh deploy:** the versioned cache keys
  (`vsp/shop/<id>/v<version>/...`) re-populate lazily; first requests after a
  deploy are slower but correct. To force invalidation (e.g. after a bad sync),
  bump the version token:

```bash
flyctl ssh console -a vehicle-selector-pro -- 'bundle exec rails runner "Shop.find_each { |s| FitmentSearchService.invalidate_shop_cache(s.id) }"'
```

## 5. Logs & error tracking

- **Logs** stream to stdout → Fly (`flyctl logs -a vehicle-selector-pro`).
  Production request logs are JSON (lograge) so they can be queried with
  `jq` or shipped to a log drain (Fly log drains → Papertrail/Grafana).
- **Sentry** captures Rails + Sidekiq exceptions when `SENTRY_DSN` is set.
  Set the secret and redeploy to enable:

```bash
flyctl secrets set -a vehicle-selector-pro SENTRY_DSN=https://<key>@<org>.ingest.sentry.io/<project>
flyctl deploy -a vehicle-selector-pro
```

## 6. Incident checklist

1. Check `/health/deep` — is it DB, cache, or process level?
2. `flyctl logs -a vehicle-selector-pro --tail` for stack traces.
3. If DB: check `flyctl postgres status -a vehicle-selector-pro-db`.
4. If Redis: `flyctl redis status -a vsp-redis`.
5. If Sidekiq is stalled: check worker machine + dead set in Sidekiq UI.
6. Escalate to restore only if the DB is unrecoverable (see §3).

## 7. Scheduled housekeeping

- **Webhook dedup rows** are pruned automatically (7-day retention, triggered
  probabilistically inside the webhook path) — no cron required.
- **Metafield sync** sweeps only `pending_sync` products on retry, so a failed
  batch never replays the whole catalog.
