-- ============================================================
-- Migration 031 — izinler + saha_gorevleri DELETE RLS Policy
-- Tarih: 2026-03-30
-- Neden: Migration 013'te bu tablolar için DELETE policy eklenmedi.
-- RLS'li tabloda eşleşmeyen DELETE → satır etkilenmez, hata yok.
-- Frontend "Kayıt silindi" toast'u gösteriyor ama aslında silinmiyor.
-- ============================================================

-- izinler DELETE policy
CREATE POLICY "izinler_delete_yonetici"
    ON izinler FOR DELETE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

-- saha_gorevleri DELETE policy
CREATE POLICY "saha_gorevleri_delete_yonetici"
    ON saha_gorevleri FOR DELETE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );
