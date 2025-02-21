# frozen_string_literal: true

describe GraphRecords do
  subject(:graph) do
    described_class.new(traversals_config: traversals_config)
                   .graph(patients: [patient])
  end

  let(:traversals_config) do
    {
      patient: %i[parents consents class_imports cohort_imports],
      parent: %i[consents class_imports cohort_imports],
      consent: %i[patient]
    }
  end

  let!(:programmes) { [create(:programme, :hpv)] }
  let!(:organisation) { create(:organisation, programmes:) }
  let!(:session) { create(:session, organisation:, programmes:) }
  let!(:class_import) { create(:class_import, session:) }
  let!(:cohort_import) { create(:cohort_import, organisation:) }
  let!(:parent) do
    create(
      :parent,
      class_imports: [class_import],
      cohort_imports: [cohort_import]
    )
  end
  let!(:patient) do
    create(
      :patient,
      parents: [parent],
      session:,
      organisation:,
      programmes:,
      class_imports: [class_import],
      cohort_imports: [cohort_import]
    )
  end
  let!(:consent) do
    create(
      :consent,
      :given,
      patient:,
      parent:,
      organisation:,
      programme: programmes.first
    )
  end

  it { should start_with "flowchart TB" }

  it "generates the graph" do
    expect(graph).to contain_exactly(
      "flowchart TB",
      "  classDef patient_focused fill:#c2e598,stroke:#000,stroke-width:3px",
      "  classDef parent fill:#faa0a0",
      "  classDef consent fill:#fffaa0",
      "  classDef class_import fill:#7fd7df",
      "  classDef cohort_import fill:#a2d2ff",
      "  patient-#{patient.id}:::patient_focused",
      "  parent-#{parent.id}:::parent",
      "  consent-#{consent.id}:::consent",
      "  class_import-#{class_import.id}:::class_import",
      "  cohort_import-#{cohort_import.id}:::cohort_import",
      "  patient-#{patient.id} --> parent-#{parent.id}",
      "  consent-#{consent.id} --> parent-#{parent.id}",
      "  class_import-#{class_import.id} --> parent-#{parent.id}",
      "  cohort_import-#{cohort_import.id} --> parent-#{parent.id}",
      "  patient-#{patient.id} --> consent-#{consent.id}",
      "  class_import-#{class_import.id} --> patient-#{patient.id}",
      "  cohort_import-#{cohort_import.id} --> patient-#{patient.id}"
    )
  end

  context "when node limit is exceeded" do
    subject(:graph_exceeded) do
      described_class.new(
        traversals_config: traversals_config,
        node_limit: 1  # A very low limit to trigger recursion limit early
      ).graph(patients: [patient])
    end

    it "returns a fallback Mermaid diagram with the error message in a red box" do
      error_message = "Recursion limit of 1 nodes has been exceeded. Try restricting the graph."
      expect(graph_exceeded).to include("flowchart TB")
      # Assuming the error node is named `error` we check its content.
      expect(graph_exceeded.join).to include("error[#{error_message}]")
      expect(graph_exceeded.join).to include("style error fill:#f88,stroke:#f00,stroke-width:2px")
    end
  end
end
