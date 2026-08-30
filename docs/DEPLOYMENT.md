# Deployment Guide — Vehicle Selector Pro

This guide reflects the **verified production deployment** of Vehicle Selector
Pro on Fly.io. Every command below was executed successfully against the live
environment at `https://vehicle-selector-pro.fly.dev`.

- **App:** `vehicle-selector-pro` (region `iad`)
- **Database:** Fly Postgres cluster `vehicle-selector-pro-db` (single node)
- **Queue/Cache:** dedicated Redis app `vsp-redis` (internal network only)
- **Processes:** `app` (Puma web) + `worker` (Sidekiq) with standby

---

## 1. Prerequisites

| Tool | Purpose | Install |
|------|---------|---------|
| flyctl | Fly.io CLI | `winget install Fly-io.flyctl` (Windows) or see fly.io/docs |
| Shopify CLI 4.x | App/extension deploy | `npm install -g @shopify/cli` |
| A Shopify Partner app | Client ID + secret | partners.shopify.com |
| A Shopify development store | Install target | Partners → Stores → Add store |

```bash
flyctl auth login          # interactive browser login
shopify auth login         # interactive Partner login (one time)
```

Headless note: in CI or non-interactive shells, export `FLY_API_TOKEN`
(create one with `flyctl tokens create deploy`) instead of `flyctl auth login`.

---

## 2. Provision infrastructure

```bash
# Web application
flyctl apps create --name vehicle-selector-pro --org personal --yes

# Postgres (single node is enough for a demo; use 3 nodes for production HA)
flyctl postgres create \
  --name vehicle-selector-pro-db \
  --region iad \
  --vm-size shared-cpu-1x \
  --initial-cluster-size 1 \
  --volume-size 1

# Attach it — this sets the DATABASE_URL secret automatically
flyctl postgres attach vehicle-selector-pro-db -a vehicle-selector-pro
```

### Redis (for Sidekiq + Rails cache)

Fly's managed Upstash Redis requires interactive prompts; a plain Redis app on
the private network is simpler and fully scriptable. Config lives in `infra/redis/fly.toml` (gitignored — holds real password) — a committed template with
placeholder is at [`infra/redis/fly.toml.example`](../infra/redis/fly.toml.example):

```bash
# 1. Generate a password and put it in infra/redis/fly.toml (keep it out of git)
openssl rand -hex 16

# 2. Create + deploy
flyctl apps create --name vsp-redis --org personal --yes
flyctl deploy --config infra/redis/fly.toml --app vsp-redis
```

The app reaches it at `redis://default:<password>@vsp-redis.internal:6379`
(private network only — never exposed publicly).

---

## 3. Configure secrets

```bash
flyctl secrets set -a vehicle-selector-pro \
  SHOPIFY_API_KEY="<client id>" \
  SHOPIFY_API_SECRET="<client secret>" \
  SHOPIFY_STORE_DOMAIN="your-store.myshopify.com" \
  HOST="https://vehicle-selector-pro.fly.dev" \
  SECRET_KEY_BASE="$(openssl rand -hex 64)" \
  ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY="$(openssl rand -hex 32)" \
  ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY="$(openssl rand -hex 32)" \
  ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT="$(openssl rand -hex 32)" \
  REDIS_URL="redis://default:<redis-password>@vsp-redis.internal:6379"
```

`DATABASE_URL` comes from the Postgres attach step. Secrets are staged and
applied on the next deploy; inspect names (never values) with
`flyctl secrets list -a vehicle-selector-pro`.

Why these matter:

- `HOST` is the OAuth redirect base — it must match the URLs in
  `shopify.app.toml` exactly.
- `SECRET_KEY_BASE` and the three `ACTIVE_RECORD_ENCRYPTION_*` keys are
  required because this app ships without `config/master.key` (tokens are
  encrypted at rest with ActiveRecord encryption).
- `REDIS_URL` switches the cache store to Redis and powers Sidekiq.

---

## 4. Deploy

```bash
flyctl deploy
```

What happens:

1. The Dockerfile image is built remotely (Depot). Build-time dummy env vars
   let Rails boot for `assets:precompile` — real values are runtime-only.
2. `[deploy] release_command` runs `bundle exec rails db:migrate` on a
   throwaway machine.
3. Machines are launched for both process groups: `app` (Puma, 2 machines)
   and `worker` (Sidekiq, 1 + standby).
