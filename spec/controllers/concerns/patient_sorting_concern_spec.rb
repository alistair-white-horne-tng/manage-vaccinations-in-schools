# frozen_string_literal: true

describe PatientSortingConcern do
  subject { klass.new(params) }

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
    create(:patient, given_name: "Alex", date_of_birth: Date.new(2010, 1, 1))
  end
  let(:blair) do
    create(:patient, given_name: "Blair", date_of_birth: Date.new(2010, 1, 2))
  end
  let(:casey) do
    create(:patient, given_name: "Casey", date_of_birth: Date.new(2010, 1, 3))
  end

  let(:programme) { create(:programme) }
  let(:session) { create(:session, programme:) }

  let(:patient_sessions) do
    [
      create(
        :patient_session,
        :added_to_session,
        patient: alex,
        programme:,
        session:
      ),
      create(
        :patient_session,
        :delay_vaccination,
        patient: blair,
        programme:,
        session:
      ),
      create(
        :patient_session,
        :vaccinated,
        patient: casey,
        programme:,
        session:
      )
    ]
  end

  describe "#sort_patients!" do
    context "when sort parameter is 'name' ascending" do
      let(:params) { { sort: "name", direction: "asc" } }

      it "sorts patient sessions by name in ascending order" do
        subject.sort_patients!(patient_sessions)
        expect(patient_sessions.map(&:patient).map(&:given_name)).to eq(
          %w[Alex Blair Casey]
        )
      end
    end

    context "when sort parameter is 'dob' descending" do
      let(:params) { { sort: "dob", direction: "desc" } }

      it "sorts patient sessions by date of birth in descending order" do
        subject.sort_patients!(patient_sessions)
        expect(patient_sessions.map(&:patient).map(&:given_name)).to eq(
          %w[Casey Blair Alex]
        )
      end
    end

    context "when sort parameter is 'outcome'" do
      let(:params) { { sort: "outcome", direction: "desc" } }

      it "sorts patient sessions by state in descending order" do
        subject.sort_patients!(patient_sessions)
        expect(patient_sessions.map(&:state)).to eq(
          %w[vaccinated delay_vaccination added_to_session]
        )
      end
    end

    context "when sort parameter is missing" do
      let(:params) { {} }

      it "does not change the order of patient sessions" do
        subject.sort_patients!(patient_sessions)
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
        subject.filter_patients!(patient_sessions)
        expect(patient_sessions.size).to eq(1)
        expect(patient_sessions.first.patient.given_name).to eq("Alex")
      end
    end

    context "when filtering by date of birth" do
      let(:params) { { dob: "02/01/2010" } }

      it "filters patient sessions by date of birth" do
        subject.filter_patients!(patient_sessions)
        expect(patient_sessions.size).to eq(1)
        expect(patient_sessions.first.patient.given_name).to eq("Blair")
      end
    end

    context "when filtering by name and date of birth" do
      let(:params) { { name: "Alex", dob: "01/01/2010" } }

      it "filters patient sessions by both name and date of birth" do
        subject.filter_patients!(patient_sessions)
        expect(patient_sessions.size).to eq(1)
        expect(patient_sessions.first.patient.given_name).to eq("Alex")
      end
    end

    context "when no filter parameters are provided" do
      let(:params) { {} }

      it "does not filter patient sessions" do
        subject.filter_patients!(patient_sessions)
        expect(patient_sessions.size).to eq(3)
      end
    end
  end
end
