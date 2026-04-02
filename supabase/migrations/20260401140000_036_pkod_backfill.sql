-- ============================================================
-- Migration 036: sprint_is_plani.pkod backfill
-- guncelleyen (ad) → personel.pkod eşleştirmesi
-- ============================================================

-- 1. Tekil ad eşleşmeleri (Elifnaz, Fatih, Nuray, Oğuzhan, Zübeyde)
UPDATE sprint_is_plani sip
SET pkod = p.pkod
FROM personel p
WHERE sip.pkod IS NULL
  AND LOWER(sip.guncelleyen) = LOWER(p.ad)
  AND p.ad NOT IN ('Mehmet');

-- 2. "Kemal Akpınar" → ad+soyad birleşik yazılmış → pkod=8
UPDATE sprint_is_plani
SET pkod = 8
WHERE pkod IS NULL
  AND LOWER(guncelleyen) = 'kemal akpınar';

-- 3. "Mehmet" → pkod=3 (Mehmet Sezgin)
UPDATE sprint_is_plani
SET pkod = 3
WHERE pkod IS NULL
  AND LOWER(guncelleyen) = 'mehmet';
