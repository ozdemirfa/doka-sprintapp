"""
generate_sprint_is_plani_seed.py
inputs/sprint_is_plan.csv (cp1254) okur →
supabase/migrations/20260328150000_020_seed_sprint_is_plani.sql üretir

Notlar:
- sno 77,78,79,80 alt_faaliyetler'de yok → NULL
- sprint_veri 1-4 için minimal kayıt eklenir
- Tarih: DD.MM.YYYY / D.MM.YYYY / DD MM YYYY → YYYY-MM-DD
- Ondalık: "0,5" → 0.5
- performans_gostergeler: ilk karakter düzeltilir (? → C)
"""

import csv
import os
import re

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CSV_PATH = os.path.join(BASE_DIR, "inputs", "sprint_is_plan.csv")
OUT_PATH = os.path.join(BASE_DIR, "supabase", "migrations",
                        "20260328150000_020_seed_sprint_is_plani.sql")

# sno remapping: CSV'deki 77-80 → alt_faaliyetler'e eklenecek 54-57
SNO_MAP = {77: 54, 78: 55, 79: 56, 80: 57}

def sq(val):
    if val is None or val == "":
        return "NULL"
    return "'" + str(val).replace("'", "''") + "'"

def parse_date(val):
    """DD.MM.YYYY / D.MM.YYYY / DD MM YYYY / D MM YYYY → 'YYYY-MM-DD' veya NULL."""
    if not val or not val.strip():
        return "NULL"
    v = val.strip()
    # Nokta veya boşlukla ayrılmış 3 parça
    parts = re.split(r'[.\s]+', v)
    if len(parts) == 3:
        try:
            d, m, y = int(parts[0]), int(parts[1]), int(parts[2])
            return f"'{y:04d}-{m:02d}-{d:02d}'"
        except ValueError:
            pass
    return "NULL"

def parse_num(val):
    """Türkçe ondalık (0,5) → SQL sayısı veya NULL."""
    if not val or not val.strip():
        return "NULL"
    v = val.strip().replace(',', '.')
    try:
        float(v)
        return v
    except ValueError:
        return "NULL"

def fix_perf(val):
    """?GSTU41 → CGSTU41 (ilk ? karakterini C ile değiştir)."""
    if not val or not val.strip():
        return None
    v = val.strip()
    if v and v[0] not in ('C', 'c') and len(v) > 1 and v[1] == 'G':
        v = 'C' + v[1:]
    return v

rows = []

with open(CSV_PATH, encoding="cp1254") as f:
    reader = csv.DictReader(f, delimiter=";")
    for row in reader:
        sprint_donem = row["sprint_donem"].strip()
        if not sprint_donem:
            continue  # Boş satır

        sno_raw = row["sno"].strip()
        sno_int = int(sno_raw) if sno_raw else None
        if sno_int is not None:
            sno_int = SNO_MAP.get(sno_int, sno_int)  # 77→1, 78→2, 79→3, 80→4
        sno_val = str(sno_int) if sno_int is not None else "NULL"

        bitis_raw = row["bitis_donem"].strip()
        bitis_val = bitis_raw if bitis_raw else "NULL"

        is_durum = row["is_durum"].strip() or None

        rows.append({
            "sprint_donem":        sprint_donem,
            "bitis_donem":         bitis_val,
            "sprint_faaliyetleri": row["sprint_faaliyetleri"].strip(),
            "sno":                 sno_val,
            "plan_sure":           parse_num(row["plan_sure"]),
            "is_durum":            sq(is_durum),
            "baslama_t":           parse_date(row["baslama_t"]),
            "inceleme_t":          parse_date(row["inceleme_t"]),
            "tamamlanma_t":        parse_date(row["tamamlanma_t"]),
            "gercek_sure":         parse_num(row["gercek_sure"]),
            "performans_gostergeler": sq(fix_perf(row["performans_gostergeler"])),
            "guncel_tarih":        parse_date(row["guncel_tarih"]),
            "guncelleyen":         sq(row["guncelleyen"].strip()),
            "pkod":                row["pkod"].strip() or "NULL",
        })

values = ",\n  ".join(
    f"({r['sprint_donem']}, {r['bitis_donem']}, {sq(r['sprint_faaliyetleri'])}, "
    f"{r['sno']}, {r['plan_sure']}, {r['is_durum']}, "
    f"{r['baslama_t']}, {r['inceleme_t']}, {r['tamamlanma_t']}, "
    f"{r['gercek_sure']}, {r['performans_gostergeler']}, "
    f"{r['guncel_tarih']}, {r['guncelleyen']}, {r['pkod']})"
    for r in rows
)

sql = f"""\
-- 020_seed_sprint_is_plani.sql
-- inputs/sprint_is_plan.csv → alt_faaliyetler (54-57) + sprint_veri (1-4) + sprint_is_plani

BEGIN;

-- alt_faaliyetler: sno 54-57 (CSV'deki 77,78,79,80 için)
INSERT INTO alt_faaliyetler (sno, fkod, alt_faaliyet, p_sure, tekrar_sayisi)
VALUES
  (54, 'SDD601', 'Diğer görevler (genel koordinasyon ve idari işler)', 1, 12),
  (55, 'SDD601', 'Diğer görevler 2', 1, 1),
  (56, 'ABP601', 'AB ve uluslararası proje görevleri (genel)', 1, 1),
  (57, 'SOG601', 'SoGreen proje görevleri (genel)', 1, 1)
ON CONFLICT (sno) DO NOTHING;

-- sprint_veri: sprint 1-4 için minimal kayıtlar
INSERT INTO sprint_veri (sprint_donem, sprint_adi, baslangic, bitis)
VALUES
  (1, 'Sprint 1', '2026-01-05', '2026-02-01'),
  (2, 'Sprint 2', '2026-02-02', '2026-02-22'),
  (3, 'Sprint 3', '2026-02-23', '2026-03-15'),
  (4, 'Sprint 4', '2026-03-16', '2026-04-05')
ON CONFLICT (sprint_donem) DO NOTHING;

INSERT INTO sprint_is_plani
  (sprint_donem, bitis_donem, sprint_faaliyetleri, sno, plan_sure,
   is_durum, baslama_t, inceleme_t, tamamlanma_t, gercek_sure,
   performans_gostergeler, guncel_tarih, guncelleyen, pkod)
VALUES
  {values};

COMMIT;
"""

with open(OUT_PATH, "w", encoding="utf-8") as f:
    f.write(sql)

print(f"Üretildi: {OUT_PATH}")
print(f"sprint_is_plani satırı: {len(rows)}")
null_sno = [r for r in rows if r['sno'] == 'NULL']
print(f"NULL sno: {len(null_sno)} satır")
