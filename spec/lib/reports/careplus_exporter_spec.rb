# frozen_string_literal: true

describe Reports::CareplusExporter do
  subject(:csv) do
    described_class.call(
      programme:,
      start_date: 1.month.ago.to_date,
      end_date: Date.current
    )
  end

  let(:programme) { create(:programme) }
  let(:session) { create(:session, programme:) }
  let(:parsed_csv) { CSV.parse(csv) }
  let(:headers) { parsed_csv.first }
  let(:data_rows) { parsed_csv[1..] }

  it "includes the expected headers" do
    expect(headers).to include(
      "NHS Number",
      "Surname",
      "Forename",
      "Date of Birth",
      "Address Line 1",
      "Person Giving Consent",
      "Ethnicity",
      "Date Attended",
      "Time Attended",
      "Venue Type",
      "Venue Code",
      "Staff Type",
      "Staff Code",
      "Attended",
      "Reason Not Attended",
      "Suspension End Date"
    )

    (1..5).each do |i|
      expect(headers).to include(
        "Vaccine #{i}",
        "Dose #{i}",
        "Reason Not Given #{i}",
        "Site #{i}",
        "Manufacturer #{i}",
        "Batch No #{i}"
      )
    end
  end

  it "does not include the patient if they have no vaccination details" do
    create(:patient_session, session:)

    expect(data_rows.first).to be_nil
  end

  it "includes the patient and vaccination details" do
    patient_session =
      create(
        :patient_session,
        :consent_given_triage_not_needed,
        programme:,
        session:
      )
    vaccination_record =
      create(
        :vaccination_record,
        programme:,
        patient_session:,
        performed_at: 2.weeks.ago
      )

    attended_index = headers.index("Attended")
    vaccine_index = headers.index("Vaccine 1")
    batch_index = headers.index("Batch No 1")
    site_index = headers.index("Site 1")
    staff_type_index = headers.index("Staff Type")
    staff_code_index = headers.index("Staff Code")

    row = data_rows.first

    expect(row[attended_index]).to eq("Y")
    expect(row[vaccine_index]).to eq("HPV")
    expect(row[batch_index]).to eq(vaccination_record.batch.name)
    expect(row[site_index]).to eq("ULA")
    expect(row[staff_type_index]).to eq("IN")
    expect(row[staff_code_index]).to eq("LW5PM")
  end

  it "excludes vaccination records outside the date range" do
    patient_session = create(:patient_session, session:)
    create(
      :vaccination_record,
      programme:,
      patient_session:,
      performed_at: 2.months.ago
    )

    expect(data_rows.first).to be_nil
  end

  it "excludes not administered vaccination records" do
    patient_session = create(:patient_session, session:)
    create(:vaccination_record, :not_administered, programme:, patient_session:)

    expect(data_rows.first).to be_nil
  end
end
