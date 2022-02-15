module CscCore
  class Scorecard < ApplicationRecord
    self.table_name = "scorecards"

    include Scorecards::Lockable
    include Scorecards::Location
    include Scorecards::Filter
    include Scorecards::CallbackNotification
    include Scorecards::Elasticsearch

    acts_as_paranoid

    enum scorecard_type: {
      self_assessment: 1,
      community_scorecard: 2
    }

    # Todo:
    enum progress: ScorecardProgress.statuses

    SCORECARD_TYPES = scorecard_types.keys.map { |key| [I18n.t("scorecard.#{key}"), key] }

    belongs_to :unit_type, class_name: "Facility"
    belongs_to :facility
    belongs_to :local_ngo, optional: true
    belongs_to :program
    belongs_to :location, foreign_key: :location_code, optional: true
    belongs_to :creator, class_name: "User"
    belongs_to :primary_school, foreign_key: :primary_school_code, optional: true

    has_many   :facilitators, foreign_key: :scorecard_uuid
    has_many   :cafs, through: :facilitators
    has_many   :participants, foreign_key: :scorecard_uuid
    has_many   :custom_indicators, foreign_key: :scorecard_uuid
    has_many   :raised_indicators, foreign_key: :scorecard_uuid
    has_many   :voting_indicators, foreign_key: :scorecard_uuid
    has_many   :ratings, foreign_key: :scorecard_uuid
    has_many   :scorecard_progresses, foreign_key: :scorecard_uuid, primary_key: :uuid
    has_many   :suggested_actions, foreign_key: :scorecard_uuid, primary_key: :uuid
    has_many   :scorecard_references, foreign_key: :scorecard_uuid, primary_key: :uuid
    # has_many   :request_changes, foreign_key: :scorecard_uuid, primary_key: :uuid

    # has_many   :indicator_activities, foreign_key: :scorecard_uuid, primary_key: :uuid
    # has_many   :strength_indicator_activities, foreign_key: :scorecard_uuid, primary_key: :uuid
    # has_many   :weakness_indicator_activities, foreign_key: :scorecard_uuid, primary_key: :uuid
    # has_many   :suggested_indicator_activities, foreign_key: :scorecard_uuid, primary_key: :uuid

    delegate  :name, to: :local_ngo, prefix: :local_ngo, allow_nil: true
    delegate  :name_en, :name_km, to: :primary_school, prefix: :primary_school, allow_nil: true
    delegate  :name, to: :facility, prefix: :facility
    delegate  :name, to: :primary_school, prefix: :primary_school, allow_nil: true

    validates :year, presence: true
    validates :province_id, presence: true
    validates :district_id, presence: true
    validates :commune_id, presence: true
    validates :unit_type_id, presence: true
    validates :facility_id, presence: true
    validates :scorecard_type, presence: true
    validates :local_ngo_id, presence: true
    validates :primary_school_code, presence: true, if: -> { facility.try(:dataset).present? }

    validates :planned_start_date, presence: true
    validates :planned_end_date, presence: true
    validates :planned_end_date, presence: true, date: { after_or_equal_to: :planned_start_date }

    before_create :secure_uuid
    before_create :set_name
    before_create :set_published
    before_save   :clear_primary_school_code, unless: -> { facility.try(:dataset).present? }

    # after_commit  :index_document_async, on: [:create, :update], if: -> { ENV["ELASTICSEARCH_ENABLED"] == "true" }
    # after_destroy :delete_document_async, if: -> { ENV["ELASTICSEARCH_ENABLED"] == "true" }

    accepts_nested_attributes_for :facilitators, allow_destroy: true
    accepts_nested_attributes_for :participants, allow_destroy: true
    accepts_nested_attributes_for :raised_indicators, allow_destroy: true
    accepts_nested_attributes_for :voting_indicators, allow_destroy: true
    accepts_nested_attributes_for :ratings, allow_destroy: true

    scope :completeds, -> { where.not(locked_at: nil) }

    def status
      progress.present? ? progress : "planned"
    end

    def completed?
      access_locked?
    end

    def renewed?
      progress == "renewed"
    end

    # Class method
    def self.t_scorecard_types
      self.scorecard_types.keys.map { |key| [I18n.t("scorecard.#{key}"), key] }
    end

    private
      def secure_uuid
        self.uuid ||= six_digit_rand

        return unless self.class.exists?(uuid: uuid)

        self.uuid = six_digit_rand
        secure_uuid
      end

      def six_digit_rand
        SecureRandom.random_number(1..999999).to_s.rjust(6, "0")
      end

      def set_name
        self.name = "#{location_code}-#{year}"
      end

      def set_published
        self.published = program.data_publication.present? && !program.data_publication.stop_publish_data?
      end

      def clear_primary_school_code
        self.primary_school_code = nil
      end
  end
end