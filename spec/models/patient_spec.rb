# frozen_string_literal: true

# == Schema Information
#
# Table name: patients
#
#  id               :bigint           not null, primary key
#  address_line_1   :string
#  address_line_2   :string
#  address_postcode :string
#  address_town     :string
#  common_name      :string
#  date_of_birth    :date             not null
#  first_name       :string           not null
#  gender_code      :integer          default("not_known"), not null
#  home_educated    :boolean
#  last_name        :string           not null
#  nhs_number       :string
#  pending_changes  :jsonb            not null
#  recorded_at      :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  cohort_id        :bigint
#  school_id        :bigint
#
# Indexes
#
#  index_patients_on_cohort_id   (cohort_id)
#  index_patients_on_nhs_number  (nhs_number) UNIQUE
#  index_patients_on_school_id   (school_id)
#
# Foreign Keys
#
#  fk_rails_...  (cohort_id => cohorts.id)
#  fk_rails_...  (school_id => locations.id)
#

describe Patient do
  describe "validations" do
    context "when home educated" do
      subject(:patient) { build(:patient, :home_educated) }

      it { should validate_absence_of(:school) }
    end

    context "with an invalid school" do
      subject(:patient) { build(:patient, school: create(:location, :clinic)) }

      it "is invalid" do
        expect(patient.valid?).to be(false)
        expect(patient.errors[:school]).to include(
          "must be a school location type"
        )
      end
    end
  end

  it { should normalize(:nhs_number).from(" 0123456789 ").to("0123456789") }
  it { should normalize(:address_postcode).from(" SW111AA ").to("SW11 1AA") }

  describe "#match_existing" do
    subject(:match_existing) do
      described_class.match_existing(
        nhs_number:,
        first_name:,
        last_name:,
        date_of_birth:,
        address_postcode:
      )
    end

    let(:nhs_number) { "0123456789" }
    let(:first_name) { "John" }
    let(:last_name) { "Smith" }
    let(:date_of_birth) { Date.new(1999, 1, 1) }
    let(:address_postcode) { "SW1A 1AA" }

    context "with no matches" do
      let(:patient) { create(:patient) }

      it { should_not include(patient) }
    end

    context "with a matching NHS number" do
      let!(:patient) { create(:patient, nhs_number:) }

      it { should include(patient) }

      context "when other patients match too" do
        let(:other_patient) do
          create(
            :patient,
            nhs_number: nil,
            first_name:,
            last_name:,
            date_of_birth:
          )
        end

        it { should_not include(other_patient) }
      end
    end

    context "with matching first name, last name and date of birth" do
      let(:nhs_number) { nil }
      let(:patient) do
        create(:patient, first_name:, last_name:, date_of_birth:)
      end

      it { should include(patient) }
    end

    context "with matching first name, last name and postcode" do
      let(:nhs_number) { nil }
      let(:patient) do
        create(:patient, first_name:, last_name:, address_postcode:)
      end

      it { should include(patient) }
    end

    context "with matching first name, date of birth and postcode" do
      let(:nhs_number) { nil }
      let(:patient) do
        create(:patient, first_name:, date_of_birth:, address_postcode:)
      end

      it { should include(patient) }
    end

    context "with matching last name, date of birth and postcode" do
      let(:nhs_number) { nil }
      let(:patient) do
        create(:patient, last_name:, date_of_birth:, address_postcode:)
      end

      it { should include(patient) }
    end

    context "when matching everything except the NHS number" do
      let(:other_patient) do
        create(
          :patient,
          nhs_number: "9876543210",
          first_name:,
          last_name:,
          date_of_birth:,
          address_postcode:
        )
      end

      it { should_not include(other_patient) }
    end
  end

  describe "#stage_changes" do
    let(:patient) { create(:patient, first_name: "John", last_name: "Doe") }

    it "stages new changes in pending_changes" do
      patient.stage_changes(first_name: "Jane", address_line_1: "123 New St")

      expect(patient.pending_changes).to eq(
        { "first_name" => "Jane", "address_line_1" => "123 New St" }
      )
    end

    it "does not stage unchanged attributes" do
      patient.stage_changes(first_name: "John", last_name: "Smith")

      expect(patient.pending_changes).to eq({ "last_name" => "Smith" })
    end

    it "does not stage blank values" do
      patient.stage_changes(
        first_name: "",
        last_name: nil,
        address_line_1: "123 New St"
      )

      expect(patient.pending_changes).to eq(
        { "address_line_1" => "123 New St" }
      )
    end

    it "updates the pending_changes attribute" do
      expect { patient.stage_changes(first_name: "Jane") }.to change {
        patient.reload.pending_changes
      }.from({}).to({ "first_name" => "Jane" })
    end

    it "does not update other attributes directly" do
      patient.stage_changes(first_name: "Jane", last_name: "Smith")

      expect(patient.first_name).to eq("John")
      expect(patient.last_name).to eq("Doe")
    end

    it "does not save any changes if no valid changes are provided" do
      expect { patient.stage_changes(first_name: "John") }.not_to(
        change { patient.reload.pending_changes }
      )
    end
  end

  describe "#with_pending_changes" do
    let(:patient) { create(:patient) }

    it "returns the patient with pending changes applied" do
      patient.stage_changes(first_name: "Jane")
      expect(patient.first_name_changed?).to be(false)

      changed_patient = patient.with_pending_changes
      expect(changed_patient.first_name_changed?).to be(true)
      expect(changed_patient.last_name_changed?).to be(false)
      expect(changed_patient.first_name).to eq("Jane")
    end
  end

  describe "#destroy_childless_parents" do
    let(:patient) { create(:patient, parents: []) }
    let(:parent) { create(:parent) }

    context "when parent has only one child" do
      before { create(:parent_relationship, parent:, patient:) }

      it "destroys the parent when the patient is destroyed" do
        expect { patient.destroy }.to change(Parent, :count).by(-1)
      end
    end

    context "when parent has multiple children" do
      let(:sibling) { create(:patient) }

      before do
        create(:parent_relationship, parent:, patient:)
        create(:parent_relationship, parent:, patient: sibling)
      end

      it "does not destroy the parent when one patient is destroyed" do
        expect { patient.destroy }.not_to change(Parent, :count)
      end
    end

    context "when patient has multiple parents" do
      let(:other_parent) { create(:parent) }

      before do
        create(:parent_relationship, parent:, patient:)
        create(:parent_relationship, parent: other_parent, patient:)
      end

      it "destroys only the childless parents" do
        expect { patient.destroy }.to change(Parent, :count).by(-2)
      end
    end
  end
end
