-- ============================================================
-- Migration 007: Schema Revisions
-- UTF-8 | DOKA Sprint Kanban
-- Tarih: 2026-03-27
-- ============================================================
-- ÇALIŞTIRMADAN ÖNCE: Supabase Dashboard → Settings → Database → Backup alın.
-- Bu migration geri alınamaz kolon silme işlemleri içerir.
-- ============================================================

-- ============================================================
-- BÖLÜM 0: VIEW'LARI KALDIR (bağımlı tablolar değişecek)
-- ============================================================
DROP VIEW IF EXISTS v_faaliyet_ozet;
DROP VIEW IF EXISTS v_alt_faaliyet_ozet;
DROP VIEW IF EXISTS v_sprint_ozet;
DROP VIEW IF EXISTS v_perf_gosterge_ozet;
DROP VIEW IF EXISTS v_faaliyet_harcama;

-- ============================================================
-- BÖLÜM 1: soplar — data fix + kısıtlama
-- ============================================================

-- FK kısıtlamalarını geçici kaldır (kisa değeri değişecek)
ALTER TABLE faaliyetler     DROP CONSTRAINT IF EXISTS faaliyetler_sop_fkey;
ALTER TABLE perf_gostergeler DROP CONSTRAINT IF EXISTS perf_gostergeler_sop_fkey;

-- Kisa değer güncellemeleri
UPDATE soplar SET kisa = 'SDD' WHERE skod = 5;
UPDATE soplar SET kisa = 'ABP' WHERE skod = 7;

-- Faaliyetler ve perf_gostergeler'deki eski referansları güncelle
UPDATE faaliyetler     SET sop = 'SDD' WHERE sop = 'SOPD';
UPDATE faaliyetler     SET sop = 'ABP' WHERE sop = 'AB';
UPDATE perf_gostergeler SET sop = 'SDD' WHERE sop = 'SOPD';
UPDATE perf_gostergeler SET sop = 'ABP' WHERE sop = 'AB';

-- 3 karakter büyük harf kısıtlaması (yeni giriş için frontend ile birlikte)
ALTER TABLE soplar ADD CONSTRAINT chk_soplar_kisa CHECK (kisa ~ '^[A-Z]{3}$');

-- ============================================================
-- BÖLÜM 2: kategori_tipleri + kategoriler temizliği
-- ============================================================

UPDATE kategori_tipleri SET kategori_adi = 'Diğer' WHERE kkod = 6;

-- M:M join ve backup tabloları kaldır
DROP TABLE IF EXISTS kategoriler_backup CASCADE;
DROP TABLE IF EXISTS kategoriler CASCADE;

-- RLS kaldır (tablo silindi)
-- (DROP TABLE CASCADE zaten RLS politikalarını da kaldırır)

-- ============================================================
-- BÖLÜM 3: faaliyetler yeniden yapılandırma
-- ============================================================

-- 3.1 Yeni sütunlar ekle
ALTER TABLE faaliyetler ADD COLUMN IF NOT EXISTS id       SERIAL;
ALTER TABLE faaliyetler ADD COLUMN IF NOT EXISTS skod     INTEGER;
ALTER TABLE faaliyetler ADD COLUMN IF NOT EXISTS kkod     INTEGER;
ALTER TABLE faaliyetler ADD COLUMN IF NOT EXISTS fsirano  INTEGER;

-- 3.2 Data migration: sop text → skod, kategori text → kkod
UPDATE faaliyetler f
SET skod = (SELECT s.skod FROM soplar s WHERE s.kisa = f.sop);

UPDATE faaliyetler f
SET kkod = (SELECT kt.kkod FROM kategori_tipleri kt WHERE kt.kategori_adi = f.kategori);

-- 3.3 fsirano: mevcut fkod'dan trailing rakamları çıkar
UPDATE faaliyetler
SET fsirano = CASE
    WHEN fkod ~ '\d+$'
    THEN REGEXP_REPLACE(fkod, '^.*?(\d+)$', '\1')::INTEGER
    ELSE NULL
END;

-- 3.4 FK kısıtlamaları ekle
ALTER TABLE faaliyetler
    ADD CONSTRAINT faaliyetler_skod_fkey FOREIGN KEY (skod) REFERENCES soplar(skod),
    ADD CONSTRAINT faaliyetler_kkod_fkey FOREIGN KEY (kkod) REFERENCES kategori_tipleri(kkod);

