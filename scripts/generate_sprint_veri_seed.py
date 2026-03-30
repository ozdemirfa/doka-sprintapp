"""
generate_sprint_veri_seed.py
inputs/sprint_veri.csv (cp1254) →
supabase/migrations/20260328180000_023_seed_sprint_veri.sql
Mevcut kayıtlar (1-4) güncellenir, yeniler (5-17) eklenir.
"""

import csv, os, re

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CSV_PATH = os.path.join(BASE_DIR, "inputs", "sprint_veri.csv")
OUT_PATH = os.path.join(BASE_DIR, "supabase", "migrations",
                        "20260328180000_023_seed_sprint_veri.sql")

def sq(val):
    if val is None or val == "":
        return "NULL"
    return "'" + str(val).replace("'", "''") + "'"

def parse_date(val):
    if not val or not val.strip():
        return "NULL"
    parts = re.split(r'[.\s]+', val.strip())
    if len(parts) == 3:
        try:
            d, m, y = int(parts[0]), int(parts[1]), int(parts[2])
            return f"'{y:04d}-{m:02d}-{d:02d}'"
        except ValueError:
            pass
    return "NULL"

rows = []
with open(CSV_PATH, encoding="cp1254") as f:
    reader = csv.DictReader(f, delimiter=";")
    for row in reader:
        donem = row["sprint_donem"].strip()
        if not donem:
            continue
        rows.append({
            "sprint_donem": donem,
            "baslangic":    parse_date(row["baslangic"]),
            "bitis":        parse_date(row["bitis"]),
            "sprint_adi":   sq(row["sprint_adi"].strip()),
            "isim_veren":   sq(row["isim_veren"].strip()),
            "sure_gun":     row["sure_gun"].strip() or "NULL",
            "ekip":         row["ekip"].strip() or "NULL",
        })

values = ",\n  ".join(
    f"({r['sprint_donem']}, {r['baslangic']}, {r['bitis']}, "
    f"{r['sprint_adi']}, {r['isim_veren']}, {r['sure_gun']}, {r['ekip']})"
    for r in rows
)

sql = f"""\
-- 023_seed_sprint_veri.sql
-- inputs/sprint_veri.csv → sprint_veri (INSERT + UPDATE mevcut kayıtlar)

BEGIN;

INSERT INTO sprint_veri
  (sprint_donem, baslangic, bitis, sprint_adi, isim_veren, sure_gun, ekip)
VALUES
  {values}
ON CONFLICT (sprint_donem) DO UPDATE SET
  baslangic  = EXCLUDED.baslangic,
  bitis      = EXCLUDED.bitis,
  sprint_adi = EXCLUDED.sprint_adi,
  isim_veren = EXCLUDED.isim_veren,
  sure_gun   = EXCLUDED.sure_gun,
  ekip       = EXCLUDED.ekip;

COMMIT;
"""

with open(OUT_PATH, "w", encoding="utf-8") as f:
    f.write(sql)

print(f"Üretildi: {OUT_PATH}")
print(f"sprint_veri satırı: {len(rows)}")
