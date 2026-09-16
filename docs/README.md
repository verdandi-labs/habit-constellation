# docs/README.md

| Doc | Status | Holds |
|---|---|---|
| `product-spec.md` | FROZEN v1 | screens, states, interactions, copy |
| `style.md` | LIVING | all visual values — changes freely |
| `api-contract.md` | FROZEN v1 | endpoint contract |
| `data-model.md` | FROZEN v1 | schema, indexes, migrations |
| `decisions.md` | append-only | decision log (ADR-01…20) |
| `testing.md` | LIVING | test plan + harness |

**Rules:** the product spec refers to visual things by name, never by value — values live in `style.md`. Frozen docs change only in the same commit as the code. Decisions are never edited, only appended.
