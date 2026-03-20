from __future__ import annotations

import json
from pathlib import Path
from typing import Dict

ROOT = Path(__file__).resolve().parents[2]
REWRITE_ROOT = ROOT / "godot_rewrite"
CHARA_ROOT = ROOT / "CSV" / "Chara"
OUTPUT_ROOT = REWRITE_ROOT / "Data" / "Characters"
PROFILE_PATH = OUTPUT_ROOT / "character_profiles.json"

KEY_NO = "\u756a\u53f7"
KEY_NAME = "\u540d\u524d"
KEY_CALL_NAME = "\u547c\u3073\u540d"
KEY_BASE = "\u57fa\u790e"
KEY_ABILITY = "\u80fd\u529b"
KEY_TALENT = "\u7d20\u8cea"
KEY_EXPERIENCE = "\u7d4c\u9a13"
KEY_CSTR = "CSTR"

CHARACTER_POOLS = {
    101: "wei",
    102: "wei",
    103: "wei",
    104: "wei",
    105: "wei",
    106: "wei",
    107: "other",
    108: "other",
    109: "other",
    110: "other",
    111: "other",
    112: "other",
}

FACTIONS = {
    101: "\u9b4f",
    102: "\u9b4f",
    103: "\u9b4f",
    104: "\u9b4f",
    105: "\u9b4f",
    106: "\u9b4f",
    107: "\u8700",
    108: "\u5434",
    109: "\u8700",
    110: "\u7fa4",
    111: "\u8700",
    112: "\u5434",
}


def load_profiles() -> Dict[int, dict]:
    if not PROFILE_PATH.exists():
        return {}
    raw = json.loads(PROFILE_PATH.read_text(encoding="utf-8"))
    return {int(key): value for key, value in raw.items()}


def parse_int(value: str) -> int:
    value = value.strip()
    if not value:
        return 0
    try:
        return int(value)
    except ValueError:
        return 0


def find_character_file(character_id: int) -> Path:
    matches = list(CHARA_ROOT.rglob(f"Chara{character_id}_*.csv"))
    if not matches:
        raise FileNotFoundError(f"CSV not found for character {character_id}")
    return matches[0]


def build_record(character_id: int, csv_path: Path, profile: dict) -> dict:
    record = {
        "id": character_id,
        "name": "",
        "callName": "",
        "faction": FACTIONS.get(character_id, ""),
        "poolId": CHARACTER_POOLS.get(character_id, ""),
        "difficulty": profile.get("difficulty", ""),
        "persona": profile.get("persona", ""),
        "job": profile.get("job", ""),
        "portraitId": int(profile.get("portraitId", 0) or 0),
        "sourceCsv": str(csv_path.relative_to(ROOT)).replace(chr(92), "/"),
        "baseStats": {},
        "abilities": {},
        "experience": {},
        "talents": [],
        "cstr": {},
        "profile": [],
    }

    for raw_line in csv_path.read_text(encoding="utf-8-sig", errors="replace").splitlines():
        if not raw_line or raw_line.startswith(";"):
            continue

        row = [part.strip() for part in raw_line.split(",")]
        if not row:
            continue

        key = row[0]
        if key == KEY_NO:
            if len(row) > 1:
                record["id"] = parse_int(row[1])
        elif key == KEY_NAME:
            record["name"] = row[1] if len(row) > 1 else ""
        elif key == KEY_CALL_NAME:
            record["callName"] = row[1] if len(row) > 1 else ""
        elif key == KEY_BASE and len(row) > 2:
            record["baseStats"][row[1]] = parse_int(row[2])
        elif key == KEY_ABILITY and len(row) > 2:
            record["abilities"][row[1]] = parse_int(row[2])
        elif key == KEY_EXPERIENCE and len(row) > 2:
            record["experience"][row[1]] = parse_int(row[2])
        elif key == KEY_TALENT and len(row) > 1:
            talent = row[1]
            if talent:
                record["talents"].append(talent)
        elif key == KEY_CSTR and len(row) > 2:
            record["cstr"][row[1]] = row[2]

    if not record["callName"]:
        record["callName"] = record["name"]

    for idx in range(92, 99):
        text = record["cstr"].get(str(idx), "")
        if text:
            record["profile"].append(text)

    return record


def main() -> None:
    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)
    profiles = load_profiles()
    generated = []

    for character_id in sorted(CHARACTER_POOLS):
        csv_path = find_character_file(character_id)
        record = build_record(character_id, csv_path, profiles.get(character_id, {}))
        output_path = OUTPUT_ROOT / f"{character_id}.json"
        output_path.write_text(json.dumps(record, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        generated.append(output_path.name)

    print(f"Generated {len(generated)} character files:")
    for name in generated:
        print(name)


if __name__ == "__main__":
    main()
