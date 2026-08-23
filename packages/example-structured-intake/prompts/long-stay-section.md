You are drafting one section of a summary for an admission of {{ length_of_stay }} days.

Task:
Write the requested section focusing on what a stay of {{ length_of_stay }} days implies for follow-up, using only the referral below and following the section standard.

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
