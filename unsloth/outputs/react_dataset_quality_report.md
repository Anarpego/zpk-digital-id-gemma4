# ZPK ReAct Dataset Quality Report

Status: PASS

## train

- rows: 1640
- assistant_turns: 11476
- json_validity_rate: 1.0
- react_format_rate: 1.0
- tool_chain_completeness: 1.0
- pii_leak_rate: 0.0
- scenarios:
  - despido_sin_prestaciones: 332
  - estafa_remesa: 325
  - extorsion_telefono_sms: 327
  - igss_sin_dpi: 325
  - sat_acceso_bloqueado: 331

## validation

- rows: 180
- assistant_turns: 1250
- json_validity_rate: 1.0
- react_format_rate: 1.0
- tool_chain_completeness: 1.0
- pii_leak_rate: 0.0
- scenarios:
  - despido_sin_prestaciones: 34
  - estafa_remesa: 37
  - extorsion_telefono_sms: 31
  - igss_sin_dpi: 41
  - sat_acceso_bloqueado: 37

## test

- rows: 180
- assistant_turns: 1274
- json_validity_rate: 1.0
- react_format_rate: 1.0
- tool_chain_completeness: 1.0
- pii_leak_rate: 0.0
- scenarios:
  - despido_sin_prestaciones: 34
  - estafa_remesa: 38
  - extorsion_telefono_sms: 42
  - igss_sin_dpi: 34
  - sat_acceso_bloqueado: 32

## Thresholds

- json_validity_rate >= 0.99
- react_format_rate >= 0.99
- tool_chain_completeness >= 0.99
- pii_leak_rate == 0.0
