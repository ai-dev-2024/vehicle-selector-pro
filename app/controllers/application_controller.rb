class ApplicationController < ActionController::Base
  include SecurityHeaders

  protect_from_forgery with: :exception, unless: -> { request.format.json? }
end
