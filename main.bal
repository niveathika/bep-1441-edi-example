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

// Walks the public surface area of the generated `d03orders` module.
//
// Generated with `bal edi 2.1.0` (the published edi-tools). The OLD tool
// emits a single body record + `fromEdiString` / `toEdiString`; envelope
// segments are stripped via `ignoreSegments: ["UNB"]` in the schema. The
// caller has no schema-free / schema-driven envelope APIs to call.

import ballerina/io;

import demo/edifact_d03_orders.d03orders;

public function main() returns error? {
    string ediText = check io:fileReadString("sample.edi");

    // The only API surface exposed by the OLD-tool generated module.
    d03orders:ORDERS body = check d03orders:fromEdiString(ediText);
    io:println("Parsed ORDERS body. BGM: ", body.Beginning_of_message);
    io:println("DTM count: ", body.Date_time_period.length());
}
