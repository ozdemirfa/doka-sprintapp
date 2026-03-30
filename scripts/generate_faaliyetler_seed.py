"""
generate_faaliyetler_seed.py
inputs/faaliyetler.csv (cp1254) okur →
supabase/migrations/20260328120000_017_seed_faaliyetler.sql üretir
"""

import csv
import os

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CSV_PATH = os.path.join(BASE_DIR, "inputs", "faaliyetler.csv")
OUT_PATH = os.path.join(BASE_DIR, "supabase", "migrations",
                        "20260328120000_017_seed_faaliyetler.sql")

rows = []
with open(CSV_PATH, encoding="cp1254") as f:
    reader = csv.DictReader(f, delimiter=";")
    for row in reader:
        skod    = int(row["skod"].strip())
        kkod    = int(row["Kategori"].strip())
        faaliyet = row["faaliyet"].strip().replace("'", "''")  # SQL escape
        fkod    = row["fkod"].strip()
        fsirano = int(fkod[-2:])
        rows.append((skod, kkod, faaliyet, fkod, fsirano))

values = ",\n  ".join(
    f"({skod}, {kkod}, '{faaliyet}', '{fkod}', {fsirano})"
    for skod, kkod, faaliyet, fkod, fsirano in rows
)

sql = f"""\
-- 017_seed_faaliyetler.sql
-- inputs/faaliyetler.csv verilerini faaliyetler tablosuna yükler
-- Trigger devre dışı bırakılarak orijinal fkod değerleri korunur

BEGIN;

ALTER TABLE faaliyetler DISABLE TRIGGER trg_faaliyetler_fkod;

INSERT INTO faaliyetler (skod, kkod, faaliyet, fkod, fsirano) VALUES
  {values};

ALTER TABLE faaliyetler ENABLE TRIGGER trg_faaliyetler_fkod;

COMMIT;
"""

with open(OUT_PATH, "w", encoding="utf-8") as f:
    f.write(sql)

print(f"Üretildi: {OUT_PATH}")
print(f"Satır sayısı: {len(rows)}")
