#!/usr/bin/env python3
"""Generate ReAct-format synthetic examples for ZPK Lote 1 cases.

Output rows mirror the Dart agent_loop contract: each assistant turn is a
JSON decision (`tool_call` or `final`), interleaved with `tool` turns that
report the simulated observation. The model trained on this learns the
ReAct dance, not just one-shot answers.

Cases covered (Lote 1):
- extorsion_telefono_sms
- estafa_remesa
- igss_sin_dpi
- sat_acceso_bloqueado
- despido_sin_prestaciones

Usage:
    uv run python generate_react_lote1.py --out data/react/
"""

from __future__ import annotations

import argparse
import json
import random
from collections import Counter
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent
DEFAULT_OUT = ROOT / "data" / "react"
SEED = 20260503


SYSTEM_PROMPT = (
    "Sos ZPK Agent. Trabajas offline en Guatemala. Nunca pidas CUI, DPI, "
    "telefono, direccion ni datos sensibles; ya fueron filtrados antes de "
    "verte. Decidi el siguiente paso. Responde SOLO con JSON valido en "
    "una de estas dos formas:\n"
    '{"action":"tool_call","tool":"<nombre>","input":{...}}\n'
    '{"action":"final","summary":"...","next_steps":["..."],"artifact_type":"..."}'
)


# --- Plantillas de input por caso (sin PII real) -----------------------------

CASE_INPUTS: dict[str, list[str]] = {
    "extorsion_telefono_sms": [
        "me llego un mensaje pidiendo plata o me hacen dano",
        "alguien me esta llamando de un numero raro y dice que sabe donde vivo",
        "me dijeron que me van a matar si no pago",
        "recibi un sms diciendo que conocen a mi familia",
        "me amenazan por whatsapp diciendo que vienen las maras",
    ],
    "estafa_remesa": [
        "me llego mensaje de western union sobre paquete retenido",
        "alguien dice que tengo un envio de remesa pendiente y debo pagar tasa",
        "tigo money me dice que gane premio si transfiero codigo",
        "moneygram pide que confirme datos por enlace para liberar dinero",
        "falso envio dice que necesita pago de aduana primero",
    ],
    "igss_sin_dpi": [
        "perdi mi dpi y necesito atencion en igss",
        "no tengo carne de salud y mi mama necesita ir al seguro social",
        "me robaron el dpi y tengo cita en igss manana",
        "voy a igss pero no encuentro mi documento",
        "afiliacion patronal pendiente y dpi extraviado",
    ],
    "sat_acceso_bloqueado": [
        "me bloqueo sat y no puedo entrar a agencia virtual",
        "no me deja ingresar a la agencia virtual con mi nit",
        "sat me dice que mi acceso esta restringido",
        "perdi acceso a portal sat y no puedo facturar",
        "agencia virtual me pide datos que no recuerdo",
    ],
    "despido_sin_prestaciones": [
        "me corrieron del trabajo sin pagar prestaciones",
        "me despidieron y no me dieron liquidacion",
        "el patrono no quiere pagar mis prestaciones de ley",
        "trabaje 3 anos y me corrieron sin nada",
        "me despidieron sin causa y no pagan indemnizacion",
    ],
}


# --- Tool effect simulators --------------------------------------------------

def tool_redact_pii(text: str) -> dict[str, Any]:
    return {"redacted_text": text, "categories": [], "redacted_count": 0}


def tool_classify_case(text: str, target: str) -> dict[str, Any]:
    return {
        "case_code": target,
        "confidence": round(random.uniform(0.55, 0.95), 2),
        "signals": [text.split()[0]],
    }


def tool_lookup_codigo_penal(category: str) -> dict[str, Any]:
    table = {
        "extorsion": {
            "article": "Art. 261",
            "name": "Extorsion",
            "penalty": "Prision de 6 a 12 anos",
        },
        "estafa": {
            "article": "Art. 263",
            "name": "Estafa Propia",
            "penalty": "Prision de 6 meses a 4 anos y multa",
        },
    }
    entry = table[category]
    return {"found": True, "category": category, **entry}


def tool_lookup_codigo_trabajo(situation: str) -> dict[str, Any]:
    return {
        "found": True,
        "situation": situation,
        "articles": ["Art. 76", "Art. 78", "Art. 82"],
        "name": "Despido injustificado",
        "derecho": "Indemnizacion + aguinaldo + bono 14 + vacaciones",
    }


def tool_lookup_institucion(code: str) -> dict[str, Any]:
    table = {
        "MP": {"name": "Ministerio Publico", "phone": "1572"},
        "PROFECO": {"name": "DIACO", "phone": "1544"},
        "IGSS": {"name": "IGSS", "phone": "1522"},
        "SAT": {"name": "SAT", "phone": "1550"},
        "MTPS": {"name": "MTPS", "phone": "1545"},
    }
    return {"found": True, "code": code, **table[code]}