-- 3.5 PK değiştir: fkod → id (fkod UNIQUE kalır, alt_faaliyetler FK yeniden bağlanır)
ALTER TABLE faaliyetler ADD CONSTRAINT faaliyetler_fkod_unique UNIQUE (fkod);
-- alt_faaliyetler FK'sını geçici kaldır (PK drop için gerekli)
ALTER TABLE alt_faaliyetler DROP CONSTRAINT IF EXISTS alt_faaliyetler_fkod_fkey;
ALTER TABLE faaliyetler DROP CONSTRAINT faaliyetler_pkey;
ALTER TABLE faaliyetler ADD PRIMARY KEY (id);
-- alt_faaliyetler FK'sını UNIQUE constraint üzerinden yeniden ekle
ALTER TABLE alt_faaliyetler
    ADD CONSTRAINT alt_faaliyetler_fkod_fkey FOREIGN KEY (fkod) REFERENCES faaliyetler(fkod);

-- 3.6 Gereksiz sütunlar kaldır
ALTER TABLE faaliyetler DROP COLUMN IF EXISTS sop;
ALTER TABLE faaliyetler DROP COLUMN IF EXISTS kategori;
ALTER TABLE faaliyetler DROP COLUMN IF EXISTS aylik_plan;
ALTER TABLE faaliyetler DROP COLUMN IF EXISTS yil;

-- 3.7 fkod otomatik üretim trigger'ı (sadece yeni INSERT'ler için)
CREATE OR REPLACE FUNCTION fn_generate_fkod()
RETURNS TRIGGER AS $$
DECLARE
    v_kisa   VARCHAR(3);
    v_fsirano INTEGER;
