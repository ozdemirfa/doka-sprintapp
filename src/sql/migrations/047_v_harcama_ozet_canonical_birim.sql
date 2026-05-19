-- ============================================================
-- Migration 047 — v_harcama_ozet.bkod canonical SOP chain
-- Tarih: 2026-05-19
--
-- Amaç:
--   v_harcama_ozet.bkod artık canonical SOP chain üzerinden:
--     harcamalar.sprint_is_plani_id
--       → sprint_is_plani.sno
--       → alt_faaliyetler.fkod
--       → faaliyetler.skod
--       → soplar.bkod
--   Fallback: sprint_is_plani.andaki_birim (legacy field, NULL olabilir)
--
--   Önceki davranış (046): yalnızca andaki_birim kullanılıyordu →
--   NULL kalan kayıtlar birim filtresinde elenip görünmüyordu.
--
-- Test: production'da id=1 harcamasının SKB (bkod=1) olarak filtrelenmesi
-- ============================================================

DROP VIEW IF EXISTS v_harcama_ozet;
CREATE VIEW v_harcama_ozet AS
SELECT
    h.id,
    h.aciklama,
    h.harcama_onay_kodu,
    h.onay_tarihi,
    h.odeme_donem,
    h.odenecek_kdvli,
    h.guncel_tarih,
    h.guncelleyen,
    h.created_at,
    h.sprint_is_plani_id,
    -- canonical: SOP'un birimi; fallback: sip.andaki_birim
    COALESCE(s.bkod, sip.andaki_birim) AS bkod,
    sip.pkod AS pkod
FROM harcamalar h
LEFT JOIN sprint_is_plani sip ON sip.id  = h.sprint_is_plani_id
LEFT JOIN alt_faaliyetler  af  ON af.sno = sip.sno
LEFT JOIN faaliyetler      f   ON f.fkod = af.fkod
LEFT JOIN soplar           s   ON s.skod = f.skod;

COMMENT ON VIEW v_harcama_ozet IS
'047: harcamalar özet view; bkod = COALESCE(soplar.bkod via sip->af->f, sip.andaki_birim)';
