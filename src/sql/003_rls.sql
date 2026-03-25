-- UTF-8 | Sprint Kanban | Row Level Security politikaları
-- TR90 Kalkınma Ajansı Sprint Kanban Projesi
-- Oluşturma tarihi: 2026-03-25

-- ============================================================
-- RLS ETKİNLEŞTİRME
-- ============================================================

ALTER TABLE kullanici_rolleri   ENABLE ROW LEVEL SECURITY;
ALTER TABLE birimler           ENABLE ROW LEVEL SECURITY;
ALTER TABLE soplar             ENABLE ROW LEVEL SECURITY;
ALTER TABLE kategoriler        ENABLE ROW LEVEL SECURITY;
ALTER TABLE personel           ENABLE ROW LEVEL SECURITY;
ALTER TABLE faaliyetler        ENABLE ROW LEVEL SECURITY;
ALTER TABLE alt_faaliyetler    ENABLE ROW LEVEL SECURITY;
ALTER TABLE anahtar_sonuclar   ENABLE ROW LEVEL SECURITY;
ALTER TABLE perf_gostergeler   ENABLE ROW LEVEL SECURITY;
ALTER TABLE sprint_veri        ENABLE ROW LEVEL SECURITY;
ALTER TABLE sprint_is_plani    ENABLE ROW LEVEL SECURITY;
ALTER TABLE sprint_retro       ENABLE ROW LEVEL SECURITY;
ALTER TABLE harcamalar         ENABLE ROW LEVEL SECURITY;
ALTER TABLE sprint_perf_gos    ENABLE ROW LEVEL SECURITY;
ALTER TABLE izinler            ENABLE ROW LEVEL SECURITY;
ALTER TABLE saha_gorevleri     ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- BÖLÜM 1: LOOKUP / OKUMA TABLOLARI
-- Tüm authenticated kullanıcılar SELECT yapabilir
-- INSERT/UPDATE/DELETE sadece Scrum Master (Fatih)
-- ============================================================