def tool_draft_denuncia(case: str, institucion: str) -> dict[str, Any]:
    return {
        "artifact_type": f"denuncia_{case}",
        "titulo": f"Denuncia formal para {institucion}",
        "hash": "sha256:DEMO_HASH_DENUNCIA",
        "longitud_caracteres": 720,
    }


def tool_draft_solicitud(institucion: str, sin_dpi: bool) -> dict[str, Any]:
    return {
        "artifact_type": f"solicitud_{institucion.lower()}",
        "titulo": f"Solicitud para {institucion}",
        "hash": "sha256:DEMO_HASH_SOLICITUD",
        "longitud_caracteres": 540,
        "sin_dpi": sin_dpi,
    }


def tool_draft_sms_familia(case: str) -> dict[str, Any]:
    return {
        "artifact_type": f"sms_familia_{case}",
        "longitud": 189,
        "hash": "sha256:DEMO_HASH_SMS",
    }


def tool_sign_packet(_: str) -> dict[str, Any]:
    return {
        "hash": "sha256:DEMO_HASH_SIGNED",
        "sig": "DEMO_HMAC_SIGNATURE",
        "key_id": "zpk-citizen-demo-key",
    }


# --- Conversation builders per case ------------------------------------------

def _assistant_tool_call(tool: str, inp: dict) -> str:
    return json.dumps({"action": "tool_call", "tool": tool, "input": inp},
                      ensure_ascii=False)


def _assistant_final(summary: str, next_steps: list[str], artifact_type: str) -> str:
    return json.dumps({
        "action": "final",
        "summary": summary,
        "next_steps": next_steps,
        "artifact_type": artifact_type,
    }, ensure_ascii=False)


def _tool_msg(name: str, payload: dict) -> dict:
    return {"role": "tool", "name": name,
            "content": json.dumps(payload, ensure_ascii=False)}


def build_extorsion(input_text: str) -> list[dict]:
    msgs = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": input_text},
        {"role": "assistant", "content": _assistant_tool_call("redact_pii", {"text": input_text})},
        _tool_msg("redact_pii", tool_redact_pii(input_text)),
        {"role": "assistant", "content": _assistant_tool_call("classify_case", {"text": input_text})},
        _tool_msg("classify_case", tool_classify_case(input_text, "extorsion_telefono_sms")),
        {"role": "assistant", "content": _assistant_tool_call("lookup_codigo_penal", {"category": "extorsion"})},
        _tool_msg("lookup_codigo_penal", tool_lookup_codigo_penal("extorsion")),
        {"role": "assistant", "content": _assistant_tool_call("lookup_institucion", {"code": "MP"})},
        _tool_msg("lookup_institucion", tool_lookup_institucion("MP")),
        {"role": "assistant", "content": _assistant_tool_call("draft_sms_familia", {"caso_codigo": "extorsion_telefono_sms"})},
        _tool_msg("draft_sms_familia", tool_draft_sms_familia("extorsion_telefono_sms")),
        {"role": "assistant", "content": _assistant_tool_call("draft_denuncia", {
            "institucion_destino": "MINISTERIO PUBLICO",
            "caso_codigo": "extorsion",
            "narrativa_redactada": "Persona reporta amenazas via telefono o SMS.",
            "articulo_cp": "Art. 261",
            "nombre_articulo": "Extorsion",
            "pena": "Prision de 6 a 12 anos",
            "pseudonimo": "zpk:local-citizen-demo",
        })},
        _tool_msg("draft_denuncia", tool_draft_denuncia("extorsion", "MINISTERIO PUBLICO")),
        {"role": "assistant", "content": _assistant_tool_call("sign_packet", {"contenido": "sha256:DEMO_HASH_DENUNCIA"})},
        _tool_msg("sign_packet", tool_sign_packet("")),
        {"role": "assistant", "content": _assistant_final(
            "Detecte un caso de extorsion. Genere denuncia para Ministerio Publico citando Art. 261 CP.",
            [
                "Llamar a 1572 para orientacion previa.",
                "Imprimir o mostrar el QR de la denuncia en la fiscalia.",
                "Enviar el mensaje generado a tu familia por WhatsApp.",
                "Si hay riesgo inmediato a la vida, llamar al 110.",
            ],
            "denuncia_extorsion",
        )},
    ]
    return msgs


