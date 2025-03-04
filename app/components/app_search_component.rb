# frozen_string_literal: true

class AppSearchComponent < ViewComponent::Base
  erb_template <<-ERB
    <%= render AppCardComponent.new(filters: true) do |card| %>
      <% card.with_heading { "Find children" } %>

      <%= form_with model: @form, url: @url, method: :get, builder: GOVUKDesignSystemFormBuilder::FormBuilder do |f| %>
        <div class="app-search-input" role="search">
          <%= f.govuk_text_field :q,
                                 label: { text: "Search", class: "nhsuk-u-visually-hidden" },
                                 autocomplete: "off",
                                 class: "app-search-input__input" %>
    
          <button class="nhsuk-button nhsuk-button--secondary app-button--icon app-search-input__submit" data-module="nhsuk-button" type="submit">
            <svg class="nhsuk-icon nhsuk-icon__search" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" focusable="false" role="img">
              <title>Search</title>
              <path d="M19.71 18.29l-4.11-4.1a7 7 0 1 0-1.41 1.41l4.1 4.11a1 1 0 0 0 1.42 0 1 1 0 0 0 0-1.42zM5 10a5 5 0 1 1 5 5 5 5 0 0 1-5-5z" fill="currentColor"></path>
            </svg>
          </button>
        </div>

        <%= govuk_details(summary_text: "Advanced filters", open: @form.date_of_birth.present? || @form.missing_nhs_number) do %>
          <%= f.govuk_date_field :date_of_birth, date_of_birth: true, legend: { text: "Date of birth", size: "s" } %>

          <%= f.govuk_check_boxes_fieldset :missing_nhs_number, multiple: false, legend: { text: "Options", size: "s" } do %>
            <%= f.govuk_check_box :missing_nhs_number, 1, 0, multiple: false, link_errors: true, label: { text: "Missing NHS number" } %>
          <% end %>

          <div class="app-button-group">
            <%= f.govuk_submit "Update results", secondary: true, class: "app-button--small" %>
            <%= govuk_button_link_to "Clear filters", @url, class: "app-button--small app-button--secondary" %>
          </div>
        <% end %>
      <% end %>
    <% end %>
  ERB

  def initialize(form:, url:)
    super

    @form = form
    @url = url
  end
end
