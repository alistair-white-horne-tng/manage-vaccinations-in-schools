# frozen_string_literal: true

class ProgrammesController < ApplicationController
  before_action :set_programme, except: :index

  layout "full"

  def index
    @programmes = policy_scope(Programme).includes(:active_vaccines)
  end

  def show
    patients =
      policy_scope(Patient).where(
        cohort: policy_scope(Cohort).for_year_groups(@programme.year_groups)
      )

    @patients_count = patients.count
    @sessions_count = policy_scope(Session).has_programme(@programme).count
    @vaccination_records_count =
      policy_scope(VaccinationRecord).where(programme: @programme).count

    @consent_notifications_count =
      @programme.consent_notifications.where(patient: patients).count

    @consents =
      policy_scope(Consent).where(patient: patients, programme: @programme)

    @consent_given_percentage =
      if (count = @consents.count).positive?
        (@consents.response_given.count / count.to_f * 100.0).to_i
      else
        0
      end
  end

  def sessions
    sessions_for_programme =
      policy_scope(Session)
        .has_programme(@programme)
        .includes(:dates, :location)
        .strict_loading

    @closed_sessions = sessions_for_programme.closed.sort
    @completed_sessions = sessions_for_programme.completed.sort
    @scheduled_sessions = sessions_for_programme.scheduled.sort
    @unscheduled_sessions = sessions_for_programme.unscheduled.sort
  end

  private

  def set_programme
    @programme = policy_scope(Programme).find_by!(type: params[:type])
  end
end
