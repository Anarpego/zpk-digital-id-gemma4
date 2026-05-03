#!/usr/bin/env python3
"""Generate synthetic Guatemala/LatAm SFT data for ZPK Digital ID.

The dataset is intentionally synthetic: no real CUI, phone number, address,
victim name, or institution account is emitted. The examples teach the model
the app's contract: local-first triage, privacy boundaries, redacted handoff,
and Spanish guidance for low-resource contexts.
"""

from __future__ import annotations

import argparse
import json
import random
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parent
DATA_DIR = ROOT / "data"


@dataclass(frozen=True)
class Scenario:
    key: str
    label: str
    mission: str
    risk: str
    tools: tuple[str, ...]
    actions: tuple[str, ...]
    allows_no_cui: bool = False


SCENARIOS = (
    Scenario(
        key="identity_recovery",
        label="recuperacion de identidad",
        mission="recuperar identidad despues de una filtracion",
        risk="critico",
        tools=(
            "validate_cui",
            "local_breach_lookup",
            "privacy_route",
            "recovery_packet",
        ),
        actions=(
            "Conservar evidencia redactada en el dispositivo.",
            "Llevar DPI fisico y paquete firmado a una institucion competente.",
            "Revocar credenciales locales si hay sospecha de control de cuenta.",
        ),
    ),
    Scenario(
        key="extortion_evidence",
        label="amenaza o extorsion",
        mission="preservar evidencia sin exponer ubicacion ni CUI",
        risk="critico",
        tools=(
            "preserve_evidence",
            "sealed_local_timeline",
            "redacted_report",
            "privacy_route",
        ),
        actions=(
            "No confrontar a la persona agresora por chat.",
            "Guardar capturas, audios, numeros y horas en archivo cifrado.",
            "Compartir solo un resumen redactado con apoyo presencial o institucional.",
        ),
    ),
    Scenario(
        key="economic_fraud",
        label="estafa economica",
        mission="reducir dano por prestamo, empleo, remesa o SIM swap",
        risk="alto",
        tools=(
            "economic_fraud_triage",
            "bank_telco_checklist",
            "redacted_institution_packet",
            "privacy_route",
        ),
        actions=(
            "Conservar recibos, chats, cuentas destino y horarios.",
            "Pedir bloqueo preventivo en banco, remesadora o telefonia.",
            "Enviar solo hechos redactados y prueba firmada local.",
        ),
    ),
    Scenario(
        key="preventive_wallet",
        label="registro preventivo",
        mission="crear credencial local antes de compartir DPI",
        risk="medio",
        tools=(
            "local_credential",
            "selective_disclosure",
            "consent_15m",
            "audit_archive",
        ),
        actions=(
            "Usar pseudonimo cuando el tramite no requiere CUI completo.",
            "No enviar foto de DPI por mensajeria informal.",
            "Borrar auditoria local cuando deje de ser necesaria.",
        ),
    ),
    Scenario(
        key="igss_registration",
        label="registro o recuperacion IGSS",
        mission="preparar registro, afiliacion o recuperacion ante IGSS",
        risk="alto",
        tools=(
            "igss_registration_agent",
            "presence_proof",
            "redacted_admin_intake",
            "privacy_route",
        ),
        actions=(
            "Separar vista ciudadana y vista administrador IGSS.",
            "Preparar DPI fisico y documentos laborales solo para canal oficial.",
            "Emitir intake redactado; si no hay CUI, no emitir credencial.",
        ),
        allows_no_cui=True,
    ),
    Scenario(
        key="sat_tax_access",
        label="acceso o actualizacion SAT",
        mission="recuperar acceso, actualizar datos o bloquear actividad sospechosa SAT",
        risk="alto",
        tools=(
            "sat_access_agent",
            "portal_safety_check",
            "redacted_update_packet",
            "privacy_route",
        ),
        actions=(
            "Usar solo portal o ventanilla oficial SAT.",
            "No compartir codigos ni fotos completas de DPI por mensajeria.",
            "Preparar paquete redactado para recuperacion o bloqueo preventivo.",
        ),
        allows_no_cui=True,
    ),
    Scenario(
        key="school_enrollment",
        label="inscripcion educativa",
        mission="preparar inscripcion, beca o constancia ante colegio o universidad",
        risk="medio",
        tools=(
            "education_enrollment_agent",
            "guardian_consent",
            "limited_student_claim",
            "redacted_admin_intake",
        ),
        actions=(
            "Separar consentimiento del responsable y datos minimos del estudiante.",
            "Evitar copias completas de DPI en telefonos personales.",
            "Entregar prueba limitada para inscripcion, beca o constancia.",
        ),
        allows_no_cui=True,
    ),
)

