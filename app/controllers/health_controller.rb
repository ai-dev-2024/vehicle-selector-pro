# Deep health endpoint. /up (Fly's liveness check) only proves the process is
# up; /health/deep also verifies the database and cache are reachable so
# external uptime monitors catch degraded states (e.g. Postgres restarting)
# before merchants do.
class HealthController < ApplicationController
  skip_before_action :verify_authenticity_token

  def deep
    checks = { database: database_ok?, cache: cache_ok? }
    status = checks.values.all? ? :ok : :service_unavailable
    render json: { status: status == :ok ? "ok" : "degraded", checks: checks, time: Time.current.iso8601 },
           status: status
  end

  private

  def database_ok?
    ActiveRecord::Base.connection.execute("SELECT 1")
    true
  rescue StandardError
    false
  end

  def cache_ok?
    Rails.cache.write("vsp/health", Time.current.to_i, expires_in: 10.seconds)
    Rails.cache.read("vsp/health").present?
  rescue StandardError
    false
  end
end
