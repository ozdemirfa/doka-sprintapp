-- ============================================================
-- Migration 008: Schema Revisions 2
-- UTF-8 | DOKA Sprint Kanban
-- Tarih: 2026-03-27
-- ============================================================
-- ÇALIŞTIRMADAN ÖNCE: Supabase Dashboard → Settings → Database → Backup alın.
-- Bu migration geri alınamaz işlemler içermektedir.
-- ============================================================

-- ============================================================
-- BÖLÜM 0: VIEW'LARI KALDIR (bağımlı tablolar değişecek)
-- ============================================================
DROP VIEW IF EXISTS v_faaliyet_ozet;
DROP VIEW IF EXISTS v_alt_faaliyet_ozet;
DROP VIEW IF EXISTS v_sprint_ozet;

-- ============================================================
-- BÖLÜM 1: YENİ TABLO — faaliyet_yil_butce
-- ============================================================
CREATE TABLE IF NOT EXISTS faaliyet_yil_butce (
    id          SERIAL PRIMARY KEY,
    faaliyet_id INTEGER NOT NULL REFERENCES faaliyetler(id) ON DELETE CASCADE,
    yil         INTEGER NOT NULL,
    butce       DECIMAL(15,2) NOT NULL DEFAULT 0,
    CONSTRAINT uq_faaliyet_yil UNIQUE (faaliyet_id, yil)
);

CREATE INDEX IF NOT EXISTS idx_faaliyet_yil_butce_faaliyet_id ON faaliyet_yil_butce(faaliyet_id);
CREATE INDEX IF NOT EXISTS idx_faaliyet_yil_butce_yil         ON faaliyet_yil_butce(yil);

ALTER TABLE faaliyet_yil_butce ENABLE ROW LEVEL SECURITY;

-- SELECT: tüm authenticated kullanıcılar
DROP POLICY IF EXISTS "faaliyet_yil_butce_select" ON faaliyet_yil_butce;
CREATE POLICY "faaliyet_yil_butce_select"
    ON faaliyet_yil_butce FOR SELECT
    TO authenticated
    USING (true);