BEGIN
    SELECT kisa INTO v_kisa FROM soplar WHERE skod = NEW.skod;
    IF v_kisa IS NULL THEN
        RAISE EXCEPTION 'Geçersiz skod: %', NEW.skod;
    END IF;

    SELECT COALESCE(MAX(fsirano), 0) + 1 INTO v_fsirano
    FROM faaliyetler
    WHERE skod = NEW.skod AND kkod = NEW.kkod;

    NEW.fsirano := v_fsirano;
    NEW.fkod    := v_kisa || NEW.kkod::TEXT || LPAD(v_fsirano::TEXT, 2, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_faaliyetler_fkod ON faaliyetler;
CREATE TRIGGER trg_faaliyetler_fkod
    BEFORE INSERT ON faaliyetler
    FOR EACH ROW
    EXECUTE FUNCTION fn_generate_fkod();

-- 3.8 İndeks güncelle
DROP INDEX IF EXISTS idx_faaliyetler_sop;
CREATE INDEX IF NOT EXISTS idx_faaliyetler_skod_kkod ON faaliyetler(skod, kkod);

-- ============================================================
-- BÖLÜM 4: alt_faaliyetler — gereksiz sütunlar kaldır
-- ============================================================

ALTER TABLE alt_faaliyetler DROP COLUMN IF EXISTS sop;
ALTER TABLE alt_faaliyetler DROP COLUMN IF EXISTS kategori;
ALTER TABLE alt_faaliyetler DROP COLUMN IF EXISTS faaliyet;

-- ============================================================
-- BÖLÜM 5: izinler — personel → pkod migrasyonu
-- ============================================================

ALTER TABLE izinler ADD COLUMN IF NOT EXISTS pkod         INTEGER;
ALTER TABLE izinler ADD COLUMN IF NOT EXISTS izin_gun_sayi INTEGER;

-- Data migration: isim eşleştirme
UPDATE izinler i
SET pkod = (
    SELECT p.pkod FROM personel p
    WHERE CONCAT(p.ad, ' ', p.soyad) = i.personel
    LIMIT 1
);

-- izin_gun_sayi başlangıçta gün farkından hesapla, sonra manuel güncellenebilir
UPDATE izinler
SET izin_gun_sayi = (izin_bitis - izin_basl) + 1
WHERE izin_gun_sayi IS NULL AND izin_basl IS NOT NULL AND izin_bitis IS NOT NULL;

-- FK ekle (NULL izin edebilir — isim eşleşemeyenler için)
ALTER TABLE izinler
    ADD CONSTRAINT izinler_pkod_fkey FOREIGN KEY (pkod) REFERENCES personel(pkod);

-- Eski personel sütununu kaldır
ALTER TABLE izinler DROP COLUMN IF EXISTS personel;

-- İndeks güncelle
DROP INDEX IF EXISTS idx_izinler_personel;
CREATE INDEX IF NOT EXISTS idx_izinler_pkod ON izinler(pkod);

-- ============================================================
-- BÖLÜM 6: saha_gorevleri — personel → pkod + gorev_gun
-- ============================================================

ALTER TABLE saha_gorevleri ADD COLUMN IF NOT EXISTS pkod      INTEGER;
ALTER TABLE saha_gorevleri ADD COLUMN IF NOT EXISTS gorev_gun INTEGER DEFAULT 1;

-- Data migration
UPDATE saha_gorevleri s
SET pkod = (
    SELECT p.pkod FROM personel p
    WHERE CONCAT(p.ad, ' ', p.soyad) = s.personel
    LIMIT 1
);

ALTER TABLE saha_gorevleri
    ADD CONSTRAINT saha_gorevleri_pkod_fkey FOREIGN KEY (pkod) REFERENCES personel(pkod);

ALTER TABLE saha_gorevleri DROP COLUMN IF EXISTS personel;

DROP INDEX IF EXISTS idx_saha_gorevleri_personel;
CREATE INDEX IF NOT EXISTS idx_saha_gorevleri_pkod ON saha_gorevleri(pkod);

-- ============================================================
-- BÖLÜM 7: sprint_is_plani — ekip_uyesi → pkod
-- ============================================================

-- RLS politikalarını güncelleme için önce kaldır
DROP POLICY IF EXISTS "sprint_is_plani_insert" ON sprint_is_plani;
DROP POLICY IF EXISTS "sprint_is_plani_update" ON sprint_is_plani;

ALTER TABLE sprint_is_plani ADD COLUMN IF NOT EXISTS pkod INTEGER;

-- Data migration
UPDATE sprint_is_plani si
SET pkod = (
    SELECT p.pkod FROM personel p
    WHERE CONCAT(p.ad, ' ', p.soyad) = si.ekip_uyesi
    LIMIT 1
);

ALTER TABLE sprint_is_plani
    ADD CONSTRAINT sprint_is_plani_pkod_fkey FOREIGN KEY (pkod) REFERENCES personel(pkod);

ALTER TABLE sprint_is_plani DROP COLUMN IF EXISTS ekip_uyesi;
ALTER TABLE sprint_is_plani DROP COLUMN IF EXISTS harcanan_butce;

-- İndeks güncelle
DROP INDEX IF EXISTS idx_sprint_is_plani_ekip_uyesi;
CREATE INDEX IF NOT EXISTS idx_sprint_is_plani_pkod ON sprint_is_plani(pkod);

-- ============================================================
-- BÖLÜM 8: harcamalar — yeniden yapılandır
-- ============================================================

ALTER TABLE harcamalar ADD COLUMN IF NOT EXISTS sprint_is_plani_id INTEGER;

ALTER TABLE harcamalar
    ADD CONSTRAINT harcamalar_sprint_is_plani_id_fkey
    FOREIGN KEY (sprint_is_plani_id) REFERENCES sprint_is_plani(id);

-- Gereksiz sütunları kaldır
ALTER TABLE harcamalar DROP COLUMN IF EXISTS sprint_donem;
ALTER TABLE harcamalar DROP COLUMN IF EXISTS sprint_faaliyet;
ALTER TABLE harcamalar DROP COLUMN IF EXISTS sno;
ALTER TABLE harcamalar DROP COLUMN IF EXISTS durum;
ALTER TABLE harcamalar DROP COLUMN IF EXISTS odeme_kalemleri;

-- İndeks güncelle
DROP INDEX IF EXISTS idx_harcamalar_sprint_donem;
DROP INDEX IF EXISTS idx_harcamalar_sno;
CREATE INDEX IF NOT EXISTS idx_harcamalar_sprint_is_plani_id ON harcamalar(sprint_is_plani_id);

-- ============================================================
-- BÖLÜM 9: sprint_perf_gos — yeniden yapılandır
-- ============================================================

ALTER TABLE sprint_perf_gos ADD COLUMN IF NOT EXISTS sprint_is_plani_id INTEGER;

ALTER TABLE sprint_perf_gos
    ADD CONSTRAINT sprint_perf_gos_sprint_is_plani_id_fkey
    FOREIGN KEY (sprint_is_plani_id) REFERENCES sprint_is_plani(id);

ALTER TABLE sprint_perf_gos DROP COLUMN IF EXISTS sprint_faaliyet;
ALTER TABLE sprint_perf_gos DROP COLUMN IF EXISTS sno;
ALTER TABLE sprint_perf_gos DROP COLUMN IF EXISTS bilesen_adi;
ALTER TABLE sprint_perf_gos DROP COLUMN IF EXISTS cikti_gostergesi;
ALTER TABLE sprint_perf_gos DROP COLUMN IF EXISTS sprint_donem;

CREATE INDEX IF NOT EXISTS idx_sprint_perf_gos_sprint_is_plani_id ON sprint_perf_gos(sprint_is_plani_id);

-- ============================================================
-- BÖLÜM 10: sprint_retro — ad → pkod, gort → aort
-- ============================================================

-- RLS güncelleme için önce kaldır
DROP POLICY IF EXISTS "sprint_retro_insert" ON sprint_retro;

ALTER TABLE sprint_retro ADD COLUMN IF NOT EXISTS pkod INTEGER;

-- Data migration
UPDATE sprint_retro r
SET pkod = (
    SELECT p.pkod FROM personel p
    WHERE CONCAT(p.ad, ' ', p.soyad) = r.ad
    LIMIT 1
);

ALTER TABLE sprint_retro
    ADD CONSTRAINT sprint_retro_pkod_fkey FOREIGN KEY (pkod) REFERENCES personel(pkod);

-- ad sütununu kaldır
ALTER TABLE sprint_retro DROP COLUMN IF EXISTS ad;
DROP INDEX IF EXISTS idx_sprint_retro_ad;
CREATE INDEX IF NOT EXISTS idx_sprint_retro_pkod ON sprint_retro(pkod);

-- gort → aort yeniden adlandır ve aritmetik ortalama olarak güncelle
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sprint_retro' AND column_name = 'gort'
    ) THEN
        ALTER TABLE sprint_retro RENAME COLUMN gort TO aort;
    END IF;
