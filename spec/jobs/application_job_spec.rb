require "rails_helper"

RSpec.describe ApplicationJob, type: :job do
  before do
    probe = Class.new(described_class) do
      def perform(kind)
        raise ArgumentError, "boom" unless kind == "gone"

        # DeserializationError wraps the error that is being handled.
        begin
          raise ActiveRecord::RecordNotFound, "gone"
        rescue ActiveRecord::RecordNotFound
          raise ActiveJob::DeserializationError
        end
      end
    end
    stub_const("RetryProbeJob", probe)
  end

  # `wait:` must be an algorithm ActiveJob knows. An unknown one raises
  # "Couldn't determine a delay" from inside the handler, hiding the real error.
  it "re-enqueues a failed job with a backoff" do
    expect { RetryProbeJob.perform_now("boom") }.to have_enqueued_job(RetryProbeJob).with("boom")
  end

  it "discards a job whose record no longer exists instead of retrying it" do
    expect { RetryProbeJob.perform_now("gone") }.not_to have_enqueued_job(RetryProbeJob)
  end
end
