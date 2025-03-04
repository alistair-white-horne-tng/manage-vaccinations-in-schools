# frozen_string_literal: true

require "pagy/extras/array"

class Sessions::RecordController < ApplicationController
  include Pagy::Backend
  include SearchFormConcern

  before_action :set_session
  before_action :set_search_form

  layout "full"

  def show
    scope =
      @session.patient_sessions.preload_for_status.in_programmes(
        @session.programmes
      )

    @valid_statuses = PatientSession::Record::STATUSES

    patient_sessions =
      @form.apply(scope) do |filtered_scope|
        filtered_scope.select do
          it.register.status == PatientSession::Register::PRESENT ||
            it.record.status.values.none?(PatientSession::Record::NONE)
        end
      end

    if patient_sessions.is_a?(Array)
      @pagy, @patient_sessions = pagy_array(patient_sessions)
    else
      @pagy, @patient_sessions = pagy(patient_sessions)
    end
  end

  private

  def set_session
    @session =
      policy_scope(Session).includes(:programmes).find_by!(
        slug: params[:session_slug]
      )
  end
end
