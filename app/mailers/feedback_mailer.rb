class FeedbackMailer < ApplicationMailer
  def give_feedback(consent_form: nil, consent: nil, session: nil)
    template_mail(
      EMAILS[:parental_consent_give_feedback],
      **opts(consent_form:, consent:, session:)
    )
  end

  private

  def opts(consent_form:, consent:, session: nil)
    @consent_form = consent_form
    @consent = consent
    @patient = consent_form || consent.patient
    @session = session || consent_form.session

    { to:, reply_to_id:, personalisation: feedback_personalisation }
  end

  def feedback_personalisation
    personalisation.merge(survey_deadline_date:)
  end

  def survey_deadline_date
    recorded_at = @consent_form&.recorded_at || @consent.recorded_at

    (recorded_at + 7.days).to_fs(:nhsuk_date)
  end
end
