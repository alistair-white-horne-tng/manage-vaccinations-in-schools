# frozen_string_literal: true

# == Schema Information
#
# Table name: locations
#
#  id               :bigint           not null, primary key
#  address          :text
#  county           :text
#  locality         :text
#  name             :text
#  postcode         :text
#  town             :text
#  type             :integer          not null
#  url              :text
#  urn              :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  imported_from_id :bigint
#
# Indexes
#
#  index_locations_on_imported_from_id  (imported_from_id)
#  index_locations_on_urn               (urn) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (imported_from_id => immunisation_imports.id)
#
FactoryBot.define do
  factory :location do
    name { Faker::Educator.primary_school }
    address { Faker::Address.street_address }
    locality { "" }
    town { Faker::Address.city }
    county { Faker::Address.county }
    postcode { Faker::Address.postcode }
    url { Faker::Internet.url }

    trait :school do
      type { :school }
      sequence(:urn, 100_000, &:to_s)
    end

    trait :generic_clinic do
      type { :generic_clinic }
      urn { nil }
    end
  end
end
