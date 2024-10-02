# frozen_string_literal: true

# == Schema Information
#
# Table name: sessions
#
#  id                                  :bigint           not null, primary key
#  academic_year                       :integer          not null
#  close_consent_at                    :date
#  days_before_first_consent_reminder  :integer
#  days_between_consent_reminders      :integer
#  maximum_number_of_consent_reminders :integer
#  send_consent_requests_at            :date
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  location_id                         :bigint
#  team_id                             :bigint           not null
#
# Indexes
#
#  index_sessions_on_team_id                                    (team_id)
#  index_sessions_on_team_id_and_location_id_and_academic_year  (team_id,location_id,academic_year) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#
FactoryBot.define do
  factory :session do
    transient do
      date { Date.current }
      programme { association :programme }
    end

    academic_year { (date || Date.current).academic_year }
    programmes { [programme] }
    team { association(:team, programmes:) }
    location { association :location, :school, team: }

    send_consent_requests_at { date - 14.days if date }
    days_before_first_consent_reminder { 7 }
    close_consent_at { date }

    after(:create) do |session, evaluator|
      next if (date = evaluator.date).nil?
      create(:session_date, session:, value: date)
    end

    trait :today do
      date { Date.current }
    end

    trait :unscheduled do
      date { nil }
    end

    trait :scheduled do
      date { Date.current + 1.week }
    end

    trait :completed do
      date { Date.current - 1.week }
    end

    trait :minimal do
      send_consent_requests_at { nil }
      days_before_first_consent_reminder { nil }
      close_consent_at { nil }
    end
  end
end