END $$;

-- Mevcut değerleri aritmetik ortalamaya dönüştür
UPDATE sprint_retro
SET aort = (ajanstaki_rolu + ajans_hakkinda) / 2.0
WHERE ajanstaki_rolu IS NOT NULL AND ajans_hakkinda IS NOT NULL;

-- aort otomatik hesaplama trigger'ı
CREATE OR REPLACE FUNCTION fn_update_aort()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.ajanstaki_rolu IS NOT NULL AND NEW.ajans_hakkinda IS NOT NULL THEN
        NEW.aort := (NEW.ajanstaki_rolu + NEW.ajans_hakkinda) / 2.0;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sprint_retro_aort ON sprint_retro;
CREATE TRIGGER trg_sprint_retro_aort
    BEFORE INSERT OR UPDATE OF ajanstaki_rolu, ajans_hakkinda ON sprint_retro
    FOR EACH ROW
    EXECUTE FUNCTION fn_update_aort();

-- org_puan duplicate sütunu kaldır (organizasyon_puan zaten var)
ALTER TABLE sprint_retro DROP COLUMN IF EXISTS org_puan;

-- ============================================================
-- BÖLÜM 11: sprint_veri — izin ve saha VIEW'dan hesaplanacak
-- ============================================================

ALTER TABLE sprint_veri DROP COLUMN IF EXISTS izin;
ALTER TABLE sprint_veri DROP COLUMN IF EXISTS saha;

-- ============================================================
-- BÖLÜM 12: perf_gostergeler — yeniden yapılandır
-- ============================================================

-- 12.1 Yeni sütunlar ekle
ALTER TABLE perf_gostergeler ADD COLUMN IF NOT EXISTS id      SERIAL;
ALTER TABLE perf_gostergeler ADD COLUMN IF NOT EXISTS skod    INTEGER;
ALTER TABLE perf_gostergeler ADD COLUMN IF NOT EXISTS kkod    INTEGER;
ALTER TABLE perf_gostergeler ADD COLUMN IF NOT EXISTS pg_sira INTEGER;

-- 12.2 Data migration: sop text → skod
UPDATE perf_gostergeler pg
SET skod = (SELECT s.skod FROM soplar s WHERE s.kisa = pg.sop);