COUNTRIES = (
    "Guatemala",
    "El Salvador",
    "Honduras",
    "Mexico",
    "Nicaragua",
    "Costa Rica",
    "Colombia",
    "Peru",
)

COMMUNITIES = (
    "municipio rural",
    "barrio urbano",
    "comunidad migrante",
    "centro educativo",
    "organizacion civil",
    "oficina municipal",
)

SCENARIO_COMMUNITIES = {
    "igss_registration": ("agencia IGSS", "municipio rural", "barrio urbano"),
    "sat_tax_access": ("ventanilla SAT", "oficina municipal", "barrio urbano"),
    "school_enrollment": (
        "centro educativo",
        "municipio rural",
        "comunidad migrante",
    ),
}

INCIDENTS = (
    "portal de empleo filtrado",
    "base universitaria expuesta",
    "tramite publico con credenciales debiles",
    "mensaje de amenaza por telefono",
    "oferta falsa de ayuda social",
    "prestamo no reconocido",
    "remesa retenida por cuenta sospechosa",
    "duplicado de SIM",
)

SCENARIO_INCIDENTS = {
    "igss_registration": (
        "afiliacion IGSS no encontrada",
        "patrono no aparece en expediente sintetico",
        "recuperacion de acceso IGSS por telefono perdido",
    ),
    "sat_tax_access": (
        "correo SAT cambiado sin autorizacion",
        "acceso SAT bloqueado por intento sospechoso",
        "actualizacion tributaria detenida por documentos incompletos",
    ),
    "school_enrollment": (
        "inscripcion escolar detenida por falta de documentos",
        "beca universitaria requiere prueba limitada",
        "constancia educativa retenida por verificacion manual",
    ),
}


SYSTEM_PROMPT = (
    "Eres ZPK Digital ID, un agente local para Guatemala y America Latina. "
    "Responde en espanol claro, no pidas mas datos personales, no reveles CUI, "
    "no inventes instituciones y separa internet de offline. Devuelve solo JSON."
)


def assistant_payload(scenario: Scenario, country: str, community: str) -> dict:
    no_cui_clause = (
        " Si la persona no tiene CUI a mano, solo genera checklist e intake; no emite credencial."
        if scenario.allows_no_cui
        else ""
    )
    return {
        "summary": (
            f"El caso de {scenario.label} se maneja en modo local. "
            f"El agente usa herramientas del dispositivo para {scenario.mission} "
            f"sin enviar CUI, direccion, telefono ni evidencia privada."
            f"{no_cui_clause}"
        ),
        "next_steps": list(scenario.actions),
        "national_scale_note": (
            f"Este flujo escala en {country} y otros paises de America Latina "
            f"porque cada {community} puede verificar, firmar y compartir solo "
            "paquetes redactados sin centralizar identificadores."
        ),
        "safety_review": {
            "raw_cui_included": False,
            "needs_human_review": scenario.risk in {"alto", "critico"},
        },
    }


def user_prompt(
    scenario: Scenario,
    country: str,
    community: str,
    incident: str,
    rng: random.Random,
) -> str:
    match_count = rng.choice([0, 1, 2])
    network = rng.choice(["sin internet", "internet inestable", "solo datos moviles"])
    cui_available = rng.choice(["si", "no"]) if scenario.allows_no_cui else "si"
    fields = rng.sample(
        ["nombre", "telefono", "correo", "direccion", "historial laboral"],
        k=rng.randint(2, 4),
    )
    return (
        f"Pais: {country}. Contexto: {community}. Conectividad: {network}. "
        f"Incidente sintetico: {incident}. Flujo: {scenario.label}. "
        f"CUI disponible: {cui_available}. "
        f"Coincidencias locales: {match_count}. Campos expuestos: {', '.join(fields)}. "
        "Explica que debe hacer la app ZPK, que puede hacer offline y que solo "
        "puede usar internet para descargar modelo o actualizar boletines. "
        "Incluye vista persona y vista administrador cuando aplique."
    )


