-- ============================================================
-- Migration 006: Bug Fixes & Schema Enhancements
-- Vercel test sonrası düzeltmeler
-- ============================================================

-- 1. sprint_retro: JS'in beklediği sütunları ekle
--    (sprint_toplanti kolonu korunur, yeni sütunlar eklenir)
ALTER TABLE sprint_retro ADD COLUMN IF NOT EXISTS sprint_donem INTEGER REFERENCES sprint_veri(sprint_donem);
ALTER TABLE sprint_retro ADD COLUMN IF NOT EXISTS org_puan     INTEGER CHECK (org_puan BETWEEN 1 AND 10);
ALTER TABLE sprint_retro ADD COLUMN IF NOT EXISTS gort         DECIMAL(5,2);

-- 2. perf_gostergeler: 2026 gerçekleşme sütunu
ALTER TABLE perf_gostergeler ADD COLUMN IF NOT EXISTS gerceklesen_2026 DECIMAL(10,2);

-- 3. harcamalar: çoklu ödeme dönemi desteği (JSONB)
--    Mevcut odeme_donem ve odenecek_kdvli korunur, geriye dönük uyumlu
ALTER TABLE harcamalar ADD COLUMN IF NOT EXISTS odeme_kalemleri JSONB;

-- 4. harcamalar: sprint_faaliyet sütunu (zaten varsa pas geç)
--    Kontrol: SELECT column_name FROM information_schema.columns
--    WHERE table_name='harcamalar' AND column_name='sprint_faaliyet';
-- (Bu sütun 001_schema.sql'de zaten tanımlanmış)

-- 5. RLS: sprint_is_plani INSERT — standart kullanıcı sadece kendine ekleyebilir
DROP POLICY IF EXISTS "sprint_is_plani_insert" ON sprint_is_plani;
CREATE POLICY "sprint_is_plani_insert"
    ON sprint_is_plani FOR INSERT
    TO authenticated
    WITH CHECK (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
        OR ekip_uyesi = (SELECT CONCAT(ad, ' ', soyad) FROM personel WHERE auth_id = auth.uid())
    );

-- 6. RLS: sprint_is_plani UPDATE — sadece yönetici veya kendi görevi
--    (Mevcut politika zaten bu şekilde ama yeniden oluştur)
DROP POLICY IF EXISTS "sprint_is_plani_update" ON sprint_is_plani;
CREATE POLICY "sprint_is_plani_update"
    ON sprint_is_plani FOR UPDATE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
        OR ekip_uyesi = (SELECT CONCAT(ad, ' ', soyad) FROM personel WHERE auth_id = auth.uid())
    );

-- 7. izinler: tur sütunu ekle (Yıllık/Hastalık/Ücretsiz/Diğer)
ALTER TABLE izinler ADD COLUMN IF NOT EXISTS tur VARCHAR(20);

-- 8. faaliyetler: yil sütunu ekle (v_faaliyet_ozet view'ı için zorunlu)
ALTER TABLE faaliyetler ADD COLUMN IF NOT EXISTS yil INTEGER DEFAULT 2026;

-- 9. sprint_retro: eski organizasyon_puan verisini yeni org_puan sütununa kopyala
UPDATE sprint_retro SET org_puan = organizasyon_puan WHERE org_puan IS NULL AND organizasyon_puan IS NOT NULL;

-- 10. sprint_perf_gos için sprint_donem sütunu ekle (tarih bazlı filtre için)
ALTER TABLE sprint_perf_gos ADD COLUMN IF NOT EXISTS sprint_donem INTEGER REFERENCES sprint_veri(sprint_donem);

-- 8. v_sprint_ozet: retro_agg'i sprint_donem üzerinden birleştir
--    (sprint_toplanti DATE yerine yeni sprint_donem INTEGER kullan)
CREATE OR REPLACE VIEW v_sprint_ozet AS
WITH
sip_agg AS (
    SELECT
        sprint_donem,
        COALESCE(SUM(plan_sure), 0)                                             AS plan_toplam,
        COALESCE(SUM(CASE WHEN is_durum = 'Tamamlandı' AND bitis_donem = sprint_donem
            THEN plan_sure ELSE 0 END), 0)                                      AS t_skor,
        COALESCE(SUM(CASE WHEN is_durum = 'Tamamlandı' AND bitis_donem = sprint_donem
            THEN gercek_sure ELSE 0 END), 0)                                    AS gerceklesme
    FROM sprint_is_plani
    GROUP BY sprint_donem
),
retro_agg AS (
    SELECT
        sprint_donem,
        AVG(org_puan)                                                           AS org_puan,
        AVG(SQRT(ajanstaki_rolu::float * ajans_hakkinda::float))                AS hepiniss
    FROM sprint_retro
    WHERE sprint_donem IS NOT NULL
      AND ajanstaki_rolu IS NOT NULL AND ajans_hakkinda IS NOT NULL
    GROUP BY sprint_donem
)
SELECT
    sv.sprint_donem,
    sv.baslangic,
    sv.bitis,
    sv.sprint_adi,
    sv.isim_veren,
    sv.sure_gun,
    sv.ekip,
    sv.izin,
    sv.saha,
    ra.org_puan,
    ra.hepiniss,
    COALESCE(sa.t_skor, 0)                                                      AS t_skor,
    CASE
        WHEN (sv.sure_gun * sv.ekip - COALESCE(sv.izin, 0)) > 0
        THEN COALESCE(sa.t_skor, 0)::float
             / (sv.sure_gun * sv.ekip - COALESCE(sv.izin, 0)) * 100
        ELSE 0
    END                                                                         AS gki,
    COALESCE(sa.plan_toplam, 0)                                                 AS plan_toplam,
    COALESCE(sa.gerceklesme, 0)                                                 AS gerceklesme
FROM sprint_veri sv
LEFT JOIN sip_agg sa ON sa.sprint_donem = sv.sprint_donem
LEFT JOIN retro_agg ra ON ra.sprint_donem = sv.sprint_donem;

-- 9. v_faaliyet_ozet: yil sütunu ekle (yıl bazlı filtre için)
CREATE OR REPLACE VIEW v_faaliyet_ozet AS
SELECT
    f.fkod,
    f.sop,
    f.kategori,
    f.faaliyet,
    f.yil,
    f.butce_2026,
    f.aylik_plan,
    AVG(vafo.is_durum_oran)                                                     AS is_durum_ort,
    COALESCE(SUM(vafo.harcanan_butce), 0)                                       AS harcanan_butce_toplam
FROM faaliyetler f
LEFT JOIN v_alt_faaliyet_ozet vafo ON vafo.fkod = f.fkod
GROUP BY f.fkod, f.sop, f.kategori, f.faaliyet, f.yil, f.butce_2026, f.aylik_plan;