-- 12.3 kkod: bilesen_kodu formatı "N.M" → N = kkod, M = pg_sira
UPDATE perf_gostergeler
SET kkod = CAST(SPLIT_PART(bilesen_kodu, '.', 1) AS INTEGER)
WHERE bilesen_kodu ~ '^\d+\.\d+$';

UPDATE perf_gostergeler
SET pg_sira = CAST(SPLIT_PART(bilesen_kodu, '.', 2) AS INTEGER)
WHERE bilesen_kodu ~ '^\d+\.\d+$';

-- 12.4 FK ekle
ALTER TABLE perf_gostergeler
    ADD CONSTRAINT perf_gostergeler_skod_fkey FOREIGN KEY (skod) REFERENCES soplar(skod),
    ADD CONSTRAINT perf_gostergeler_kkod_fkey FOREIGN KEY (kkod) REFERENCES kategori_tipleri(kkod);

-- 12.5 PK değiştir: cg_kod → id (cg_kod UNIQUE kalır, sprint_perf_gos FK yeniden bağlanır)
ALTER TABLE perf_gostergeler ADD CONSTRAINT perf_gostergeler_cg_kod_unique UNIQUE (cg_kod);
-- sprint_perf_gos FK'sını geçici kaldır (PK drop için gerekli)
ALTER TABLE sprint_perf_gos DROP CONSTRAINT IF EXISTS sprint_perf_gos_cg_kod_fkey;
ALTER TABLE perf_gostergeler DROP CONSTRAINT perf_gostergeler_pkey;
ALTER TABLE perf_gostergeler ADD PRIMARY KEY (id);
-- sprint_perf_gos FK'sını UNIQUE constraint üzerinden yeniden ekle
ALTER TABLE sprint_perf_gos
    ADD CONSTRAINT sprint_perf_gos_cg_kod_fkey FOREIGN KEY (cg_kod) REFERENCES perf_gostergeler(cg_kod);

-- 12.6 sop text sütununu kaldır
ALTER TABLE perf_gostergeler DROP COLUMN IF EXISTS sop;

-- İndeks güncelle
DROP INDEX IF EXISTS idx_perf_gostergeler_sop;
CREATE INDEX IF NOT EXISTS idx_perf_gostergeler_skod_kkod ON perf_gostergeler(skod, kkod);

-- 12.7 cg_kod ve bilesen_kodu otomatik üretim trigger'ı (yeni INSERT'ler için)
CREATE OR REPLACE FUNCTION fn_generate_cg_kod()
RETURNS TRIGGER AS $$
DECLARE
    v_kisa   VARCHAR(3);
    v_sira   INTEGER;
BEGIN
    SELECT kisa INTO v_kisa FROM soplar WHERE skod = NEW.skod;
    IF v_kisa IS NULL THEN
        RAISE EXCEPTION 'Geçersiz skod: %', NEW.skod;
    END IF;

    SELECT COALESCE(MAX(pg_sira), 0) + 1 INTO v_sira
    FROM perf_gostergeler
    WHERE skod = NEW.skod AND kkod = NEW.kkod;

    NEW.pg_sira      := v_sira;
    NEW.cg_kod       := 'CG' || v_kisa || NEW.kkod::TEXT || v_sira::TEXT;
    NEW.bilesen_kodu := NEW.kkod::TEXT || '.' || v_sira::TEXT;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_perf_gostergeler_cg_kod ON perf_gostergeler;
CREATE TRIGGER trg_perf_gostergeler_cg_kod
    BEFORE INSERT ON perf_gostergeler
    FOR EACH ROW
    EXECUTE FUNCTION fn_generate_cg_kod();

-- ============================================================
-- BÖLÜM 13: VIEW'LARI YENİDEN OLUŞTUR
-- ============================================================

-- VIEW 1: v_alt_faaliyet_ozet
-- Kaynak: alt_faaliyetler × sprint_is_plani × harcamalar (sprint_is_plani_id üzerinden)
CREATE OR REPLACE VIEW v_alt_faaliyet_ozet AS
SELECT
    af.sno,
    af.fkod,
    af.alt_faaliyet,
    af.anahtar_sonuclar,
    af.p_sure,
    af.tekrar_sayisi,
    -- İş yükü: p_sure × tekrar_sayisi
    COALESCE(af.p_sure * af.tekrar_sayisi, 0)                           AS is_yuku,
    -- Gerçekleşme sayısı: tüm sprint_is_plani bağlı kayıtların sayısı
    COUNT(si.id)                                                         AS gerceklesme_sayi,
    -- Gerçek iş yükü: gerçek süre toplamı
    COALESCE(SUM(si.gercek_sure), 0)                                    AS gercek_is_yuku,
    -- Harcanan bütçe: harcamalar tablosundan sprint_is_plani üzerinden
    COALESCE(SUM(h.odenecek_kdvli), 0)                                  AS harcanan_butce,
    -- İş durum oranı: gerceklesme_sayi / tekrar_sayisi
    CASE
        WHEN af.tekrar_sayisi > 0
        THEN COUNT(si.id)::DECIMAL / af.tekrar_sayisi
        ELSE NULL
    END                                                                  AS is_durum_oran