4. Health check: `GET /up` every 15s.

Seed the demo catalog (vehicles + fitments) once after the first deploy:

```bash
flyctl machine run registry.fly.io/vehicle-selector-pro:<image-tag> \
  -a vehicle-selector-pro --region iad \
  --vm-size shared-cpu-1x --vm-memory 512mb --rm \
  bundle exec rails db:seed
```

---

## 5. Register the app on Shopify

`shopify.app.toml` carries the application URL, OAuth redirect URLs, App Proxy
mapping and webhook subscriptions. Push it (plus the Theme App Extension) with:

```bash
shopify app deploy --allow-updates
```

Notes learned the hard way:

- The mandatory **customer-privacy webhooks** (`customers/data_request`,
  `customers/redact`, `shop/redact`) **cannot** be registered via CLI/API —
  configure them in the Partners Dashboard under **Customer privacy**. The
  Rails endpoints for them exist at `/webhooks/customers_data_request`,
  `/webhooks/customers_redact`, `/webhooks/shop_redact`.
- Theme-app-extension block schemas must use `"target": "section"` (or
  `head`/`body`) — `"target": "block"` is rejected.

Then install the app on the dev store:

```
https://vehicle-selector-pro.fly.dev/login?shop=your-store.myshopify.com
```

Approve the scopes in the Shopify admin; the OAuth callback stores the shop's
access token (encrypted) and opens the embedded admin dashboard.

---

## 6. Verify

```bash
# Health
curl https://vehicle-selector-pro.fly.dev/up
# => {"status":"ok"}

# App Proxy (signature verified server-side) — years for the shop
curl "https://vehicle-selector-pro.fly.dev/apps/vehicle-selector/years?shop=<domain>&timestamp=<ts>&signature=<hmac>"
```

The proxy signature is `HMAC-SHA256(secret, sorted key=value pairs excluding
signature)` — Shopify adds it automatically when storefront traffic arrives
through the proxy; for manual testing compute it with the app's client secret.

Machine status:

```bash
flyctl status -a vehicle-selector-pro   # app + worker should be "started"
flyctl logs -a vehicle-selector-pro --no-tail
```

---

## 7. Operating notes

### One-off jobs

`flyctl ssh console` can be unreliable from some networks; a one-off machine
is deterministic:

```bash
flyctl machine run registry.fly.io/vehicle-selector-pro:<image-tag> \
  -a vehicle-selector-pro --region iad --rm \
  bundle exec rails runner "puts Shop.count"
```

### Autoscaling behaviour

`fly.toml:19` is `min_machines_running = 1` (always warm — avoids 2–4s cold start on OAuth/webhooks). Set `0` only to save cost on idle dev (`auto_stop_machines = true` / `auto_start_machines = true`); first request then pays the cold-start latency.

### Costs (approximate, shared instances)

| Resource | Spec | ~Monthly |
|----------|------|----------|
| 2× web machines | shared-cpu-1x 256MB | ~$4 |
| 1× worker + standby | shared-cpu-1x 256MB | ~$2 |
| Postgres | shared-cpu-1x + 1GB volume | ~$3 |
| Redis | shared-cpu-1x 256MB ×2 | ~$4 |

Tear everything down with `flyctl apps destroy vehicle-selector-pro`,
`flyctl postgres destroy vehicle-selector-pro-db`, etc.

---

## 8. Troubleshooting (from real incidents)

| Symptom | Cause | Fix |
|---------|-------|-----|
| `wrong number of arguments (given 1, expected 0)` in `ConnectionPool#initialize` at boot | `connection_pool` 3.x removed the hash constructor Rails 7.1's redis cache store uses | Pin `gem 'connection_pool', '~> 2.4'` |
| Puma crashes: `rb_sysopen - tmp/pids/server.pid` | `tmp/` excluded from the image | `RUN mkdir -p tmp/pids log storage` in Dockerfile |
| `PG::DuplicateTable ... index_app_settings_on_shop_id` | `t.references` + same-named explicit index | `t.references ..., index: false` |
| Build fails in `assets:precompile` | `database.yml` raises without `DATABASE_URL` in production | Provide a dummy `DATABASE_URL` build ARG |
| Zeitwerk/eager-load crash (`Shopify::ThrottledError` uninitialized) | Error classes defined inline in another file | One Zeitwerk-managed file per constant + inflections |
