# Plan: Rails 7.1 → 7.2 Upgrade (resolves remaining advisories)

## Why

The dependency audit is green only because `.bundler-audit.yml` whitelists
three advisories whose fixes live in Rails 7.2.3.1+ (the 7.1 line is frozen at
7.1.6 with no backports):

| Advisory | Gem | Fix |
|---|---|---|
| GHSA-v55j-83pf-r9cq | actionview (XSS in tag helpers) | 7.2.3.1+ |
| GHSA-89vf-4333-qx8v | activesupport (ReDoS in `number_to_delimited`) | 7.2+ |
| GHSA-2j26-frm8-cmj9 | activesupport (XSS in `SafeBuffer#%`) | 7.2+ |

The shopify_app (GHSA-6j52-38f8-qhxr) and Puma (GHSA-qpgp-93vx-g8v8,
GHSA-2vqw-3mp8-cgmx) advisories stay whitelisted as not-exploitable, but the
same upgrade window is the natural moment to bump shopify_app 22 → 23 and
puma 6 → 7 if desired.

## Risk assessment

- **Low risk for this codebase**: no Active Storage, no Action Mailbox, no
  custom railties, no deprecated-API usage detected in `app/`.
- **Known breaking points to verify:**
  - `config.active_support` / `config.action_view` new defaults (7.2 changes
    `config.autoloader`, adds `YAML.safe_load` defaults tightening).
  - Rails 7.2 requires Ruby >= 3.1 — we run 3.2, fine.
  - `solid_cache 0.7` is Rails 7.1-oriented; verify it accepts 7.2 (it does —
    0.x supports 7.1/7.2, 1.x requires 7.2+).
  - `shopify_app 22` declares `railties >= 7.0`; no hard pin against 7.2.
- **Deployed app**: Fly deploy workflow runs on every push to main, so a bad
  upgrade reaches production. Mitigation: upgrade on a branch, run the full
  suite + boot check, then merge.

## Steps

### 1. Branch
```bash
git checkout -b rails-7-2
```

### 2. Gemfile bump
```ruby
gem "rails", "~> 7.2.2"
```
Keep `shopify_app ~> 22.0` (optional follow-up: `~> 23.0` in the same branch,
but that is its own regression surface — prefer a second pass).

### 3. Update bundle
```bash
bundle update rails
```
Expect new `actionpack`, `actionview`, `activestorage`, `activesupport`,
`railties` 7.2.x. Run `bundle exec bundler-audit check` — the three Rails
advisories should disappear.

### 4. Config updates
- `config/environments/*.rb`: run `bin/rails app:update` interactively and
  accept only the 7.2 defaults (new framework defaults file
  `config/initializers/new_framework_defaults_7_2.rb`).
- Load and later delete the new defaults file once verified.

### 5. Full verification
```bash
bundle exec rails zeitwerk:check
bundle exec rspec                # 101 examples expected green
ruby spec/test_runner.rb         # integration: 12 runs
bundle exec rubocop
bundle exec bundler-audit check  # expect: no unwhitelisted advisories
RAILS_ENV=production bundle exec rails runner 'puts "boot ok"'
```

### 6. Remove whitelist entries
Delete the three Rails advisories from `.bundler-audit.yml` (the
`# Tracked upgrade` block). Keep the Active Storage / Puma / shopify_app
entries with their justifications.

### 7. Canary deploy
```bash
flyctl deploy --strategy rolling
curl -s https://vehicle-selector-pro.fly.dev/health/deep
# expect {"status":"ok","checks":{"database":true,"cache":true}}
```
Then run the signed app-proxy smoke test (years/makes/search/check_fitment)
as documented in `docs/OPERATIONS.md`.

### 8. Merge & close out
```bash
git checkout main && git merge --no-ff rails-7-2 && git push
```
Update `CHANGELOG.md` (new 1.3.1 entry), `REQUIREMENTS-VERIFICATION.md`
(Rails 7.2.x row), and remove the "Tracked upgrade" note from
`.bundler-audit.yml` comments.

## Rollback

If the canary deploy fails health checks, `flyctl releases` shows the last
good release; `flyctl rollback <version>` restores it while the branch is
fixed. The Docker image is rebuilt per-deploy, so no artifact cleanup is
needed.
