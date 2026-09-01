class ApplicationController < ActionController::Base
  include SecurityHeaders

  protect_from_forgery with: :exception, unless: -> { request.format.json? }

  # Server-side system status for the admin status banner. Mirrors the cheap
  # part of /health/deep (database reachability); the cache check is skipped
  # here so the banner never adds latency to every admin page render.
  def systems_healthy?
    ActiveRecord::Base.connection.select_value("SELECT 1").present?
  rescue StandardError
    false
  end
  helper_method :systems_healthy?
end