-- kullanici_rolleri
CREATE POLICY "kullanici_rolleri_select"
    ON kullanici_rolleri FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "kullanici_rolleri_insert_yonetici"
    ON kullanici_rolleri FOR INSERT
    TO authenticated
    WITH CHECK (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

CREATE POLICY "kullanici_rolleri_update_yonetici"
    ON kullanici_rolleri FOR UPDATE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

CREATE POLICY "kullanici_rolleri_delete_yonetici"
    ON kullanici_rolleri FOR DELETE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

-- birimler
CREATE POLICY "birimler_select"
    ON birimler FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "birimler_insert_fatih"
    ON birimler FOR INSERT
    TO authenticated
    WITH CHECK (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

CREATE POLICY "birimler_update_fatih"
    ON birimler FOR UPDATE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

CREATE POLICY "birimler_delete_fatih"
    ON birimler FOR DELETE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

-- soplar
CREATE POLICY "soplar_select"
    ON soplar FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "soplar_insert_fatih"
    ON soplar FOR INSERT
    TO authenticated
    WITH CHECK (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

CREATE POLICY "soplar_update_fatih"
    ON soplar FOR UPDATE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

CREATE POLICY "soplar_delete_fatih"
    ON soplar FOR DELETE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

-- kategoriler
CREATE POLICY "kategoriler_select"
    ON kategoriler FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "kategoriler_insert_fatih"
    ON kategoriler FOR INSERT
    TO authenticated
    WITH CHECK (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

CREATE POLICY "kategoriler_update_fatih"
    ON kategoriler FOR UPDATE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

CREATE POLICY "kategoriler_delete_fatih"
    ON kategoriler FOR DELETE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

-- personel
CREATE POLICY "personel_select"
    ON personel FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "personel_insert_fatih"
    ON personel FOR INSERT
    TO authenticated
    WITH CHECK (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

CREATE POLICY "personel_update_fatih"
    ON personel FOR UPDATE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

-- faaliyetler
CREATE POLICY "faaliyetler_select"
    ON faaliyetler FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "faaliyetler_insert_fatih"
    ON faaliyetler FOR INSERT
    TO authenticated
    WITH CHECK (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

CREATE POLICY "faaliyetler_update_fatih"
    ON faaliyetler FOR UPDATE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

CREATE POLICY "faaliyetler_delete_fatih"
    ON faaliyetler FOR DELETE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

-- alt_faaliyetler
CREATE POLICY "alt_faaliyetler_select"
    ON alt_faaliyetler FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "alt_faaliyetler_insert_fatih"
    ON alt_faaliyetler FOR INSERT
    TO authenticated
    WITH CHECK (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

CREATE POLICY "alt_faaliyetler_update_fatih"
    ON alt_faaliyetler FOR UPDATE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

-- anahtar_sonuclar
CREATE POLICY "anahtar_sonuclar_select"
    ON anahtar_sonuclar FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "anahtar_sonuclar_insert_fatih"
    ON anahtar_sonuclar FOR INSERT
    TO authenticated
    WITH CHECK (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

-- perf_gostergeler
CREATE POLICY "perf_gostergeler_select"
    ON perf_gostergeler FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "perf_gostergeler_insert_fatih"
    ON perf_gostergeler FOR INSERT
    TO authenticated
    WITH CHECK (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

CREATE POLICY "perf_gostergeler_update_fatih"
    ON perf_gostergeler FOR UPDATE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

-- sprint_veri
CREATE POLICY "sprint_veri_select"
    ON sprint_veri FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "sprint_veri_insert_fatih"
    ON sprint_veri FOR INSERT
    TO authenticated
    WITH CHECK (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

CREATE POLICY "sprint_veri_update_fatih"
    ON sprint_veri FOR UPDATE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

-- ============================================================
-- BÖLÜM 2: sprint_is_plani (ANA KANBAN TABLOSU)
-- SELECT: tüm ekip tüm görevleri görebilir
-- INSERT: tüm ekip görev ekleyebilir
-- UPDATE: sadece kendi görevi veya Fatih (Scrum Master)
-- DELETE: sadece Fatih (Scrum Master)
-- ============================================================

CREATE POLICY "sprint_is_plani_select"
    ON sprint_is_plani FOR SELECT
    TO authenticated
    USING (true);

COMMENT ON POLICY "sprint_is_plani_select" ON sprint_is_plani
    IS 'Tüm authenticated ekip tüm görevleri görebilir';

CREATE POLICY "sprint_is_plani_insert"
    ON sprint_is_plani FOR INSERT
    TO authenticated
    WITH CHECK (auth.role() = 'authenticated');

COMMENT ON POLICY "sprint_is_plani_insert" ON sprint_is_plani
    IS 'Tüm authenticated ekip görev ekleyebilir';

-- Kullanıcılar kendi görevlerini veya Fatih tüm görevleri güncelleyebilir
CREATE POLICY "sprint_is_plani_update"
    ON sprint_is_plani FOR UPDATE
    TO authenticated
    USING (
        ekip_uyesi = (SELECT ad FROM personel WHERE auth_id = auth.uid())
        OR (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

COMMENT ON POLICY "sprint_is_plani_update" ON sprint_is_plani
    IS 'Kullanıcı kendi görevini, Fatih ise tüm görevleri güncelleyebilir';

CREATE POLICY "sprint_is_plani_delete"
    ON sprint_is_plani FOR DELETE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

COMMENT ON POLICY "sprint_is_plani_delete" ON sprint_is_plani
    IS 'Sadece Scrum Master (Fatih) görev silebilir';

-- ============================================================
-- BÖLÜM 3: sprint_retro
-- INSERT: kişi sadece kendi adıyla kayıt ekleyebilir
-- SELECT: tüm ekip görebilir
-- ============================================================

CREATE POLICY "sprint_retro_select"
    ON sprint_retro FOR SELECT
    TO authenticated
    USING (true);

COMMENT ON POLICY "sprint_retro_select" ON sprint_retro
    IS 'Tüm ekip tüm retro sonuçlarını görebilir';

CREATE POLICY "sprint_retro_insert"
    ON sprint_retro FOR INSERT
    TO authenticated
    WITH CHECK (
        ad = (SELECT ad FROM personel WHERE auth_id = auth.uid())
    );

COMMENT ON POLICY "sprint_retro_insert" ON sprint_retro
    IS 'Herkes sadece kendi adıyla retro puanı girebilir';

-- ============================================================
-- BÖLÜM 4: harcamalar
-- INSERT: tüm ekip girebilir
-- SELECT: tüm ekip görebilir
-- UPDATE: sadece Fatih (Scrum Master)
-- ============================================================

CREATE POLICY "harcamalar_select"
    ON harcamalar FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "harcamalar_insert"
    ON harcamalar FOR INSERT
    TO authenticated
    WITH CHECK (auth.role() = 'authenticated');

COMMENT ON POLICY "harcamalar_insert" ON harcamalar
    IS 'Tüm authenticated ekip harcama girebilir';

CREATE POLICY "harcamalar_update"
    ON harcamalar FOR UPDATE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

COMMENT ON POLICY "harcamalar_update" ON harcamalar
    IS 'Sadece Scrum Master (Fatih) harcama güncelleyebilir';

-- ============================================================
-- BÖLÜM 5: sprint_perf_gos, izinler, saha_gorevleri
-- INSERT/SELECT: tüm authenticated kullanıcılar
-- ============================================================

-- sprint_perf_gos
CREATE POLICY "sprint_perf_gos_select"
    ON sprint_perf_gos FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "sprint_perf_gos_insert"
    ON sprint_perf_gos FOR INSERT
    TO authenticated
    WITH CHECK (auth.role() = 'authenticated');

-- izinler
CREATE POLICY "izinler_select"
    ON izinler FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "izinler_insert"
    ON izinler FOR INSERT
    TO authenticated
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "izinler_update_fatih"
    ON izinler FOR UPDATE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

-- saha_gorevleri
CREATE POLICY "saha_gorevleri_select"
    ON saha_gorevleri FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "saha_gorevleri_insert"
    ON saha_gorevleri FOR INSERT
    TO authenticated
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "saha_gorevleri_update_fatih"
    ON saha_gorevleri FOR UPDATE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );
