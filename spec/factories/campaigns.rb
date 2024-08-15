# frozen_string_literal: true

# == Schema Information
#
# Table name: campaigns
#
#  id            :bigint           not null, primary key
#  academic_year :integer          not null
#  active        :boolean          default(FALSE), not null
#  end_date      :date
#  name          :string           not null
#  start_date    :date
#  type          :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  team_id       :integer          not null
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#
FactoryBot.define do
  factory :campaign do
    transient { batch_count { 1 } }

    name { "Campaign" }
    type { %w[flu hpv].sample }
    academic_year { Time.zone.today.year }

    team

    trait :active do
      active { true }

      start_date { Date.new(academic_year, 9, 1) }
      end_date { Date.new(academic_year + 1, 7, 31) }

      vaccines { [association(:vaccine, batch_count:)] }
    end

    trait :hpv do
      active
      name { "HPV" }
      type { "hpv" }
      vaccines { [association(:vaccine, :gardasil_9, batch_count:)] }
    end

    trait :hpv_all_vaccines do
      hpv
      vaccines do
        [
          association(:vaccine, :cervarix, batch_count:),
          association(:vaccine, :gardasil, batch_count:),
          association(:vaccine, :gardasil_9, batch_count:)
        ]
      end
    end

    trait :hpv_no_batches do
      batch_count { 0 }
      hpv
    end

    trait :flu do
      active
      name { "Flu" }
      type { "flu" }
      vaccines do
        [
          association(:vaccine, :adjuvanted_quadrivalent, batch_count:),
          association(:vaccine, :cell_quadrivalent, batch_count:),
          association(:vaccine, :fluenz_tetra, batch_count:),
          association(:vaccine, :quadrivalent_influenza, batch_count:),
          association(:vaccine, :quadrivalent_influvac_tetra, batch_count:),
          association(:vaccine, :supemtek, batch_count:)
        ]
      end
    end

    trait :flu_all_vaccines do
      flu
      vaccines do
        [
          association(:vaccine, :adjuvanted_quadrivalent, batch_count:),
          association(:vaccine, :cell_quadrivalent, batch_count:),
          association(:vaccine, :fluad_tetra, batch_count:),
          association(:vaccine, :flucelvax_tetra, batch_count:),
          association(:vaccine, :fluenz_tetra, batch_count:),
          association(:vaccine, :quadrivalent_influenza, batch_count:),
          association(:vaccine, :quadrivalent_influvac_tetra, batch_count:),
          association(:vaccine, :supemtek, batch_count:)
        ]
      end
    end

    trait :flu_nasal_only do
      name { "Flu" }
      vaccines { [association(:vaccine, :fluenz_tetra, batch_count:)] }
    end
  end
end
