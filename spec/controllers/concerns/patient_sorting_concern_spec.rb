# frozen_string_literal: true

describe PatientSortingConcern do
  subject(:controller) { klass.new(params) }

  let(:klass) do
    Class.new do
      include PatientSortingConcern
      attr_accessor :params

      def initialize(params)
        @params = params
      end
    end
  end

  let(:alex) do
    create(
      :patient,
      given_name: "Alex",
      year_group: 8,
      address_postcode: "SW1A 1AA"
    )
  end
  let(:blair) do
    create(
      :patient,
      given_name: "Blair",
      year_group: 9,
      address_postcode: "SW2A 1AA"
    )
  end
  let(:casey) do
    create(:patient, given_name: "Casey", year_group: 10, address_postcode: nil)
  end

  let(:programme) { create(:programme) }
  let(:session) { create(:session, programmes: [programme]) }

  let(:patient_sessions) do
    [
      create(:patient_session, :added_to_session, patient: alex, session:),
      create(:patient_session, :delay_vaccination, patient: blair, session:),
      create(:patient_session, :vaccinated, patient: casey, session:)
    ]
  end

  describe "#sort_patients!" do
    context "when sort parameter is 'name' ascending" do
      let(:params) { { sort: "name", direction: "asc" } }

      it "sorts patient sessions by name in ascending order" do
        controller.sort_patients!(patient_sessions, programme:)
        expect(patient_sessions.map(&:patient).map(&:given_name)).to eq(
          %w[Alex Blair Casey]
        )
      end
    end

    context "when sort parameter is 'dob' descending" do
      let(:params) { { sort: "dob", direction: "desc" } }

      it "sorts patient sessions by date of birth in descending order" do
        controller.sort_patients!(patient_sessions, programme:)
        expect(patient_sessions.map(&:patient).map(&:given_name)).to eq(
          %w[Alex Blair Casey]
        )
      end
    end

    context "when sort parameter is 'outcome'" do
      let(:params) { { sort: "outcome", direction: "desc" } }

      it "sorts patient sessions by state in descending order" do
        controller.sort_patients!(patient_sessions, programme:)
        expect(patient_sessions.map { it.status(programme:) }).to eq(
          %w[vaccinated delay_vaccination added_to_session]
        )
      end
    end

    context "when sort parameter is 'postcode'" do
      let(:params) { { sort: "postcode", direction: "desc" } }

      it "sorts patient sessions by name in ascending order" do
        controller.sort_patients!(patient_sessions, programme:)
        expect(patient_sessions.map(&:patient).map(&:given_name)).to eq(
          %w[Blair Alex Casey]
        )
      end

      context "when a patient is restricted" do
        before { blair.update!(restricted_at: Time.current) }

        it "they are treated as though they have no postcode" do
          controller.sort_patients!(patient_sessions, programme:)
          expect(patient_sessions.map(&:patient).map(&:given_name)).to eq(
            %w[Alex Casey Blair]
          )
        end
      end
    end

    context "when sort parameter is missing" do
      let(:params) { {} }

      it "does not change the order of patient sessions" do
        controller.sort_patients!(patient_sessions, programme:)
        expect(patient_sessions.map(&:patient).map(&:given_name)).to eq(
          %w[Alex Blair Casey]
        )
      end
    end
  end

  describe "#filter_patients!" do
    context "when filtering by name" do
      let(:params) { { name: "Alex" } }

      it "filters patient sessions by patient name" do
        controller.filter_patients!(patient_sessions, programme:)
        expect(patient_sessions.size).to eq(1)
        expect(patient_sessions.first.patient.given_name).to eq("Alex")
      end
    end

    context "when filtering by postcode" do
      let(:params) { { postcode: "SW2A" } }

      it "filters patient sessions by date of birth" do
        controller.filter_patients!(patient_sessions, programme:)
        expect(patient_sessions.size).to eq(1)
        expect(patient_sessions.first.patient.given_name).to eq("Blair")
      end

      context "when a patient is restricted" do
        before { blair.update!(restricted_at: Time.current) }

        it "excludes the patient from the result" do
          controller.filter_patients!(patient_sessions, programme:)
          expect(patient_sessions.size).to eq(0)
        end
      end
    end

    context "when filtering by year group" do
      let(:params) { { year_groups: %w[9] } }

      it "filters patient sessions by date of birth" do
        controller.filter_patients!(patient_sessions, programme:)
        expect(patient_sessions.size).to eq(1)
        expect(patient_sessions.first.patient.given_name).to eq("Blair")
      end
    end

    context "when filtering by name and date of birth" do
      let(:params) { { name: "Alex", year_groups: %w[8] } }

      it "filters patient sessions by both name and date of birth" do
        controller.filter_patients!(patient_sessions, programme:)
        expect(patient_sessions.size).to eq(1)
        expect(patient_sessions.first.patient.given_name).to eq("Alex")
      end
    end

    context "when no filter parameters are provided" do
      let(:params) { {} }

      it "does not filter patient sessions" do
        controller.filter_patients!(patient_sessions, programme:)
        expect(patient_sessions.size).to eq(3)
      end
    end
  end
end
