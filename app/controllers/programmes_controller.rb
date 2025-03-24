# frozen_string_literal: true

require "pagy/extras/array"

class ProgrammesController < ApplicationController
  include Pagy::Backend
  include SearchFormConcern

  before_action :set_programme, except: :index
  before_action :set_search_form, only: :patients

  layout "full"

  def index
    @programmes = policy_scope(Programme).includes(:active_vaccines)
  end

  def show
    patients = policy_scope(Patient).in_programmes([@programme])

    @patients_count = patients.count
    @vaccinations_count =
      policy_scope(VaccinationRecord).where(programme: @programme).count
    @consent_notifications_count =
      @programme.consent_notifications.has_programme(@programme).count
    @consents =
      policy_scope(Consent).where(patient: patients, programme: @programme)
  end

  def sessions
    @sessions =
      policy_scope(Session)
        .has_programme(@programme)
        .for_current_academic_year
        .eager_load(:location)
        .preload(
          :session_dates,
          patient_sessions: [
            :gillick_assessments,
            :session_attendances,
            {
              patient: %i[consent_statuses triage_statuses vaccination_records]
            }
          ]
        )
        .order("locations.name")
  end

  def patients
    scope =
      policy_scope(Patient).includes(:vaccination_statuses).in_programmes(
        [@programme]
      )

    patients = @form.apply(scope, programme: @programme)

    @pagy, @patients = pagy(patients)
  end

  def consent_form
    send_file(
      "public/consent_forms/#{@programme.type}.pdf",
      filename: "#{@programme.name} Consent Form.pdf",
      disposition: "attachment"
    )
  end

  private

  def set_programme
    @programme = authorize policy_scope(Programme).find_by!(type: params[:type])
  end
end
