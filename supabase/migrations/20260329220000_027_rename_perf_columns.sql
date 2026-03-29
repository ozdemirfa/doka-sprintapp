-- 027_rename_perf_columns.sql
-- perf_gostergeler tablosunda iki kolon adı değişikliği:
--   hedef              → kumulatif_hedef
--   tamamlanma_donemi  → planlanan_tamamlanma_donemi
-- v_perf_gosterge_ozet view yeniden oluşturulur:
--   yeni kolon adları + soplar JOIN (sop, baslangic, bitis alanları eklenir)

-- 1. View bağımlılığını kaldır
DROP VIEW IF EXISTS v_perf_gosterge_ozet;

-- 2. Kolon adı değişiklikleri
ALTER TABLE perf_gostergeler RENAME COLUMN hedef TO kumulatif_hedef;
ALTER TABLE perf_gostergeler RENAME COLUMN tamamlanma_donemi TO planlanan_tamamlanma_donemi;

-- 3. View'u yeni kolon adları ve soplar JOIN ile yeniden oluştur
CREATE OR REPLACE VIEW v_perf_gosterge_ozet AS
SELECT
    pg.id,
    pg.cg_kod,
    pg.skod,
    pg.kkod,
    pg.pg_sira,
    pg.bilesen_kodu,
    pg.bilesen_adi,
    pg.cikti_gostergesi,
    pg.birim,
    pg.kumulatif_hedef,
    pg.planlanan_tamamlanma_donemi,
    pg.katki_sonuc_gostergesi,
    pg.aciklama,
    -- soplar alanları (frontend yıl filtresi ve SOP bilgisi için)
    s.kisa                          AS sop,
    s.baslangic                     AS baslangic,
    s.bitis                         AS bitis,
    -- Yıllık hedef ve gerçekleşme
    COALESCE(pgy_2024.hedef,        0) AS hedef_2024,
    COALESCE(pgy_2024.gerceklesen,  0) AS gerceklesen_2024,
    COALESCE(pgy_2025.hedef,        0) AS hedef_2025,
    COALESCE(pgy_2025.gerceklesen,  0) AS gerceklesen_2025,
    COALESCE(pgy_2026.hedef,        0) AS hedef_2026,
    COALESCE(spg_2026.toplam,       0) AS gerceklesen_2026,
    (COALESCE(pgy_2024.gerceklesen, 0)
     + COALESCE(pgy_2025.gerceklesen, 0)
     + COALESCE(spg_2026.toplam,    0)) AS kumulatif_gerceklesme
FROM perf_gostergeler pg
LEFT JOIN soplar s
       ON s.skod = pg.skod
LEFT JOIN perf_gost_yillik pgy_2024
       ON pgy_2024.cg_kod = pg.cg_kod AND pgy_2024.yil = 2024
LEFT JOIN perf_gost_yillik pgy_2025
       ON pgy_2025.cg_kod = pg.cg_kod AND pgy_2025.yil = 2025
LEFT JOIN perf_gost_yillik pgy_2026
       ON pgy_2026.cg_kod = pg.cg_kod AND pgy_2026.yil = 2026
LEFT JOIN (
    SELECT cg_kod, SUM(gerceklesme) AS toplam
    FROM sprint_perf_gos
    WHERE yil = 2026
    GROUP BY cg_kod
) spg_2026 ON spg_2026.cg_kod = pg.cg_kod;

COMMENT ON VIEW v_perf_gosterge_ozet IS 'Performans göstergesi bazlı kümülatif gerçekleşme ve hedef karşılaştırması (perf_gost_yillik ile normalize edilmiş; soplar JOIN dahil)';
