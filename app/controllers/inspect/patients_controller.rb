# frozen_string_literal: true

module Inspect
  class PatientsController < ApplicationController
    def show
      # Merge default values into the query parameters if they aren’t present.
      defaults = {
        include_consents: '1',
        include_class_imports: '0',
        other_patient_ids: '',
        other_parent_ids: ''
      }
      params.reverse_merge!(defaults)

      @patient = policy_scope(Patient).find(params[:patient_id])

      # Read the filter parameter from params
      @include_consents = params[:include_consents].last == '1'
      @include_class_imports = params[:include_class_imports].last == '1'
      @other_patient_ids = params[:other_patient_ids].split(',').map { |s| s.strip.to_i }
      @other_parent_ids = params[:other_parent_ids].split(',').map { |s| s.strip.to_i }

      # Pass the option to your graph builder. Adjust the API as needed.
      @mermaid = "flowchart TB
  classDef patient fill:#c2e598,color:#000
  classDef parent fill:#faa0a0,color:#000
  classDef consent fill:#fffaa0,color:#000
  classDef class_import fill:#7fd7df,color:#000
  classDef patient_highlighted fill:#c2e598,stroke:#000,stroke-width:3px,color:#000
  classDef parent_highlighted fill:#faa0a0,stroke:#000,stroke-width:3px,color:#000
  patient-16390:::patient_highlighted
  patient-16390:::patient_highlighted --> parent-42558:::parent
  parent-42558:::parent
  consent-79740:::consent --> parent-42558:::parent
  class_import-3367:::class_import --> parent-42558:::parent
  patient-16390:::patient_highlighted --> parent-42557:::parent
  parent-42557:::parent
  consent-79751:::consent --> parent-42557:::parent
  class_import-3367:::class_import --> parent-42557:::parent
  class_import-3862:::class_import --> parent-42557:::parent
  patient-16390:::patient_highlighted --> consent-79740:::consent
  patient-16390:::patient_highlighted --> consent-79751:::consent
  class_import-3367:::class_import --> patient-16390:::patient_highlighted
  class_import-3862:::class_import --> patient-16390:::patient_highlighted"
      # @mermaid = policy_scope(GraphPatient).call(params[:patient_id],
      #                                            @other_patient_ids,
      #                                            @other_parent_ids,
      #                                            @include_consents,
      #                                            @include_class_imports)
    end
  end
end
