# frozen_string_literal: true

# == Schema Information
#
# Table name: consent_notifications
#
#  id           :bigint           not null, primary key
#  reminder     :boolean          not null
#  sent_at      :datetime         not null
#  patient_id   :bigint           not null
#  programme_id :bigint           not null
#
# Indexes
#
#  index_consent_notifications_on_patient_id                   (patient_id)
#  index_consent_notifications_on_patient_id_and_programme_id  (patient_id,programme_id)
#  index_consent_notifications_on_programme_id                 (programme_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (programme_id => programmes.id)
#
describe ConsentNotification do
  subject(:consent_notification) { build(:consent_notification) }

  it { should be_valid }

  describe "#create_and_send!" do
    subject(:create_and_send!) do
      travel_to(today) do
        described_class.create_and_send!(
          patient:,
          programme:,
          session:,
          reminder:
        )
      end
    end

    let(:today) { Date.new(2024, 1, 1) }

    let(:parents) { create_list(:parent, 2) }
    let(:patient) { create(:patient, parents:) }
    let(:programme) { create(:programme) }
    let(:session) { create(:session, programme:, patients: [patient]) }

    context "with a request" do
      let(:reminder) { false }

      it "creates a record" do
        expect { create_and_send! }.to change(described_class, :count).by(1)

        consent_notification = described_class.last
        expect(consent_notification).not_to be_reminder
        expect(consent_notification.programme).to eq(programme)
        expect(consent_notification.patient).to eq(patient)
        expect(consent_notification.sent_at).to be_today
      end

      it "enqueues an email per parent" do
        expect { create_and_send! }.to have_enqueued_mail(
          ConsentMailer,
          :request
        ).with(
          params: {
            parent: parents.first,
            patient:,
            programme:,
            session:
          },
          args: []
        ).and have_enqueued_mail(ConsentMailer, :request).with(
                params: {
                  parent: parents.second,
                  patient:,
                  programme:,
                  session:
                },
                args: []
              )
      end

      it "enqueues a text per parent" do
        expect { create_and_send! }.to have_enqueued_text(
          :consent_request
        ).with(
          parent: parents.first,
          patient:,
          programme:,
          session:
        ).and have_enqueued_text(:consent_request).with(
                parent: parents.second,
                patient:,
                programme:,
                session:
              )
      end
    end

    context "with a reminder" do
      let(:reminder) { true }

      it "creates a record" do
        expect { create_and_send! }.to change(described_class, :count).by(1)

        consent_notification = described_class.last
        expect(consent_notification).to be_reminder
        expect(consent_notification.programme).to eq(programme)
        expect(consent_notification.patient).to eq(patient)
        expect(consent_notification.sent_at).to be_today
      end

      it "enqueues an email per parent" do
        expect { create_and_send! }.to have_enqueued_mail(
          ConsentMailer,
          :reminder
        ).with(
          params: {
            parent: parents.first,
            patient:,
            programme:,
            session:
          },
          args: []
        ).and have_enqueued_mail(ConsentMailer, :reminder).with(
                params: {
                  parent: parents.second,
                  patient:,
                  programme:,
                  session:
                },
                args: []
              )
      end

      it "enqueues a text per parent" do
        expect { create_and_send! }.to have_enqueued_text(
          :consent_reminder
        ).with(
          parent: parents.first,
          patient:,
          programme:,
          session:
        ).and have_enqueued_text(:consent_reminder).with(
                parent: parents.second,
                patient:,
                programme:,
                session:
              )
      end

      it "sets consent_reminder_sent_at on the patient" do
        expect { create_and_send! }.to change(
          patient,
          :consent_reminder_sent_at
        ).to(today)
      end
    end
  end
end
