require "rails_helper"

# Rails 7.2 is past its security support window. Advisories that are fixed
# only in Rails 8 are accepted in .bundler-audit.yml, each with the reason it
# cannot be reached in this app. Those reasons are assumptions about what the
# app loads and calls; this spec turns them into checks, so adding one of
# these frameworks or APIs fails CI instead of silently voiding the list.
RSpec.describe "Rails surface the accepted advisories depend on" do
  let(:engines) { Rails::Engine.descendants.filter_map(&:name) }

  %w[ActionCable::Engine ActiveStorage::Engine ActionMailbox::Engine ActionText::Engine].each do |engine|
    it "does not load #{engine}" do
      expect(engines).not_to include(engine)
    end
  end

  # Action Cable mounts an unauthenticated WebSocket endpoint by default; its
  # subscribe command is the entry point of GHSA-8474-xrp6-wh69.
  it "exposes no Action Cable endpoint" do
    paths = Rails.application.routes.routes.map { |route| route.path.spec.to_s }

    expect(paths.grep(%r{\A/cable})).to be_empty
  end

  # GHSA-2586-8ghr-69fj and GHSA-gmj8-hvj3-49mw affect every session store
  # except the cookie store.
  it "keeps sessions in the cookie store" do
    expect(Rails.application.config.session_store).to eq(ActionDispatch::Session::CookieStore)
  end

  # Streaming (GHSA-rwvh-fw6r-pwvp), Parameters#each_key (GHSA-wm3x-v3qw-4jh3),
  # the highlight / simple_format / strip_tags helpers (GHSA-2p2f-4rq4-gjwc,
  # GHSA-v6rj-xm57-3p59, GHSA-rq8q-p985-fjq7) and safe_constantize on request
  # input (GHSA-8474-xrp6-wh69). A match is not automatically a vulnerability:
  # read the advisory, then either avoid the API or upgrade Rails.
  it "does not call the APIs named in the accepted advisories" do
    pattern = /ActionController::Live|send_stream|\.each_key\b|\bhighlight\(|\bsimple_format\b|\bstrip_tags\b|constantize/
    offenders = Rails.root.glob("app/**/*.{rb,erb}").select { |file| file.read.match?(pattern) }

    expect(offenders.map { |file| file.relative_path_from(Rails.root).to_s }).to be_empty
  end
end
