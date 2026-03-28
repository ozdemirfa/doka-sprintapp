-- ============================================================
-- Migration 010: fsirano NULL Backfill + NOT NULL Kısıtlaması
-- UTF-8 | DOKA Sprint Kanban
-- Tarih: 2026-03-29
-- ============================================================
-- SORUN:
-- 007_revisions.sql satır 75'te "ELSE NULL" kullanıldı.
-- fkod sonunda sayısal olmayan satırlar fsirano = NULL aldı.
-- fn_generate_fkod() trigger'ı MAX(fsirano) kullanırken
-- NULL satırları görmezden gelir → COALESCE(MAX(NULL), 0) + 1 = 1
-- → yeni insert için fsirano=1 hesaplanır
-- → aynı (skod, kkod) grubunda zaten fsirano=1 olan satır varsa
--   fkod UNIQUE kısıtlaması ihlal edilir.
-- ============================================================

-- BÖLÜM 1: fsirano NULL olan satırları backfill et
-- Sayısal soneki olan fkod'dan değeri parse et,
-- olmayanlar için (skod, kkod) grubu içindeki sıralı numara ata.
-- ============================================================

-- Önce sayısal soneği olan satırları parse ile güncelle
UPDATE faaliyetler
SET fsirano = REGEXP_REPLACE(fkod, '^.*?([0-9]+)$', '\1')::INTEGER
WHERE fsirano IS NULL
  AND fkod ~ '[0-9]+$';

-- Geri kalan NULL'lara (sayısal sonek yok) grup içi sıra numarası ver
WITH ranked AS (
    SELECT id,
           ROW_NUMBER() OVER (
               PARTITION BY skod, kkod
               ORDER BY fkod
           ) AS rn
    FROM faaliyetler
    WHERE fsirano IS NULL
)
UPDATE faaliyetler f
SET fsirano = (
    SELECT COALESCE(
        (SELECT MAX(f2.fsirano) FROM faaliyetler f2
         WHERE f2.skod = f.skod AND f2.kkod = f.kkod AND f2.fsirano IS NOT NULL),
        0
    ) + r.rn
    FROM ranked r WHERE r.id = f.id
)
WHERE fsirano IS NULL;

-- BÖLÜM 2: NOT NULL kısıtlaması ekle (yeniden NULL kalmasın)
ALTER TABLE faaliyetler ALTER COLUMN fsirano SET NOT NULL;

-- ============================================================
-- DOĞRULAMA SORGULARI
-- ============================================================
-- 1. NULL fsirano kaldı mı?
--    SELECT COUNT(*) FROM faaliyetler WHERE fsirano IS NULL;
--    → 0 olmalı
--
-- 2. (skod, kkod) grubu içinde fsirano tekrarı var mı?
--    SELECT skod, kkod, fsirano, COUNT(*)
--    FROM faaliyetler
--    GROUP BY skod, kkod, fsirano
--    HAVING COUNT(*) > 1;
--    → 0 satır olmalı
--
-- 3. fkod ile fsirano tutarlı mı?
--    SELECT fkod, fsirano FROM faaliyetler ORDER BY skod, kkod, fsirano;
-- ============================================================
