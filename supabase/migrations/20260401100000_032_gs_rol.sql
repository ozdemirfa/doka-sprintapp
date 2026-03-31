-- Migration 032: 'gs' (Geniş Standart) kullanıcı rolü ekleme
-- gs: standart yetkiler + tüm ekip adına sprint görevi tanımlama + drag/drop

-- 1. kullanici_rolleri tablosuna gs ekle
INSERT INTO kullanici_rolleri (rol_kodu, aciklama)
VALUES ('gs', 'Geniş Standart — tüm ekip üyeleri adına görev tanımlayabilir')
ON CONFLICT (rol_kodu) DO NOTHING;

-- 2. sprint_is_plani UPDATE: gs tüm satırları güncelleyebilir (drag/drop + görev düzenleme)
--    Mevcut standart policy yalnızca kendi görevine (pkod eşleşmesi) izin veriyor;
--    gs başkası adına oluşturduğu görevi de taşıyabilmeli.
CREATE POLICY "sprint_is_plani_update_gs"
  ON sprint_is_plani FOR UPDATE TO authenticated
  USING (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'gs'
  )
  WITH CHECK (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'gs'
  );
