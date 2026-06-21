# RAG Evaluation Report

Generated: `2026-06-21T05:52:15.072679+00:00`

## Aggregate Results

| Metric | Score | Threshold | Pass |
|---|---:|---:|:---:|
| faithfulness | 0.860 | 0.850 | yes |
| answer_relevancy | 0.667 | 0.800 | no |
| context_precision | 0.934 | 0.750 | yes |
| context_recall | 1.000 | 0.800 | yes |

- Cases: 145
- Citation coverage: 1.000
- Negative abstention rate: 1.000
- Mean latency: 7331.884 ms
- p95 latency: 20717.970 ms

## Application Results

| Application | Cases | Faithfulness | Relevancy | Context precision | Context recall |
|---|---:|---:|---:|---:|---:|
| bug_reporting | 30 | 0.922 | 0.674 | 0.936 | 1.000 |
| compliance_policy | 8 | 0.857 | 0.747 | 0.885 | 1.000 |
| customer_support | 8 | 0.800 | 0.744 | 0.952 | 1.000 |
| developer_documentation | 7 | 0.857 | 0.633 | 0.976 | 1.000 |
| education_assistant | 8 | 0.833 | 0.826 | 1.000 | 1.000 |
| employee_onboarding | 8 | 0.857 | 0.635 | 0.952 | 1.000 |
| equipment_maintenance | 7 | 0.714 | 0.559 | 0.964 | 1.000 |
| healthcare_administration | 8 | 0.857 | 0.704 | 0.921 | 1.000 |
| incident_response | 7 | 0.833 | 0.669 | 0.935 | 1.000 |
| it_helpdesk | 8 | 1.000 | 0.734 | 0.942 | 1.000 |
| kubernetes_troubleshooting | 30 | 0.842 | 0.619 | 0.922 | 1.000 |
| legal_document_navigation | 8 | 1.000 | 0.734 | 0.943 | 1.000 |
| sales_enablement | 8 | 0.714 | 0.505 | 0.854 | 1.000 |

## Failed or Unscored Cases

| ID | Application | Category | Notes |
|---|---|---|---|
| K8S-EVAL-001 | kubernetes_troubleshooting | factoid | One or more RAGAS metrics were not produced |
| K8S-EVAL-002 | kubernetes_troubleshooting | procedural | One or more RAGAS metrics were not produced |
| K8S-EVAL-003 | kubernetes_troubleshooting | procedural | One or more RAGAS metrics were not produced |
| K8S-EVAL-004 | kubernetes_troubleshooting | procedural | One or more RAGAS metrics were not produced |
| K8S-EVAL-005 | kubernetes_troubleshooting | factoid | One or more RAGAS metrics were not produced |
| K8S-EVAL-012 | kubernetes_troubleshooting | procedural | One or more RAGAS metrics were not produced |
| K8S-EVAL-013 | kubernetes_troubleshooting | factoid | One or more RAGAS metrics were not produced |
| K8S-EVAL-014 | kubernetes_troubleshooting | procedural | One or more RAGAS metrics were not produced |
| K8S-EVAL-015 | kubernetes_troubleshooting | reasoning | One or more RAGAS metrics were not produced |
| K8S-EVAL-017 | kubernetes_troubleshooting | procedural | One or more RAGAS metrics were not produced |
| K8S-EVAL-020 | kubernetes_troubleshooting | multi_hop | One or more RAGAS metrics were not produced |
| K8S-EVAL-023 | kubernetes_troubleshooting | reasoning | One or more RAGAS metrics were not produced |
| K8S-EVAL-024 | kubernetes_troubleshooting | procedural | One or more RAGAS metrics were not produced |
| K8S-EVAL-025 | kubernetes_troubleshooting | multi_hop | One or more RAGAS metrics were not produced |
| K8S-EVAL-026 | kubernetes_troubleshooting | multi_hop | One or more RAGAS metrics were not produced |
| K8S-EVAL-027 | kubernetes_troubleshooting | multi_hop | One or more RAGAS metrics were not produced |
| K8S-EVAL-028 | kubernetes_troubleshooting | safety | One or more RAGAS metrics were not produced |
| BUG-EVAL-001 | bug_reporting | factoid | One or more RAGAS metrics were not produced |
| BUG-EVAL-002 | bug_reporting | factoid | One or more RAGAS metrics were not produced |
| BUG-EVAL-005 | bug_reporting | reasoning | One or more RAGAS metrics were not produced |
| BUG-EVAL-006 | bug_reporting | procedural | One or more RAGAS metrics were not produced |
| BUG-EVAL-008 | bug_reporting | safety | One or more RAGAS metrics were not produced |
| BUG-EVAL-010 | bug_reporting | reasoning | One or more RAGAS metrics were not produced |
| BUG-EVAL-011 | bug_reporting | factoid | One or more RAGAS metrics were not produced |
| BUG-EVAL-018 | bug_reporting | procedural | One or more RAGAS metrics were not produced |
| BUG-EVAL-019 | bug_reporting | multi_hop | One or more RAGAS metrics were not produced |
| BUG-EVAL-023 | bug_reporting | factoid | One or more RAGAS metrics were not produced |
| BUG-EVAL-024 | bug_reporting | factoid | One or more RAGAS metrics were not produced |
| BUG-EVAL-027 | bug_reporting | factoid | One or more RAGAS metrics were not produced |
| BUG-EVAL-028 | bug_reporting | procedural | One or more RAGAS metrics were not produced |
| IT_HELPDESK-002 | it_helpdesk | procedural | One or more RAGAS metrics were not produced |
| IT_HELPDESK-003 | it_helpdesk | procedural | One or more RAGAS metrics were not produced |
| IT_HELPDESK-006 | it_helpdesk | procedural | One or more RAGAS metrics were not produced |
| CUSTOMER_SUPPORT-005 | customer_support | procedural | One or more RAGAS metrics were not produced |
| CUSTOMER_SUPPORT-006 | customer_support | procedural | One or more RAGAS metrics were not produced |
| DEVELOPER_DOCUMENTATION-004 | developer_documentation | factoid | One or more RAGAS metrics were not produced |
| INCIDENT_RESPONSE-005 | incident_response | reasoning | One or more RAGAS metrics were not produced |
| COMPLIANCE_POLICY-004 | compliance_policy | procedural | One or more RAGAS metrics were not produced |
| COMPLIANCE_POLICY-006 | compliance_policy | reasoning | One or more RAGAS metrics were not produced |
| EDUCATION_ASSISTANT-003 | education_assistant | reasoning | One or more RAGAS metrics were not produced |
| EDUCATION_ASSISTANT-006 | education_assistant | procedural | One or more RAGAS metrics were not produced |
| HEALTHCARE_ADMINISTRATION-004 | healthcare_administration | safety | One or more RAGAS metrics were not produced |
| EQUIPMENT_MAINTENANCE-001 | equipment_maintenance | procedural | One or more RAGAS metrics were not produced |
| SALES_ENABLEMENT-006 | sales_enablement | procedural | One or more RAGAS metrics were not produced |
