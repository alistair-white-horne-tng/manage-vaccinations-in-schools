# frozen_string_literal: true

module Inspect
  module Graph
    class GraphsController < ApplicationController
      skip_after_action :verify_policy_scoped

      def show
        # Merge default values into the query parameters if they aren’t present.
        defaults = {
          include_consents: "1",
          include_class_imports: "0",
          other_patient_ids: "",
          other_parent_ids: ""
        }
        params.reverse_merge!(defaults)

        @object = params[:object_type].classify.constantize.find(params[:object_id])

        # Read the filter parameter from params
        @include_consents = params[:include_consents].last == "1"
        @include_class_imports = params[:include_class_imports].last == "1"
        @other_patient_ids =
          params[:other_patient_ids].split(",").map { |s| s.strip.to_i } # TODO: fix linter warnings
        @other_parent_ids =
          params[:other_parent_ids].split(",").map { |s| s.strip.to_i }

        # Generate graph
        @mermaid =
          GraphRecords
            .new(
              traversals_config: build_traversals_config,
              # traversals_config: {
              #   patient: %i[
              #     sessions
              #     parents
              #     consents
              #     class_imports
              #     cohort_imports
              #   ],
              #   parent: %i[consents class_imports cohort_imports],
              #   consent: %i[patient],
              #   # session: %i[patients]
              # },
              node_order: %i[
                session
                class_import
                cohort_import
                patient
                consent
                parent
              ]
            )
            .graph(
              params[:object_type].to_sym => [@object.id],
            )
            .join("\n")
      end

      private

      def build_traversals_config
        selected_relationships =
          Array(params[:relationships])
            .reject(&:blank?)
            .map(&:to_sym)

        { params[:object_type].to_sym => selected_relationships }
      end

      # def show_params
      #   params.expect(batch: %i[name expiry(3i) expiry(2i) expiry(1i)])
      # end
    end
  end
end