-- INSERT: yalnızca yöneticiler
DROP POLICY IF EXISTS "faaliyet_yil_butce_insert_yonetici" ON faaliyet_yil_butce;
CREATE POLICY "faaliyet_yil_butce_insert_yonetici"
    ON faaliyet_yil_butce FOR INSERT
    TO authenticated
    WITH CHECK (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

-- UPDATE: yalnızca yöneticiler
DROP POLICY IF EXISTS "faaliyet_yil_butce_update_yonetici" ON faaliyet_yil_butce;
CREATE POLICY "faaliyet_yil_butce_update_yonetici"
    ON faaliyet_yil_butce FOR UPDATE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    )
    WITH CHECK (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

-- DELETE: yalnızca yöneticiler
DROP POLICY IF EXISTS "faaliyet_yil_butce_delete_yonetici" ON faaliyet_yil_butce;
CREATE POLICY "faaliyet_yil_butce_delete_yonetici"
    ON faaliyet_yil_butce FOR DELETE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

-- Seed: faaliyetler.butce_2026 → faaliyet_yil_butce (2026 yılı için)
-- NOT: butce_2026 kolonu bu migration'da KALDIRILMIYOR
INSERT INTO faaliyet_yil_butce (faaliyet_id, yil, butce)
SELECT id, 2026, COALESCE(butce_2026, 0)
FROM faaliyetler
WHERE butce_2026 IS NOT NULL
ON CONFLICT (faaliyet_id, yil) DO NOTHING;

-- ============================================================
-- BÖLÜM 2: TRIGGER — fn_sync_performans_gostergeler()
-- AFTER INSERT OR UPDATE OR DELETE on sprint_perf_gos
-- sprint_is_plani.performans_gostergeler'i STRING_AGG ile günceller
-- ============================================================
CREATE OR REPLACE FUNCTION fn_sync_performans_gostergeler()
RETURNS TRIGGER AS $$
DECLARE
    v_sip_id INTEGER;
    v_agg    TEXT;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_sip_id := OLD.sprint_is_plani_id;
    ELSE
        v_sip_id := NEW.sprint_is_plani_id;
    END IF;

    IF v_sip_id IS NULL THEN
        RETURN COALESCE(NEW, OLD);
    END IF;

    -- On UPDATE, also sync the old parent if sprint_is_plani_id changed
    IF TG_OP = 'UPDATE' AND OLD.sprint_is_plani_id IS DISTINCT FROM NEW.sprint_is_plani_id
       AND OLD.sprint_is_plani_id IS NOT NULL THEN
        SELECT COALESCE(STRING_AGG(cg_kod, ',' ORDER BY cg_kod), '')
        INTO v_agg
        FROM sprint_perf_gos
        WHERE sprint_is_plani_id = OLD.sprint_is_plani_id;
        UPDATE sprint_is_plani SET performans_gostergeler = v_agg WHERE id = OLD.sprint_is_plani_id;
    END IF;

    SELECT COALESCE(STRING_AGG(cg_kod, ',' ORDER BY cg_kod), '')
    INTO v_agg
    FROM sprint_perf_gos
    WHERE sprint_is_plani_id = v_sip_id;

    UPDATE sprint_is_plani
    SET performans_gostergeler = v_agg
    WHERE id = v_sip_id;

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_sync_performans_gostergeler ON sprint_perf_gos;
CREATE TRIGGER trg_sync_performans_gostergeler
    AFTER INSERT OR UPDATE OR DELETE ON sprint_perf_gos
    FOR EACH ROW
    EXECUTE FUNCTION fn_sync_performans_gostergeler();

-- ============================================================
-- BÖLÜM 3: TRIGGER — fn_set_tamamlanma_donemi()
-- BEFORE INSERT OR UPDATE OF tamamlanma_tarihi on sprint_perf_gos
-- Format: YEAR || '/' || QUARTER (örn: "2026/1")
-- NULL tarih → NULL dönem
-- ============================================================
CREATE OR REPLACE FUNCTION fn_set_tamamlanma_donemi()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.tamamlanma_tarihi IS NOT NULL THEN
        NEW.tamamlanma_donemi :=
            EXTRACT(YEAR FROM NEW.tamamlanma_tarihi)::INTEGER::TEXT
            || '/'
            || EXTRACT(QUARTER FROM NEW.tamamlanma_tarihi)::INTEGER::TEXT;
    ELSE
        NEW.tamamlanma_donemi := NULL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_set_tamamlanma_donemi ON sprint_perf_gos;
CREATE TRIGGER trg_set_tamamlanma_donemi
    BEFORE INSERT OR UPDATE OF tamamlanma_tarihi ON sprint_perf_gos
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_tamamlanma_donemi();

-- ============================================================
-- BÖLÜM 4: v_alt_faaliyet_ozet YENİDEN OLUŞTUR
-- (is_durum_oran → ROUND(..., 2) eklendi)
-- ============================================================
CREATE OR REPLACE VIEW v_alt_faaliyet_ozet AS
SELECT
    af.sno,
    af.fkod,
    af.alt_faaliyet,
    af.anahtar_sonuclar,
    af.p_sure,
    af.tekrar_sayisi,
    -- İş yükü: p_sure × tekrar_sayisi
    COALESCE(af.p_sure * af.tekrar_sayisi, 0)                           AS is_yuku,
    -- Gerçekleşme sayısı: tüm sprint_is_plani bağlı kayıtların sayısı
    COUNT(si.id)                                                         AS gerceklesme_sayi,
    -- Gerçek iş yükü: gerçek süre toplamı
    COALESCE(SUM(si.gercek_sure), 0)                                    AS gercek_is_yuku,
    -- Harcanan bütçe: harcamalar tablosundan sprint_is_plani üzerinden
    COALESCE(SUM(h.odenecek_kdvli), 0)                                  AS harcanan_butce,
    -- İş durum oranı: gerceklesme_sayi / tekrar_sayisi (2 ondalık basamağa yuvarlanmış)
    CASE
        WHEN af.tekrar_sayisi > 0
        THEN ROUND(COUNT(si.id)::DECIMAL / af.tekrar_sayisi::NUMERIC, 2)
        ELSE NULL
    END                                                                  AS is_durum_oran
FROM alt_faaliyetler af
LEFT JOIN sprint_is_plani si ON si.sno = af.sno
LEFT JOIN harcamalar h ON h.sprint_is_plani_id = si.id
GROUP BY af.sno, af.fkod, af.alt_faaliyet, af.anahtar_sonuclar,
         af.p_sure, af.tekrar_sayisi;

COMMENT ON VIEW v_alt_faaliyet_ozet IS 'Alt faaliyet bazlı iş yükü, gerçekleşme ve harcama özeti';

-- v_faaliyet_ozet — 007 ile aynı (BÖLÜM 0'da drop edildiği için yeniden oluşturuluyor)
CREATE OR REPLACE VIEW v_faaliyet_ozet AS
SELECT
    f.id,
    f.fkod,
    f.skod,
    f.kkod,
    f.faaliyet,
    f.butce_2026,
    AVG(vafo.is_durum_oran)             AS is_durum_ort,
    COALESCE(SUM(vafo.harcanan_butce), 0) AS harcanan_butce_toplam
FROM faaliyetler f
LEFT JOIN v_alt_faaliyet_ozet vafo ON vafo.fkod = f.fkod
GROUP BY f.id, f.fkod, f.skod, f.kkod, f.faaliyet, f.butce_2026;

COMMENT ON VIEW v_faaliyet_ozet IS 'Faaliyet bazlı bütçe, durum ve ilerleme özeti';

-- ============================================================
-- BÖLÜM 5: v_sprint_ozet YENİDEN OLUŞTUR
-- (gki → ROUND(..., 2) eklendi)
-- ============================================================
CREATE OR REPLACE VIEW v_sprint_ozet AS
WITH
sip_agg AS (
    SELECT
        sprint_donem,
        COALESCE(SUM(plan_sure), 0)                                          AS plan_toplam,
        COALESCE(SUM(CASE WHEN is_durum = 'Tamamlandı' AND bitis_donem = sprint_donem
            THEN plan_sure ELSE 0 END), 0)                                   AS t_skor,
        COALESCE(SUM(CASE WHEN is_durum = 'Tamamlandı' AND bitis_donem = sprint_donem
            THEN gercek_sure ELSE 0 END), 0)                                 AS gerceklesme
    FROM sprint_is_plani
    GROUP BY sprint_donem
),
retro_agg AS (
    SELECT
        sprint_donem,
        EXP(AVG(LN(NULLIF(organizasyon_puan::float, 0))))                   AS org_puan,
        EXP(AVG(LN(NULLIF(aort::float, 0))))                                AS hepiniss
    FROM sprint_retro
    WHERE sprint_donem IS NOT NULL
      AND ajanstaki_rolu IS NOT NULL AND ajans_hakkinda IS NOT NULL
    GROUP BY sprint_donem
),
izin_agg AS (
    SELECT
        sv.sprint_donem,
        COALESCE(SUM(iz.izin_gun_sayi), 0) AS toplam_izin
    FROM sprint_veri sv
    LEFT JOIN izinler iz
        ON iz.izin_basl <= sv.bitis AND iz.izin_bitis >= sv.baslangic
    GROUP BY sv.sprint_donem
),
saha_agg AS (
    SELECT
        sv.sprint_donem,
        COALESCE(SUM(sg.gorev_gun), 0) AS toplam_saha
    FROM sprint_veri sv
    LEFT JOIN saha_gorevleri sg
        ON sg.tarih BETWEEN sv.baslangic AND sv.bitis
    GROUP BY sv.sprint_donem
)
SELECT
    sv.sprint_donem,
    sv.baslangic,
    sv.bitis,
    sv.sprint_adi,
    sv.isim_veren,
    sv.sure_gun,
    sv.ekip,
    ia.toplam_izin                                                           AS izin,
    sa.toplam_saha                                                           AS saha,
    ra.org_puan,
    ra.hepiniss,
    COALESCE(sip.t_skor, 0)                                                  AS t_skor,
    CASE
        WHEN (sv.sure_gun * sv.ekip - COALESCE(ia.toplam_izin, 0)) > 0
        THEN ROUND(
            COALESCE(sip.t_skor, 0)::NUMERIC
            / (sv.sure_gun * sv.ekip - COALESCE(ia.toplam_izin, 0)) * 100,
            2
        )
        ELSE 0
    END                                                                      AS gki,
    COALESCE(sip.plan_toplam, 0)                                             AS plan_toplam,
    COALESCE(sip.gerceklesme, 0)                                             AS gerceklesme
FROM sprint_veri sv
LEFT JOIN sip_agg sip ON sip.sprint_donem = sv.sprint_donem
LEFT JOIN retro_agg ra  ON ra.sprint_donem = sv.sprint_donem
LEFT JOIN izin_agg ia   ON ia.sprint_donem = sv.sprint_donem
LEFT JOIN saha_agg sa   ON sa.sprint_donem = sv.sprint_donem;

COMMENT ON VIEW v_sprint_ozet IS 'Sprint bazlı GKİ (yuvarlanmış), Hepiniss, T.Skor, OrgPuan — izin/saha canlı hesaplama';

-- ============================================================
-- BÖLÜM 6: DOĞRULAMA SORGULARI
-- ============================================================
-- Aşağıdaki SELECT'leri çalıştırarak migration'ı doğrulayın:
--
-- 1. faaliyet_yil_butce tablosu oluşturuldu mu?
--    SELECT COUNT(*) FROM faaliyet_yil_butce;
--    → faaliyetler.butce_2026 IS NOT NULL olan satır sayısı kadar
--
-- 2. faaliyet_yil_butce seed verileri doğru mu?
--    SELECT fyb.faaliyet_id, fyb.yil, fyb.butce, f.butce_2026
--    FROM faaliyet_yil_butce fyb
--    JOIN faaliyetler f ON f.id = fyb.faaliyet_id
--    WHERE fyb.yil = 2026
--    LIMIT 5;
--    → butce ve butce_2026 değerleri eşleşmeli
--
-- 3. trg_sync_performans_gostergeler trigger'ı aktif mi?
--    SELECT trigger_name, event_manipulation, event_object_table
--    FROM information_schema.triggers
--    WHERE trigger_name = 'trg_sync_performans_gostergeler';
--
-- 4. trg_set_tamamlanma_donemi trigger'ı aktif mi?
--    SELECT trigger_name, event_manipulation, event_object_table
--    FROM information_schema.triggers
--    WHERE trigger_name = 'trg_set_tamamlanma_donemi';
--
-- 5. v_alt_faaliyet_ozet is_durum_oran yuvarlanmış mı?
--    SELECT sno, is_yuku, harcanan_butce, is_durum_oran
--    FROM v_alt_faaliyet_ozet
--    LIMIT 5;
--    → is_durum_oran değerleri 2 ondalık basamaklı olmalı
--
-- 6. v_sprint_ozet gki yuvarlanmış mı?
--    SELECT sprint_donem, t_skor, gki
--    FROM v_sprint_ozet
--    LIMIT 5;
--    → gki değerleri 2 ondalık basamaklı olmalı
--
-- 7. RLS politikaları doğru mu?
--    SELECT policyname, cmd FROM pg_policies
--    WHERE tablename = 'faaliyet_yil_butce';
--    → 4 politika: select, insert, update, delete
