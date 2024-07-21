# frozen_string_literal: true

class Vaccinations::EditController < ApplicationController
  include Wicked::Wizard::Translated # For custom URLs, see en.yml wicked
  include TodaysBatchConcern
  include VaccinationMailerConcern

  before_action :set_session
  before_action :set_patient
  before_action :set_patient_session
  before_action :set_draft_vaccination_record
  before_action :set_batches
  before_action :set_steps
  before_action :setup_wizard_translated

  layout "two_thirds"

  def show
    render_wizard
  end

  def update
    if current_step == :confirm
      handle_confirm
    elsif current_step == :batch
      @draft_vaccination_record.assign_attributes(update_params)
      update_default_batch_for_today
    else
      @draft_vaccination_record.assign_attributes(update_params)
    end

    render_wizard @draft_vaccination_record
  end

  private

  def handle_confirm
    @draft_vaccination_record.assign_attributes(
      update_params.merge(recorded_at: Time.zone.now)
    )

    if @draft_vaccination_record.save
      send_vaccination_mail(@draft_vaccination_record)
      @patient_session.do_vaccination!
    end
  end

  def finish_wizard_path
    # TODO: is this the correct thing to be showing if the vaccination is not administered?
    flash[:success] = {
      heading: "Vaccination recorded for",
      heading_link_text: @patient.full_name,
      heading_link_href: session_patient_path(@session, id: @patient.id)
    }
    session_vaccinations_path(@session)
  end

  def update_params
    permitted_attributes = {
      confirm: %i[notes],
      batch: %i[batch_id],
      reason: %i[reason]
    }.fetch(current_step)

    params
      .fetch(:vaccination_record, {})
      .permit(permitted_attributes)
      .merge(form_step: current_step)
  end

  def set_steps
    # Translated steps are cached after running setup_wizard_translated.
    # To allow us to run this method multiple times during a single action
    # lifecycle, we need to clear the cache.
    @wizard_translations = nil

    self.steps = @draft_vaccination_record.form_steps
  end

  def set_draft_vaccination_record
    @draft_vaccination_record = @patient_session.draft_vaccination_record
  end

  def set_batches
    @batches =
      @draft_vaccination_record.vaccine.batches.order(expiry: :asc, name: :asc)
  end

  def set_patient_session
    @patient_session = @patient.patient_sessions.find_by(session: @session)
  end

  def set_session
    @session =
      policy_scope(Session).find(
        params.fetch(:session_id) { params.fetch(:id) }
      )
  end

  def set_patient
    @patient =
      policy_scope(Patient).find(
        params.fetch(:patient_id) { params.fetch(:id) }
      )
  end

  def update_default_batch_for_today
    if params.dig(:vaccination_record, :todays_batch).present? &&
         update_params[:batch_id].in?(
           params[:vaccination_record][:todays_batch]
         )
      self.todays_batch_id = update_params[:batch_id]
    end
  end

  def current_step
    @current_step ||= wizard_value(step).to_sym
  end
end
