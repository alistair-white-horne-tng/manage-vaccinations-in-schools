# frozen_string_literal: true

require "rails_helper"

describe "Parental consent" do
  include EmailExpectations

  before { Flipper.enable(:parent_contact_method) }

  scenario "Refused" do
    given_an_hpv_campaign_is_underway
    when_i_go_to_the_consent_form
    then_i_see_the_start_page

    when_i_fill_in_my_details
    then_i_see_the_consent_page

    when_i_refuse_consent
    then_i_can_check_my_answers

    when_i_confirm_my_answers
    then_i_see_the_confirmation_page
    and_i_receive_an_email_confirming_that_my_child_wont_be_vaccinated
    and_i_receive_an_email_prompting_me_to_give_feedback

    when_the_nurse_checks_the_consent_responses
    then_they_see_that_the_child_has_consent_refused
    and_the_action_in_the_vaccination_session_is_to_check_refusal
  end

  def given_an_hpv_campaign_is_underway
    @team = create(:team, :with_one_nurse)
    campaign = create(:campaign, :hpv, team: @team)
    location = create(:location, :school, name: "Pilot School")
    @session =
      create(:session, :in_future, campaign:, location:, patients_in_session: 1)
    @child = @session.patients.first
  end

  def when_i_go_to_the_consent_form
    visit start_session_parent_interface_consent_forms_path(@session)
  end

  def then_i_see_the_start_page
    expect(page).to have_content(
      "Give or refuse consent for an HPV vaccination"
    )
  end

  def when_i_refuse_consent
    expect(page).to have_content("Do you agree")
    choose "No"
    click_on "Continue"

    expect(page).to have_content("Why are you refusing to give consent?")
    choose "Medical reasons"
    click_on "Continue"

    expect(page).to have_content(
      "What medical reasons prevent your child from being vaccinated?"
    )
    fill_in "Give details", with: "They have a weakened immune system"
    click_on "Continue"
  end

  def when_i_fill_in_my_details
    click_on "Start now"

    expect(page).to have_content("What is your child’s name?")
    fill_in "First name", with: @child.first_name
    fill_in "Last name", with: @child.last_name
    choose "No" # Do they use a different name in school?
    click_on "Continue"

    expect(page).to have_content("What is your child’s date of birth?")
    fill_in "Day", with: @child.date_of_birth.day
    fill_in "Month", with: @child.date_of_birth.month
    fill_in "Year", with: @child.date_of_birth.year
    click_on "Continue"

    expect(page).to have_content("Confirm your child’s school")
    choose "Yes, they go to this school"
    click_on "Continue"

    expect(page).to have_content("About you")
    fill_in "Your name", with: "Jane #{@child.last_name}"
    choose "Mum" # Your relationship to the child
    fill_in "Email address", with: "jane@example.com"
    fill_in "Phone number", with: "07123456789"
    click_on "Continue"

    expect(page).to have_content("Phone contact method")
    choose "I do not have specific needs"
    click_on "Continue"
  end

  def then_i_see_the_consent_page
    expect(page).to have_content("Do you agree")
  end

  def then_i_can_check_my_answers
    expect(page).to have_content("Check your answers")
  end

  def when_i_confirm_my_answers
    click_on "Confirm"
  end

  def then_i_see_the_confirmation_page
    expect(page).to have_content(
      "Your child will not get an HPV vaccination at school"
    )
  end

  def and_i_receive_an_email_confirming_that_my_child_wont_be_vaccinated
    expect(enqueued_jobs.first["scheduled_at"]).to be_nil
    expect(
      Time.zone.parse(enqueued_jobs.second["scheduled_at"]).to_i
    ).to be_within(1.second).of(1.hour.from_now.to_i)

    expect_email_to "jane@example.com",
                    EMAILS[:parental_consent_confirmation_refused]
  end

  def and_i_receive_an_email_prompting_me_to_give_feedback
    expect_email_to "jane@example.com",
                    EMAILS[:parental_consent_give_feedback],
                    :second
    expect(ActionMailer::Base.deliveries.count).to eq(2)
  end

  def when_the_nurse_checks_the_consent_responses
    sign_in @team.users.first

    visit "/dashboard"
    click_on "Vaccination programmes", match: :first
    click_on "HPV"
    click_on "School sessions"
    click_on "Pilot School"
    click_on "Check consent responses"
  end

  def then_they_see_that_the_child_has_consent_refused
    expect(page).to have_content("Refused")
    click_on "Refused"
    expect(page).to have_content(@child.full_name)
  end

  def and_the_action_in_the_vaccination_session_is_to_check_refusal
    click_on "Vaccination programmes", match: :first
    click_on "HPV"
    click_on "School sessions"
    click_on "Pilot School"
    click_on "Record vaccinations"

    expect(page).to have_content("Could not vaccinate")
    click_on "Could not vaccinate"

    within("tr", text: @child.full_name) do
      expect(page).to have_content("Consent refused")
    end
  end
end