FROM alt_faaliyetler af
LEFT JOIN sprint_is_plani si ON si.sno = af.sno
LEFT JOIN harcamalar h ON h.sprint_is_plani_id = si.id
GROUP BY af.sno, af.fkod, af.alt_faaliyet, af.anahtar_sonuclar,
         af.p_sure, af.tekrar_sayisi;

COMMENT ON VIEW v_alt_faaliyet_ozet IS 'Alt faaliyet bazlı iş yükü, gerçekleşme ve harcama özeti';

-- VIEW 2: v_faaliyet_ozet
CREATE OR REPLACE VIEW v_faaliyet_ozet AS
SELECT
    f.id,
    f.fkod,
    f.skod,
    f.kkod,
    f.faaliyet,
    f.butce_2026,
    AVG(vafo.is_durum_oran)             AS is_durum_ort,
    COALESCE(SUM(vafo.harcanan_butce), 0) AS harcanan_butce_toplam
FROM faaliyetler f
LEFT JOIN v_alt_faaliyet_ozet vafo ON vafo.fkod = f.fkod
GROUP BY f.id, f.fkod, f.skod, f.kkod, f.faaliyet, f.butce_2026;

COMMENT ON VIEW v_faaliyet_ozet IS 'Faaliyet bazlı bütçe, durum ve ilerleme özeti';

-- VIEW 3: v_sprint_ozet
-- izin ve saha artık izinler/saha_gorevleri tablolarından hesaplanıyor
CREATE OR REPLACE VIEW v_sprint_ozet AS
WITH
sip_agg AS (
    SELECT
        sprint_donem,
        COALESCE(SUM(plan_sure), 0)                                          AS plan_toplam,
        COALESCE(SUM(CASE WHEN is_durum = 'Tamamlandı' AND bitis_donem = sprint_donem
            THEN plan_sure ELSE 0 END), 0)                                   AS t_skor,
        COALESCE(SUM(CASE WHEN is_durum = 'Tamamlandı' AND bitis_donem = sprint_donem
            THEN gercek_sure ELSE 0 END), 0)                                 AS gerceklesme
    FROM sprint_is_plani
    GROUP BY sprint_donem
),
retro_agg AS (
    SELECT
        sprint_donem,
        EXP(AVG(LN(NULLIF(organizasyon_puan::float, 0))))                   AS org_puan,
        EXP(AVG(LN(NULLIF(aort::float, 0))))                                AS hepiniss
    FROM sprint_retro
    WHERE sprint_donem IS NOT NULL
      AND ajanstaki_rolu IS NOT NULL AND ajans_hakkinda IS NOT NULL
    GROUP BY sprint_donem
),
izin_agg AS (
    SELECT
        sv.sprint_donem,
        COALESCE(SUM(iz.izin_gun_sayi), 0) AS toplam_izin
    FROM sprint_veri sv
    LEFT JOIN izinler iz
        ON iz.izin_basl <= sv.bitis AND iz.izin_bitis >= sv.baslangic
    GROUP BY sv.sprint_donem
),
saha_agg AS (
    SELECT
        sv.sprint_donem,
        COALESCE(SUM(sg.gorev_gun), 0) AS toplam_saha
    FROM sprint_veri sv
    LEFT JOIN saha_gorevleri sg
        ON sg.tarih BETWEEN sv.baslangic AND sv.bitis
    GROUP BY sv.sprint_donem
)
SELECT
    sv.sprint_donem,
    sv.baslangic,
    sv.bitis,
    sv.sprint_adi,
    sv.isim_veren,
    sv.sure_gun,
    sv.ekip,
    ia.toplam_izin                                                           AS izin,
    sa.toplam_saha                                                           AS saha,
    ra.org_puan,
    ra.hepiniss,
    COALESCE(sip.t_skor, 0)                                                  AS t_skor,
    CASE
        WHEN (sv.sure_gun * sv.ekip - COALESCE(ia.toplam_izin, 0)) > 0
        THEN COALESCE(sip.t_skor, 0)::float
             / (sv.sure_gun * sv.ekip - COALESCE(ia.toplam_izin, 0)) * 100
        ELSE 0
    END                                                                      AS gki,
    COALESCE(sip.plan_toplam, 0)                                             AS plan_toplam,
    COALESCE(sip.gerceklesme, 0)                                             AS gerceklesme
