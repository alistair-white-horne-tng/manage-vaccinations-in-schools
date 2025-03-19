# frozen_string_literal: true

require "digest"

# Spit out a Mermaid-style graph of records.
#
# Usage:
#  graph = GraphRecords.new.graph(patients: [patient])
#  puts graph
#
class GraphRecords
  BOX_STYLES = %w[
    fill:#e6194B,color:white
    fill:#3cb44b,color:black
    fill:#ffe119,color:black
    fill:#4363d8,color:white
    fill:#f58231,color:black
    fill:#911eb4,color:white
    fill:#42d4f4,color:black
    fill:#f032e6,color:white
    fill:#bfef45,color:black
    fill:#fabed4,color:black
    fill:#469990,color:white
    fill:#dcbeff,color:black
    fill:#9A6324,color:white
    fill:#fffac8,color:black
    fill:#800000,color:white
    fill:#aaffc3,color:black
    fill:#808000,color:white
    fill:#ffd8b1,color:black
    fill:#000075,color:white
    fill:#a9a9a9,color:black
    fill:#ffffff,color:black
    fill:#000000,color:white
  ].freeze

  DEFAULT_NODE_ORDER = %i[
    programme
    class_import
    cohort_import
    organisation
    team
    location
    session
    patient_session
    patient
    vaccine
    batch
    vaccination_record
    triage
    user
    consent
    consent_form
    parent_relationship
    parent
  ].freeze

  # @param focus_config [Hash] Hash of model names to ids to focus on (make bold)
  # @param node_order [Array] Array of model names in order to render nodes
  # @param traversals_config [Hash] Hash of model names to arrays of associations to traverse
  # @param node_limit [Integer] The maximum number of nodes which can be displayed
  def initialize(
    focus_config: {},
    node_order: DEFAULT_NODE_ORDER,
    traversals_config: {},
    node_limit: 100
  )
    @focus_config = focus_config
    @node_order = node_order
    @traversals_config = traversals_config
    @node_limit = node_limit
  end

  # @param objects [Hash] Hash of model name to ids to be graphed
  def graph(**objects)
    @nodes = Set.new
    @edges = Set.new
    @inspected = Set.new
    @focus = @focus_config.map { _1.to_s.classify.constantize.where(id: _2) }

    begin
      objects.map do |klass, ids|
        class_name = klass.to_s.singularize
        associated_objects =
          load_association(class_name.classify.constantize.where(id: ids))

        @focus += associated_objects

        associated_objects.each do |obj|
          @nodes << obj
          introspect(obj)
        end
      end
      ["flowchart TB"] + render_styles + render_nodes + render_edges + render_clicks
    rescue StandardError => e
      if e.message.include?("Recursion limit")
        # Create a Mermaid diagram with a red box containing the error message.
        [
          "flowchart TB",
          "    error[#{e.message}]",
          "    style error fill:#f88,stroke:#f00,stroke-width:2px"
        ]
      else
        raise e
      end
    end
  end

  def traversals
    @traversals ||= {
      patient: %i[parents consents cohort_imports vaccination_records sessions],
      parent: %i[patients consents],
      consent: %i[consent_form patient parent],
    }.merge(@traversals_config)
  end

  def render_styles
    # object_types = %i[session programme patient parent consent class_import cohort_import]
    object_types =
      @nodes.to_a.map { |node| node.class.name.underscore.to_sym }.uniq

    styles =
      object_types.each_with_object({}) do |type, hash|
        color_index =
          Digest::MD5.hexdigest(type.to_s).to_i(16) % BOX_STYLES.length
        hash[type] = "#{BOX_STYLES[color_index]},stroke:#000"
      end

    focused_styles =
      styles.each_with_object({}) do |(type, style), hash|
        hash["#{type}_focused"] = "#{style},stroke-width:3px"
      end

    styles.merge!(focused_styles)

    styles
      .with_indifferent_access
      .slice(*(@nodes.map { class_text_for_obj(it) }))
      .map { |klass, style| "  classDef #{klass} #{style}" }
  end

  def render_nodes
    @nodes.to_a.map { "  #{node_with_class(it)}" }
  end

  def render_edges
    @edges.map { |from, to| "  #{node_name(from)} --> #{node_name(to)}" }
  end

  def render_clicks
    @nodes.to_a.map { "  click #{node_name(it)} \"#{node_link(it)}\"" }
  end

  def introspect(obj)
    associations_list = traversals[obj.class.name.underscore.to_sym]
    return if associations_list.blank?

    return if @inspected.include?(obj)
    @inspected << obj

    associations_list.each do
      get_associated_objects(obj, it).each do
        @nodes << it
        @edges << order_nodes(obj, it)

        if @nodes.length > @node_limit
          raise "Recursion limit of #{@node_limit} nodes has been exceeded. Try restricting the graph."
        end

        introspect(it)
      end
    end
  end

  def get_associated_objects(obj, association_name)
    obj
      .send(association_name)
      .then { |associated_objects| load_association(associated_objects) }
  end

  def load_association(associated_objects)
    Array(
      if associated_objects.is_a?(ActiveRecord::Relation)
        associated_objects.strict_loading!(false)
      else
        associated_objects
      end
    )
  end

  def order_nodes(*nodes)
    nodes.sort_by do |node|
      @node_order.index(node.class.name.underscore.to_sym) || Float::INFINITY
    end
  end

  def node_link(obj)
    base_endpoint = Rails.application.routes.default_url_options[:host]

    "#{base_endpoint}/inspect/graph/#{obj.class.name.underscore}/#{obj.id}"
  end

  def node_name(obj)
    # TODO: decide if sometimes details about the object can be displayed as well; if the info isn't PII ->
    # Eg organisation name
    klass = obj.class.name.underscore
    "#{klass}-#{obj.id}"
  end

  def node_with_class(obj)
    "#{node_name(obj)}:::#{class_text_for_obj(obj)}"
  end

  def class_text_for_obj(obj)
    obj.class.name.underscore + (obj.in?(@focus) ? "_focused" : "")
  end
end
