"""
generate_faaliyet_yil_butce_seed.py
inputs/faaliyet_yil_butce.csv (cp1254) →
supabase/migrations/20260328200000_025_seed_faaliyet_yil_butce.sql

butce: "1.000.000" / "14.000.000,00" / boş → DECIMAL
fkod → faaliyet_id subquery ile eşleştirilir
"""

import csv, os

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CSV_PATH = os.path.join(BASE_DIR, "inputs", "faaliyet_yil_butce.csv")
OUT_PATH = os.path.join(BASE_DIR, "supabase", "migrations",
                        "20260328200000_025_seed_faaliyet_yil_butce.sql")

def parse_butce(val):
    """'1.000.000' / '14.000.000,00' / '' → sayı string (default 0)"""
    if not val or not val.strip():
        return "0"
    v = val.strip().replace('.', '').replace(',', '.')
    try:
        float(v)
        return v
    except ValueError:
        return "0"

rows = []
with open(CSV_PATH, encoding="cp1254") as f:
    reader = csv.DictReader(f, delimiter=";")
    for row in reader:
        fkod = row["fkod"].strip()
        if not fkod:
            continue
        rows.append({
            "fkod":  fkod,
            "yil":   row["yil"].strip(),
            "butce": parse_butce(row["butce"]),
        })

# Her satır: subquery ile fkod → faaliyet_id
value_lines = ",\n  ".join(
    f"((SELECT id FROM faaliyetler WHERE fkod = '{r['fkod']}'), {r['yil']}, {r['butce']})"
    for r in rows
)

sql = f"""\
-- 025_seed_faaliyet_yil_butce.sql
-- inputs/faaliyet_yil_butce.csv → faaliyet_yil_butce

BEGIN;

INSERT INTO faaliyet_yil_butce (faaliyet_id, yil, butce)
VALUES
  {value_lines}
ON CONFLICT (faaliyet_id, yil) DO UPDATE SET
  butce = EXCLUDED.butce;

COMMIT;
"""

with open(OUT_PATH, "w", encoding="utf-8") as f:
    f.write(sql)

print(f"Üretildi: {OUT_PATH}")
print(f"faaliyet_yil_butce satırı: {len(rows)}")
