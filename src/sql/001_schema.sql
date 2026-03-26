-- UTF-8 | Sprint Kanban | Tablo şeması — tüm CREATE TABLE ifadeleri
-- TR90 Kalkınma Ajansı Sprint Kanban Projesi
-- Oluşturma tarihi: 2026-03-25

-- ============================================================
-- BÖLÜM 1: LOOKUP TABLOLARI
-- ============================================================

-- birimler: Ajans birimleri (SKB, MEKB, KYİKB, PİDB)
CREATE TABLE IF NOT EXISTS birimler (
    bkod        INTEGER         PRIMARY KEY,
    birim_kisa  VARCHAR(10)     NOT NULL UNIQUE,
    birim_adi   VARCHAR(100)    NOT NULL,
    durum       VARCHAR(10)     DEFAULT 'Aktif'
);

COMMENT ON TABLE birimler IS 'TR90 Kalkınma Ajansı birimlerinin lookup tablosu';
COMMENT ON COLUMN birimler.bkod IS 'Birim kodu (PK)';
COMMENT ON COLUMN birimler.birim_kisa IS 'Birim kısa adı (ör: SKB, MEKB)';
COMMENT ON COLUMN birimler.birim_adi IS 'Birimin tam adı';
COMMENT ON COLUMN birimler.durum IS 'Aktif veya Pasif';

-- soplar: SOP (Sonuç Odaklı Program) tanımları
CREATE TABLE IF NOT EXISTS soplar (
    skod        INTEGER         PRIMARY KEY,
    kisa        VARCHAR(10)     NOT NULL UNIQUE,
    sop_adi     VARCHAR(100)    NOT NULL,
    baslangic   INTEGER,
    bitis       INTEGER,
    bkod        INTEGER         REFERENCES birimler(bkod),
    durum       VARCHAR(10)     DEFAULT 'Aktif'
);

COMMENT ON TABLE soplar IS 'SOP (Sonuç Odaklı Program) lookup tablosu';
COMMENT ON COLUMN soplar.skod IS 'SOP kodu (PK)';
COMMENT ON COLUMN soplar.kisa IS 'SOP kısa kodu (ör: STU, KDU, MEK)';
COMMENT ON COLUMN soplar.sop_adi IS 'SOP tam adı';
COMMENT ON COLUMN soplar.baslangic IS 'Başlangıç yılı';
COMMENT ON COLUMN soplar.bitis IS 'Bitiş yılı';
COMMENT ON COLUMN soplar.bkod IS 'Bağlı birim FK → birimler.bkod';
COMMENT ON COLUMN soplar.durum IS 'Aktif veya Pasif';

CREATE INDEX IF NOT EXISTS idx_soplar_bkod ON soplar(bkod);

-- kategori_tipleri: Master kategori tanımları (normalize edilmiş)
CREATE TABLE IF NOT EXISTS kategori_tipleri (
    kkod            INTEGER         PRIMARY KEY,
    kategori_adi    VARCHAR(200)    NOT NULL UNIQUE
);

COMMENT ON TABLE kategori_tipleri IS 'Master kategori tanımları (normalize edilmiş)';
COMMENT ON COLUMN kategori_tipleri.kkod IS 'Kategori kodu (PK)';
COMMENT ON COLUMN kategori_tipleri.kategori_adi IS 'Kategori açıklaması (unique)';

-- kategoriler: SOP-kategori ilişki tablosu (Many-to-Many)
CREATE TABLE IF NOT EXISTS kategoriler (
    skod            INTEGER         REFERENCES soplar(skod),
    kkod            INTEGER         REFERENCES kategori_tipleri(kkod),
    PRIMARY KEY (skod, kkod)
);

COMMENT ON TABLE kategoriler IS 'SOP ve kategori tipleri arasındaki ilişki tablosu';
COMMENT ON COLUMN kategoriler.skod IS 'SOP kodu (PK, FK → soplar.skod)';
COMMENT ON COLUMN kategoriler.kkod IS 'Kategori kodu (PK, FK → kategori_tipleri.kkod)';

-- kullanici_rolleri: Uygulama içi yetki seviyeleri (kategoriler)
CREATE TABLE IF NOT EXISTS kullanici_rolleri (
    rol_kodu    VARCHAR(20)     PRIMARY KEY,
    aciklama    VARCHAR(100)    NOT NULL
);

