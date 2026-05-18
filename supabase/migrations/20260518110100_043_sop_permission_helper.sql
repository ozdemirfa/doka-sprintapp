-- ============================================================
-- Migration 043: current_user_has_sop_permission(skod, izin) helper
-- UTF-8 NoBOM | DOKA Sprint Kanban
-- Tarih: 2026-05-18
-- Sprint: S3 (Birim-bazlı SOP Görünürlüğü)
-- ============================================================
-- Bu fonksiyon, giriş yapan kullanıcının kendi birim(ler)i üzerinden
-- birim_sop_izni matrisine bakarak verilen SOP için yetkisi olup
-- olmadığını döndürür. RLS politikalarında SOP-katmanlı görünürlük
-- için kullanılır (migration 044).
--
-- Semantik:
--   * Kullanıcı yönetici ise → TRUE (her şeyi görür/değiştirir)
--   * birim_sop_izni'nde personel.bkod = bkod AND skod eşleşen satır var ve
--     ilgili kolon (okuma|yazma|silme) TRUE ise → TRUE
--   * Aksi halde → FALSE
--
-- NOT: personel.bkod NULL olabilir; o durumda personel sadece yönetici
-- olmadığı sürece hiç SOP göremez (kasıtlı — birim ataması yapılmamış
-- personel sistem dışında demektir).
-- ============================================================

CREATE OR REPLACE FUNCTION current_user_has_sop_permission(
  p_skod INTEGER,
  p_izin TEXT  -- 'okuma' | 'yazma' | 'silme'
) RETURNS BOOLEAN
LANGUAGE SQL STABLE SECURITY DEFINER AS $$
  SELECT
    -- Yönetici by-pass
    EXISTS (
      SELECT 1 FROM personel
      WHERE auth_id = auth.uid()
        AND rol_kodu = 'yönetici'
    )
    OR
    -- Birim eşleşmesi üzerinden matris kontrolü
    EXISTS (
      SELECT 1
      FROM personel p
      JOIN birim_sop_izni bsi
        ON bsi.bkod = p.bkod
       AND bsi.skod = p_skod
      WHERE p.auth_id = auth.uid()
        AND CASE p_izin
              WHEN 'okuma' THEN bsi.okuma
              WHEN 'yazma' THEN bsi.yazma
              WHEN 'silme' THEN bsi.silme
              ELSE FALSE
            END
    );
$$;

GRANT EXECUTE ON FUNCTION current_user_has_sop_permission(INTEGER, TEXT) TO authenticated;

COMMENT ON FUNCTION current_user_has_sop_permission(INTEGER, TEXT) IS
  'S3: Giriş yapan personelin kendi birimi üzerinden p_skod için p_izin yetkisi var mı? Yönetici her zaman TRUE.';

-- ──────────────────────────────────────────────────────────────
-- Yardımcı view: kullanıcının okuyabildiği SOP listesi
-- (UI dropdown'larının ve RLS sub-query'lerinin kolay kullanımı için)
-- ──────────────────────────────────────────────────────────────
DROP VIEW IF EXISTS v_user_visible_soplar;
CREATE VIEW v_user_visible_soplar AS
  SELECT DISTINCT s.skod, s.kisa, s.sop_adi, s.bkod
    FROM soplar s
   WHERE current_user_has_sop_permission(s.skod, 'okuma');

GRANT SELECT ON v_user_visible_soplar TO authenticated;

COMMENT ON VIEW v_user_visible_soplar IS
  'S3: Mevcut kullanıcının okuma yetkisi olan SOP''lar. Yönetici tüm soplar listesini görür.';
