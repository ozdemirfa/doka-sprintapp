-- ============================================================
-- Migration 018: izinler + saha_gorevleri DELETE RLS Policy Ekle
-- UTF-8 | DOKA Sprint Kanban
-- Tarih: 2026-03-31
-- ============================================================
-- Kök Neden:
-- 003_rls.sql'de izinler ve saha_gorevleri tabloları için
-- SELECT/INSERT/UPDATE policy mevcut ancak DELETE policy yok.
-- Supabase davranışı: RLS'li tabloda eşleşen DELETE policy yoksa
-- işlem sessizce 0 satır etkiler, hata döndürmez.
-- Sonuç: Frontend "Kayıt silindi" toast'unu gösterir ama
-- veritabanında hiçbir şey silinmez.
-- Migration 013 benzer sorunu sprint_veri/alt_faaliyetler/perf_gostergeler
-- için düzeltti; bu migration izinler ve saha_gorevleri'ni tamamlar.
-- ============================================================

CREATE POLICY "izinler_delete_yonetici"
    ON izinler FOR DELETE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

CREATE POLICY "saha_gorevleri_delete_yonetici"
    ON saha_gorevleri FOR DELETE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

-- ============================================================
-- DOĞRULAMA
-- ============================================================
-- SELECT policyname, tablename, cmd
-- FROM pg_policies
-- WHERE tablename IN ('izinler', 'saha_gorevleri')
--   AND cmd = 'DELETE';
-- → Her iki tablo için DELETE policy görülmeli
