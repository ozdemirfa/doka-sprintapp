"""
generate_harcamalar_seed.py
inputs/harcamalar.csv (cp1254) →
supabase/migrations/20260328160000_021_seed_harcamalar.sql
"""

import csv, os, re

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CSV_PATH = os.path.join(BASE_DIR, "inputs", "harcamalar.csv")
OUT_PATH = os.path.join(BASE_DIR, "supabase", "migrations",
                        "20260328160000_021_seed_harcamalar.sql")

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

def parse_money(val):
    """'144.000,00' → 144000.00"""
    if not val or not val.strip():
        return "NULL"
    v = val.strip().replace('.', '').replace(',', '.')
    try:
        float(v)
        return v
    except ValueError:
        return "NULL"

rows = []
with open(CSV_PATH, encoding="cp1254") as f:
    reader = csv.DictReader(f, delimiter=";")
    for row in reader:
        sip_id = row["sprint_is_plani_id"].strip()
        if not sip_id:
            continue
        rows.append({
            "aciklama":           sq(row["aciklama"].strip()),
            "harcama_onay_kodu":  sq(row["harcama_onay_kodu"].strip()),
            "onay_tarihi":        parse_date(row["onay_tarihi"]),
            "odeme_donem":        sq(row["odeme_donem"].strip()),
            "odenecek_kdvli":     parse_money(row["odenecek_kdvli"]),
            "guncel_tarih":       parse_date(row["guncel_tarih"]),
            "guncelleyen":        sq(row["guncelleyen"].strip()),
            "sprint_is_plani_id": sip_id,
        })

values = ",\n  ".join(
    f"({r['aciklama']}, {r['harcama_onay_kodu']}, {r['onay_tarihi']}, "
    f"{r['odeme_donem']}, {r['odenecek_kdvli']}, "
    f"{r['guncel_tarih']}, {r['guncelleyen']}, {r['sprint_is_plani_id']})"
    for r in rows
)

sql = f"""\
-- 021_seed_harcamalar.sql
-- inputs/harcamalar.csv → harcamalar tablosu

BEGIN;

INSERT INTO harcamalar
  (aciklama, harcama_onay_kodu, onay_tarihi, odeme_donem,
   odenecek_kdvli, guncel_tarih, guncelleyen, sprint_is_plani_id)
VALUES
  {values};

COMMIT;
"""

with open(OUT_PATH, "w", encoding="utf-8") as f:
    f.write(sql)

print(f"Üretildi: {OUT_PATH}")
print(f"harcamalar satırı: {len(rows)}")
