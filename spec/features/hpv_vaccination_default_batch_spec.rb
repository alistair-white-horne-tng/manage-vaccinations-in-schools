# frozen_string_literal: true

describe "HPV vaccination" do
  around { |example| travel_to(Time.zone.local(2024, 2, 1)) { example.run } }

  scenario "Default batch" do
    given_i_am_signed_in
    when_i_vaccinate_a_patient
    then_i_see_the_default_batch_banner_with_batch_1

    when_i_click_the_change_batch_link
    then_i_see_the_change_batch_page

    when_i_choose_the_second_batch
    then_i_see_the_default_batch_banner_with_batch_2

    when_i_vaccinate_a_second_patient
    then_i_see_the_default_batch_on_the_confirmation_page
    and_i_see_the_default_batch_on_the_patient_page
  end

  def given_i_am_signed_in
    programme = create(:programme, :hpv)
    organisation =
      create(:organisation, :with_one_nurse, programmes: [programme])

    batches =
      programme.vaccines.flat_map do |vaccine|
        create_list(:batch, 4, organisation:, vaccine:)
      end

    @batch = batches.first
    @batch2 = batches.second

    @session = create(:session, organisation:, programmes: [programme])

    @patient =
      create(
        :patient,
        :consent_given_triage_not_needed,
        :in_attendance,
        session: @session
      )
    @patient2 =
      create(
        :patient,
        :consent_given_triage_not_needed,
        :in_attendance,
        session: @session
      )

    sign_in organisation.users.first
  end

  def when_i_vaccinate_a_patient
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

    choose @batch.name

    # Find the selected radio button element
    selected_radio_button = find(:radio_button, @batch.name, checked: true)

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

  def when_i_vaccinate_a_second_patient
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

  def then_i_see_the_default_batch_banner_with_batch_1
    expect(page).to have_content(/You are currently using.*#{@batch.name}/)
  end

  def then_i_see_the_default_batch_banner_with_batch_2
    expect(page).to have_content(/You are currently using.*#{@batch2.name}/)
  end

  def when_i_click_the_change_batch_link
    click_link "Change the default batch"
  end

  def then_i_see_the_change_batch_page
    expect(page).to have_content("Select a default batch for this session")
    expect(page).to have_selector(:label, @batch.name)
    expect(page).to have_selector(:label, @batch2.name)
  end

  def when_i_choose_the_second_batch
    choose @batch2.name
    click_button "Continue"
  end

  def then_i_see_the_default_batch_on_the_confirmation_page
    expect(page).to have_content("Check and confirm")
    expect(page).to have_content(@batch2.name)

    click_button "Confirm"
  end

  def and_i_see_the_default_batch_on_the_patient_page
    click_link @patient2.full_name

    expect(page).to have_content("Vaccinated")
    expect(page).to have_content(@batch2.name)
  end
end
