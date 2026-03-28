-- ============================================================
-- Migration 014 — personel.eposta Sütunu
-- Tarih: 2026-04-01
-- ============================================================

-- personel tablosuna e-posta alanı ekle (görüntüleme/referans amaçlı)
-- Not: Login işlemi auth.users.email üzerinden devam eder.
ALTER TABLE personel ADD COLUMN IF NOT EXISTS eposta VARCHAR(255);

COMMENT ON COLUMN personel.eposta IS 'Görüntüleme/referans amaçlı e-posta alanı. Login için auth.users.email kullanılır.';
