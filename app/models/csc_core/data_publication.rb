module CscCore
  class DataPublication < ApplicationRecord
    self.table_name = "data_publications"

    enum published_option: {
      stop_publish_data: 0,
      publish_from_today: 1,
      publish_all: 2
    }

    belongs_to :program

    after_save :create_data_publication_log
    after_save :publish_all_scorecards, if: -> { publish_all? }

    def self.options
      [
        [I18n.t("program.stop_publish_data"), "stop_publish_data"],
        [I18n.t("program.publish_from_today"), "publish_from_today"],
        [I18n.t("program.publish_all"), "publish_all"]
      ]
    end

    private
      def create_data_publication_log
        program.data_publication_logs.create(published_option: published_option)
      end

      def publish_all_scorecards
        program.scorecards.where(published: false).update_all(published: true)
      end
  end
end
