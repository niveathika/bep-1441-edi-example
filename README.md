# EDIFACT D03A ORDERS — BEP-1441 OLD/NEW comparison

A self-contained Ballerina project that parses a single EDIFACT D03A ORDERS interchange. Used to demonstrate the diff between the pre- and post-BEP-1441 generated code, and to drive the four-cell OLD/NEW × tool/module compatibility matrix.

The repository's git history has exactly two commits:

1. **OLD tool, OLD module** — generated with `bal edi 2.1.0` (the published version on Ballerina Central) against `ballerina/edi 1.5.3`. The codegen output is body-only (no envelope), the schema strips envelope segments via `ignoreSegments`, and `main.bal` has only `fromEdiString` / `toEdiString` to call.

2. **NEW tool, NEW module** — regenerated with `bal edi 2.2.0` (the BEP-1441 envelope-aware tool) against `ballerina/edi 1.6.0`. The schema gains a structured `envelope`, the codegen output exposes typed `OrdersInterchange` / `OrdersTransaction` records, and `main.bal` exercises every public API (schema-free header peek, schema-driven envelope parse, hierarchical interchange parse with fail-safe per-transaction body, plus the existing body parse).

Each commit's `git diff HEAD~1` is the exact change the user sees when they regenerate with the new tool.

## Files

| Path | Purpose |
|---|---|
| `sample.edi` | One D03A ORDERS interchange — UNB / UNH / BGM / DTM / NAD / LIN / QTY / CNT / UNT / UNZ. |
| `schemas/ORDERS.json` | Generated schema. Old shape vs. new shape is the bulk of the diff. |
| `modules/d03orders/orders.bal` | Generated typed records and parser functions. |
| `main.bal` | Driver that exercises the available public APIs. |
| `Ballerina.toml` | Project manifest. The `[[dependency]]` block on `ballerina/edi` switches between `1.5.3` (Central) and `1.6.0` (local repo, NEW). |

## Run it

```bash
bal run
```

## Compatibility matrix

The OLD/NEW × tool/module 2×2 is exercised by toggling two knobs:

* The active `bal edi` tool (`bal tool use edi:<version>`).
* The pinned `ballerina/edi` dependency in `Ballerina.toml`.

See `MATRIX.md` (added at the end of the BEP-1441 implementation) for the full results.
