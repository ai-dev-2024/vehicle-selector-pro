require "rails_helper"

# Guards the production cache fallback in config/environments/production.rb:
# when REDIS_URL is absent the app falls back to :solid_cache_store (Postgres-
# backed, shared across machines). That branch is only safe if the solid_cache
# migrations are part of the repo and the store actually round-trips against
# the schema — this spec pins both, so a future refactor can't silently break
# the no-REDIS_URL deployment path.
RSpec.describe "production cache fallback (Solid Cache without REDIS_URL)" do
  it "ships the solid_cache migrations in the schema" do
    table_present = ActiveRecord::Base.connection.data_source_exists?("solid_cache_entries")
    expect(table_present).to be(true),
                             "run the solid_cache migrations (db:migrate)"
  end

  it "resolves the stores referenced by production.rb" do
    expect(ActiveSupport::Cache.lookup_store(:solid_cache_store).class).to eq(SolidCache::Store)
    expect(ActiveSupport::Cache.lookup_store(:redis_cache_store).class).to eq(ActiveSupport::Cache::RedisCacheStore)
  end

  it "round-trips cache writes/reads/deletes through the Solid Cache store" do
    store = ActiveSupport::Cache.lookup_store(:solid_cache_store)
    key = "vsp/cache_fallback_spec/#{SecureRandom.hex(8)}"

    expect(store.write(key, { fallback: true, at: Time.current.iso8601 })).to be(true)
    value = store.read(key)
    expect(value).to be_a(Hash)
    expect(value[:fallback]).to be(true)
    expect(store.delete(key)).to be(true)
    expect(store.read(key)).to be_nil
  ensure
    store&.delete(key)
  end
end
