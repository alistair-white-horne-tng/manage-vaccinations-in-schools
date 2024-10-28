# frozen_string_literal: true

class AppSessionPatientTableComponent < ViewComponent::Base
  def initialize(
    section:,
    caption: nil,
    columns: %i[name year_group],
    consent_form: nil,
    params: {},
    patient_sessions: nil,
    patients: nil,
    year_groups: []
  )
    super

    if patient_sessions && !patients
      @patients = patient_sessions.map(&:patient)
      @patient_sessions = patient_sessions.map { [_1.patient, _1] }.to_h
    elsif patients && !patient_sessions
      @patients = patients
      @patient_sessions = {}
    else
      raise "Provide only patients or patient sessions."
    end

    @caption = caption
    @columns = columns
    @consent_form = consent_form
    @params = params
    @section = section
    @year_groups = year_groups
  end

  private

  attr_reader :params, :year_groups

  def column_name(column)
    {
      action: "Action needed",
      dob: "Date of birth",
      name: "Full name",
      outcome: "Outcome",
      postcode: "Postcode",
      reason: "Reason for refusal",
      select_for_matching: "Action",
      year_group: "Year group"
    }.fetch(column)
  end

  def column_value(patient, column)
    patient_session = @patient_sessions[patient]

    case column
    when :action, :outcome
      t("patient_session_statuses.#{patient_session.state}.text")
    when :dob
      patient.date_of_birth.to_fs(:long)
    when :name
      name_cell(patient)
    when :year_group
      helpers.patient_year_group(patient)
    when :reason
      patient_session
        .consents
        .map { |c| c.human_enum_name(:reason_for_refusal) }
        .uniq
        .join("<br />")
        .html_safe
    when :postcode
      patient.restricted? ? "" : patient.address_postcode
    when :select_for_matching
      matching_link(patient)
    else
      raise ArgumentError, "Unknown column: #{column}"
    end
  end

  def name_cell(patient)
    safe_join(
      [
        patient_link(patient),
        (
          if patient.has_preferred_name?
            "<span class=\"nhsuk-u-font-size-16\">Known as: ".html_safe +
              patient.preferred_full_name + "</span>".html_safe
          end
        )
      ].compact,
      tag.br
    )
  end

  def patient_link(patient)
    session = @patient_sessions[patient]&.session

    if @section == :matching || session.nil?
      patient.full_name
    else
      govuk_link_to patient.full_name,
                    session_patient_path(
                      session,
                      patient,
                      section: params[:section],
                      tab: params[:tab]
                    )
    end
  end

  def matching_link(patient)
    govuk_button_link_to(
      "Select",
      match_consent_form_path(@consent_form, patient),
      secondary: true,
      class: "app-button--small"
    )
  end

  def header_link(column)
    return column_name(column) if column == :select_for_matching

    direction =
      if params[:sort] == column.to_s && params[:direction] == "asc"
        "desc"
      else
        "asc"
      end

    data = { turbo: "true", turbo_action: "replace" }

    filter_params = {
      direction:,
      name: params[:name],
      postcode: params[:postcode],
      sort: column,
      year_groups: params[:year_groups]
    }

    path =
      if @section == :matching
        consent_form_path(@consent_form, **filter_params)
      else
        session_section_tab_path(
          section: params[:section],
          session_id: params[:session_id],
          tab: params[:tab],
          **filter_params
        )
      end

    link_to column_name(column), path, data:
  end

  def form_url
    if @section == :matching
      consent_form_path(@consent_form)
    else
      session_section_tab_path(
        session_id: params[:session_id],
        section: params[:section],
        tab: params[:tab]
      )
    end
  end

  def header_attributes(column)
    sort =
      if params[:sort] == column.to_s
        params[:direction] == "asc" ? "ascending" : "descending"
      else
        "none"
      end
    { html_attributes: { aria: { sort: } } }
  end
end