COMMENT ON TABLE kullanici_rolleri IS 'Sistem yetki/rol seviyeleri';
COMMENT ON COLUMN kullanici_rolleri.rol_kodu IS 'Rol kodu (PK, ör: yönetici, standart, izleyici)';

-- personel: Sistem kullanıcıları ve ekip üyeleri
CREATE TABLE IF NOT EXISTS personel (
    pkod        INTEGER         PRIMARY KEY,
    ad          VARCHAR(50)     NOT NULL,
    soyad       VARCHAR(50)     NOT NULL,
    bkod        INTEGER         REFERENCES birimler(bkod),
    durum       VARCHAR(10)     DEFAULT 'Aktif',
    auth_id     UUID            UNIQUE REFERENCES auth.users(id),
    rol_kodu    VARCHAR(20)     REFERENCES kullanici_rolleri(rol_kodu) DEFAULT 'standart'
);

COMMENT ON TABLE personel IS 'Sistem kullanıcıları ve ekip üyeleri';
COMMENT ON COLUMN personel.pkod IS 'Personel kodu (PK)';
COMMENT ON COLUMN personel.ad IS 'Personel adı';
COMMENT ON COLUMN personel.soyad IS 'Personel soyadı';
COMMENT ON COLUMN personel.bkod IS 'Bağlı birim FK → birimler.bkod';
COMMENT ON COLUMN personel.durum IS 'Aktif veya Pasif';
COMMENT ON COLUMN personel.auth_id IS 'Supabase Auth kullanıcı ID (auth.users.id)';
COMMENT ON COLUMN personel.rol_kodu IS 'Kullanıcı yetki seviyesi FK → kullanici_rolleri.rol_kodu (varsayılan: standart)';

CREATE INDEX IF NOT EXISTS idx_personel_bkod ON personel(bkod);
CREATE INDEX IF NOT EXISTS idx_personel_auth_id ON personel(auth_id);
CREATE INDEX IF NOT EXISTS idx_personel_rol_kodu ON personel(rol_kodu);

-- ============================================================
-- BÖLÜM 2: ANA İŞ TABLOLARI
-- ============================================================

-- faaliyetler: Yıllık faaliyet planı (30 kayıt)
CREATE TABLE IF NOT EXISTS faaliyetler (
    fkod        VARCHAR(10)     PRIMARY KEY,
    sop         VARCHAR(10)     REFERENCES soplar(kisa),
    kategori    VARCHAR(200),
    faaliyet    VARCHAR(500)    NOT NULL,
    butce_2026  DECIMAL(15,2)   DEFAULT 0,
    aylik_plan  JSONB           DEFAULT '{}'
);

COMMENT ON TABLE faaliyetler IS 'Yıllık SOP bazlı faaliyet planı';
COMMENT ON COLUMN faaliyetler.fkod IS 'Faaliyet kodu (PK, ör: KDU101, STU401)';
COMMENT ON COLUMN faaliyetler.sop IS 'SOP kısa kodu FK → soplar.kisa';
COMMENT ON COLUMN faaliyetler.kategori IS 'Faaliyet kategorisi';
COMMENT ON COLUMN faaliyetler.faaliyet IS 'Faaliyet açıklaması';
COMMENT ON COLUMN faaliyetler.butce_2026 IS '2026 yılı bütçesi (TL)';
COMMENT ON COLUMN faaliyetler.aylik_plan IS 'Aylık planlama bayrakları JSONB: {"oca":1,"sub":0,...}';

CREATE INDEX IF NOT EXISTS idx_faaliyetler_sop ON faaliyetler(sop);

-- alt_faaliyetler: Alt görev/faaliyet tanımları (53 kayıt)
CREATE TABLE IF NOT EXISTS alt_faaliyetler (
    sno                 INTEGER         PRIMARY KEY,
    fkod                VARCHAR(10)     REFERENCES faaliyetler(fkod),
    sop                 VARCHAR(10),
    kategori            VARCHAR(200),
    faaliyet            VARCHAR(500),
    alt_faaliyet        VARCHAR(500)    NOT NULL,
    anahtar_sonuclar    TEXT,
    p_sure              DECIMAL(5,1),
    tekrar_sayisi       INTEGER
);

