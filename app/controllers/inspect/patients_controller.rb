# frozen_string_literal: true

module Inspect
  class PatientsController < ApplicationController
    def show
      @patient = policy_scope(Patient).find(params[:patient_id])
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
  class_import-3862:::class_import --> patient-16390:::patient_highlighted" #policy_scope(GraphPatient).call(@patient.id)
    end
  end
end
