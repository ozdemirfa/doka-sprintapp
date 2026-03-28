-- ============================================================
-- Migration 012: İzleyici Rolü + perf_gostergeler.aciklama + personel.durum
-- UTF-8 | DOKA Sprint Kanban
-- Tarih: 2026-03-30
-- ============================================================
-- AMAÇ:
-- 1. kullanici_rolleri tablosuna 'izleyici' rol_kodu eklenir.
--    İzleyici: sadece okuma erişimi, yazma işlemleri yasak.
-- 2. perf_gostergeler tablosuna 'aciklama' kolonu eklenir.
--    (Migration 007'de atlandı; ayarlar.html sorgu hatası düzeltilir.)
-- 3. personel tablosuna 'durum' kolonu eklenir (Aktif/Pasif).
--    Mevcut satırlar 'Aktif' olarak backfill edilir.
-- ============================================================

-- BÖLÜM 1: İzleyici rolü
-- ============================================================
INSERT INTO kullanici_rolleri (rol_kodu, aciklama)
VALUES ('izleyici', 'Görüntüleme amacıyla. Sadece okuma erişimi.')
ON CONFLICT (rol_kodu) DO NOTHING;

-- BÖLÜM 2: perf_gostergeler.aciklama eksik kolon
-- ============================================================
ALTER TABLE perf_gostergeler ADD COLUMN IF NOT EXISTS aciklama TEXT;

COMMENT ON COLUMN perf_gostergeler.aciklama IS 'Performans göstergesi için ek açıklama';

-- BÖLÜM 3: personel.durum kolonu (Aktif/Pasif)
-- ============================================================
ALTER TABLE personel ADD COLUMN IF NOT EXISTS durum VARCHAR(20) DEFAULT 'Aktif';

-- Mevcut satırları backfill et
UPDATE personel SET durum = 'Aktif' WHERE durum IS NULL;

COMMENT ON COLUMN personel.durum IS 'Personel durumu: Aktif veya Pasif. Pasif personel form dropdownlarında gösterilmez.';

-- ============================================================
-- DOĞRULAMA SORGULARI
-- ============================================================
-- 1. İzleyici rolü eklendi mi?
--    SELECT rol_kodu, aciklama FROM kullanici_rolleri WHERE rol_kodu = 'izleyici';
--    → 1 satır: izleyici
--
-- 2. perf_gostergeler.aciklama var mı?
--    SELECT column_name, data_type FROM information_schema.columns
--    WHERE table_name = 'perf_gostergeler' AND column_name = 'aciklama';
--    → 1 satır: aciklama, text
--
-- 3. personel.durum var mı, NULL kalmadı mı?
--    SELECT COUNT(*) FROM personel WHERE durum IS NULL;
--    → 0 olmalı
--    SELECT DISTINCT durum FROM personel;
--    → 'Aktif' ve varsa 'Pasif'
-- ============================================================
