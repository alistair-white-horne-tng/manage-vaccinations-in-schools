# frozen_string_literal: true

describe Reports::CSVSchoolMoves do
  subject(:csv) { described_class.call(SchoolMoveLogEntry.all) }

  let(:rows) { CSV.parse(csv, headers: true) }

  describe ".call" do
    context "with a standard school move" do
      let(:old_school) { create(:school, :secondary) }
      let(:new_school) { create(:school, :secondary) }

      before do
        patient = create(:patient, school: old_school)
        create(:school_move_log_entry, patient: patient, school: new_school)
      end

      it "returns a CSV with the school moves data" do
        expect(rows.first.to_hash).to include(
          {
            "NHS_REF" => SchoolMoveLogEntry.last.patient.nhs_number,
            "SURNAME" => SchoolMoveLogEntry.last.patient.family_name,
            "FORENAME" => SchoolMoveLogEntry.last.patient.given_name,
            "GENDER" => SchoolMoveLogEntry.last.patient.gender_code.humanize,
            "DOB" =>
              SchoolMoveLogEntry.last.patient.date_of_birth.to_fs(:govuk),
            "ADDRESS1" => SchoolMoveLogEntry.last.patient.address_line_1,
            "ADDRESS2" => SchoolMoveLogEntry.last.patient.address_line_2,
            "ADDRESS3" => nil,
            "TOWN" => SchoolMoveLogEntry.last.patient.address_town,
            "POSTCODE" => SchoolMoveLogEntry.last.patient.address_postcode,
            "COUNTY" => nil,
            "ETHNIC_OR" => nil,
            "ETHNIC_DESCRIPTION" => nil,
            "NATIONAL_URN_NO" => new_school.urn,
            "BASE_NAME" => new_school.name,
            "STARTDATE" => new_school.created_at.to_fs(:govuk),
            "STUD_ID" => nil,
            "DES_NUMBER" => nil
          }
        )
      end
    end

    context "when moving to home education" do
      before do
        patient = create(:patient, :home_educated)
        create(:school_move_log_entry, :home_educated, patient: patient)
      end

      it "returns '999999' as the URN" do
        expect(rows.first["NATIONAL_URN_NO"]).to eq("999999")
      end
    end

    context "when moving to an unknown school" do
      before do
        patient = create(:patient, school: nil)
        create(:school_move_log_entry, :unknown_school, patient: patient)
      end

      it "returns '888888' as the URN" do
        expect(rows.first["NATIONAL_URN_NO"]).to eq("888888")
      end
    end
  end
end
