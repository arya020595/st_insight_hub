# frozen_string_literal: true

# Gracefully handle SolidQueue enqueue failures for non-critical Active Storage jobs.
#
# When Active Storage attaches a file, it enqueues AnalyzeJob, PurgeJob, and MirrorJob
# as after_commit callbacks. If the SolidQueue database tables don't exist or are unreachable,
# the enqueue raises SolidQueue::Job::EnqueueError, which propagates up and crashes the
# entire HTTP request — even though the file was already uploaded successfully.
#
# This initializer wraps the enqueue step for these jobs so failures are logged as warnings
# instead of raising. The file still gets saved; analysis/purge just won't run until the
# queue is available (or next time the blob is accessed and analyzed lazily).
#
# Affected jobs:
#   - ActiveStorage::AnalyzeJob  (extracts metadata like dimensions after upload)
#   - ActiveStorage::PurgeJob    (cleans up replaced/orphaned attachments)
#   - ActiveStorage::MirrorJob   (syncs files across mirror storage services)

Rails.application.config.after_initialize do
  active_storage_jobs = [
    ActiveStorage::AnalyzeJob,
    ActiveStorage::PurgeJob,
    ActiveStorage::MirrorJob
  ]

  active_storage_jobs.each do |job_class|
    next unless job_class.respond_to?(:around_enqueue)

    job_class.around_enqueue do |job, block|
      block.call
    rescue StandardError => e
      if e.class.name.start_with?("SolidQueue") || e.is_a?(ActiveRecord::StatementInvalid)
        Rails.logger.warn(
          "[SolidQueue] Failed to enqueue #{job.class.name}: #{e.message}. " \
          "Ensure the queue database is set up: bin/rails db:prepare"
        )
      else
        raise
      end
    end
  end
end
