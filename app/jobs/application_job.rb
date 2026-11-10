class ApplicationJob < ActiveJob::Base
  # Handlers are matched last-declared-first, so the catch-all has to come
  # first or it shadows the specific handlers below it.
  #
  # Cap retries so a permanently failing job doesn't retry forever. Once the
  # attempts are used up the error is re-raised and Sidekiq moves the job to
  # the deadset (retry: false would silently drop it, losing the payload).
  retry_on StandardError, wait: :polynomially_longer, jitter: 0.15, attempts: 5

  # Automatically retry jobs that encountered a deadlock
  retry_on ActiveRecord::Deadlocked

  # The record the job was enqueued for no longer exists; a retry cannot succeed.
  discard_on ActiveJob::DeserializationError
end
