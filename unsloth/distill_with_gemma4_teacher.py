#!/usr/bin/env python3
"""Build RLKD-style teacher traces for ZPK.

Default mode uses a deterministic local teacher so the repo always has a
reproducible, private baseline. With `--teacher gemini-api`, the same prompts
can be sent to a Gemma/Gemini-compatible API using `GEMINI_API_KEY`.
"""

from __future__ import annotations

import argparse
import json
import os
import urllib.request
from pathlib import Path


ROOT = Path(__file__).resolve().parent
DATA_DIR = ROOT / "data"
INPUT = DATA_DIR / "zpk_gt_latam_sft_train.jsonl"
OUTPUT = DATA_DIR / "zpk_gt_latam_rlkd_teacher.jsonl"


def read_jsonl(path: Path, limit: int) -> list[dict]:
    rows = []
    with path.open("r", encoding="utf-8") as handle:
        for line in handle:
            if line.strip():
                rows.append(json.loads(line))
            if len(rows) >= limit:
                break
    return rows


def local_teacher(row: dict) -> dict:
    metadata = row["metadata"]
    scenario = metadata["scenario"]
    tools = metadata["tools"]
    return {
        "id": row["id"],
        "teacher": "deterministic-zpk-structure-v1",
        "scenario": scenario,
        "steps": [
            {
                "meta_reasoning": "Decidir si el caso requiere bloquear datos personales antes de razonar.",
                "subproblem": "Validar privacidad y formato sin exponer CUI.",
                "solution": "Usar solo hechos sinteticos, redacciones y herramientas locales.",
            },
            {
                "meta_reasoning": "Elegir la herramienta local que reduce mas dano inmediato.",
                "subproblem": f"Ejecutar flujo {scenario} con {', '.join(tools[:2])}.",
                "solution": "Clasificar riesgo, preservar evidencia y preparar paquete redactado.",
            },
            {
                "meta_reasoning": "Definir si una institucion necesita recibir informacion.",
                "subproblem": "Minimizar divulgacion en el handoff.",
                "solution": "Compartir prueba firmada, pseudonimo y resumen sin CUI completo.",
            },
        ],
        "reward_targets": {
            "json_contract": True,
            "raw_cui_included": False,
            "offline_boundary": "online solo para descarga o actualizacion; decision offline",
        },
    }


def gemini_teacher(row: dict, model: str) -> dict:
    api_key = os.environ.get("GEMINI_API_KEY", "")
    if not api_key:
        raise RuntimeError("GEMINI_API_KEY is required for --teacher gemini-api")
    prompt = (
        "Convierte este caso ZPK en pasos RLKD. Devuelve JSON con lista steps; "
        "cada step debe tener meta_reasoning, subproblem y solution. No incluyas PII.\n\n"
        + json.dumps(row, ensure_ascii=False)
    )
    url = (
        "https://generativelanguage.googleapis.com/v1beta/models/"
        f"{model}:generateContent?key={api_key}"
    )
    body = json.dumps(
        {"contents": [{"parts": [{"text": prompt}]}]},
        ensure_ascii=False,
    ).encode("utf-8")
    request = urllib.request.Request(
        url,
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(request, timeout=90) as response:
        decoded = json.loads(response.read().decode("utf-8"))
    text = decoded["candidates"][0]["content"]["parts"][0]["text"]
    start = text.find("{")
    end = text.rfind("}")
    payload = json.loads(text[start : end + 1])
    payload["id"] = row["id"]
    payload["teacher"] = model
    return payload


def write_jsonl(path: Path, rows: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row, ensure_ascii=False, sort_keys=True) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, default=INPUT)
    parser.add_argument("--output", type=Path, default=OUTPUT)
    parser.add_argument("--limit", type=int, default=1200)
    parser.add_argument("--teacher", choices=["local", "gemini-api"], default="local")
    parser.add_argument("--model", default="gemma-4-31b-it")
    args = parser.parse_args()

    source_rows = read_jsonl(args.input, args.limit)
    teacher_rows = [
        local_teacher(row)
        if args.teacher == "local"
        else gemini_teacher(row, args.model)
        for row in source_rows
    ]
    write_jsonl(args.output, teacher_rows)
    print(args.output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
