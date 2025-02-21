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

      # Generate graph
      @mermaid = GraphRecords.new(params[:patient_id],
                                  focus_config: {
                                    patient: [params[:patient_id]] + @other_patient_ids,
                                    parents: @other_parent_ids
                                  },
                                  traversals_config: {
                                    patient: %i[parents consents class_imports cohort_imports],
                                    parent: %i[consents class_imports cohort_imports],
                                  },
                                  node_order: %i[class_import cohort_import patient consent parent],
      ).graph(patient: [params[:patient_id]] + @other_patient_ids,
              parent: @other_parent_ids).join("\n")
    end
  end
end
