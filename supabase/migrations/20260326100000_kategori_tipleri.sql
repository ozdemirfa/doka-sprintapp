-- UTF-8 | Sprint Kanban | kategori_tipleri normalizasyonu
-- kategori_tipleri master tablosunu oluştur ve kategoriler tablosunu normalize et

-- ============================================================
-- ADIM 1: kategori_tipleri master tablosunu oluştur
-- ============================================================
CREATE TABLE IF NOT EXISTS kategori_tipleri (
    kkod            INTEGER         PRIMARY KEY,
    kategori_adi    VARCHAR(200)    NOT NULL UNIQUE
);

COMMENT ON TABLE kategori_tipleri IS 'Master kategori tanımları (normalize edilmiş)';
COMMENT ON COLUMN kategori_tipleri.kkod IS 'Kategori kodu (PK)';
COMMENT ON COLUMN kategori_tipleri.kategori_adi IS 'Kategori açıklaması (unique)';

-- ============================================================
-- ADIM 2: Master kategori verilerini ekle
-- ============================================================
INSERT INTO kategori_tipleri (kkod, kategori_adi) VALUES
(1, 'Araştırma, Analiz ve Raporlama'),
(2, 'İşbirliği ve Koordinasyon Faaliyetleri'),
(3, 'Kapasite Geliştirme Faaliyetleri'),
(4, 'Tanıtım ve Yatırım Destek Faaliyetleri'),
(5, 'Destek Programları'),
(6, 'Proje Uygulama Faaliyetleri')
ON CONFLICT (kkod) DO NOTHING;

-- ============================================================
-- ADIM 3: kategoriler tablosunu normalize et
-- (eski yapı: skod + kkod + kategori_adi → yeni yapı: skod + kkod FK)
-- ============================================================

-- Mevcut veriyi yedekle
CREATE TABLE IF NOT EXISTS kategoriler_backup AS
SELECT * FROM kategoriler;

-- Eski tabloyu kaldır
DROP TABLE IF EXISTS kategoriler CASCADE;

-- Yeni normalize tabloyu oluştur
CREATE TABLE IF NOT EXISTS kategoriler (
    skod            INTEGER         REFERENCES soplar(skod),
    kkod            INTEGER         REFERENCES kategori_tipleri(kkod),
    PRIMARY KEY (skod, kkod)
);

COMMENT ON TABLE kategoriler IS 'SOP ve kategori tipleri arasındaki ilişki tablosu';
COMMENT ON COLUMN kategoriler.skod IS 'SOP kodu (PK, FK → soplar.skod)';
COMMENT ON COLUMN kategoriler.kkod IS 'Kategori kodu (PK, FK → kategori_tipleri.kkod)';

-- ============================================================
-- ADIM 4: SOP-kategori ilişkilerini yükle
-- ============================================================
INSERT INTO kategoriler (skod, kkod) VALUES
-- STU (skod=1)
(1, 1), (1, 2), (1, 3), (1, 4), (1, 5),
-- KDU (skod=2)
(2, 1), (2, 2), (2, 3), (2, 4), (2, 5),
-- MEK (skod=3)
(3, 1), (3, 2), (3, 3),
-- SOG (skod=8)
(8, 1), (8, 2), (8, 6)
ON CONFLICT (skod, kkod) DO NOTHING;

-- ============================================================
-- ADIM 5: RLS politikaları
-- ============================================================
ALTER TABLE kategori_tipleri ENABLE ROW LEVEL SECURITY;
ALTER TABLE kategoriler      ENABLE ROW LEVEL SECURITY;

-- kategori_tipleri: tüm oturum açmış kullanıcılar okuyabilir
CREATE POLICY "kategori_tipleri_select"
    ON kategori_tipleri FOR SELECT
    TO authenticated
    USING (true);

-- kategoriler: tüm oturum açmış kullanıcılar okuyabilir
CREATE POLICY "kategoriler_select"
    ON kategoriler FOR SELECT
    TO authenticated
    USING (true);

-- kategoriler: sadece Fatih (yönetici) yazabilir
CREATE POLICY "kategoriler_insert_fatih"
    ON kategoriler FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() IN (SELECT id FROM auth.users WHERE email = 'fatih@tr90.gov.tr'));

CREATE POLICY "kategoriler_update_fatih"
    ON kategoriler FOR UPDATE
    TO authenticated
    USING (auth.uid() IN (SELECT id FROM auth.users WHERE email = 'fatih@tr90.gov.tr'));

CREATE POLICY "kategoriler_delete_fatih"
    ON kategoriler FOR DELETE
    TO authenticated
    USING (auth.uid() IN (SELECT id FROM auth.users WHERE email = 'fatih@tr90.gov.tr'));
