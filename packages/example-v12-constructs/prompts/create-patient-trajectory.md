{{ snippet.snomed_tool_guidance.content }}

problem_concepts block:
{{ node.identify_problem.content | concept_bullets }}

patient_concepts block:
{{ node.extract_patient_concepts.content | concept_bullets }}

typical_trajectory_concepts block:
{{ node.create_typical_trajectory.content | concept_bullets }}