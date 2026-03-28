-- 016_rename_butce_column.sql
-- faaliyetler.butce_2026 → sop_butce olarak yeniden adlandır

BEGIN;

-- 1. Kolon adını değiştir
ALTER TABLE faaliyetler RENAME COLUMN butce_2026 TO sop_butce;

-- 2. Etkilenen view'ı yeniden oluştur (kolon adı değiştiğinden önce drop gerekli)
DROP VIEW IF EXISTS v_faaliyet_ozet;
CREATE VIEW v_faaliyet_ozet AS
SELECT
    f.id,
    f.fkod,
    f.skod,
    f.kkod,
    f.faaliyet,
    f.sop_butce,
    AVG(vafo.is_durum_oran)               AS is_durum_ort,
    COALESCE(SUM(vafo.harcanan_butce), 0) AS harcanan_butce_toplam
FROM faaliyetler f
LEFT JOIN v_alt_faaliyet_ozet vafo ON vafo.fkod = f.fkod
GROUP BY f.id, f.fkod, f.skod, f.kkod, f.faaliyet, f.sop_butce;

COMMENT ON COLUMN faaliyetler.sop_butce IS 'SOP bütçesi (TL)';

COMMIT;
