# Conformance Matrix

This matrix maps current source-of-truth requirements to executable behavioral coverage. Fixture-only/self-equality tests have been removed; test files listed here call production APIs directly.

| Requirement area | Source | Test files | Status |
|---|---|---|---|
| RFC 854 command bytes and IAC framing | RFC 854 | `telnet_test.mbt`, `telnet_behavior_tdd_test.mbt`, `telnet_expanded_behavior_tdd_test.mbt` | Behavioral coverage |
| Data, escaped IAC, command/data ordering | RFC 854 | `telnet_test.mbt`, `telnet_edge_cases_test.mbt`, `telnet_behavior_tdd_test.mbt`, `telnet_expanded_behavior_tdd_test.mbt` | Behavioral coverage |
| Subnegotiation framing and escaped IAC in payloads | RFC 854/RFC 855 | `telnet_test.mbt`, `telnet_edge_cases_test.mbt`, `telnet_behavior_tdd_test.mbt`, `telnet_expanded_behavior_tdd_test.mbt` | Behavioral coverage |
| Incomplete parser states and parser recovery | RFC 854 + project policy | `telnet_test.mbt`, `telnet_edge_cases_test.mbt`, `telnet_behavior_tdd_test.mbt`, `telnet_expanded_behavior_tdd_test.mbt` | Behavioral coverage |
| Strict vs lenient command policy | Project policy | `telnet_behavior_tdd_test.mbt`, `telnet_expanded_behavior_tdd_test.mbt` | Behavioral coverage |
| NVT CR/LF/CR-NUL policy | RFC 854 + project policy | `telnet_expanded_behavior_tdd_test.mbt`, `telnet_policy_blind_spots_tdd_test.mbt` | Behavioral coverage |
| BINARY directional behavior | RFC 856 | `telnet_policy_blind_spots_tdd_test.mbt` | Behavioral coverage |
| ECHO and SUPPRESS-GO-AHEAD negotiation | RFC 857/RFC 858 | `telnet_test.mbt`, `telnet_behavior_tdd_test.mbt` | Behavioral coverage |
| RFC 1143 Q-method receiving transitions | RFC 1143 | `telnet_test.mbt`, `telnet_behavior_tdd_test.mbt`, `telnet_expanded_behavior_tdd_test.mbt` | Behavioral coverage |
| RFC 1143 local initiation transitions | RFC 1143 | `telnet_behavior_tdd_test.mbt`, `telnet_expanded_behavior_tdd_test.mbt`, `telnet_policy_blind_spots_tdd_test.mbt` | Behavioral coverage |
| TERMINAL-TYPE | RFC 1091 | `telnet_test.mbt`, `telnet_edge_cases_test.mbt`, `telnet_behavior_tdd_test.mbt`, `telnet_expanded_behavior_tdd_test.mbt` | Behavioral coverage |
| NAWS | RFC 1073 | `telnet_test.mbt`, `telnet_edge_cases_test.mbt`, `telnet_behavior_tdd_test.mbt`, `telnet_expanded_behavior_tdd_test.mbt` | Behavioral coverage |
| NEW-ENVIRON | RFC 1572 | `telnet_test.mbt`, `telnet_edge_cases_test.mbt`, `telnet_behavior_tdd_test.mbt`, `telnet_expanded_behavior_tdd_test.mbt` | Behavioral coverage |
| CHARSET | RFC 2066 | `telnet_test.mbt`, `telnet_edge_cases_test.mbt`, `telnet_behavior_tdd_test.mbt`, `telnet_expanded_behavior_tdd_test.mbt` | Behavioral coverage |
| LINEMODE | RFC 1184 | `telnet_test.mbt`, `telnet_edge_cases_test.mbt`, `telnet_behavior_tdd_test.mbt`, `telnet_expanded_behavior_tdd_test.mbt` | Behavioral coverage |
| START_TLS state boundary | RFC 2946 + project security policy | `telnet_test.mbt`, `telnet_edge_cases_test.mbt`, `telnet_behavior_tdd_test.mbt`, `telnet_expanded_behavior_tdd_test.mbt`, `telnet_policy_blind_spots_tdd_test.mbt` | Behavioral coverage |
| Encoder canonicalization and sizing | RFC 854 + project performance policy | `telnet_test.mbt`, `telnet_edge_cases_test.mbt`, `telnet_behavior_tdd_test.mbt`, `telnet_expanded_behavior_tdd_test.mbt`, `telnet_missing_behavior_tdd_test.mbt` | Behavioral coverage |
| Public API contracts and hardening | Project API/security policy | `telnet_missing_behavior_tdd_test.mbt`, `telnet_policy_blind_spots_tdd_test.mbt`, `tools/check-test-tautologies.sh` | Behavioral coverage + CI guard |
