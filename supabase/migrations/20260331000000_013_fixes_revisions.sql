-- ============================================================
-- Migration 013 — RLS DELETE Policy Eklemeleri + perf_gostergeler Sütun Temizliği
-- Tarih: 2026-03-28
-- ============================================================

-- ──────────────────────────────────────────────────────────────
-- BÖLÜM 1: Eksik RLS DELETE policy'leri ekle
-- Neden: sprint_veri, alt_faaliyetler, perf_gostergeler tablolarında
-- INSERT/UPDATE policy mevcut ancak DELETE policy yok.
-- RLS'li tabloda eşleşmeyen DELETE → satır etkilenmez, error döndürülmez
-- → Frontend hata görmeden "Kayıt silindi" toast'u gösteriyor.
-- ──────────────────────────────────────────────────────────────

CREATE POLICY "sprint_veri_delete_yonetici"
    ON sprint_veri FOR DELETE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

CREATE POLICY "alt_faaliyetler_delete_yonetici"
    ON alt_faaliyetler FOR DELETE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

CREATE POLICY "perf_gostergeler_delete_yonetici"
    ON perf_gostergeler FOR DELETE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

-- ──────────────────────────────────────────────────────────────
-- BÖLÜM 2: perf_gostergeler yıllık sütunlarını kaldır
-- Neden: migration 011 ile perf_gost_yillik tablosu oluşturuldu ve
-- hedef_2024/2025/2026, gerceklesen_2024/2025/2026 verileri normalize edildi.
-- Artık bu sütunlar perf_gostergeler'de tutulmasına gerek yok.
-- v_perf_gosterge_ozet view'u bu sütunlara referans verdiğinden önce kaldırılmalı.
-- ──────────────────────────────────────────────────────────────

-- 2.1 View bağımlılığını kaldır
DROP VIEW IF EXISTS v_perf_gosterge_ozet;

-- 2.2 Yıllık sütunları kaldır
ALTER TABLE perf_gostergeler
    DROP COLUMN IF EXISTS hedef_2024,
    DROP COLUMN IF EXISTS hedef_2025,
    DROP COLUMN IF EXISTS hedef_2026,
    DROP COLUMN IF EXISTS gerceklesen_2024,
    DROP COLUMN IF EXISTS gerceklesen_2025,
    DROP COLUMN IF EXISTS gerceklesen_2026;

-- 2.3 View'u perf_gost_yillik JOIN'i ile yeniden oluştur
CREATE OR REPLACE VIEW v_perf_gosterge_ozet AS
SELECT
    pg.id,
    pg.cg_kod,
    pg.skod,
    pg.kkod,
    pg.bilesen_kodu,
    pg.bilesen_adi,
    pg.cikti_gostergesi,
    pg.birim,
    pg.hedef,
    pg.tamamlanma_donemi,
    pg.katki_sonuc_gostergesi,
    pg.aciklama,
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

COMMENT ON VIEW v_perf_gosterge_ozet IS 'Performans göstergesi bazlı kümülatif gerçekleşme ve hedef karşılaştırması (perf_gost_yillik ile normalize edilmiş)';
