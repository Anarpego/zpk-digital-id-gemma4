# ZPK Dataset Quality Report

Status: PASS

## Splits

- train: 9840
- validation: 1080
- test: 1080

## Scenario Distribution

- economic_fraud: 1716
- extortion_evidence: 1732
- identity_recovery: 1744
- igss_registration: 1713
- preventive_wallet: 1680
- sat_tax_access: 1727
- school_enrollment: 1688

## Checks

- JSONL parses.
- IDs are unique across splits.
- Assistant content is strict JSON.
- No 13-digit identifiers appear.
- Metadata marks rows as synthetic and without real personal data.
- `safety_review.raw_cui_included` is false.