def build_estafa(input_text: str) -> list[dict]:
    msgs = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": input_text},
        {"role": "assistant", "content": _assistant_tool_call("redact_pii", {"text": input_text})},
        _tool_msg("redact_pii", tool_redact_pii(input_text)),
        {"role": "assistant", "content": _assistant_tool_call("classify_case", {"text": input_text})},
        _tool_msg("classify_case", tool_classify_case(input_text, "estafa_remesa")),
        {"role": "assistant", "content": _assistant_tool_call("lookup_codigo_penal", {"category": "estafa"})},
        _tool_msg("lookup_codigo_penal", tool_lookup_codigo_penal("estafa")),
        {"role": "assistant", "content": _assistant_tool_call("lookup_institucion", {"code": "PROFECO"})},
        _tool_msg("lookup_institucion", tool_lookup_institucion("PROFECO")),
        {"role": "assistant", "content": _assistant_tool_call("draft_sms_familia", {"caso_codigo": "estafa_remesa"})},
        _tool_msg("draft_sms_familia", tool_draft_sms_familia("estafa_remesa")),
        {"role": "assistant", "content": _assistant_tool_call("draft_denuncia", {
            "institucion_destino": "DIACO",
            "caso_codigo": "estafa_remesa",
            "narrativa_redactada": "Persona reporta intento de estafa de remesa o paquete falso.",
            "articulo_cp": "Art. 263",
            "nombre_articulo": "Estafa Propia",
            "pena": "Prision de 6 meses a 4 anos y multa",
            "pseudonimo": "zpk:local-citizen-demo",
        })},
        _tool_msg("draft_denuncia", tool_draft_denuncia("estafa_remesa", "DIACO")),
        {"role": "assistant", "content": _assistant_tool_call("sign_packet", {"contenido": "sha256:DEMO_HASH_DENUNCIA"})},
        _tool_msg("sign_packet", tool_sign_packet("")),
        {"role": "assistant", "content": _assistant_final(
            "Detecte estafa de remesa o paquete falso. Prepare queja para DIACO bajo Art. 263 CP.",
            [
                "Llamar a 1544 para orientacion previa.",
                "No transferir dinero ni dar codigos al supuesto remitente.",
                "Presentar la queja en oficina DIACO con la captura redactada.",
            ],
            "denuncia_estafa_remesa",
        )},
    ]
    return msgs


def build_igss(input_text: str) -> list[dict]:
    msgs = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": input_text},
        {"role": "assistant", "content": _assistant_tool_call("redact_pii", {"text": input_text})},
        _tool_msg("redact_pii", tool_redact_pii(input_text)),
        {"role": "assistant", "content": _assistant_tool_call("classify_case", {"text": input_text})},
        _tool_msg("classify_case", tool_classify_case(input_text, "igss_sin_dpi")),
        {"role": "assistant", "content": _assistant_tool_call("lookup_institucion", {"code": "IGSS"})},
        _tool_msg("lookup_institucion", tool_lookup_institucion("IGSS")),
        {"role": "assistant", "content": _assistant_tool_call("draft_solicitud", {
            "institucion": "IGSS",
            "motivo": "Atencion presencial sin DPI fisico",
            "sin_dpi": True,
            "pseudonimo": "zpk:local-citizen-demo",
        })},
        _tool_msg("draft_solicitud", tool_draft_solicitud("IGSS", True)),
        {"role": "assistant", "content": _assistant_tool_call("sign_packet", {"contenido": "sha256:DEMO_HASH_SOLICITUD"})},
        _tool_msg("sign_packet", tool_sign_packet("")),
        {"role": "assistant", "content": _assistant_final(
            "Genere solicitud para IGSS pidiendo atencion presencial sin DPI fisico.",
            [
                "Llamar a 1522 para orientacion previa.",
                "Acudir a IGSS con la solicitud impresa o el QR.",
                "Llevar identificacion alterna y un testigo si es posible.",
            ],
            "solicitud_igss",
        )},
    ]
    return msgs


def build_sat(input_text: str) -> list[dict]:
    msgs = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": input_text},
        {"role": "assistant", "content": _assistant_tool_call("redact_pii", {"text": input_text})},
        _tool_msg("redact_pii", tool_redact_pii(input_text)),
        {"role": "assistant", "content": _assistant_tool_call("classify_case", {"text": input_text})},
        _tool_msg("classify_case", tool_classify_case(input_text, "sat_acceso_bloqueado")),
        {"role": "assistant", "content": _assistant_tool_call("lookup_institucion", {"code": "SAT"})},
        _tool_msg("lookup_institucion", tool_lookup_institucion("SAT")),
        {"role": "assistant", "content": _assistant_tool_call("draft_solicitud", {
            "institucion": "SAT",
            "motivo": "Restablecimiento de acceso a Agencia Virtual",
            "sin_dpi": False,
            "pseudonimo": "zpk:local-citizen-demo",
        })},
        _tool_msg("draft_solicitud", tool_draft_solicitud("SAT", False)),
        {"role": "assistant", "content": _assistant_tool_call("sign_packet", {"contenido": "sha256:DEMO_HASH_SOLICITUD"})},
        _tool_msg("sign_packet", tool_sign_packet("")),
        {"role": "assistant", "content": _assistant_final(
            "Genere solicitud SAT para restablecer Agencia Virtual.",
            [
                "Llamar a 1550 para orientacion previa.",
                "Acudir presencialmente a la oficina SAT mas cercana con DPI.",
                "No reingresar credenciales SAT desde enlaces recibidos por SMS.",
            ],
            "solicitud_sat",
        )},
    ]
    return msgs


