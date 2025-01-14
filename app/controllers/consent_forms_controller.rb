# frozen_string_literal: true

require "pagy/extras/array"

class ConsentFormsController < ApplicationController
  include Pagy::Backend
  include PatientSortingConcern

  before_action :set_consent_form, except: :index
  before_action :set_patient, only: %i[edit_match update_match]

  layout "full"

  def index
    @pagy, @consent_forms = pagy(consent_form_scope.order(:recorded_at))
  end

  def show
    patients = policy_scope(Patient).to_a
    sort_and_filter_patients!(patients)
    @pagy, @patients = pagy_array(patients)
  end

  def edit_match
    render :match, layout: "two_thirds"
  end

  def update_match
    @consent_form.match_with_patient!(@patient, current_user:)

    session = @patient.upcoming_sessions.first || @consent_form.original_session

    flash[:success] = {
      heading: "Consent matched for",
      heading_link_text: @patient.full_name,
      heading_link_href:
        session_patient_path(
          session,
          id: @patient.id,
          section: "triage",
          tab: "given"
        )
    }

    redirect_to action: :index
  end

  def edit_invalidate
    render :invalidate, layout: "two_thirds"
  end

  def update_invalidate
    @consent_form.assign_attributes(invalidate_params)

    if @consent_form.save
      redirect_to consent_forms_path,
                  flash: {
                    success:
                      "Consent response from #{@consent_form.parent_full_name} marked as invalid"
                  }
    else
      render :invalidate, layout: "two_thirds", status: :unprocessable_entity
    end
  end

  def new_patient
    @patient =
      Patient.from_consent_form(@consent_form).tap(&:clear_changes_information)

    render layout: "two_thirds"
  end

  def create_patient
    @patient = Patient.from_consent_form(@consent_form)

    ActiveRecord::Base.transaction do
      @patient.save!

      SchoolMove.new(
        patient: @patient,
        school: @patient.school,
        home_educated: @patient.home_educated,
        organisation:
          @patient.school.present? ? nil : @consent_form.organisation
      ).confirm!

      # This should now match because the patient with the same NHS number
      # exists. We need to perform_now to make sure the record is matched and
      # the consent form disappears from the index page
      ConsentFormMatchingJob.perform_now(@consent_form)
    end

    flash[:success] = "#{@patient.full_name}’s record created from a consent \
                       response from #{@consent_form.parent_full_name}"

    redirect_to action: :index
  end

  private

  def consent_form_scope
    policy_scope(ConsentForm).unmatched.recorded.not_invalidated
  end

  def set_consent_form
    @consent_form = consent_form_scope.find(params[:id])
  end

  def set_patient
    @patient = policy_scope(Patient).find(params[:patient_id])
  end

  def invalidate_params
    params.expect(consent_form: :notes).merge(invalidated_at: Time.current)
  end
end
