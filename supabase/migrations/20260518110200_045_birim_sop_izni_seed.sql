-- ============================================================
-- Migration 045: birim_sop_izni seed — mevcut görünürlüğü koru
-- UTF-8 NoBOM | DOKA Sprint Kanban
-- Tarih: 2026-05-18
-- Sprint: S3 (Birim-bazlı SOP Görünürlüğü)
-- ============================================================
-- Bu seed, 044 RLS sertleştirmesinden ÖNCE çalıştığında non-admin
-- kullanıcıların SOP listesini boşaltmaz:
--   * Her birim (birimler) × her SOP (soplar) kombinasyonu için bir satır
--   * okuma = TRUE (mevcut "tüm SOP'lar herkes tarafından görünür" davranışı)
--   * yazma = FALSE, silme = FALSE (admin matris üzerinden seçici şekilde açar)
--
-- Sonradan admin yetki-yonetimi.html "Birim-SOP Eşleme" sekmesinden
-- istediği birim×SOP×{yazma,silme} hücrelerini açar.
-- Mevcut sop_birim (M2M visibility tablosu) ile koşut çalışır — sop_birim
-- "SOP hangi birime sahiplenildi" semantiği taşır, birim_sop_izni ise
-- "her birim hangi SOP'ları ne yetkisiyle görür/değiştirir" semantiği.
--
-- ON CONFLICT: idempotent (re-run aynı sonuç).
-- ============================================================

BEGIN;

INSERT INTO birim_sop_izni (bkod, skod, okuma, yazma, silme)
  SELECT b.bkod, s.skod, TRUE, FALSE, FALSE
    FROM birimler b
    CROSS JOIN soplar s
ON CONFLICT (bkod, skod) DO NOTHING;

-- Doğrulama: kaç satır eklendi (info)
DO $$
DECLARE
  total_rows INTEGER;
  birim_count INTEGER;
  sop_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO birim_count FROM birimler;
  SELECT COUNT(*) INTO sop_count FROM soplar;
  SELECT COUNT(*) INTO total_rows FROM birim_sop_izni;

  RAISE NOTICE
    'birim_sop_izni seed: % birim × % sop → beklenen %, mevcut %',
    birim_count, sop_count, birim_count * sop_count, total_rows;
END $$;

COMMIT;
