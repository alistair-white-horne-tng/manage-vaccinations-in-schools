# frozen_string_literal: true

class PatientSession::Triage
  def initialize(patient_session)
    @patient_session = patient_session
  end

  STATUSES = [
    SAFE_TO_VACCINATE = :safe_to_vaccinate,
    DO_NOT_VACCINATE = :do_not_vaccinate,
    DELAY_VACCINATION = :delay_vaccination,
    REQUIRED = :required,
    NOT_REQUIRED = :not_required
  ].freeze

  def status
    @status ||= programmes.index_with { programme_status(it) }
  end

  def all
    @all ||=
      Hash.new do |hash, programme|
        hash[programme] = all_by_programme_id.fetch(programme.id, [])
      end
  end

  def latest
    @latest ||=
      Hash.new do |hash, programme|
        hash[programme] = all[programme].reject(&:invalidated?).max_by(
          &:created_at
        )
      end
  end

  def consent_needs_triage?(programme:)
    consent.latest[programme].any?(&:triage_needed?)
  end

  def vaccination_history_needs_triage?(programme:)
    outcome.all[programme].any?(&:administered?) &&
      !VaccinatedCriteria.call(
        programme,
        patient:,
        vaccination_records: outcome.all[programme]
      )
  end

  private

  attr_reader :patient_session

  delegate :consent, :outcome, :patient, :programmes, to: :patient_session

  def programme_status(programme)
    if safe_to_vaccinate?(programme)
      SAFE_TO_VACCINATE
    elsif do_not_vaccinate?(programme)
      DO_NOT_VACCINATE
    elsif delay_vaccination?(programme)
      DELAY_VACCINATION
    elsif required?(programme)
      REQUIRED
    else
      NOT_REQUIRED
    end
  end

  def safe_to_vaccinate?(programme)
    latest[programme]&.ready_to_vaccinate?
  end

  def do_not_vaccinate?(programme)
    latest[programme]&.do_not_vaccinate?
  end

  def delay_vaccination?(programme)
    latest[programme]&.delay_vaccination?
  end

  def required?(programme)
    return true if latest[programme]&.needs_follow_up?

    consent.status[programme] == PatientSession::Consent::GIVEN &&
      (
        consent_needs_triage?(programme:) ||
          vaccination_history_needs_triage?(programme:)
      )
  end

  def all_by_programme_id
    @all_by_programme_id ||= patient.triages.group_by(&:programme_id)
  end
end
