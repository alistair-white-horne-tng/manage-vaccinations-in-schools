# frozen_string_literal: true

describe "Parental consent" do
  scenario "Consent form exactly matches the cohort" do
    stub_pds_search_to_return_no_patients

    given_an_hpv_programme_is_underway
    when_a_nurse_checks_consent_responses
    then_there_should_be_no_consent_for_my_child

    when_i_go_to_the_consent_form
    when_i_fill_in_my_childs_name_and_birthday

    when_i_give_consent
    and_i_answer_no_to_all_the_medical_questions
    then_i_can_check_my_answers

    when_i_submit_the_consent_form
    then_i_get_a_confirmation_email_and_scheduled_survey_email
    and_i_get_a_confirmation_text

    when_the_nurse_checks_the_consent_responses
    then_they_see_that_the_child_has_consent
    and_they_see_the_full_consent_form

    when_they_check_triage
    then_the_patient_should_be_ready_to_vaccinate
  end

  def given_an_hpv_programme_is_underway
    @programme = create(:programme, :hpv)
    @organisation =
      create(:organisation, :with_one_nurse, programmes: [@programme])
    location = create(:school, name: "Pilot School")
    @session =
      create(
        :session,
        :scheduled,
        organisation: @organisation,
        programme: @programme,
        location:
      )
    @child = create(:patient, session: @session)
  end

  def when_a_nurse_checks_consent_responses
    sign_in @organisation.users.first
    visit "/dashboard"

    click_on "Programmes", match: :first
    click_on "HPV"
    within ".app-secondary-navigation" do
      click_on "Sessions"
    end
    click_on "Pilot School"
    click_on "Check consent responses"
  end

  def then_there_should_be_no_consent_for_my_child
    expect(page).to have_content("No response")

    click_on "No response"
    expect(page).to have_content(@child.full_name)
  end

  def when_i_go_to_the_consent_form
    visit start_parent_interface_consent_forms_path(@session, @programme)
  end

  def when_i_give_consent
    choose "Yes, they go to this school"
    click_on "Continue"

    expect(page).to have_content("About you")
    fill_in "Your name", with: "Jane #{@child.family_name}"
    choose "Mum" # Your relationship to the child
    fill_in "Email address", with: "jane@example.com"
    fill_in "Phone number", with: "07123456789"
    check "Tick this box if you’d like to get updates by text message"
    click_on "Continue"

    expect(page).to have_content("Phone contact method")
    choose "I do not have specific needs"
    click_on "Continue"

    expect(page).to have_content("Do you agree")
    choose "Yes, I agree"
    click_on "Continue"

    expect(page).to have_content("Home address")
    fill_in "Address line 1", with: "1 Test Street"
    fill_in "Address line 2 (optional)", with: "2nd Floor"
    fill_in "Town or city", with: "Testville"
    fill_in "Postcode", with: "TE1 1ST"
    click_on "Continue"
  end

  def when_i_fill_in_my_childs_name_and_birthday
    click_on "Start now"

    expect(page).to have_content("What is your child’s name?")
    fill_in "First name", with: @child.given_name
    fill_in "Last name", with: @child.family_name
    choose "No" # Do they use a different name in school?
    click_on "Continue"

    expect(page).to have_content("What is your child’s date of birth?")
    fill_in "Day", with: @child.date_of_birth.day
    fill_in "Month", with: @child.date_of_birth.month
    fill_in "Year", with: @child.date_of_birth.year
    click_on "Continue"
  end

  def and_i_answer_no_to_all_the_medical_questions
    until page.has_content?("Check your answers and confirm")
      choose "No"
      click_on "Continue"
    end
  end

  def then_i_can_check_my_answers
    expect(page).to have_content("Check your answers and confirm")
    expect(page).to have_content("Child’s name#{@child.full_name}")
  end

  def when_i_submit_the_consent_form
    click_on "Confirm"
  end

  def then_i_get_a_confirmation_email_and_scheduled_survey_email
    expect(page).to have_content(
      "#{@child.full_name} will get their HPV vaccination at school"
    )

    expect_email_to("jane@example.com", :consent_confirmation_given)
  end

  def and_i_get_a_confirmation_text
    expect_text_to("07123 456789", :consent_confirmation_given)
  end

  def when_the_nurse_checks_the_consent_responses
    sign_in @organisation.users.first
    visit "/dashboard"

    click_on "Programmes", match: :first
    click_on "HPV"
    within ".app-secondary-navigation" do
      click_on "Sessions"
    end
    click_on "Pilot School"
    click_on "Check consent responses"
  end

  def then_they_see_that_the_child_has_consent
    expect(page).to have_content("Consent given")
    click_on "Consent given"
    expect(page).to have_content(@child.full_name)
  end

  def and_they_see_the_full_consent_form
    click_on @child.full_name
    click_on "Jane #{@child.family_name}"

    expect(page).to have_content(
      "Consent response from Jane #{@child.family_name}"
    )
    expect(page).to have_content(
      [
        "Home address",
        "1 Test Street",
        "2nd Floor",
        "Testville",
        "TE1 1ST"
      ].join
    )
    expect(page).to have_content(["School", "Pilot School"].join)

    click_on "Back to #{@child.full_name}"

    click_on "Activity log"
    expect(page).to have_content("Consent given")
    expect(page).not_to have_content(
      "Consent response manually matched with child record"
    )

    click_on "Back to consents page"
  end

  def when_they_check_triage
    click_link "Pilot School"
    click_on "Triage health questions"
    click_on "No triage needed"
  end

  def then_the_patient_should_be_ready_to_vaccinate
    expect(page).to have_content(@child.full_name)
    click_on @child.full_name
    expect(page).to have_content("#{@child.full_name} is ready for the nurse")
  end
end
