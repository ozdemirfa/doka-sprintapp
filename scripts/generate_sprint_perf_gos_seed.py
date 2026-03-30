"""
generate_sprint_perf_gos_seed.py
inputs/sprint_perf_gos.csv (cp1254) →
supabase/migrations/20260328170000_022_seed_sprint_perf_gos.sql
"""

import csv, os, re

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CSV_PATH = os.path.join(BASE_DIR, "inputs", "sprint_perf_gos.csv")
OUT_PATH = os.path.join(BASE_DIR, "supabase", "migrations",
                        "20260328170000_022_seed_sprint_perf_gos.sql")

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

def parse_num(val):
    if not val or not val.strip():
        return "NULL"
    return val.strip().replace(',', '.')

rows = []
with open(CSV_PATH, encoding="cp1254") as f:
    reader = csv.DictReader(f, delimiter=";")
    for row in reader:
        sip_id = row["sprint_is_plani_id"].strip()
        if not sip_id:
            continue
        rows.append({
            "cg_kod":             sq(row["cg_kod"].strip()),
            "aciklama":           sq(row["aciklama"].strip()),
            "gerceklesme":        parse_num(row["gerceklesme"]),
            "tamamlanma_donemi":  sq(row["tamamlanma_donemi"].strip()),
            "tamamlanma_tarihi":  parse_date(row["tamamlanma_tarihi"]),
            "yil":                row["yil"].strip() or "NULL",
            "sprint_is_plani_id": sip_id,
        })

values = ",\n  ".join(
    f"({r['sprint_is_plani_id']}, {r['cg_kod']}, {r['aciklama']}, "
    f"{r['gerceklesme']}, {r['tamamlanma_donemi']}, "
    f"{r['tamamlanma_tarihi']}, {r['yil']})"
    for r in rows
)

sql = f"""\
-- 022_seed_sprint_perf_gos.sql
-- inputs/sprint_perf_gos.csv → sprint_perf_gos tablosu

BEGIN;

INSERT INTO sprint_perf_gos
  (sprint_is_plani_id, cg_kod, aciklama, gerceklesme,
   tamamlanma_donemi, tamamlanma_tarihi, yil)
VALUES
  {values};

COMMIT;
"""

with open(OUT_PATH, "w", encoding="utf-8") as f:
    f.write(sql)

print(f"Üretildi: {OUT_PATH}")
print(f"sprint_perf_gos satırı: {len(rows)}")
