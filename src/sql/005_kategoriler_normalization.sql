-- UTF-8 | Sprint Kanban | Kategoriler tablosu normalizasyonu
-- TR90 Kalkınma Ajansı Sprint Kanban Projesi  
-- Oluşturma tarihi: 2026-03-26
-- Amaç: Kategoriler tablosundaki veri tekrarını normalize etmek

-- ============================================================
-- MİGRASYON: KATEGORİLER NORMALIZE ETME
-- Mevcut kategoriler tablosunu normalize etme (skod + kkod tekrarını çözme)
-- ============================================================

-- 1. ADIM: Mevcut kategoriler tablosunu geçici olarak yedekle
CREATE TABLE IF NOT EXISTS kategoriler_backup AS 
SELECT * FROM kategoriler;

-- 2. ADIM: Mevcut kategoriler tablosunu temizle  
DROP TABLE IF EXISTS kategoriler CASCADE;

-- 3. ADIM: kategori_tipleri master tablosunu oluştur (schema'da zaten tanımlı ama emin olmak için)
CREATE TABLE IF NOT EXISTS kategori_tipleri (
    kkod            INTEGER         PRIMARY KEY,
    kategori_adi    VARCHAR(200)    NOT NULL UNIQUE
);

-- 4. ADIM: Yeni normalize kategoriler tablosunu oluştur
CREATE TABLE IF NOT EXISTS kategoriler (
    skod            INTEGER         REFERENCES soplar(skod),
    kkod            INTEGER         REFERENCES kategori_tipleri(kkod),
    PRIMARY KEY (skod, kkod)
);

-- 5. ADIM: Kommentleri ekle
COMMENT ON TABLE kategori_tipleri IS 'Master kategori tanımları (normalize edilmiş)';
COMMENT ON COLUMN kategori_tipleri.kkod IS 'Kategori kodu (PK)';
COMMENT ON COLUMN kategori_tipleri.kategori_adi IS 'Kategori açıklaması (unique)';

COMMENT ON TABLE kategoriler IS 'SOP ve kategori tipleri arasındaki ilişki tablosu';
COMMENT ON COLUMN kategoriler.skod IS 'SOP kodu (PK, FK → soplar.skod)';
COMMENT ON COLUMN kategoriler.kkod IS 'Kategori kodu (PK, FK → kategori_tipleri.kkod)';

-- 6. ADIM: Master kategori tiplerini ekle
INSERT INTO kategori_tipleri (kkod, kategori_adi) VALUES
(1, 'Araştırma, Analiz ve Raporlama'),
(2, 'İşbirliği ve Koordinasyon Faaliyetleri'),
(3, 'Kapasite Geliştirme Faaliyetleri'),
(4, 'Tanıtım ve Yatırım Destek Faaliyetleri'),
(5, 'Destek Programları'),
(6, 'Proje Uygulama Faaliyetleri')
ON CONFLICT (kkod) DO NOTHING;

-- 7. ADIM: SOP-kategori ilişkilerini normalize et
INSERT INTO kategoriler (skod, kkod) VALUES
-- STU (skod=1) - 5 kategori
(1, 1), (1, 2), (1, 3), (1, 4), (1, 5),
-- KDU (skod=2) - 5 kategori  
(2, 1), (2, 2), (2, 3), (2, 4), (2, 5),
-- MEK (skod=3) - 3 kategori
(3, 1), (3, 2), (3, 3),
-- SOG (skod=8) - 3 kategori (Proje Uygulama Faaliyetleri = kkod 6)
(8, 1), (8, 2), (8, 6)
ON CONFLICT (skod, kkod) DO NOTHING;

-- 8. ADIM: Veri doğrulama query'si (opsiyonel - test için)
-- Bu query normalize öncesi ve sonrası kayıt sayılarını karşılaştırır
/*
SELECT 
    'Önceki yapı' AS yapitur, 
    COUNT(*) AS kayit_sayisi,
    COUNT(DISTINCT kategori_adi) AS benzersiz_kategori
FROM kategoriler_backup
UNION ALL
SELECT 
    'Yeni yapı' AS yapitur,
    COUNT(*) AS kayit_sayisi,
    (SELECT COUNT(*) FROM kategori_tipleri) AS benzersiz_kategori
FROM kategoriler;
*/

-- 9. ADIM: Geçici backup tablosu temizle (opsiyonel)
-- DROP TABLE IF EXISTS kategoriler_backup;