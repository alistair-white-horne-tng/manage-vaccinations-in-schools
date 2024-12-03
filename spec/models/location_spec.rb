# frozen_string_literal: true

# == Schema Information
#
# Table name: locations
#
#  id                        :bigint           not null, primary key
#  address_line_1            :text
#  address_line_2            :text
#  address_postcode          :text
#  address_town              :text
#  gias_establishment_number :integer
#  gias_local_authority_code :integer
#  name                      :text             not null
#  ods_code                  :string
#  type                      :integer          not null
#  url                       :text
#  urn                       :string
#  year_groups               :integer          default([]), not null, is an Array
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  team_id                   :bigint
#
# Indexes
#
#  index_locations_on_ods_code  (ods_code) UNIQUE
#  index_locations_on_team_id   (team_id)
#  index_locations_on_urn       (urn) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#

describe Location do
  describe "scopes" do
    describe "#for_year_groups" do
      subject(:scope) { described_class.for_year_groups(year_groups) }

      let(:year_groups) { [8, 9, 10, 11] }

      let(:matching) { create(:school, :secondary) } # 7-11
      let(:mismatch) { create(:school, :primary) } # 0-6

      it { should include(matching) }
      it { should_not include(mismatch) }
    end
  end

  describe "validations" do
    it { should validate_presence_of(:name) }

    context "with a community clinic" do
      subject(:location) { build(:community_clinic, ods_code: "abc") }

      it { should validate_presence_of(:ods_code) }
      it { should validate_uniqueness_of(:ods_code).ignoring_case_sensitivity }

      it { should_not validate_presence_of(:urn) }
      it { should validate_uniqueness_of(:urn) }
    end

    context "with a generic clinic" do
      subject(:location) { build(:generic_clinic, organisation:) }

      let(:organisation) { create(:organisation) }

      it { should validate_presence_of(:ods_code) }
      it { should validate_uniqueness_of(:ods_code).ignoring_case_sensitivity }

      it do
        expect(location).to validate_comparison_of(:ods_code).is_equal_to(
          organisation.ods_code
        )
      end

      it { should_not validate_presence_of(:urn) }
      it { should validate_uniqueness_of(:urn) }
    end

    context "with a school" do
      subject(:location) { build(:school, urn: "abc") }

      it { should_not validate_presence_of(:ods_code) }
      it { should validate_uniqueness_of(:ods_code).ignoring_case_sensitivity }

      it { should validate_presence_of(:urn) }
      it { should validate_uniqueness_of(:urn) }
    end
  end

  it { should normalize(:address_postcode).from(" SW111AA ").to("SW11 1AA") }
  it { should normalize(:ods_code).from(" r1a ").to("R1A") }
  it { should normalize(:urn).from(" 123 ").to("123") }

  describe "#clinic?" do
    subject(:clinic?) { location.clinic? }

    context "with a community clinic" do
      let(:location) { build(:community_clinic) }

      it { should be(true) }
    end

    context "with a generic clinic" do
      let(:location) do
        build(:generic_clinic, organisation: create(:organisation))
      end

      it { should be(true) }
    end

    context "with a school" do
      let(:location) { build(:school) }

      it { should be(false) }
    end
  end
end
