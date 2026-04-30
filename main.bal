// Copyright (c) 2026 WSO2 LLC. (http://www.wso2.org).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

// Walks the public surface area of the BEP-1441 envelope-aware EDI APIs
// against a real D03A ORDERS sample.
//
// Generated with the BEP-1441 envelope-aware tool against `ballerina/edi
// 1.6.0`. Compared with the previous commit (the OLD-tool baseline), the
// schema gained a structured `envelope` field, the codegen output gained
// `OrdersInterchange` / `OrdersTransaction` typed wrappers and an
// `interchangeFromEdiString` entry point, and this driver gained four new
// tiers of access: schema-free header peek, schema-driven envelope-only
// parse, fully typed hierarchical interchange parse with fail-safe per-
// transaction body, and the existing body parse.

import ballerina/edi;
import ballerina/io;

import demo/edifact_d03_orders.d03orders;

public function main() returns error? {
    string ediText = check io:fileReadString("sample.edi");

    // 1. Body parse via the generated typed wrapper. Available with both the
    //    OLD and NEW tools — the existing API surface.
    d03orders:ORDERS body = check d03orders:fromEdiString(ediText);
    io:println("Parsed ORDERS body. BGM: ", body.Beginning_of_message);

    // 2. Schema-free EDIFACT header peek. New in BEP-1441; no schema needed.
    edi:EdifactHeaders headers = check edi:edifactHeadersFromEdiString(ediText);
    io:println("Sender: ", headers.unb.sender.id, " | Control ref: ", headers.unb.controlRef);
    edi:EdifactUNH? unh = headers?.unh;
    if unh is edi:EdifactUNH {
        io:println("Message type: ", unh.messageIdentifier.messageType,
                "/", unh.messageIdentifier.version, unh.messageIdentifier.release);
    }

    // 3. Schema-driven envelope-only parse via the generated typed wrapper.
    //    Returns a fully typed `ORDERSHeaders` record — no `json` on the surface.
    d03orders:ORDERSHeaders envHeaders = check d03orders:headersFromEdiString(ediText);
    io:println("Schema-driven UNB control reference: ",
            envHeaders.interchange.interchange_header.control_reference);

    // 4. Hierarchical interchange parse with fail-safe per-transaction body.
    //    All envelope segments and bodies are typed (no `json` on the surface).
    d03orders:ORDERSInterchange ix = check d03orders:interchangeFromEdiString(ediText);
    io:println("Interchange has ", ix.transactions.length(), " transaction(s).");
    foreach var t in ix.transactions {
        d03orders:ORDERS|error parsed = t.body;
        if parsed is error {
            io:println("  - quarantined: ", parsed.message());
            continue;
        }
        io:println("  - parsed body. BGM: ", parsed.Beginning_of_message);
    }
}
