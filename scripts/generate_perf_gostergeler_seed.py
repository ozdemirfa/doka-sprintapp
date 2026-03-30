"""
generate_perf_gostergeler_seed.py
inputs/perf_gostergeler.csv (cp1254) okur →
supabase/migrations/20260328140000_019_seed_perf_gostergeler.sql üretir

CSV kolonları: cg_kod;bilesen_kodu;bilesen_adi;cikti_gostergesi;birim;hedef;tamamlanma_donemi;katki_sonuc_gostergesi
- cg_kod ilk karakteri garbled (?G...) → C ile düzelt (CGSTU11)
- hedef: #BAŞV! ve boş → NULL
- skod: cg_kod içindeki SOP kısaltmasından türetilir
- kkod / pg_sira: bilesen_kodu "N.M." formatından türetilir
- perf_gost_yillik: 2026 için ayrıca INSERT
"""

import csv
import os
import re

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CSV_PATH = os.path.join(BASE_DIR, "inputs", "perf_gostergeler.csv")
OUT_PATH = os.path.join(BASE_DIR, "supabase", "migrations",
                        "20260328140000_019_seed_perf_gostergeler.sql")

# soplar tablosundan bilinen SOP kisa → skod eşlemesi
SOP_SKOD = {
    'STU': 1, 'KDU': 2, 'MEK': 3,
    'YKF': 4, 'SDD': 5, 'BAK': 6,
    'ABP': 7, 'SOG': 8,
}

def sq(val):
    """SQL string: None → NULL, string → '...' (tek tırnak escape)."""
    if val is None or val == "":
        return "NULL"
    return "'" + str(val).replace("'", "''") + "'"

def parse_hedef(val):
    """Sayısal hedef → sayı string, hata/boş → NULL."""
    if not val or val.strip().startswith('#'):
        return "NULL"
    try:
        return str(float(val.strip()))
    except ValueError:
        return "NULL"

rows = []

with open(CSV_PATH, encoding="cp1254") as f:
    reader = csv.DictReader(f, delimiter=";")
    for row in reader:
        raw_cg = row["cg_kod"].strip()
        if not raw_cg:
            continue

        # İlk karakter garbled (Ç→?) → C ile düzelt
        cg_kod = "C" + raw_cg[1:]   # ?GSTU11 → CGSTU11

        # SOP kisa: cg_kod[2:5]  → STU, KDU vb.
        sop_kisa = cg_kod[2:5]
        skod = SOP_SKOD.get(sop_kisa)
        if skod is None:
            print(f"UYARI: Bilinmeyen SOP kisa '{sop_kisa}' ({cg_kod}) — satır atlandı")
            continue

        # bilesen_kodu "1.1." → kkod=1, pg_sira=1
        bkod_raw = row["bilesen_kodu"].strip()  # örn. "1.1."
        parts = [p for p in bkod_raw.split('.') if p.strip()]
        kkod    = int(parts[0]) if len(parts) >= 1 else None
        pg_sira = int(parts[1]) if len(parts) >= 2 else None

        bilesen_adi         = row["bilesen_adi"].strip()
        cikti_gostergesi    = row["cikti_gostergesi"].strip()
        birim               = row["birim"].strip()
        hedef               = parse_hedef(row["hedef"])
        tamamlanma_donemi   = row["tamamlanma_donemi"].strip()
        katki               = row["katki_sonuc_gostergesi"].strip()

        rows.append({
            "cg_kod": cg_kod,
            "skod": skod,
            "kkod": kkod,
            "pg_sira": pg_sira,
            "bilesen_kodu": bkod_raw,
            "bilesen_adi": bilesen_adi,
            "cikti_gostergesi": cikti_gostergesi,
            "birim": birim,
            "hedef": hedef,
            "tamamlanma_donemi": tamamlanma_donemi,
            "katki": katki,
        })

pg_values = ",\n  ".join(
    f"({sq(r['cg_kod'])}, {r['skod']}, {r['kkod']}, {r['pg_sira']}, "
    f"{sq(r['bilesen_kodu'])}, {sq(r['bilesen_adi'])}, {sq(r['cikti_gostergesi'])}, "
    f"{sq(r['birim'])}, {r['hedef']}, "
    f"{sq(r['tamamlanma_donemi'])}, {sq(r['katki'])})"
    for r in rows
)

sql = f"""\
-- 019_seed_perf_gostergeler.sql
-- inputs/perf_gostergeler.csv → perf_gostergeler + perf_gost_yillik (2026)

BEGIN;

-- Trigger devre dışı: cg_kod ve bilesen_kodu manuel girilecek
ALTER TABLE perf_gostergeler DISABLE TRIGGER trg_perf_gostergeler_cg_kod;

INSERT INTO perf_gostergeler
  (cg_kod, skod, kkod, pg_sira, bilesen_kodu, bilesen_adi,
   cikti_gostergesi, birim, hedef,
   tamamlanma_donemi, katki_sonuc_gostergesi)
VALUES
  {pg_values};

ALTER TABLE perf_gostergeler ENABLE TRIGGER trg_perf_gostergeler_cg_kod;

-- perf_gost_yillik: 2026 hedef kayıtları (hedef_2026 kolonu kaldırıldığından hedef kullanılır)
INSERT INTO perf_gost_yillik (perf_gostergeler_id, cg_kod, yil, hedef, gerceklesen)
SELECT id, cg_kod, 2026, hedef, NULL
FROM perf_gostergeler
WHERE hedef IS NOT NULL
ON CONFLICT (cg_kod, yil) DO NOTHING;

COMMIT;
"""

with open(OUT_PATH, "w", encoding="utf-8") as f:
    f.write(sql)

print(f"Üretildi: {OUT_PATH}")
print(f"perf_gostergeler satırı: {len(rows)}")
