# frozen_string_literal: true

class VaccinationRecordsController < ApplicationController
  def index
    @vaccination_records = vaccination_records
  end

  def show
    @vaccination_record = vaccination_records.find(params[:id])
    @patient = @vaccination_record.patient
    @session = @vaccination_record.session
    @school = @patient.school
  end

  def export_dps
    send_data(dps_export.csv, filename: dps_export.filename)
  end

  def reset_dps_export
    campaign.dps_exports.destroy_all

    flash[:success] = { heading: "DPS exports have been reset for campaign" }

    redirect_to campaign_immunisation_imports_path(campaign)
  end

  private

  def campaign
    @campaign ||= policy_scope(Campaign).active.find(params[:campaign_id])
  end

  def vaccination_records
    @vaccination_records ||=
      policy_scope(VaccinationRecord)
        .includes(
          :batch,
          :campaign,
          :performed_by_user,
          :vaccine,
          patient: :school,
          session: :location
        )
        .recorded
        .where(campaign:)
        .order(:recorded_at)
        .strict_loading
  end

  def dps_export
    @dps_export ||= DPSExport.create!(campaign:)
  end
end
