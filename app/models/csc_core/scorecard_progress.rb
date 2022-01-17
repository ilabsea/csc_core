module CscCore
  class ScorecardProgress < ApplicationRecord
    self.table_name = "scorecard_progresses"

    belongs_to :scorecard, primary_key: "uuid", foreign_key: "scorecard_uuid"
    belongs_to :user

    enum status: {
      downloaded: 1,
      running: 2,
      submitted: 3,
      renewed: 4
    }

    after_save :set_scorecard_progress
    after_save :update_counter_cache, if: :downloaded?
    after_destroy :update_counter_cache, if: :downloaded?

    scope :downloadeds, -> { where(status: :downloaded) }

    private
      def update_counter_cache
        scorecard.update_column(:downloaded_count, scorecard.scorecard_progresses.downloadeds.count)
      end

      def set_scorecard_progress
        return if !scorecard.renewed? && self.class.statuses[scorecard.progress].to_i >= self.class.statuses[status].to_i

        scorecard.progress = status
        scorecard.save(validate: false)
      end
  end
end
