-- ============================================================
-- Migration 021: andaki_birim sütunu + başkan rolü
-- ============================================================

-- 1. sprint_is_plani tablosuna andaki_birim sütunu ekle
ALTER TABLE sprint_is_plani
  ADD COLUMN IF NOT EXISTS andaki_birim INTEGER REFERENCES birimler(bkod);

-- 2. Mevcut kayıtları personelin şu anki birimiyle doldur
UPDATE sprint_is_plani sip
SET andaki_birim = (SELECT bkod FROM personel WHERE pkod = sip.pkod)
WHERE andaki_birim IS NULL;

-- 3. INSERT trigger: yeni görev eklenirken andaki_birim otomatik dolsun
CREATE OR REPLACE FUNCTION fn_set_andaki_birim()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.andaki_birim IS NULL THEN
    SELECT bkod INTO NEW.andaki_birim FROM personel WHERE pkod = NEW.pkod;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_set_andaki_birim ON sprint_is_plani;
CREATE TRIGGER trg_set_andaki_birim
  BEFORE INSERT ON sprint_is_plani
  FOR EACH ROW EXECUTE FUNCTION fn_set_andaki_birim();

-- 4. başkan rolünü kullanici_rolleri tablosuna ekle
INSERT INTO kullanici_rolleri (rol_kodu, aciklama)
VALUES ('başkan', 'Tüm birimlerin kayıtlarını görüntüleyebilir; kendi biriminde aktif personele görev tanımlayabilir')
ON CONFLICT (rol_kodu) DO NOTHING;

-- 5. sprint_is_plani INSERT policy: başkan kendi biriminde görev tanımlayabilir
DROP POLICY IF EXISTS "sprint_is_plani_insert" ON sprint_is_plani;

CREATE POLICY "sprint_is_plani_insert"
  ON sprint_is_plani FOR INSERT
  TO authenticated
  WITH CHECK (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) IN ('yönetici', 'gs')
    OR pkod = (SELECT pkod FROM personel WHERE auth_id = auth.uid())
    OR (
      (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'başkan'
      AND pkod IN (
        SELECT p.pkod FROM personel p
        WHERE p.bkod = (SELECT bkod FROM personel WHERE auth_id = auth.uid())
          AND p.durum = 'Aktif'
      )
    )
  );

-- 6. sprint_is_plani UPDATE policy: başkan kendi biriminin görevlerini güncelleyebilir
DROP POLICY IF EXISTS "sprint_is_plani_update_baskan" ON sprint_is_plani;

CREATE POLICY "sprint_is_plani_update_baskan"
  ON sprint_is_plani FOR UPDATE
  TO authenticated
  USING (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'başkan'
    AND pkod IN (
      SELECT p.pkod FROM personel p
      WHERE p.bkod = (SELECT bkod FROM personel WHERE auth_id = auth.uid())
    )
  )
  WITH CHECK (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'başkan'
    AND pkod IN (
      SELECT p.pkod FROM personel p
      WHERE p.bkod = (SELECT bkod FROM personel WHERE auth_id = auth.uid())
    )
  );

-- 7. andaki_birim index
CREATE INDEX IF NOT EXISTS idx_sprint_is_plani_andaki_birim
  ON sprint_is_plani(andaki_birim);