COMMENT ON TABLE alt_faaliyetler IS 'Alt faaliyet tanımları — sprint görevlerinin bağlandığı temel tablo';
COMMENT ON COLUMN alt_faaliyetler.sno IS 'Sıra numarası (PK, benzersiz)';
COMMENT ON COLUMN alt_faaliyetler.fkod IS 'Bağlı faaliyet FK → faaliyetler.fkod';
COMMENT ON COLUMN alt_faaliyetler.alt_faaliyet IS 'Alt faaliyet açıklaması';
COMMENT ON COLUMN alt_faaliyetler.p_sure IS 'Planlanan süre (gün)';
COMMENT ON COLUMN alt_faaliyetler.tekrar_sayisi IS 'Yıl içi tekrar sayısı';

CREATE INDEX IF NOT EXISTS idx_alt_faaliyetler_fkod ON alt_faaliyetler(fkod);

-- anahtar_sonuclar: Alt faaliyet başarı kriterleri (91 kayıt)
CREATE TABLE IF NOT EXISTS anahtar_sonuclar (
    sno             INTEGER         REFERENCES alt_faaliyetler(sno),
    as_no           INTEGER,
    anahtar_sonuc   VARCHAR(500)    NOT NULL,
    durum           VARCHAR(20)     DEFAULT 'Aktif',
    created_at      TIMESTAMPTZ     DEFAULT NOW(),
    PRIMARY KEY (sno, as_no)
);

COMMENT ON TABLE anahtar_sonuclar IS 'Alt faaliyet başarı kriterleri ve anahtar sonuçları';
COMMENT ON COLUMN anahtar_sonuclar.sno IS 'Alt faaliyet sıra no (PK, FK → alt_faaliyetler.sno)';
COMMENT ON COLUMN anahtar_sonuclar.as_no IS 'Anahtar sonuç sıra no (PK)';
COMMENT ON COLUMN anahtar_sonuclar.anahtar_sonuc IS 'Beklenen sonuç açıklaması';

CREATE INDEX IF NOT EXISTS idx_anahtar_sonuclar_sno ON anahtar_sonuclar(sno);

-- sprint_veri: Sprint dönemleri (17 kayıt: 4 aktif + 13 şablon)
CREATE TABLE IF NOT EXISTS sprint_veri (
    sprint_donem    INTEGER         PRIMARY KEY,
    baslangic       DATE            NOT NULL,
    bitis           DATE            NOT NULL,
    sprint_adi      VARCHAR(50),
    isim_veren      VARCHAR(50),
    sure_gun        INTEGER,
    ekip            INTEGER,
    izin            INTEGER         DEFAULT 0,
    saha            INTEGER         DEFAULT 0
);

COMMENT ON TABLE sprint_veri IS 'Sprint dönemlerinin tanım ve meta verileri';
COMMENT ON COLUMN sprint_veri.sprint_donem IS 'Sprint dönem numarası (PK)';
COMMENT ON COLUMN sprint_veri.baslangic IS 'Sprint başlangıç tarihi';
COMMENT ON COLUMN sprint_veri.bitis IS 'Sprint bitiş tarihi';
COMMENT ON COLUMN sprint_veri.sprint_adi IS 'Sprint ismi (ör: Middle, Zemu, Maison, House)';
COMMENT ON COLUMN sprint_veri.isim_veren IS 'Sprint adını veren kişi';
COMMENT ON COLUMN sprint_veri.sure_gun IS 'Sprint süresi (gün cinsinden)';
COMMENT ON COLUMN sprint_veri.ekip IS 'Ekip üye sayısı';
COMMENT ON COLUMN sprint_veri.izin IS 'Sprint dönemindeki toplam izin gün sayısı';
COMMENT ON COLUMN sprint_veri.saha IS 'Sprint dönemindeki toplam saha görev gün sayısı';

-- sprint_is_plani: Ana Kanban tablosu (102 kayıt) ⭐
CREATE TABLE IF NOT EXISTS sprint_is_plani (
    id                      SERIAL          PRIMARY KEY,
    sprint_donem            INTEGER         REFERENCES sprint_veri(sprint_donem),
    bitis_donem             INTEGER,
    sprint_faaliyetleri     VARCHAR(500)    NOT NULL,
    sno                     INTEGER         REFERENCES alt_faaliyetler(sno),
    plan_sure               DECIMAL(5,1),
    is_durum                VARCHAR(20)     CHECK (is_durum IN ('Başladı', 'İncelemede', 'Tamamlandı') OR is_durum IS NULL),
    baslama_t               DATE,
    inceleme_t              DATE,
    tamamlanma_t            DATE,
    ekip_uyesi              VARCHAR(50),
    gercek_sure             DECIMAL(5,1),
    harcanan_butce          DECIMAL(15,2),
    performans_gostergeler  TEXT,
    guncel_tarih            DATE,
    guncelleyen             VARCHAR(50),
    created_at              TIMESTAMPTZ     DEFAULT NOW()
);

