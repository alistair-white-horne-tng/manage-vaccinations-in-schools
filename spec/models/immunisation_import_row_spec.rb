# frozen_string_literal: true

require "rails_helper"

describe ImmunisationImportRow, type: :model do
  subject(:immunisation_import_row) do
    described_class.new(
      data:,
      campaign:,
      user:,
      imported_from: immunisation_import
    )
  end

  let(:campaign) { create(:campaign, :flu, academic_year: 2023) }
  let(:team) { create(:team, ods_code: "abc") }
  let(:user) { create(:user, teams: [team]) }
  let(:immunisation_import) { create(:immunisation_import, campaign:, user:) }

  let(:nhs_number) { "1234567890" }
  let(:first_name) { "Harry" }
  let(:last_name) { "Potter" }
  let(:date_of_birth) { "20120101" }
  let(:address_postcode) { "SW1A 1AA" }
  let(:valid_data) do
    {
      "ORGANISATION_CODE" => "abc",
      "VACCINATED" => "Yes",
      "ANATOMICAL_SITE" => "nasal",
      "BATCH_EXPIRY_DATE" => "20210101",
      "BATCH_NUMBER" => "123",
      "SCHOOL_NAME" => "Hogwarts",
      "SCHOOL_URN" => "123456",
      "PERSON_FORENAME" => first_name,
      "PERSON_SURNAME" => last_name,
      "PERSON_DOB" => date_of_birth,
      "PERSON_POSTCODE" => address_postcode,
      "PERSON_GENDER_CODE" => "Male",
      "NHS_NUMBER" => nhs_number,
      "DATE_OF_VACCINATION" => "20240101",
      "VACCINE_GIVEN" => "AstraZeneca Fluenz Tetra LAIV"
    }
  end

  before { create(:location, :school, urn: "123456") }

  describe "validations" do
    context "with an empty row" do
      let(:data) { {} }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:administered]).to include(
          "is not included in the list"
        )
        expect(immunisation_import_row.errors[:organisation_code]).to include(
          "can't be blank"
        )
      end
    end

    context "when missing fields" do
      let(:data) { { "VACCINATED" => "Yes" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:batch_expiry_date]).to eq(
          ["can't be blank"]
        )
        expect(immunisation_import_row.errors[:batch_number]).to eq(
          ["can't be blank"]
        )
        expect(immunisation_import_row.errors[:delivery_site]).to eq(
          ["can't be blank"]
        )
        expect(immunisation_import_row.errors[:delivery_method]).to eq(
          ["can't be blank"]
        )
        expect(immunisation_import_row.errors[:organisation_code]).to eq(
          ["can't be blank"]
        )
        expect(immunisation_import_row.errors[:patient_gender_code]).to eq(
          ["is not included in the list"]
        )
        expect(immunisation_import_row.errors[:patient_postcode]).to eq(
          ["Enter a valid postcode, such as SW1A 1AA"]
        )
      end
    end

    context "with an invalid organisation code" do
      let(:data) { { "ORGANISATION_CODE" => "this is too long" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:organisation_code]).to eq(
          ["must be equal to abc"]
        )
      end
    end

    context "with an invalid vaccine" do
      let(:data) { { "VACCINATED" => "Yes", "VACCINE_GIVEN" => "test" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:vaccine_given]).to eq(
          [
            "The test vaccine is unknown or not administered as part of this programme."
          ]
        )
      end
    end

    context "with an invalid postcode" do
      let(:data) { { "PERSON_POSTCODE" => "ABC DEF" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:patient_postcode]).to include(
          "Enter a valid postcode, such as SW1A 1AA"
        )
      end
    end

    context "with an invalid gender code" do
      let(:data) { { "PERSON_GENDER_CODE" => "10" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:patient_postcode]).to eq(
          ["Enter a valid postcode, such as SW1A 1AA"]
        )
      end
    end

    context "with an invalid session date" do
      let(:data) { { "DATE_OF_VACCINATION" => "21000101" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
      end
    end

    context "with an invalid NHS number" do
      let(:data) { { "NHS_NUMBER" => "abc" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:patient_nhs_number]).to eq(
          ["is the wrong length (should be 10 characters)"]
        )
      end
    end

    context "with an invalid patient date of birth" do
      let(:data) { { "PERSON_DOB" => "21000101" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
      end
    end

    context "with more than two matching patients" do
      let(:data) do
        {
          "PERSON_FORENAME" => "John",
          "PERSON_SURNAME" => "Smith",
          "PERSON_DOB" => "19900101"
        }
      end

      before do
        create_list(
          :patient,
          2,
          first_name: "John",
          last_name: "Smith",
          date_of_birth: Date.new(1990, 1, 1)
        )
      end

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:patient]).to eq(
          [
            "Two or more possible patients match the patient first name, last name, date of birth or postcode."
          ]
        )
      end
    end

    context "with an invalid dose sequence" do
      let(:campaign) { create(:campaign, :hpv) }

      let(:data) { { "VACCINE_GIVEN" => "Gardasil9", "DOSE_SEQUENCE" => "4" } }

      it "has errors" do
        expect(immunisation_import_row).to be_invalid
        expect(immunisation_import_row.errors[:dose_sequence]).to include(
          /must be less than/
        )
      end
    end

    context "with valid fields for Flu" do
      let(:campaign) { create(:campaign, :flu, academic_year: 2023) }

      let(:data) do
        {
          "ORGANISATION_CODE" => "abc",
          "VACCINATED" => "Yes",
          "BATCH_EXPIRY_DATE" => "20210101",
          "BATCH_NUMBER" => "123",
          "ANATOMICAL_SITE" => "nasal",
          "SCHOOL_NAME" => "Hogwarts",
          "SCHOOL_URN" => "123456",
          "PERSON_FORENAME" => "Harry",
          "PERSON_SURNAME" => "Potter",
          "PERSON_DOB" => "20120101",
          "PERSON_POSTCODE" => "SW1A 1AA",
          "PERSON_GENDER_CODE" => "Male",
          "DATE_OF_VACCINATION" => "20240101",
          "VACCINE_GIVEN" => "AstraZeneca Fluenz Tetra LAIV"
        }
      end

      it { should be_valid }
    end
  end

  describe "#patient" do
    subject(:patient) { immunisation_import_row.patient }

    context "without patient data" do
      let(:data) { {} }

      it { should be_nil }
    end

    context "with new patient data" do
      let(:data) { valid_data }

      it { should_not be_nil }
    end

    context "with an existing patient matching NHS number" do
      let(:data) { valid_data }

      let(:patient) { create(:patient, nhs_number:) }

      it { should eq(patient) }
    end

    context "with an existing patient matching first name, last name and date of birth" do
      let(:data) { valid_data }

      let(:patient) do
        create(:patient, first_name:, last_name:, date_of_birth:)
      end

      it { should eq(patient) }
    end

    context "with an existing patient matching first name, last name and postcode" do
      let(:data) { valid_data }

      let(:patient) do
        create(:patient, first_name:, last_name:, address_postcode:)
      end

      it { should eq(patient) }
    end

    context "with an existing patient matching first name, date of birth and postcode" do
      let(:data) { valid_data }

      let(:patient) do
        create(:patient, first_name:, date_of_birth:, address_postcode:)
      end

      it { should eq(patient) }
    end

    context "with an existing patient matching last name, date of birth and postcode" do
      let(:data) { valid_data }

      let(:patient) do
        create(:patient, last_name:, date_of_birth:, address_postcode:)
      end

      it { should eq(patient) }
    end

    context "with a school" do
      let(:data) { valid_data }

      it "creates a patient with a school" do
        expect(patient.home_educated).to be(false)
        expect(patient.school).not_to be_nil
      end
    end

    context "when home educated" do
      let(:data) { valid_data.merge("SCHOOL_URN" => "999999") }

      it "creates a home educated patient" do
        expect(patient.home_educated).to be(true)
        expect(patient.school).to be_nil
      end
    end

    context "with an unknown school" do
      let(:data) { valid_data.merge("SCHOOL_URN" => "888888") }

      it "creates a patient with an unknown school" do
        expect(patient.home_educated).to be(false)
        expect(patient.school).to be_nil
      end
    end
  end

  describe "#session" do
    subject(:session) { immunisation_import_row.session }

    context "without data" do
      let(:data) { {} }

      it { should be_nil }
    end

    context "with a school" do
      let(:data) { valid_data }

      it "sets the location to the patient's school" do
        expect(session.location).to be_school
      end
    end

    context "when home educated and community care setting" do
      let(:data) do
        valid_data.merge("SCHOOL_URN" => "999999", "CARE_SETTING" => "2")
      end

      it "sets the location to a generic clinic" do
        expect(session.location).to be_generic_clinic
        expect(session.location.ods_code).to eq(team.ods_code)
      end
    end

    context "when home educated and unknown care setting" do
      let(:data) { valid_data.merge("SCHOOL_URN" => "999999") }

      it "sets the location to a generic clinic" do
        expect(session.location).to be_generic_clinic
        expect(session.location.ods_code).to eq(team.ods_code)
      end
    end

    context "with an unknown school and school care setting" do
      let(:data) do
        valid_data.merge(
          "SCHOOL_URN" => "888888",
          "SCHOOL_NAME" => "Waterloo Road",
          "CARE_SETTING" => "1"
        )
      end

      it "doesn't set a location" do
        expect(session.location).to be_nil
      end
    end

    context "with an unknown school and community care setting" do
      let(:data) do
        valid_data.merge(
          "SCHOOL_URN" => "888888",
          "SCHOOL_NAME" => "Waterloo Road",
          "CARE_SETTING" => "2"
        )
      end

      it "sets the location to a generic clinic" do
        expect(session.location).to be_generic_clinic
        expect(session.location.ods_code).to eq(team.ods_code)
      end
    end

    context "with an unknown school and unknown case setting" do
      let(:data) do
        valid_data.merge(
          "SCHOOL_URN" => "888888",
          "SCHOOL_NAME" => "Waterloo Road"
        )
      end

      it "doesn't set a location" do
        expect(session.location).to be_nil
      end
    end
  end

  describe "#notes" do
    subject(:notes) { immunisation_import_row.notes }

    context "without data" do
      let(:data) { {} }

      it { should be_nil }
    end

    context "with a school" do
      let(:data) { valid_data }

      it { should be_nil }
    end

    context "when home educated and community care setting" do
      let(:data) do
        valid_data.merge("SCHOOL_URN" => "999999", "CARE_SETTING" => "2")
      end

      it { should be_nil }
    end

    context "when home educated and unknown care setting" do
      let(:data) { valid_data.merge("SCHOOL_URN" => "999999") }

      it { should be_nil }
    end

    context "with an unknown school and school care setting" do
      let(:data) do
        valid_data.merge(
          "SCHOOL_URN" => "888888",
          "SCHOOL_NAME" => "Waterloo Road",
          "CARE_SETTING" => "1"
        )
      end

      it { should eq("Vaccinated at Waterloo Road") }
    end

    context "with an unknown school and community care setting" do
      let(:data) do
        valid_data.merge(
          "SCHOOL_URN" => "888888",
          "SCHOOL_NAME" => "Waterloo Road",
          "CARE_SETTING" => "2"
        )
      end

      it { should be_nil }
    end

    context "with an unknown school and unknown case setting" do
      let(:data) do
        valid_data.merge(
          "SCHOOL_URN" => "888888",
          "SCHOOL_NAME" => "Waterloo Road"
        )
      end

      it { should eq("Vaccinated at Waterloo Road") }
    end
  end

  describe "#administered" do
    subject(:administered) { immunisation_import_row.administered }

    context "without a vaccinated field" do
      let(:data) { {} }

      it { should be_nil }
    end

    context "with positive vaccinated field" do
      let(:data) { { "VACCINATED" => "Yes" } }

      it { should be(true) }
    end

    context "with negative vaccinated field" do
      let(:data) { { "VACCINATED" => "No" } }

      it { should be(false) }
    end

    context "with an unknown vaccinated field" do
      let(:data) { { "VACCINATED" => "Other" } }

      it { should be_nil }
    end

    context "with a vaccine given field" do
      let(:data) { { "VACCINE_GIVEN" => "Vaccine" } }

      it { should be(true) }
    end
  end

  describe "#batch_expiry_date" do
    subject(:batch_expiry_date) { immunisation_import_row.batch_expiry_date }

    context "without a value" do
      let(:data) { {} }

      it { should be_nil }
    end

    context "with an invalid value" do
      let(:data) { { "BATCH_EXPIRY_DATE" => "abc" } }

      it { should be_nil }
    end

    context "with a valid value" do
      let(:data) { { "BATCH_EXPIRY_DATE" => "20100101" } }

      it { should eq(Date.new(2010, 1, 1)) }
    end
  end

  describe "#batch_number" do
    subject(:batch_number) { immunisation_import_row.batch_number }

    context "without a value" do
      let(:data) { {} }

      it { should be_nil }
    end

    context "with a value" do
      let(:data) { { "BATCH_NUMBER" => "abc" } }

      it { should eq("abc") }
    end
  end

  describe "#reason" do
    subject(:reason) { immunisation_import_row.reason }

    context "without a reason" do
      let(:data) { { "VACCINATED" => "No" } }

      it { expect(immunisation_import_row).to be_invalid }
    end

    context "without an unknown reason" do
      let(:data) do
        { "VACCINATED" => "No", "REASON_NOT_VACCINATED" => "Unknown" }
      end

      it { expect(immunisation_import_row).to be_invalid }
    end

    context "with a reason" do
      let(:data) do
        { "VACCINATED" => "No", "REASON_NOT_VACCINATED" => "Did Not Attend" }
      end

      it { should eq(:absent_from_session) }
    end
  end

  describe "#delivery_method" do
    subject(:delivery_method) { immunisation_import_row.delivery_method }

    context "without an anatomical site" do
      let(:data) { {} }

      it { should be_nil }
    end

    context "with a nasal anatomical site" do
      let(:data) { { "ANATOMICAL_SITE" => "nasal" } }

      it { should eq(:nasal_spray) }
    end

    context "with a non-nasal anatomical site" do
      let(:data) { { "ANATOMICAL_SITE" => "left thigh" } }

      it { should eq(:intramuscular) }
    end

    context "with an unknown anatomical site" do
      let(:data) { { "ANATOMICAL_SITE" => "other" } }

      it { should be_nil }
    end
  end

  describe "#delivery_site" do
    subject(:delivery_site) { immunisation_import_row.delivery_site }

    context "without an anatomical site" do
      let(:data) { {} }

      it { should be_nil }
    end

    context "with a left thigh anatomical site" do
      let(:data) { { "ANATOMICAL_SITE" => "left thigh" } }

      it { should eq(:left_thigh) }
    end

    context "with a right thigh anatomical site" do
      let(:data) { { "ANATOMICAL_SITE" => "right thigh" } }

      it { should eq(:right_thigh) }
    end

    context "with a left upper arm anatomical site" do
      let(:data) { { "ANATOMICAL_SITE" => "left upper arm" } }

      it { should eq(:left_arm_upper_position) }
    end

    context "with a right upper arm anatomical site" do
      let(:data) { { "ANATOMICAL_SITE" => "right upper arm" } }

      it { should eq(:right_arm_upper_position) }
    end

    context "with a left buttock anatomical site" do
      let(:data) { { "ANATOMICAL_SITE" => "left buttock" } }

      it { should eq(:left_buttock) }
    end

    context "with a right buttock anatomical site" do
      let(:data) { { "ANATOMICAL_SITE" => "right buttock" } }

      it { should eq(:right_buttock) }
    end

    context "with a nasal anatomical site" do
      let(:data) { { "ANATOMICAL_SITE" => "nasal" } }

      it { should eq(:nose) }
    end

    context "with an unknown anatomical site" do
      let(:data) { { "ANATOMICAL_SITE" => "other" } }

      it { should be_nil }
    end
  end

  describe "#dose_sequence" do
    subject(:dose_sequence) { immunisation_import_row.dose_sequence }

    let(:campaign) { create(:campaign, :hpv) }

    context "without a value" do
      let(:data) { { "VACCINE_GIVEN" => "Gardasil9" } }

      it { should be_nil }
    end

    context "with an invalid value" do
      let(:data) do
        { "VACCINE_GIVEN" => "Gardasil9", "DOSE_SEQUENCE" => "abc" }
      end

      it { should be_nil }
    end

    context "with a valid value" do
      let(:data) { { "VACCINE_GIVEN" => "Gardasil9", "DOSE_SEQUENCE" => "1" } }

      it { should eq(1) }
    end
  end

  describe "#organisation_code" do
    subject(:organisation_code) { immunisation_import_row.organisation_code }

    context "without a value" do
      let(:data) { {} }

      it { should be_nil }
    end

    context "with a value" do
      let(:data) { { "ORGANISATION_CODE" => "abc" } }

      it { should eq("abc") }
    end
  end

  describe "#patient_date_of_birth" do
    subject(:patient_date_of_birth) do
      immunisation_import_row.patient_date_of_birth
    end

    context "without a value" do
      let(:data) { {} }

      it { should be_nil }
    end

    context "with a value" do
      let(:data) { { "PERSON_DOB" => "abc" } }

      it { should be_nil }
    end

    context "with a valid value" do
      let(:data) { { "PERSON_DOB" => "19900101" } }

      it { should eq(Date.new(1990, 1, 1)) }
    end
  end

  describe "#patient_gender_code" do
    subject(:patient_gender_code) do
      immunisation_import_row.patient_gender_code
    end

    context "without a value" do
      let(:data) { {} }

      it { should be_nil }
    end

    shared_examples "with a value" do |key|
      context "with an unknown value" do
        let(:data) { { key => "unknown" } }

        it { should be_nil }
      end

      context "with a 'not known' value" do
        let(:data) { { key => "Not Known" } }

        it { should eq(0) }
      end

      context "with a 'male' value" do
        let(:data) { { key => "Male" } }

        it { should eq(1) }
      end

      context "with a 'female' value" do
        let(:data) { { key => "Female" } }

        it { should eq(2) }
      end

      context "with a 'not specified' value" do
        let(:data) { { key => "Not Specified" } }

        it { should eq(9) }
      end
    end

    include_examples "with a value", "PERSON_GENDER_CODE"
    include_examples "with a value", "PERSON_GENDER"
  end

  describe "#patient_postcode" do
    subject(:patient_postcode) { immunisation_import_row.patient_postcode }

    context "without a value" do
      let(:data) { {} }

      it { should be_nil }
    end

    context "with an invalid postcode" do
      let(:data) { { "PERSON_POSTCODE" => "abc" } }

      it { should eq("abc") }
    end

    context "with a valid postcode" do
      let(:data) { { "PERSON_POSTCODE" => "SW1 1AA" } }

      it { should eq("SW1 1AA") }
    end

    context "with a valid unformatted postcode" do
      let(:data) { { "PERSON_POSTCODE" => "sw11aa" } }

      it { should eq("SW1 1AA") }
    end
  end

  describe "#recorded_at" do
    subject(:recorded_at) { immunisation_import_row.recorded_at }

    let(:data) { {} }

    it { should_not be_nil }
  end

  describe "#care_setting" do
    subject(:care_setting) { immunisation_import_row.care_setting }

    context "without a value" do
      let(:data) { {} }

      it { should be_nil }
    end

    context "with a valid value" do
      let(:data) { { "CARE_SETTING" => "1" } }

      it { should eq(1) }
    end

    context "with an invalid value" do
      let(:data) { { "CARE_SETTING" => "School" } }

      it { should be_nil }
    end
  end

  describe "#to_vaccination_record" do
    subject(:vaccination_record) do
      immunisation_import_row.to_vaccination_record
    end

    let(:data) { valid_data }

    it "does not have a vaccinator as that isn't provided in the import" do
      expect(vaccination_record.user).to be_nil
    end

    it "sets the administered at time" do
      expect(vaccination_record.administered_at).to eq(
        Time.new(2024, 1, 1, 12, 0, 0, "+00:00")
      )
    end

    context "with a daylight saving time date" do
      let(:data) { valid_data.merge("DATE_OF_VACCINATION" => "20230901") }

      it "sets the administered at time" do
        expect(vaccination_record.administered_at).to eq(
          Time.new(2023, 9, 1, 12, 0, 0, "+01:00")
        )
      end
    end
  end
end
