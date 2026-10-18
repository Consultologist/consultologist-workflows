section_name block:
{{ item.name }}

patient_trajectory_concepts block:
{{ node.create_patient_trajectory.content | concept_context }}