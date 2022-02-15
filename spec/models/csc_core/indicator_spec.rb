require 'rails_helper'

module CscCore
  RSpec.describe Indicator, type: :model do
    it { is_expected.to belong_to(:categorizable).touch(true) }
    it { is_expected.to have_many(:languages_indicators).dependent(:destroy) }
    it { is_expected.to have_many(:languages).through(:languages_indicators) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to([:categorizable_id, :categorizable_type]) }

    it "should touch the categorizable" do
      indicator = build(:indicator)
      expect(indicator.categorizable).to receive(:touch)
      indicator.save!
    end
  end
end