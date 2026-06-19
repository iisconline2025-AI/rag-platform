# Quality Metrics

## RAGAS Metrics

The platform is evaluated using four standard RAGAS metrics plus two platform-specific metrics.

### Faithfulness

> Are the claims in the answer supported by the retrieved context?

- **Target**: ≥ 0.85
- **How it works**: Each claim in the generated answer is checked against the retrieved chunks. The score is the fraction of claims that have supporting evidence.
- **Stored on**: `chat_messages.faithfulness` column

### Answer Relevancy

> Does the answer address the question that was asked?

- **Target**: ≥ 0.80
- **How it works**: Measures semantic similarity between the question and the generated answer. A high score means the answer is on-topic.

### Context Precision

> Are the retrieved chunks relevant to the question?

- **Target**: ≥ 0.75
- **How it works**: Measures what fraction of retrieved chunks are actually relevant to answering the question. High precision means less noise in the context window.

### Context Recall

> Does the expected source document appear in the top-K results?

- **Target**: ≥ 0.80
- **How it works**: Checks if the ground-truth source document appears in the retrieved chunks. A recall of 1.0 means the expected document was always retrieved.

## Platform-Specific Metrics

### Citation Coverage

> What fraction of answers include at least one source citation?

- **Target**: ≥ 90%
- **How it works**: Counts answers where `sources` array is non-empty.

### Tenant Isolation

> Can Tenant A ever see Tenant B's documents?

- **Target**: 100% (zero cross-tenant leaks)
- **How it works**: Creates two tenants with distinct documents, queries from one tenant for content only in the other's documents, and asserts empty results.

## Acceptance Criteria

| Metric | Minimum Bar |
|:-------|:-----------|
| Faithfulness | ≥ 0.80 |
| Answer Relevancy | ≥ 0.75 |
| Citation Coverage | ≥ 85% |
| Tenant Isolation | 100% |
| API Tests Passing | ≥ 90% |
| Load Test (10 concurrent) | < 30s per query |

## Faithfulness UI Badge

The frontend displays a color-coded badge based on the faithfulness score:

| Score | Color | Meaning |
|:------|:------|:--------|
| ≥ 0.85 | Green | High confidence — well grounded |
| 0.70–0.84 | Yellow | Moderate — some claims may lack support |
| < 0.70 | Red | Low confidence — was retried with stronger model |
