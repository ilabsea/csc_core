# == Schema Information
#
# Table name: languages
#
#  id         :bigint           not null, primary key
#  code       :string
#  name_en    :string
#  name_km    :string
#  program_id :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
module CscCore
  class Language < ApplicationRecord
    self.table_name = "languages"

    belongs_to :program
    has_many :languages_indicators
    has_many :indicators, through: :languages_indicators

    validates :code, presence: true
    validates :name_en, presence: true
    validates :name_km, presence: true

    def name
      self["name_#{I18n.locale}"]
    end
  end
end
