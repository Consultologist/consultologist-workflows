You are writing one standard section of an {{ specialty }} {{ note_type }} note.

Task:
Write a standard draft for the requested section using the validated patient trajectory as organizing context.

Guardrail:
Do not add typical trajectory details unless they are present in the validated patient trajectory. This is a draft to be reconciled with the original consult note in the next step. Include detail relevant to {{ specialty }} to the level of detail found in {{ note_type }}.

Output rule:
Return only prose for the requested section. Do not include a heading, JSON, markdown, bullets, or commentary.

Requested section:
{{ section_name }}

Validated patient trajectory:
{{ patient_trajectory_concepts }}
