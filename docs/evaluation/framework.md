# Evaluation Framework

The platform uses RAGAS (Retrieval-Augmented Generation Assessment) for systematic quality evaluation.

**Owner**: M10 · **Directory**: `evaluation/`

## Overview

The evaluation framework tests three dimensions:

1. **Answer Quality** — Are the generated answers faithful and relevant?
2. **Retrieval Quality** — Are the right chunks being retrieved?
3. **System Integrity** — Is multi-tenant isolation enforced?

## Q&A Dataset

Located at `evaluation/qa_dataset.jsonl` — 30 curated question-answer pairs.

### Format

```json
{
  "question": "How do I reset the Bosch dishwasher?",
  "ground_truth": "Press and hold the Start button for 3 seconds...",
  "expected_source_document": "bosch_manual.pdf",
  "expected_source_page": 12,
  "type": "factoid"
}
```

### Question Types

| Type | Count | Description |
|:-----|:------|:------------|
| Factoid | ~10 | Direct factual questions with single-source answers |
| Multi-hop | ~10 | Questions requiring reasoning across multiple chunks |
| Negative | ~10 | Questions where the answer is NOT in the documents |

## Sample Data

Located at `evaluation/sample-data/` — organized by application domain:

- `customer_support/` — support guides
- `it_helpdesk/` — IT SOPs
- `equipment_maintenance/` — maintenance manuals
- `bug-reporting/` — triage playbooks
- `compliance_policy/` — policy documents
- And 7 more domains (12 total)

## Running Evaluations

```bash
cd evaluation
pip install -r requirements.txt

# Validate dataset integrity
python validate_dataset.py

# Run full RAGAS evaluation
python run_eval.py --api-url https://rag-platform-production.up.railway.app

# Run multi-application benchmark suite
python run_test_suite.py
```

## Evaluation Script (`run_eval.py`)

1. Ingest test documents into a test tenant
2. Run all 30 questions through `POST /chat/query`
3. Collect `{question, answer, contexts, ground_truth}` tuples
4. Compute RAGAS metrics
5. Generate report as `artifacts/evaluation_results/report_{timestamp}.json`

## Integration Tests

```bash
# Auth + API integration tests
pytest tests/test_auth.py -v

# Evaluation dataset validation
pytest tests/test_evaluation_dataset.py -v
```

### Multi-Tenant Isolation Test

```python
def test_tenant_a_cannot_see_tenant_b_docs():
    # 1. Create Tenant A + upload doc_a.pdf
    # 2. Create Tenant B + upload doc_b.pdf
    # 3. Query as Tenant A for content ONLY in doc_b.pdf
    # 4. Assert: answer is "I don't have enough information..."
    # 5. Assert: sources list is empty
```

## Load Testing (Stretch Goal)

Using Locust — 20 concurrent users for 5 minutes on `/chat/query`:
- Record p50, p95, p99 latency
- Verify no errors under load
- Results saved to `evaluation/RESULTS.md`