COMMENT ON TABLE sprint_is_plani IS 'Ana Kanban tablosu — sprint görevleri ve durumları';
COMMENT ON COLUMN sprint_is_plani.id IS 'Otomatik artan PK';
COMMENT ON COLUMN sprint_is_plani.sprint_donem IS 'Görevin ait olduğu sprint FK → sprint_veri.sprint_donem';
COMMENT ON COLUMN sprint_is_plani.bitis_donem IS 'Görevin tamamlandığı/bitirildiği sprint dönemi (GKİ hesabı için)';
COMMENT ON COLUMN sprint_is_plani.sprint_faaliyetleri IS 'Görev açıklaması';
COMMENT ON COLUMN sprint_is_plani.sno IS 'Bağlı alt faaliyet FK → alt_faaliyetler.sno';
COMMENT ON COLUMN sprint_is_plani.plan_sure IS 'Planlanan süre (gün)';
COMMENT ON COLUMN sprint_is_plani.is_durum IS 'Kanban durumu: NULL=Backlog, Başladı, İncelemede, Tamamlandı';
COMMENT ON COLUMN sprint_is_plani.baslama_t IS 'Başlama tarihi (Backlog→Başladı geçişinde otomatik)';
COMMENT ON COLUMN sprint_is_plani.inceleme_t IS 'İncelemeye alınma tarihi';
COMMENT ON COLUMN sprint_is_plani.tamamlanma_t IS 'Tamamlanma tarihi';
COMMENT ON COLUMN sprint_is_plani.ekip_uyesi IS 'Atanan ekip üyesi adı';
COMMENT ON COLUMN sprint_is_plani.gercek_sure IS 'Gerçekleşen süre (gün)';
COMMENT ON COLUMN sprint_is_plani.harcanan_butce IS 'Bu göreve ait harcanan bütçe (TL)';
COMMENT ON COLUMN sprint_is_plani.guncel_tarih IS 'Son güncelleme tarihi (audit trigger ile)';
COMMENT ON COLUMN sprint_is_plani.guncelleyen IS 'Son güncelleyen kullanıcı (audit trigger ile)';

CREATE INDEX IF NOT EXISTS idx_sprint_is_plani_sprint_donem ON sprint_is_plani(sprint_donem);
CREATE INDEX IF NOT EXISTS idx_sprint_is_plani_sno ON sprint_is_plani(sno);
CREATE INDEX IF NOT EXISTS idx_sprint_is_plani_ekip_uyesi ON sprint_is_plani(ekip_uyesi);
CREATE INDEX IF NOT EXISTS idx_sprint_is_plani_is_durum ON sprint_is_plani(is_durum);
CREATE INDEX IF NOT EXISTS idx_sprint_is_plani_bitis_donem ON sprint_is_plani(bitis_donem);

-- harcamalar: Harcama kayıtları (8 kayıt)
CREATE TABLE IF NOT EXISTS harcamalar (
    id                  SERIAL          PRIMARY KEY,
    sprint_donem        INTEGER         REFERENCES sprint_veri(sprint_donem),
    sprint_faaliyet     VARCHAR(500),
    sno                 INTEGER         REFERENCES alt_faaliyetler(sno),
    aciklama            TEXT,
    harcama_onay_kodu   VARCHAR(20),
    onay_tarihi         DATE,
    odeme_donem         VARCHAR(20),
    odenecek_kdvli      DECIMAL(15,2)   NOT NULL,
    durum               VARCHAR(20),
    guncel_tarih        DATE,
    guncelleyen         VARCHAR(50),
    created_at          TIMESTAMPTZ     DEFAULT NOW()
);

