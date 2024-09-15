# frozen_string_literal: true

class SessionRemindersJob < ApplicationJob
  queue_as :default

  def perform
    return unless Flipper.enabled?(:scheduled_emails)

    patient_sessions.each do |patient_session|
      patient_session.consents_to_send_communication.each do |consent|
        SessionMailer.with(consent:, patient_session:).reminder.deliver_later
      end

      patient_session.update!(reminder_sent_at: Time.zone.now)
    end
  end

  private

  def patient_sessions
    PatientSession
      .includes(:consents)
      .joins(:session)
      .merge(Session.active.tomorrow)
      .reminder_not_sent
  end
end
