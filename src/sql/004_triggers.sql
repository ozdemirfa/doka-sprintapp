-- UTF-8 | Sprint Kanban | Audit ve otomatik alan trigger'ları
-- TR90 Kalkınma Ajansı Sprint Kanban Projesi
-- Oluşturma tarihi: 2026-03-25

-- ============================================================
-- AUDIT FONKSİYONU
-- Her güncellemede guncel_tarih ve guncelleyen otomatik set edilir
-- Kullanıcı adı: personel.ad || '.' || personel.soyad (ör: fatih.ozdemir)
-- ============================================================

CREATE OR REPLACE FUNCTION update_audit_fields()
RETURNS TRIGGER AS $$
BEGIN
    -- guncel_tarih: Güncelleme zamanının tarih kısmı
    NEW.guncel_tarih = NOW()::DATE;
    -- guncelleyen: Giriş yapan kullanıcının ad.soyad formatı
    NEW.guncelleyen = (
        SELECT LOWER(ad) || '.' || LOWER(soyad)
        FROM personel
        WHERE auth_id = auth.uid()
        LIMIT 1
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION update_audit_fields() IS
    'Audit trigger fonksiyonu — her UPDATE işleminde guncel_tarih ve guncelleyen alanlarını otomatik günceller';

-- ============================================================
-- TRIGGER 1: sprint_is_plani audit
-- BEFORE UPDATE → update_audit_fields() çağrılır
-- ============================================================

DROP TRIGGER IF EXISTS trg_sprint_is_plani_audit ON sprint_is_plani;

CREATE TRIGGER trg_sprint_is_plani_audit
    BEFORE UPDATE ON sprint_is_plani
    FOR EACH ROW
    EXECUTE FUNCTION update_audit_fields();

COMMENT ON TRIGGER trg_sprint_is_plani_audit ON sprint_is_plani IS
    'Her sprint_is_plani UPDATE işleminde guncel_tarih ve guncelleyen alanlarını otomatik günceller';

-- ============================================================
-- TRIGGER 2: harcamalar audit
-- BEFORE UPDATE → update_audit_fields() çağrılır
-- ============================================================

DROP TRIGGER IF EXISTS trg_harcamalar_audit ON harcamalar;

CREATE TRIGGER trg_harcamalar_audit
    BEFORE UPDATE ON harcamalar
    FOR EACH ROW
    EXECUTE FUNCTION update_audit_fields();

COMMENT ON TRIGGER trg_harcamalar_audit ON harcamalar IS
    'Her harcamalar UPDATE işleminde guncel_tarih ve guncelleyen alanlarını otomatik günceller';