def build_despido(input_text: str) -> list[dict]:
    msgs = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": input_text},
        {"role": "assistant", "content": _assistant_tool_call("redact_pii", {"text": input_text})},
        _tool_msg("redact_pii", tool_redact_pii(input_text)),
        {"role": "assistant", "content": _assistant_tool_call("classify_case", {"text": input_text})},
        _tool_msg("classify_case", tool_classify_case(input_text, "despido_sin_prestaciones")),
        {"role": "assistant", "content": _assistant_tool_call("lookup_codigo_trabajo", {"situation": "despido_injustificado"})},
        _tool_msg("lookup_codigo_trabajo", tool_lookup_codigo_trabajo("despido_injustificado")),
        {"role": "assistant", "content": _assistant_tool_call("lookup_institucion", {"code": "MTPS"})},
        _tool_msg("lookup_institucion", tool_lookup_institucion("MTPS")),
        {"role": "assistant", "content": _assistant_tool_call("draft_denuncia", {
            "institucion_destino": "MTPS",
            "caso_codigo": "despido_sin_prestaciones",
            "narrativa_redactada": "Despido sin pago de prestaciones laborales.",
            "articulo_cp": "Art. 76 / Art. 78 / Art. 82",
            "nombre_articulo": "Despido injustificado",
            "pena": "Indemnizacion + aguinaldo + bono 14 + vacaciones",
            "pseudonimo": "zpk:local-citizen-demo",
        })},
        _tool_msg("draft_denuncia", tool_draft_denuncia("despido_sin_prestaciones", "MTPS")),
        {"role": "assistant", "content": _assistant_tool_call("sign_packet", {"contenido": "sha256:DEMO_HASH_DENUNCIA"})},
        _tool_msg("sign_packet", tool_sign_packet("")),
        {"role": "assistant", "content": _assistant_final(
            "Detecte despido sin prestaciones. Genere queja para MTPS citando Codigo de Trabajo.",
            [
                "Llamar a 1545 para orientacion previa.",
                "Presentar la queja en la Inspeccion General de Trabajo.",
                "Conservar contratos, recibos y mensajes con el patrono como evidencia.",
            ],
            "denuncia_despido_sin_prestaciones",
        )},
    ]
    return msgs


BUILDERS = {
    "extorsion_telefono_sms": build_extorsion,
    "estafa_remesa": build_estafa,
    "igss_sin_dpi": build_igss,
    "sat_acceso_bloqueado": build_sat,
    "despido_sin_prestaciones": build_despido,
}


def build_rows(per_case: int) -> list[dict]:
    rng = random.Random(SEED)
    rows = []
    counter: Counter = Counter()
    for case, inputs in CASE_INPUTS.items():
        for i in range(per_case):
            text = inputs[i % len(inputs)]
            # variaciones triviales para que cada row sea unico
            if i >= len(inputs):
                text = text + f" (caso variante {i})"
            messages = BUILDERS[case](text)
            counter[case] += 1
            rows.append({
                "id": f"react_{case}_{i:04d}",
                "messages": messages,
                "metadata": {
                    "scenario": case,
                    "format": "react_v1",
                    "contains_real_personal_data": False,
                    "lote": 1,
                },
            })
    rng.shuffle(rows)
    return rows


def split_train_val_test(rows: list[dict]) -> dict[str, list[dict]]:
    n = len(rows)
    train_end = int(n * 0.82)
    val_end = int(n * 0.91)
    return {
        "train": rows[:train_end],
        "validation": rows[train_end:val_end],
        "test": rows[val_end:],
    }


def write_jsonl(path: Path, rows: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as h:
        for row in rows:
            h.write(json.dumps(row, ensure_ascii=False) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--per-case", type=int, default=400,
                        help="examples per case (default 400 -> 2000 total)")
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT)
    args = parser.parse_args()

    rows = build_rows(args.per_case)
    splits = split_train_val_test(rows)
    for name, subset in splits.items():
        path = args.out / f"zpk_react_lote1_{name}.jsonl"
        write_jsonl(path, subset)
        print(f"wrote {path} ({len(subset)} rows)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
