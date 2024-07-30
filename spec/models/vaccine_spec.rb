# frozen_string_literal: true

# == Schema Information
#
# Table name: vaccines
#
#  id                  :bigint           not null, primary key
#  brand               :text             not null
#  dose                :decimal(, )      not null
#  gtin                :text
#  method              :integer          not null
#  snomed_product_code :string           not null
#  snomed_product_term :string           not null
#  supplier            :text             not null
#  type                :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

require "rails_helper"

describe Vaccine, type: :model do
  describe "#contains_gelatine?" do
    it "returns true if the vaccine is a nasal flu vaccine" do
      vaccine = build(:vaccine, :fluenz_tetra)
      expect(vaccine.contains_gelatine?).to be true
    end

    it "returns false if the vaccine is an injected flu vaccine" do
      vaccine = build(:vaccine, :quadrivalent_influenza)
      expect(vaccine.contains_gelatine?).to be false
    end

    it "returns false if the vaccine is not a flu vaccine" do
      vaccine = build(:vaccine, :gardasil_9)
      expect(vaccine.contains_gelatine?).to be false
    end
  end

  describe "#maximum_dose_sequence" do
    subject(:maximum_dose_sequence) { vaccine.maximum_dose_sequence }

    context "with a Flu vaccine" do
      let(:vaccine) { build(:vaccine, :flu) }

      it { should eq(1) }
    end

    context "with an HPV vaccine" do
      let(:vaccine) { build(:vaccine, :hpv) }

      it { should eq(3) }
    end
  end
end
