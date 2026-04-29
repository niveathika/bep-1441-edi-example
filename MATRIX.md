# BEP-1441 OLD/NEW × tool/module compatibility matrix

Each cell was driven against this directory's `sample.edi` from clean (`rm -rf target Dependencies.toml`) using the two committed states (`HEAD~1` = OLD tool, `HEAD` = NEW tool) and a per-cell `[[dependency]]` block on `ballerina/edi`.

| Cell | edi-tools | ballerina/edi | Result |
|---|---|---|---|
| 1 | 2.1.0 (Central, OLD) | 1.6.0 (local, NEW) | ✅ build + run |
| 2 | 2.2.0 (local, NEW)   | 1.6.0 (local, NEW) | ✅ build + run, all four API tiers exercised |
| 3 | 2.1.0 (Central, OLD) | 1.5.3 (Central, OLD) | ✅ build + run (baseline) |
| 4 | 2.2.0 (local, NEW)   | 1.5.3 (Central, OLD) | ❌ compile-time errors — `EdifactHeaders`, `headersFromEdiString`, `interchangeFromEdiString` not found |

## Cell 1 — NEW module + OLD-tool libs

**Setup**

```bash
git checkout HEAD~1            # OLD-tool generated lib + schema
# Ballerina.toml: [[dependency]] org="ballerina" name="edi" version="1.6.0" repository="local"
rm -rf target Dependencies.toml
bal run
```

**Result**

```
Parsed ORDERS body. BGM: {"code":"BGM","DOCUMENT_MESSAGE_NAME":{"Document_name_code":"220"},"DOCUMENT_MESSAGE_IDENTIFICATION":{"Document_identifier":"PO12345"},"MESSAGE_FUNCTION_CODE":"9"}
DTM count: 2
```

The OLD-tool schema has no `envelope` field, so `fromEdiString` falls through the runtime's backward-compat path. Verifies the additivity claim: upgrading the runtime alone does not break existing generated code.

## Cell 2 — NEW everything

**Setup**

```bash
git checkout main                  # NEW-tool generated lib + schema
# Ballerina.toml: [[dependency]] ... edi 1.6.0 (local)
bal run
```

**Result**

```
Parsed ORDERS body. BGM: {"code":"BGM",...}
Sender: SENDER | Control ref: REF1
Message type: ORDERS/D03A
Schema-driven headers JSON: {"interchange":{...},"transaction":{...}}
Interchange has 1 transaction(s).
  - parsed body. BGM: {"code":"BGM",...}
```

Exercises all four API tiers — the existing body parse, the schema-free EDIFACT header peek, the schema-driven envelope-only parse, and the typed hierarchical interchange parse. No `json` fields are visible to the user on the generated wrappers.

## Cell 3 — OLD module + OLD-tool libs (baseline)

**Setup**

```bash
git checkout HEAD~1
# Ballerina.toml: no [[dependency]] block — resolves edi 1.5.3 from Central
rm -rf target Dependencies.toml
bal run
```

**Result**

```
Parsed ORDERS body. BGM: {"code":"BGM",...}
DTM count: 2
```

Pre-BEP-1441 baseline; nothing has changed. (One pre-existing limitation worth noting: the OLD generator emits `ignoreSegments: ["UNB"]` only — UNZ has to be added by hand for `fromEdiString` to accept a full interchange. The OLD-tool commit's schema includes that manual patch. The NEW tool removes the need for it entirely by lifting all envelope segments out of the body.)

## Cell 4 — OLD module + NEW-tool libs

**Setup**

```bash
git checkout main
# Ballerina.toml: [[dependency]] ... edi 1.5.3 (Central)
rm -rf target Dependencies.toml
bal run
```

**Result**

```
ERROR [modules/d03orders/orders.bal:(56:12,56:56)] undefined function 'headersFromEdiString'
ERROR [modules/d03orders/orders.bal:(68:5,68:23)] unknown type 'EdiInterchange'
ERROR [modules/d03orders/orders.bal:(68:36,68:84)] undefined function 'interchangeFromEdiString'
ERROR [main.bal:(43:5,43:23)] unknown type 'EdifactHeaders'
ERROR [main.bal:(43:40,43:80)] undefined function 'edifactHeadersFromEdiString'
ERROR [main.bal:(45:5,45:19)] unknown type 'EdifactUNH'
ERROR [main.bal:(46:15,46:29)] unknown type 'EdifactUNH'
error: compilation contains errors
```

Compile-time failure with explicit "undefined function / unknown type" errors pointing at exactly the BEP-1441 surface area. The `bal edi libgen` post-generation notice ("Generated library uses envelope-aware schema and APIs from ballerina/edi 1.6.0 …") flags this before the user even runs `bal build`.
