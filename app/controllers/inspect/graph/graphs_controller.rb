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

        @object =
          params[:object_type].classify.constantize.find(params[:object_id])

        # Read the filter parameter from params
        @include_consents = params[:include_consents].last == "1"
        @include_class_imports = params[:include_class_imports].last == "1"
        @other_patient_ids =
          params[:other_patient_ids].split(",").map { |s| s.strip.to_i } # TODO: fix linter warnings
        @other_parent_ids =
          params[:other_parent_ids].split(",").map { |s| s.strip.to_i }

        # Generate graph
        @traversals_config = build_traversals_config

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
              ] # TODO: make this work with all types
            )
            .graph(params[:object_type].to_sym => [@object.id])
            .join("\n")
      end

      private

      def build_traversals_config
        used_types = {}
        to_process = Set.new([params[:object_type].to_sym])
        processed = Set.new

        # Process types until we've explored all connected relationships
        while (type = to_process.first)
          to_process.delete(type)
          processed.add(type)

          # Get selected relationships for this type
          selected_rels =
            Array(params.dig(:relationships, type)).reject(&:blank?).map(
              &:to_sym
            )

          # Add this type and its relationships to the config
          used_types[type] = selected_rels

          # Add target types to process queue
          klass = type.to_s.classify.constantize
          selected_rels.each do |rel|
            target_type =
              klass.reflect_on_association(rel).klass.name.underscore.to_sym
            to_process.add(target_type) unless processed.include?(target_type)
          end
        end

        used_types
      end

      # def show_params
      #   params.expect(batch: %i[name expiry(3i) expiry(2i) expiry(1i)])
      # end
    end
  end
end