FROM sprint_veri sv
LEFT JOIN sip_agg sip ON sip.sprint_donem = sv.sprint_donem
LEFT JOIN retro_agg ra  ON ra.sprint_donem = sv.sprint_donem
LEFT JOIN izin_agg ia   ON ia.sprint_donem = sv.sprint_donem
LEFT JOIN saha_agg sa   ON sa.sprint_donem = sv.sprint_donem;

COMMENT ON VIEW v_sprint_ozet IS 'Sprint bazlı GKİ, Hepiniss, T.Skor, OrgPuan — izin/saha canlı hesaplama';

-- VIEW 4: v_perf_gosterge_ozet
CREATE OR REPLACE VIEW v_perf_gosterge_ozet AS
SELECT
    pg.id,
    pg.cg_kod,
    pg.skod,
    pg.kkod,
    pg.bilesen_kodu,
    pg.bilesen_adi,
    pg.cikti_gostergesi,
    pg.birim,
    pg.hedef,
    pg.tamamlanma_donemi,
    pg.katki_sonuc_gostergesi,
    pg.hedef_2024,
    pg.hedef_2025,
    pg.hedef_2026,
    pg.gerceklesen_2024,
    pg.gerceklesen_2025,
    COALESCE(spg_2026.toplam, 0)                                             AS gerceklesen_2026,
    (COALESCE(pg.gerceklesen_2024, 0)
     + COALESCE(pg.gerceklesen_2025, 0)
     + COALESCE(spg_2026.toplam, 0))                                         AS kumulatif_gerceklesme
FROM perf_gostergeler pg
LEFT JOIN (
    SELECT cg_kod, SUM(gerceklesme) AS toplam
    FROM sprint_perf_gos
    WHERE yil = 2026
    GROUP BY cg_kod
) spg_2026 ON spg_2026.cg_kod = pg.cg_kod;

COMMENT ON VIEW v_perf_gosterge_ozet IS 'Performans göstergesi bazlı kümülatif gerçekleşme ve hedef karşılaştırması';

-- VIEW 5: v_faaliyet_harcama (YENİ — aylık harcama görünümü faaliyet bazlı)
CREATE OR REPLACE VIEW v_faaliyet_harcama AS
SELECT
    f.id                                AS faaliyet_id,
    f.fkod,
    f.faaliyet,
    f.skod,
    f.kkod,
    s.kisa                              AS sop_kisa,
    kt.kategori_adi,
    EXTRACT(YEAR  FROM h.onay_tarihi)   AS yil,
    EXTRACT(MONTH FROM h.onay_tarihi)   AS ay,
    SUM(h.odenecek_kdvli)               AS toplam_harcama,
    COUNT(h.id)                         AS harcama_adet
FROM faaliyetler f
JOIN soplar s ON s.skod = f.skod
JOIN kategori_tipleri kt ON kt.kkod = f.kkod
JOIN alt_faaliyetler af ON af.fkod = f.fkod
JOIN sprint_is_plani si ON si.sno = af.sno
JOIN harcamalar h ON h.sprint_is_plani_id = si.id
WHERE h.onay_tarihi IS NOT NULL
GROUP BY f.id, f.fkod, f.faaliyet, f.skod, f.kkod, s.kisa, kt.kategori_adi,
         EXTRACT(YEAR FROM h.onay_tarihi), EXTRACT(MONTH FROM h.onay_tarihi);

COMMENT ON VIEW v_faaliyet_harcama IS 'Faaliyet bazlı yıl/ay harcama özeti — filtre: yil ve faaliyet_id';

-- ============================================================
-- BÖLÜM 14: RLS POLİTİKA GÜNCELLEMELERİ
-- ============================================================

