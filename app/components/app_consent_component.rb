# frozen_string_literal: true

class AppConsentComponent < ViewComponent::Base
  attr_reader :patient_session, :section, :tab

  def initialize(patient_session:, section:, tab:)
    super

    @patient_session = patient_session
    @section = section
    @tab = tab
  end

  delegate :patient, to: :patient_session
  delegate :session, to: :patient_session

  def consents
    @consents ||= patient_session.consents.sort_by(&:created_at).reverse
  end

  def latest_consent_request_or_reminder
    @latest_consent_request_or_reminder ||=
      patient
        .consent_notifications
        .where(programme: session.programmes)
        .order(sent_at: :desc, id: :desc)
        .first
  end

  def can_send_consent_request?
    patient_session.no_consent? && patient.send_notifications? &&
      session.open_for_consent? && patient.parents.any?
  end

  def status_colour(consent)
    if consent.invalidated? || consent.withdrawn?
      "grey"
    elsif consent.response_given?
      "aqua-green"
    elsif consent.response_refused?
      "red"
    else
      "grey"
    end
  end
end
