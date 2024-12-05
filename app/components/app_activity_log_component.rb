# frozen_string_literal: true

class AppActivityLogComponent < ViewComponent::Base
  def initialize(patient: nil, patient_session: nil)
    super

    if patient.nil? && patient_session.nil?
      raise "Pass either a patient or a patient session."
    elsif patient && patient_session
      raise "Pass only a patient or a patient session."
    end

    @patient = patient || patient_session.patient
    @patient_sessions =
      patient_session ? [patient_session] : patient.patient_sessions

    @consents = (patient || patient_session).consents
    @gillick_assessments = (patient || patient_session).gillick_assessments
    @pre_screenings = (patient || patient_session).pre_screenings
    @triages = (patient || patient_session).triages
    @vaccination_records =
      (patient || patient_session).vaccination_records.with_discarded
  end

  attr_reader :patient,
              :patient_sessions,
              :consents,
              :gillick_assessments,
              :pre_screenings,
              :triages,
              :vaccination_records

  def events_by_day
    all_events.sort_by { -_1[:time].to_i }.group_by { _1[:time].to_date }
  end

  def all_events
    [
      attendance_events,
      consent_events,
      gillick_assessment_events,
      notify_events,
      pre_screening_events,
      session_events,
      triage_events,
      vaccination_events
    ].flatten
  end

  def consent_events
    consents.flat_map do |consent|
      if consent.invalidated?
        [
          {
            title:
              "Consent #{consent.response} by #{consent.name} (#{consent.who_responded})",
            time: consent.created_at,
            by: consent.recorded_by&.full_name
          },
          {
            title: "Consent from #{consent.name} invalidated",
            time: consent.invalidated_at
          }
        ]
      elsif consent.withdrawn?
        [
          {
            title:
              "Consent given by #{consent.name} (#{consent.who_responded})",
            time: consent.created_at,
            by: consent.recorded_by&.full_name
          },
          {
            title: "Consent from #{consent.name} withdrawn",
            time: consent.withdrawn_at
          }
        ]
      else
        [
          {
            title:
              "Consent #{consent.response} by #{consent.name} (#{consent.who_responded})",
            time: consent.created_at,
            by: consent.recorded_by&.full_name
          }
        ]
      end
    end
  end

  def gillick_assessment_events
    gillick_assessments.each_with_index.map do |gillick_assessment, index|
      action = index.zero? ? "Completed" : "Updated"
      outcome =
        (
          if gillick_assessment.gillick_competent?
            "Gillick competent"
          else
            "not Gillick competent"
          end
        )

      {
        title: "#{action} Gillick assessment as #{outcome}",
        notes: gillick_assessment.notes,
        time: gillick_assessment.created_at,
        by: gillick_assessment.performed_by.full_name
      }
    end
  end

  def notify_events
    patient.notify_log_entries.map do
      {
        title: "#{_1.title} sent",
        time: _1.created_at,
        notes: patient.restricted? ? "" : _1.recipient,
        by: _1.sent_by&.full_name
      }
    end
  end

  def pre_screening_events
    pre_screenings.map do |pre_screening|
      {
        title: "Completed pre-screening checks",
        notes: pre_screening.notes,
        time: pre_screening.created_at,
        by: pre_screening.performed_by.full_name
      }
    end
  end

  def session_events
    patient_sessions.map do |patient_session|
      [
        {
          title: "Added to session at #{patient_session.location.name}",
          time: patient_session.created_at
        }
      ]
    end
  end

  def triage_events
    triages.map do
      {
        title: "Triaged decision: #{_1.human_enum_name(:status)}",
        time: _1.created_at,
        notes: _1.notes,
        by: _1.performed_by.full_name
      }
    end
  end

  def vaccination_events
    vaccination_records.flat_map do |vaccination_record|
      title =
        if vaccination_record.administered?
          "Vaccinated with #{helpers.vaccine_heading(vaccination_record.vaccine)}"
        else
          "#{vaccination_record.programme.name} vaccination not given: #{vaccination_record.human_enum_name(:outcome)}"
        end

      kept = {
        title:,
        time: vaccination_record.performed_at,
        notes: vaccination_record.notes,
        by: vaccination_record.performed_by&.full_name
      }

      discarded =
        if vaccination_record.discarded?
          {
            title:
              "#{vaccination_record.programme.name} vaccination record deleted",
            time: vaccination_record.discarded_at
          }
        end

      [kept, discarded].compact
    end
  end

  def attendance_events
    patient_sessions
      .flat_map(&:session_attendances)
      .map do
        title = (_1.attending? ? "Attended session" : "Absent from session")
        title += " at #{_1.patient_session.location.name}"

        { title:, time: _1.created_at }
      end
  end
end