-- sprint_is_plani: pkod bazlı politikalar
DROP POLICY IF EXISTS "sprint_is_plani_insert" ON sprint_is_plani;
CREATE POLICY "sprint_is_plani_insert"
    ON sprint_is_plani FOR INSERT
    TO authenticated
    WITH CHECK (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
        OR pkod = (SELECT pkod FROM personel WHERE auth_id = auth.uid())
    );

DROP POLICY IF EXISTS "sprint_is_plani_update" ON sprint_is_plani;
CREATE POLICY "sprint_is_plani_update"
    ON sprint_is_plani FOR UPDATE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
        OR pkod = (SELECT pkod FROM personel WHERE auth_id = auth.uid())
    );

-- sprint_retro: pkod bazlı insert
DROP POLICY IF EXISTS "sprint_retro_insert" ON sprint_retro;
CREATE POLICY "sprint_retro_insert"
    ON sprint_retro FOR INSERT
    TO authenticated
    WITH CHECK (
        pkod = (SELECT pkod FROM personel WHERE auth_id = auth.uid())
    );

-- kategori_tipleri: RLS etkinleştir (kategoriler silindiğinden yönetim buradan)
ALTER TABLE kategori_tipleri ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "kategori_tipleri_select" ON kategori_tipleri;
CREATE POLICY "kategori_tipleri_select"
    ON kategori_tipleri FOR SELECT
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "kategori_tipleri_insert_yonetici" ON kategori_tipleri;
CREATE POLICY "kategori_tipleri_insert_yonetici"
    ON kategori_tipleri FOR INSERT
    TO authenticated
    WITH CHECK (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

DROP POLICY IF EXISTS "kategori_tipleri_update_yonetici" ON kategori_tipleri;
CREATE POLICY "kategori_tipleri_update_yonetici"
    ON kategori_tipleri FOR UPDATE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

DROP POLICY IF EXISTS "kategori_tipleri_delete_yonetici" ON kategori_tipleri;
CREATE POLICY "kategori_tipleri_delete_yonetici"
    ON kategori_tipleri FOR DELETE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

-- ============================================================
-- BÖLÜM 15: AUDIT TRIGGER GÜNCELLEMESİ
-- harcamalar audit trigger'ı güncelle (sprint_donem artık yok)
-- sprint_is_plani audit trigger güncelle (ekip_uyesi artık yok)
-- ============================================================

-- Audit function personel tablosundan pkod → isim çeker
CREATE OR REPLACE FUNCTION update_audit_fields()
RETURNS TRIGGER AS $$
DECLARE
    v_ad    VARCHAR(50);
    v_soyad VARCHAR(50);
BEGIN
    SELECT ad, soyad INTO v_ad, v_soyad
    FROM personel
    WHERE auth_id = auth.uid();

    NEW.guncel_tarih := NOW()::DATE;
    NEW.guncelleyen  := COALESCE(CONCAT(v_ad, ' ', v_soyad), '');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- BÖLÜM 16: YORUM SATIRLARI / DOĞRULAMA SORGULARI
-- ============================================================
-- Aşağıdaki SELECT'leri çalıştırarak migration'ı doğrulayın:
--
-- 1. soplar kisa güncellendi mi?
--    SELECT skod, kisa FROM soplar WHERE skod IN (5,7);
--    → (5, 'SDD'), (7, 'ABP')
--
-- 2. faaliyetler yeni yapı:
--    SELECT id, fkod, skod, kkod, fsirano FROM faaliyetler LIMIT 5;
--
-- 3. fkod auto-generate test:
--    INSERT INTO faaliyetler (skod, kkod, faaliyet, butce_2026)
--    VALUES (1, 1, 'Test faaliyet', 0) RETURNING fkod, fsirano;
--
-- 4. alt_faaliyetler temizlendi mi?
--    SELECT column_name FROM information_schema.columns
--    WHERE table_name='alt_faaliyetler';
--    → sno, fkod, alt_faaliyet, anahtar_sonuclar, p_sure, tekrar_sayisi
--
-- 5. v_sprint_ozet çalışıyor mu?
--    SELECT sprint_donem, t_skor, hepiniss, izin, saha FROM v_sprint_ozet LIMIT 3;
--
-- 6. v_alt_faaliyet_ozet çalışıyor mu?
--    SELECT sno, is_yuku, harcanan_butce, is_durum_oran FROM v_alt_faaliyet_ozet LIMIT 5;
