# frozen_string_literal: true

class ConsentFormsController < ApplicationController
  before_action :set_consent_form, except: %i[unmatched_responses]
  skip_after_action :verify_policy_scoped

  layout "full"

  def unmatched_responses
    @session = policy_scope(Session).find(params.fetch(:session_id))
    @unmatched_consent_responses = @session.unmatched_consent_forms
  end

  def show
    @patient_sessions =
      @consent_form
        .scheduled_session
        .patient_sessions
        .includes(:patient)
        .order("patients.last_name")
  end

  def review_match
    @patient_session =
      policy_scope(PatientSession).find(params[:patient_session_id])
  end

  def match
    @patient_session =
      policy_scope(PatientSession).find(params[:patient_session_id])

    patient = @patient_session.patient

    session =
      patient.match_consent_form!(@consent_form) ||
        @consent_form.scheduled_session

    flash[:success] = {
      heading: "Consent matched for",
      heading_link_text: patient.full_name,
      heading_link_href:
        session_patient_path(
          session,
          id: patient.id,
          section: "triage",
          tab: "given"
        )
    }

    if session.unmatched_consent_forms.any?
      redirect_to session_consents_unmatched_responses_path(session)
    else
      redirect_to session_consents_path(session)
    end
  end

  private

  def set_consent_form
    @consent_form = policy_scope(ConsentForm).find(params[:id])
  end
end
