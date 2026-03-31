-- ============================================================
-- Migration 020: sprint_is_plani RLS Politikası Temizliği
-- UTF-8 | DOKA Sprint Kanban
-- Tarih: 2026-03-31
-- ============================================================
-- AMAÇ: 007_revisions.sql'de ekip_uyesi kolonu kaldırıldıktan
-- sonra geride kalan eski RLS politikalarını temizle ve yeniden
-- oluştur. "column sprint_is_plani.ekip_uyesi does not exist"
-- hatasının kökü olan stale politikaları kaldırır.
--
-- UYGULAMA SONRASI: Supabase Dashboard → Settings → API →
-- "Reload" (Schema Cache) işlemini yapın.
-- ============================================================

-- ────────────────────────────────────────────────
-- BÖLÜM 1: Tüm mevcut sprint_is_plani politikalarını kaldır
-- ────────────────────────────────────────────────
DROP POLICY IF EXISTS "sprint_is_plani_select"       ON sprint_is_plani;
DROP POLICY IF EXISTS "sprint_is_plani_insert"       ON sprint_is_plani;
DROP POLICY IF EXISTS "sprint_is_plani_update"       ON sprint_is_plani;
DROP POLICY IF EXISTS "sprint_is_plani_update_gs"    ON sprint_is_plani;
DROP POLICY IF EXISTS "sprint_is_plani_delete"       ON sprint_is_plani;

-- ────────────────────────────────────────────────
-- BÖLÜM 2: Güvenlik — ekip_uyesi kolonu hâlâ varsa kaldır
-- ────────────────────────────────────────────────
ALTER TABLE sprint_is_plani DROP COLUMN IF EXISTS ekip_uyesi;

-- ────────────────────────────────────────────────
-- BÖLÜM 3: Temiz politikaları oluştur
-- ────────────────────────────────────────────────

-- SELECT: tüm authenticated kullanıcılar
CREATE POLICY "sprint_is_plani_select"
    ON sprint_is_plani FOR SELECT
    TO authenticated
    USING (true);

-- INSERT: yönetici veya görev kendisine ait (pkod)
CREATE POLICY "sprint_is_plani_insert"
    ON sprint_is_plani FOR INSERT
    TO authenticated
    WITH CHECK (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) IN ('yönetici', 'gs')
        OR pkod = (SELECT pkod FROM personel WHERE auth_id = auth.uid())
    );

-- UPDATE: yönetici veya görev kendisine ait (pkod)
CREATE POLICY "sprint_is_plani_update"
    ON sprint_is_plani FOR UPDATE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
        OR pkod = (SELECT pkod FROM personel WHERE auth_id = auth.uid())
    )
    WITH CHECK (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
        OR pkod = (SELECT pkod FROM personel WHERE auth_id = auth.uid())
    );

-- UPDATE (gs): gs rolü tüm satırları güncelleyebilir (drag/drop + görev düzenleme)
CREATE POLICY "sprint_is_plani_update_gs"
    ON sprint_is_plani FOR UPDATE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'gs'
    )
    WITH CHECK (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'gs'
    );

-- DELETE: yalnızca yönetici
CREATE POLICY "sprint_is_plani_delete"
    ON sprint_is_plani FOR DELETE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

-- ────────────────────────────────────────────────
-- DOĞRULAMA
-- SELECT policyname, cmd FROM pg_policies
-- WHERE tablename = 'sprint_is_plani' ORDER BY cmd;
-- → 5 politika: DELETE, INSERT, SELECT, UPDATE (x2 — standart + gs)
-- ────────────────────────────────────────────────
