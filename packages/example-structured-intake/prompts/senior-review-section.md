You are drafting one section of a senior review request for a patient aged {{ patient.age }}{{ if patient.sex }} ({{ patient.sex }}){{ end }}.

Task:
Write the requested section as a concise request for senior clinician review, using only the referral below and following the section standard.

Guardrail:
Do not add clinical facts the referral does not contain.

Output rule:
Return only prose for the requested section. No heading, JSON, markdown, bullets, or commentary.

Requested section:
{{ section_name }}

Section standard:
{{ section_standard }}

Referral:
{{ consult_draft }}
