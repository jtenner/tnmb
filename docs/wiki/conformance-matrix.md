# Conformance Matrix

This matrix maps current source-of-truth requirements to fixture test coverage. The tests are still fixture-first: they document expectations before production parser, encoder, negotiator, and option-codec APIs exist.

| Requirement area | Source | Test files | Status |
|---|---|---|---|
| RFC 854 command bytes and IAC framing | RFC 854 | `telnet_test.mbt`, `telnet_generated_cases_test.mbt`, `telnet_matrix_generated_test.mbt` | Fixture coverage |
| Data, escaped IAC, command/data ordering | RFC 854 | `telnet_test.mbt`, `telnet_edge_cases_test.mbt`, `telnet_comprehensive_spec_test.mbt` | Fixture coverage |
| Subnegotiation framing and escaped IAC in payloads | RFC 854/RFC 855 | `telnet_test.mbt`, `telnet_edge_cases_test.mbt`, `telnet_blind_spots_test.mbt` | Fixture coverage |
| Incomplete parser states and parser recovery | RFC 854 + project policy | `telnet_test.mbt`, `telnet_edge_cases_test.mbt`, `telnet_blind_spots_test.mbt` | Fixture coverage |
| Strict vs lenient command policy | Project policy | `telnet_comprehensive_spec_test.mbt`, `telnet_blind_spots_test.mbt` | Fixture coverage |
| NVT CR/LF/CR-NUL policy | RFC 854 + project policy | `telnet_comprehensive_spec_test.mbt`, `telnet_blind_spots_test.mbt` | Fixture coverage |
| BINARY directional behavior | RFC 856 | `telnet_comprehensive_spec_test.mbt`, `telnet_blind_spots_test.mbt` | Fixture coverage |
| ECHO and SUPPRESS-GO-AHEAD negotiation | RFC 857/RFC 858 | `telnet_test.mbt`, `telnet_scenarios_test.mbt` | Fixture coverage |
| RFC 1143 Q-method receiving transitions | RFC 1143 | `telnet_test.mbt`, `telnet_matrix_generated_test.mbt`, `telnet_blind_spots_test.mbt` | Fixture coverage |
| RFC 1143 local initiation transitions | RFC 1143 | `telnet_comprehensive_spec_test.mbt`, `telnet_blind_spots_test.mbt` | Fixture coverage |
| Option side validity policy | RFC option docs + project policy | `telnet_scenarios_test.mbt` | Fixture coverage |
| TERMINAL-TYPE | RFC 1091 | `telnet_test.mbt`, `telnet_comprehensive_spec_test.mbt`, `telnet_blind_spots_test.mbt`, `telnet_scenarios_test.mbt` | Fixture coverage |
| NAWS | RFC 1073 | `telnet_test.mbt`, `telnet_comprehensive_spec_test.mbt`, `telnet_blind_spots_test.mbt`, `telnet_scenarios_test.mbt` | Fixture coverage |
| NEW-ENVIRON | RFC 1572 | `telnet_test.mbt`, `telnet_comprehensive_spec_test.mbt`, `telnet_blind_spots_test.mbt` | Fixture coverage |
| CHARSET | RFC 2066 | `telnet_test.mbt`, `telnet_comprehensive_spec_test.mbt`, `telnet_blind_spots_test.mbt` | Fixture coverage |
| LINEMODE | RFC 1184 | `telnet_test.mbt`, `telnet_comprehensive_spec_test.mbt`, `telnet_blind_spots_test.mbt` | Fixture coverage |
| START_TLS state boundary | RFC 2946 + project security policy | `telnet_test.mbt`, `telnet_edge_cases_test.mbt`, `telnet_blind_spots_test.mbt`, `telnet_scenarios_test.mbt` | Fixture coverage |
| Encoder canonicalization and sizing | RFC 854 + project performance policy | `telnet_test.mbt`, `telnet_comprehensive_spec_test.mbt`, `telnet_blind_spots_test.mbt`, `telnet_scenarios_test.mbt` | Fixture coverage |
| Hostile/stress inputs | Project security policy | `telnet_comprehensive_spec_test.mbt`, `telnet_scenarios_test.mbt` | Fixture coverage |
| Public API contracts | Project API policy | `telnet_blind_spots_test.mbt` | Contract fixtures only |

## Remaining status labels

- **Fixture coverage**: Expected data and policy are represented, but production APIs are not called yet.
- **Contract fixtures only**: Future API names and behavior are described as strings or data, not real symbols.
- **Behavioral coverage**: Future state where tests call implementation functions directly.

Before release, all major rows should move from fixture coverage to behavioral coverage.
