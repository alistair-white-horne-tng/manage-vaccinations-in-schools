# frozen_string_literal: true

module Inspect
  module Graph
    class GraphsController < ApplicationController
      skip_after_action :verify_policy_scoped

      def show
        # TODO: make sure the input arguments are safe (eg no code execution)

        @object =
          params[:object_type].classify.constantize.find(params[:object_id])

        # Generate graph
        @traversals_config = build_traversals_config
        @graph_params = build_graph_params

        @mermaid =
          GraphRecords
            .new(
              traversals_config: build_traversals_config,
              node_order: %i[
                programme
                session
                class_import
                cohort_import
                patient
                consent
                parent_relationship
                parent
              ] # TODO: make this work with all types
            )
            .graph(**@graph_params)
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

      def build_graph_params
        # Build the graph params
        graph_params = { params[:object_type].to_sym => [@object.id] }

        # Add additional IDs from the form
        if params[:additional_ids].present?
          params[:additional_ids].each do |type, ids_string|
            next if ids_string.blank?
            additional_ids = ids_string.split(",").map { |s| s.strip.to_i }
            next unless additional_ids.any?
            type_sym = type.to_sym
            graph_params[type_sym] ||= []
            graph_params[type_sym].concat(additional_ids)
          end
        end

        graph_params
      end

      # def show_params
      #   params.expect(batch: %i[name expiry(3i) expiry(2i) expiry(1i)])
      # end
    end
  end
end
