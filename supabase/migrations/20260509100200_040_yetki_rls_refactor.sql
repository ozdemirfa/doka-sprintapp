-- ============================================================
-- Migration 026: current_user_has_permission helper + RLS genişletme
-- UTF-8 | DOKA Sprint Kanban
-- Tarih: 2026-05-09
-- ============================================================
-- Bu migration:
--   1. current_user_has_permission(tablo, yetki) helper fonksiyonu kurar
--      — kullanıcının atandığı yetki gruplarından izin türünü kontrol eder.
--   2. KRİTİK tablolarda mevcut hard-coded rol kontrollerini "OR permission"
--      ile genişletir; eski politikalar silinmez, sadece yenilenir.
--   3. Geriye uyum: yönetici/standart/izleyici rolleri 025'te aynen seed
--      edildiği için davranış değişmez. Yeni atanan özel gruplar (örn.
--      "Bütçe Editörü" → harcamalar yazma+güncelleme) bu genişletme
--      sayesinde DB seviyesinde geçerli olur.
-- ============================================================

-- ── 1. Helper fonksiyon ─────────────────────────────────────
CREATE OR REPLACE FUNCTION current_user_has_permission(
  p_tablo TEXT,
  p_yetki TEXT  -- 'okuma' | 'yazma' | 'guncelleme' | 'silme'
) RETURNS BOOLEAN
LANGUAGE SQL STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1
      FROM personel p
      JOIN personel_yetki_grubu pyg ON pyg.personel_pkod = p.pkod
      JOIN yetki_grubu yg            ON yg.id = pyg.yetki_grubu_id AND yg.aktif
      JOIN yetki_grubu_tablo_izni i  ON i.yetki_grubu_id = yg.id
     WHERE p.auth_id = auth.uid()
       AND i.tablo_adi = p_tablo
       AND CASE p_yetki
             WHEN 'okuma'      THEN i.okuma
             WHEN 'yazma'      THEN i.yazma
             WHEN 'guncelleme' THEN i.guncelleme
             WHEN 'silme'      THEN i.silme
             ELSE FALSE
           END
  );
$$;

GRANT EXECUTE ON FUNCTION current_user_has_permission(TEXT, TEXT) TO authenticated;

-- ── 2. Kritik tablolarda DELETE policy genişletme ───────────

-- harcamalar: yönetici VEYA permission matrisinde silme yetkisi olan
DROP POLICY IF EXISTS "harcamalar_delete" ON harcamalar;
CREATE POLICY "harcamalar_delete"
  ON harcamalar FOR DELETE TO authenticated
  USING (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('harcamalar', 'silme')
  );

-- harcamalar: yönetici VEYA permission matrisinde güncelleme yetkisi olan
DROP POLICY IF EXISTS "harcamalar_update" ON harcamalar;
CREATE POLICY "harcamalar_update"
  ON harcamalar FOR UPDATE TO authenticated
  USING (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('harcamalar', 'guncelleme')
  );

-- harcamalar: yönetici VEYA yazma yetkisi olan VEYA standart (kendi)
DROP POLICY IF EXISTS "harcamalar_insert" ON harcamalar;
CREATE POLICY "harcamalar_insert"
  ON harcamalar FOR INSERT TO authenticated
  WITH CHECK (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) IN ('yönetici','gs','standart','başkan')
    OR current_user_has_permission('harcamalar', 'yazma')
  );

-- izinler / saha_gorevleri DELETE
DROP POLICY IF EXISTS "izinler_delete" ON izinler;
CREATE POLICY "izinler_delete"
  ON izinler FOR DELETE TO authenticated
  USING (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('izinler', 'silme')
  );

DROP POLICY IF EXISTS "saha_gorevleri_delete" ON saha_gorevleri;
CREATE POLICY "saha_gorevleri_delete"
  ON saha_gorevleri FOR DELETE TO authenticated
  USING (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('saha_gorevleri', 'silme')
  );

-- soplar / kategoriler / faaliyetler / alt_faaliyetler / perf_gostergeler:
-- yönetici VEYA permission'da yazma/güncelleme/silme
DO $$
DECLARE
  t TEXT;
BEGIN
  FOR t IN SELECT unnest(ARRAY['soplar','faaliyetler','alt_faaliyetler','perf_gostergeler']) LOOP
    EXECUTE format('DROP POLICY IF EXISTS "%s_modify_extended" ON %I', t, t);
    EXECUTE format($f$
      CREATE POLICY "%s_modify_extended" ON %I FOR ALL TO authenticated
        USING (
          (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
          OR current_user_has_permission('%s', 'guncelleme')
          OR current_user_has_permission('%s', 'silme')
        )
        WITH CHECK (
          (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
          OR current_user_has_permission('%s', 'yazma')
          OR current_user_has_permission('%s', 'guncelleme')
        );
    $f$, t, t, t, t, t, t);
  END LOOP;
END $$;

-- ── 3. Audit log: rol değişikliği denetlenir ────────────────
-- personel_yetki_grubu üzerine audit trigger ekleyelim (017'deki fn_audit_log varsa)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'fn_audit_log') THEN
    DROP TRIGGER IF EXISTS trg_audit_personel_yetki_grubu ON personel_yetki_grubu;
    CREATE TRIGGER trg_audit_personel_yetki_grubu
      AFTER INSERT OR UPDATE OR DELETE ON personel_yetki_grubu
      FOR EACH ROW EXECUTE FUNCTION fn_audit_log();

    DROP TRIGGER IF EXISTS trg_audit_yetki_grubu_tablo_izni ON yetki_grubu_tablo_izni;
    CREATE TRIGGER trg_audit_yetki_grubu_tablo_izni
      AFTER INSERT OR UPDATE OR DELETE ON yetki_grubu_tablo_izni
      FOR EACH ROW EXECUTE FUNCTION fn_audit_log();
  END IF;
END $$;
