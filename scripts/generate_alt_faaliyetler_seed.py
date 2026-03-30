"""
generate_alt_faaliyetler_seed.py
inputs/alt_faaliyetler.csv (cp1254) okur →
supabase/migrations/20260328130000_018_seed_alt_faaliyetler.sql üretir

CSV yapısı: sno;fkod;alt_faaliyet;anahtar_sonuclar;p_sure;tekrar_sayisi
- İlk satır boş/çöp → atlanır
- anahtar_sonuclar: "/*madde1/*madde2" formatında, hem alt_faaliyetler TEXT hem de
  anahtar_sonuclar tablosuna ayrı satır olarak yazılır
"""

import csv
import os

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CSV_PATH = os.path.join(BASE_DIR, "inputs", "alt_faaliyetler.csv")
OUT_PATH = os.path.join(BASE_DIR, "supabase", "migrations",
                        "20260328130000_018_seed_alt_faaliyetler.sql")

def sq(val):
    """SQL string: None→NULL, string→'...' with escaped quotes."""
    if val is None or val == "":
        return "NULL"
    return "'" + str(val).replace("'", "''") + "'"

def num(val):
    return val.strip() if val and val.strip() else "NULL"

alt_rows = []      # alt_faaliyetler INSERT satırları
as_rows  = []      # anahtar_sonuclar INSERT satırları

with open(CSV_PATH, encoding="cp1254") as f:
    next(f)  # İlk boş/çöp satırı atla
    reader = csv.DictReader(f, delimiter=";")
    for row in reader:
        sno          = row["sno"].strip()
        fkod         = row["fkod"].strip()
        alt_faaliyet = row["alt_faaliyet"].strip()
        as_raw       = row["anahtar_sonuclar"].strip()
        p_sure       = num(row["p_sure"])
        tekrar       = num(row["tekrar_sayisi"])

        if not sno:
            continue  # Boş satır

        alt_rows.append(
            f"  ({sno}, {sq(fkod)}, {sq(alt_faaliyet)}, {sq(as_raw)}, "
            f"{p_sure}, {tekrar})"
        )

        # anahtar_sonuclar tablosu: "/*madde1/*madde2" → ayrı satırlar
        if as_raw:
            items = [i.strip() for i in as_raw.split("/*") if i.strip()]
            for as_no, item in enumerate(items, start=1):
                as_rows.append(f"  ({sno}, {as_no}, {sq(item)})")

alt_values = ",\n".join(alt_rows)
as_values  = ",\n".join(as_rows)

sql = f"""\
-- 018_seed_alt_faaliyetler.sql
-- inputs/alt_faaliyetler.csv → alt_faaliyetler + anahtar_sonuclar tabloları

BEGIN;

INSERT INTO alt_faaliyetler (sno, fkod, alt_faaliyet, anahtar_sonuclar, p_sure, tekrar_sayisi) VALUES
{alt_values};

INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
{as_values};

COMMIT;
"""

with open(OUT_PATH, "w", encoding="utf-8") as f:
    f.write(sql)

print(f"Üretildi: {OUT_PATH}")
print(f"alt_faaliyetler satırı: {len(alt_rows)}")
print(f"anahtar_sonuclar satırı: {len(as_rows)}")