def make_example(index: int, rng: random.Random) -> dict:
    scenario = rng.choice(SCENARIOS)
    country = rng.choice(COUNTRIES)
    community = rng.choice(SCENARIO_COMMUNITIES.get(scenario.key, COMMUNITIES))
    incident = rng.choice(SCENARIO_INCIDENTS.get(scenario.key, INCIDENTS))
    return {
        "id": f"zpk-gt-latam-{index:05d}",
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {
                "role": "user",
                "content": user_prompt(scenario, country, community, incident, rng),
            },
            {
                "role": "assistant",
                "content": json.dumps(
                    assistant_payload(scenario, country, community),
                    ensure_ascii=False,
                    separators=(",", ":"),
                ),
            },
        ],
        "metadata": {
            "scenario": scenario.key,
            "country": country,
            "community": community,
            "incident": incident,
            "risk": scenario.risk,
            "tools": list(scenario.tools),
            "allows_no_cui": scenario.allows_no_cui,
            "synthetic": True,
            "contains_real_personal_data": False,
        },
    }


def write_jsonl(path: Path, rows: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row, ensure_ascii=False, sort_keys=True) + "\n")


def write_dataset_card(train: list[dict], validation: list[dict], test: list[dict]) -> None:
    card = f"""# ZPK Guatemala/LatAm Synthetic Agent SFT Dataset

This dataset is generated, not scraped. It contains no real CUI, DPI, phone
numbers, addresses, victim names, bank accounts, or case files.

## Purpose

Teach Gemma 4 to follow the ZPK app contract in Spanish:

- distinguish online bootstrap from offline citizen workflows;
- protect raw CUI/DPI and other PII;
- triage identity recovery, extortion evidence, economic fraud, remittance/SIM
  risk, IGSS registration, SAT access, school enrollment, and preventive wallet
  registration;
- return valid JSON accepted by the app's `AgentResponseContract`;
- produce citizen and administrator views with redacted institution handoff
  steps for Guatemala and Latin America;
- handle no-CUI intake cases without emitting a false identity credential.

## Splits

- Train examples: {len(train)}
- Validation examples: {len(validation)}
- Test examples: {len(test)}

## Format

Each row uses TRL conversational `messages` format with `system`, `user`, and
`assistant` turns. The assistant turn is strict JSON with:

- `summary`
- `next_steps`
- `national_scale_note`
- `safety_review.raw_cui_included=false`
- `safety_review.needs_human_review`

## Safety

The generator intentionally avoids 13-digit identifiers and real institutional
claims. Use `uv run python evaluate_dataset.py` before training.
"""
    (DATA_DIR / "DATASET_CARD.md").write_text(card, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--examples", type=int, default=12000)
    parser.add_argument("--seed", type=int, default=20260502)
    parser.add_argument("--train-ratio", type=float, default=0.82)
    parser.add_argument("--validation-ratio", type=float, default=0.09)
    args = parser.parse_args()

    rng = random.Random(args.seed)
    rows = [make_example(index + 1, rng) for index in range(args.examples)]
    rng.shuffle(rows)

    train_end = int(len(rows) * args.train_ratio)
    validation_end = train_end + int(len(rows) * args.validation_ratio)
    train = rows[:train_end]
    validation = rows[train_end:validation_end]
    test = rows[validation_end:]

    write_jsonl(DATA_DIR / "zpk_gt_latam_sft_train.jsonl", train)
    write_jsonl(DATA_DIR / "zpk_gt_latam_sft_validation.jsonl", validation)
    write_jsonl(DATA_DIR / "zpk_gt_latam_sft_test.jsonl", test)
    write_dataset_card(train, validation, test)
    print(DATA_DIR)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
