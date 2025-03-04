# frozen_string_literal: true

describe "Vaccination" do
  around { |example| travel_to(Time.zone.local(2024, 2, 1)) { example.run } }

  scenario "Today's batch" do
    given_i_am_signed_in

    when_i_vaccinate_a_patient_with_hpv

    when_i_vaccinate_a_second_patient_with_hpv
    then_i_see_the_default_batch_on_the_confirmation_page
    and_i_see_the_default_batch_on_the_patient_page

    when_i_vaccinate_a_patient_with_menacwy
    then_i_am_required_to_choose_a_batch
  end

  def given_i_am_signed_in
    programmes = [create(:programme, :hpv), create(:programme, :menacwy)]

    organisation = create(:organisation, :with_one_nurse, programmes:)

    batches =
      programmes.map do |programme|
        programme.vaccines.flat_map do |vaccine|
          create_list(:batch, 2, organisation:, vaccine:)
        end
      end

    @hpv_batch = batches.first.first

    @session = create(:session, organisation:, programmes:)

    @patient =
      create(
        :patient,
        :consent_given_triage_not_needed,
        :in_attendance,
        session: @session,
        year_group: 9
      )

    @patient2 =
      create(
        :patient,
        :consent_given_triage_not_needed,
        :in_attendance,
        session: @session,
        year_group: 8
      )

    sign_in organisation.users.first
  end

  def when_i_vaccinate_a_patient_with_hpv
    visit session_vaccinations_path(@session)

    click_link @patient.full_name

    # pre-screening
    find_all(".nhsuk-fieldset")[0].choose "Yes"
    find_all(".nhsuk-fieldset")[1].choose "Yes"
    find_all(".nhsuk-fieldset")[2].choose "Yes"
    find_all(".nhsuk-fieldset")[3].choose "Yes"

    # vaccination
    find_all(".nhsuk-fieldset")[4].choose "Yes"
    choose "Left arm (upper position)"
    click_button "Continue"

    choose @hpv_batch.name

    # Find the selected radio button element
    selected_radio_button = find(:radio_button, @hpv_batch.name, checked: true)

    # Find the "Default to this batch for this session" checkbox immediately below and check it
    checkbox_below =
      selected_radio_button.find(
        :xpath,
        'following::input[@type="checkbox"][1]'
      )
    checkbox_below.check
    click_button "Continue"

    click_button "Confirm"
  end

  def when_i_vaccinate_a_second_patient_with_hpv
    visit session_vaccinations_path(@session)

    click_link @patient2.full_name

    # pre-screening
    find_all(".nhsuk-fieldset")[0].choose "Yes"
    find_all(".nhsuk-fieldset")[1].choose "Yes"
    find_all(".nhsuk-fieldset")[2].choose "Yes"
    find_all(".nhsuk-fieldset")[3].choose "Yes"

    # vaccination
    find_all(".nhsuk-fieldset")[4].choose "Yes"
    choose "Left arm (upper position)"
    click_button "Continue"
  end

  def then_i_see_the_default_batch_on_the_confirmation_page
    expect(page).to have_content("Check and confirm")
    expect(page).to have_content(@hpv_batch.name)

    click_button "Confirm"
  end

  def and_i_see_the_default_batch_on_the_patient_page
    click_link @patient2.full_name

    expect(page).to have_content("Vaccinated")
    expect(page).to have_content(@hpv_batch.name)
  end

  def when_i_vaccinate_a_patient_with_menacwy
    visit session_vaccinations_path(@session, programme_type: "menacwy")

    click_link @patient.full_name

    # pre-screening
    find_all(".nhsuk-fieldset")[0].choose "Yes"
    find_all(".nhsuk-fieldset")[1].choose "Yes"
    find_all(".nhsuk-fieldset")[2].choose "Yes"
    find_all(".nhsuk-fieldset")[3].choose "Yes"

    # vaccination
    find_all(".nhsuk-fieldset")[4].choose "Yes"
    choose "Left arm (upper position)"
    click_button "Continue"
  end

  def then_i_am_required_to_choose_a_batch
    expect(page).to have_content("Which batch did you use?")
  end
end