COMMENT ON TABLE harcamalar IS 'Faaliyet harcama kayıtları';
COMMENT ON COLUMN harcamalar.id IS 'Otomatik artan PK';
COMMENT ON COLUMN harcamalar.sprint_donem IS 'İlgili sprint FK → sprint_veri.sprint_donem';
COMMENT ON COLUMN harcamalar.sno IS 'İlgili alt faaliyet FK → alt_faaliyetler.sno';
COMMENT ON COLUMN harcamalar.odeme_donem IS 'Ödeme dönemi (ör: 2026.Oca, 2026.Şub)';
COMMENT ON COLUMN harcamalar.odenecek_kdvli IS 'KDV dahil ödenecek tutar (TL)';
COMMENT ON COLUMN harcamalar.guncel_tarih IS 'Son güncelleme tarihi (audit trigger ile)';
COMMENT ON COLUMN harcamalar.guncelleyen IS 'Son güncelleyen kullanıcı (audit trigger ile)';

CREATE INDEX IF NOT EXISTS idx_harcamalar_sprint_donem ON harcamalar(sprint_donem);
CREATE INDEX IF NOT EXISTS idx_harcamalar_sno ON harcamalar(sno);

-- perf_gostergeler: Performans göstergeleri tanımları (28 kayıt)
CREATE TABLE IF NOT EXISTS perf_gostergeler (
    cg_kod                  VARCHAR(20)     PRIMARY KEY,
    sop                     VARCHAR(10)     REFERENCES soplar(kisa),
    bilesen_kodu            VARCHAR(10),
    bilesen_adi             VARCHAR(500),
    cikti_gostergesi        VARCHAR(500),
    birim                   VARCHAR(20),
    hedef                   DECIMAL(10,2),
    tamamlanma_donemi       VARCHAR(10),
    katki_sonuc_gostergesi  VARCHAR(500),
    hedef_2024              DECIMAL(10,2),
    hedef_2025              DECIMAL(10,2),
    hedef_2026              DECIMAL(10,2),
    gerceklesen_2024        DECIMAL(10,2),
    gerceklesen_2025        DECIMAL(10,2)
);

COMMENT ON TABLE perf_gostergeler IS 'SOP bazlı çıktı performans göstergeleri';
COMMENT ON COLUMN perf_gostergeler.cg_kod IS 'Çıktı göstergesi kodu (PK, ör: ÇGSTU11)';
COMMENT ON COLUMN perf_gostergeler.sop IS 'Bağlı SOP FK → soplar.kisa';
COMMENT ON COLUMN perf_gostergeler.hedef_2026 IS '2026 yılı hedef değeri';
COMMENT ON COLUMN perf_gostergeler.gerceklesen_2024 IS '2024 yılı gerçekleşme değeri';
COMMENT ON COLUMN perf_gostergeler.gerceklesen_2025 IS '2025 yılı gerçekleşme değeri';

CREATE INDEX IF NOT EXISTS idx_perf_gostergeler_sop ON perf_gostergeler(sop);

-- sprint_perf_gos: Sprint bazlı performans gerçekleşmeleri (8 kayıt)
CREATE TABLE IF NOT EXISTS sprint_perf_gos (
    id                      SERIAL          PRIMARY KEY,
    sprint_faaliyet         VARCHAR(500),
    sno                     INTEGER         REFERENCES alt_faaliyetler(sno),
    cg_kod                  VARCHAR(20)     REFERENCES perf_gostergeler(cg_kod),
    bilesen_adi             VARCHAR(500),
    cikti_gostergesi        VARCHAR(500),
    aciklama                TEXT,
    birim                   VARCHAR(20),
    gerceklesme             DECIMAL(10,2),
    tamamlanma_donemi       VARCHAR(10),
    tamamlanma_tarihi       DATE,
    yil                     INTEGER,
    created_at              TIMESTAMPTZ     DEFAULT NOW()
);

COMMENT ON TABLE sprint_perf_gos IS 'Sprint bazlı performans göstergesi gerçekleşme kayıtları';
COMMENT ON COLUMN sprint_perf_gos.cg_kod IS 'Çıktı göstergesi kodu FK → perf_gostergeler.cg_kod';
COMMENT ON COLUMN sprint_perf_gos.gerceklesme IS 'Gerçekleşme miktarı';
COMMENT ON COLUMN sprint_perf_gos.yil IS 'Yıl bilgisi (2026)';

CREATE INDEX IF NOT EXISTS idx_sprint_perf_gos_cg_kod ON sprint_perf_gos(cg_kod);
CREATE INDEX IF NOT EXISTS idx_sprint_perf_gos_yil ON sprint_perf_gos(yil);

