require "rails_helper"

# Guards the root cause of the October 2026 red CI: with no .ruby-version and
# `ruby ">= 3.2.0"` in the Gemfile, Dependabot resolved the lockfile against
# its own newer Ruby and locked gems (rbs 4.2.0) that CI's Ruby could not
# install. .ruby-version is now the single source of truth; every consumer
# that picks a Ruby or resolves gems must agree with it.
RSpec.describe "Ruby toolchain consistency" do
  let(:pinned) { Rails.root.join(".ruby-version").read.strip }
  let(:lockfile) { Bundler::LockfileParser.new(Rails.root.join("Gemfile.lock").read) }

  it "runs the suite on the pinned Ruby (CI reads .ruby-version)" do
    expect(RUBY_VERSION).to eq(pinned)
  end

  it "makes Bundler (and Dependabot) resolve against the pinned Ruby" do
    expect(Bundler.definition.ruby_version&.versions).to eq([pinned])
  end

  it "records the pinned Ruby in Gemfile.lock" do
    expect(lockfile.ruby_version).to start_with("ruby #{pinned}")
  end

  it "locks gems for the Linux platform CI and Docker install on" do
    expect(lockfile.platforms.map(&:to_s)).to include("x86_64-linux").or include("x86_64-linux-gnu")
  end

  # shopify_api depends on the openssl gem. Locking the version that ships as
  # a default gem with the pinned Ruby lets Bundler reuse it instead of
  # compiling it (the slim Docker image has no OpenSSL headers).
  it "locks the openssl gem bundled with the pinned Ruby" do
    default = Dir[File.join(Gem.default_specifications_dir, "openssl-*.gemspec")]
              .map { |path| File.basename(path, ".gemspec").delete_prefix("openssl-") }
    locked = lockfile.specs.find { |spec| spec.name == "openssl" }&.version.to_s
    expect([locked]).to eq(default)
  end

  it "builds the Docker image on the pinned Ruby" do
    from = Rails.root.join("Dockerfile").read[/^FROM ruby:(\S+)/, 1]
    expect(from).to eq("#{pinned}-slim")
  end

  # The Gemfile reads .ruby-version, so the gem layer must copy it before
  # `bundle install` or the image build fails while parsing the Gemfile.
  it "copies .ruby-version into the image before bundle install" do
    dockerfile = Rails.root.join("Dockerfile").read
    copy = dockerfile.index(/^COPY .*\.ruby-version/)
    install = dockerfile.index(/^RUN .*bundle install/)
    expect(copy).not_to be_nil
    expect(copy).to be < install
  end

  # The precompile step boots Rails on dummy credentials. As ARGs they exist
  # only during the build; as ENV they would persist into the runtime image,
  # where a missing Fly secret would silently fall back to a public value.
  it "keeps the build-time dummy credentials out of the runtime environment" do
    dockerfile = Rails.root.join("Dockerfile").read.gsub(/\\\r?\n/, " ")
    env_instructions = dockerfile.lines.grep(/\AENV\b/).join

    expect(env_instructions).to include("RAILS_ENV=production")
    expect(env_instructions).not_to match(/SECRET_KEY_BASE|SHOPIFY_API_KEY|SHOPIFY_API_SECRET|DATABASE_URL/)
  end
end
