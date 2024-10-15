# frozen_string_literal: true

describe PDSLookupJob do
  subject(:perform_now) { described_class.perform_now(patient) }

  context "with an NHS number already" do
    let(:patient) { create(:patient, nhs_number: "0123456789") }

    it "doesn't change the NHS number" do
      expect { perform_now }.not_to change(patient, :nhs_number)
    end
  end

  context "without an NHS number" do
    let(:patient) do
      create(
        :patient,
        nhs_number: nil,
        given_name: "John",
        family_name: "Smith",
        date_of_birth: Date.new(2014, 2, 18),
        address_postcode: "SW11 1AA"
      )
    end

    before do
      stub_request(
        :get,
        "https://sandbox.api.service.nhs.uk/personal-demographics/FHIR/R4/Patient"
      ).with(
        query: {
          "_history" => "true",
          "address-postalcode" => "SW11 1AA",
          "birthdate" => "eq2014-02-18",
          "family" => "Smith",
          "given" => "John"
        }
      ).to_return(
        body: file_fixture(response_file),
        headers: {
          "Content-Type" => "application/fhir+json"
        }
      )
    end

    context "with a match" do
      let(:response_file) { "pds/search-patients-response.json" }

      it "changes the NHS number of the patient" do
        expect { perform_now }.to change(patient, :nhs_number).from(nil).to(
          "9449306168"
        )
      end
    end

    context "without a match" do
      let(:response_file) { "pds/search-patients-no-results-response.json" }

      it "doesn't change the NHS number" do
        expect { perform_now }.not_to change(patient, :nhs_number)
      end
    end
  end
end