-- sprint_retro: Sprint retrospektif puanları (29 kayıt)
CREATE TABLE IF NOT EXISTS sprint_retro (
    id                  SERIAL          PRIMARY KEY,
    tarih               TIMESTAMP,
    ad                  VARCHAR(50),
    sprint_toplanti     DATE,
    organizasyon_puan   INTEGER         CHECK (organizasyon_puan BETWEEN 1 AND 10),
    ajanstaki_rolu      INTEGER         CHECK (ajanstaki_rolu BETWEEN 1 AND 10),
    ajans_hakkinda      INTEGER         CHECK (ajans_hakkinda BETWEEN 1 AND 10),
    durum               VARCHAR(20),
    created_at          TIMESTAMPTZ     DEFAULT NOW()
);

COMMENT ON TABLE sprint_retro IS 'Sprint retrospektif form yanıtları ve memnuniyet puanları';
COMMENT ON COLUMN sprint_retro.id IS 'Otomatik artan PK';
COMMENT ON COLUMN sprint_retro.tarih IS 'Form yanıtlanma zamanı';
COMMENT ON COLUMN sprint_retro.ad IS 'Personel adı';
COMMENT ON COLUMN sprint_retro.sprint_toplanti IS 'Sprint toplantı tarihi (sprint_veri.bitis ile eşleşir)';
COMMENT ON COLUMN sprint_retro.organizasyon_puan IS 'Organizasyon puanı (1-10)';
COMMENT ON COLUMN sprint_retro.ajanstaki_rolu IS 'Ajanstaki rolüne memnuniyet (1-10)';
COMMENT ON COLUMN sprint_retro.ajans_hakkinda IS 'Ajans hakkında genel memnuniyet (1-10)';

CREATE INDEX IF NOT EXISTS idx_sprint_retro_sprint_toplanti ON sprint_retro(sprint_toplanti);
CREATE INDEX IF NOT EXISTS idx_sprint_retro_ad ON sprint_retro(ad);

-- izinler: Personel izin kayıtları (5 kayıt)
CREATE TABLE IF NOT EXISTS izinler (
    id          SERIAL          PRIMARY KEY,
    izin_basl   DATE            NOT NULL,
    izin_bitis  DATE            NOT NULL,
    personel    VARCHAR(50),
    aciklama    VARCHAR(200),
    durum       VARCHAR(20),
    created_at  TIMESTAMPTZ     DEFAULT NOW()
);

COMMENT ON TABLE izinler IS 'Personel izin kayıtları (GKİ hesabında sprint_veri.izin için)';
COMMENT ON COLUMN izinler.izin_basl IS 'İzin başlangıç tarihi';
COMMENT ON COLUMN izinler.izin_bitis IS 'İzin bitiş tarihi';
COMMENT ON COLUMN izinler.personel IS 'Personel adı (Auth bağımsız VARCHAR)';
COMMENT ON COLUMN izinler.aciklama IS 'İzin türü açıklaması (ör: Yıllık izin)';

CREATE INDEX IF NOT EXISTS idx_izinler_personel ON izinler(personel);
CREATE INDEX IF NOT EXISTS idx_izinler_izin_basl ON izinler(izin_basl);

-- saha_gorevleri: Saha/seyahat görev kayıtları (5 kayıt)
CREATE TABLE IF NOT EXISTS saha_gorevleri (
    id          SERIAL          PRIMARY KEY,
    tarih       DATE            NOT NULL,
    personel    VARCHAR(50),
    gorevli_il  VARCHAR(50),
    aciklama    TEXT,
    durum       VARCHAR(20),
    created_at  TIMESTAMPTZ     DEFAULT NOW()
);

COMMENT ON TABLE saha_gorevleri IS 'Personel saha/seyahat görev kayıtları';
COMMENT ON COLUMN saha_gorevleri.tarih IS 'Görev tarihi';
COMMENT ON COLUMN saha_gorevleri.personel IS 'Personel adı';
COMMENT ON COLUMN saha_gorevleri.gorevli_il IS 'Görev yapılan il (Artvin, Rize, Ordu vb.)';

CREATE INDEX IF NOT EXISTS idx_saha_gorevleri_personel ON saha_gorevleri(personel);
CREATE INDEX IF NOT EXISTS idx_saha_gorevleri_tarih ON saha_gorevleri(tarih);
