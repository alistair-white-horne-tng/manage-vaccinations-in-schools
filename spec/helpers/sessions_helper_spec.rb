# frozen_string_literal: true

describe SessionsHelper do
  let(:programme) { create(:programme, :flu) }
  let(:location) { create(:school, name: "Waterloo Road") }
  let(:date) { nil }
  let(:session) do
    create(:session, programme:, academic_year: 2024, date:, location:)
  end

  describe "#session_academic_year" do
    subject(:session_academic_year) { helper.session_academic_year(session) }

    it { should eq("2024/25") }
  end

  describe "#session_consent_period" do
    subject(:session_consent_period) { helper.session_consent_period(session) }

    it { should eq("Not provided") }

    context "when in the past" do
      let(:date) { Date.yesterday }

      it { should start_with("Closed ") }
    end

    context "when in the future" do
      let(:date) { Date.tomorrow }

      it { should start_with("Open until ") }
    end
  end

  describe "#session_status_tag" do
    subject(:session_status_tag) { helper.session_status_tag(session) }

    context "when unscheduled" do
      let(:session) { create(:session, :unscheduled) }

      it do
        expect(session_status_tag).to eq(
          "<strong class=\"nhsuk-tag nhsuk-tag--purple\">No sessions scheduled</strong>"
        )
      end
    end

    context "when scheduled" do
      let(:session) { create(:session, :scheduled) }

      it do
        expect(session_status_tag).to eq(
          "<strong class=\"nhsuk-tag\">Sessions scheduled</strong>"
        )
      end
    end

    context "when completed" do
      let(:session) { create(:session, :completed) }

      it do
        expect(session_status_tag).to eq(
          "<strong class=\"nhsuk-tag nhsuk-tag--green\">All sessions completed</strong>"
        )
      end
    end
  end
end
