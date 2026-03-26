-- ============================================================
-- SUPABASE KURULUM SQL — Tek dosya, tek çalıştırma
-- Supabase Dashboard → SQL Editor → New query → Paste → Run
-- ============================================================

-- [1/5] TABLO ŞEMASI

-- UTF-8 | Sprint Kanban | Tablo şeması — tüm CREATE TABLE ifadeleri
-- DOKA Sprint Kanban Projesi
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

COMMENT ON TABLE birimler IS 'DOKA birimlerinin lookup tablosu';
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

-- kategoriler: SOP-kategori composite PK
CREATE TABLE IF NOT EXISTS kategoriler (
    skod            INTEGER         REFERENCES soplar(skod),
    kkod            INTEGER,
    kategori_adi    VARCHAR(200)    NOT NULL,
    PRIMARY KEY (skod, kkod)
);

COMMENT ON TABLE kategoriler IS 'SOP bazlı faaliyet kategorileri';
COMMENT ON COLUMN kategoriler.skod IS 'SOP kodu (PK, FK → soplar.skod)';
COMMENT ON COLUMN kategoriler.kkod IS 'Kategori kodu (PK)';
COMMENT ON COLUMN kategoriler.kategori_adi IS 'Kategori açıklaması';

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

-- [2/5] VIEW'LAR

-- UTF-8 | Sprint Kanban | Hesaplanan alan view'ları
-- DOKA Sprint Kanban Projesi
-- Oluşturma tarihi: 2026-03-25
-- NOT: Excel formülleri birebir SQL'e çevrilmiştir (requirements.md bölüm 3)

-- ============================================================
-- VIEW 1: v_sprint_ozet
-- GKİ, Hepiniss, T.Skor, OrgPuan hesaplamaları
-- Kaynak: sprint_veri × sprint_is_plani × sprint_retro
-- NOT: Cross-product önlemek için CTE kullanılır
-- ============================================================
CREATE OR REPLACE VIEW v_sprint_ozet AS
WITH
-- Sprint iş planı metrikleri: sprint_is_plani'den ayrı aggregate
sip_agg AS (
    SELECT
        sprint_donem,
        COALESCE(SUM(plan_sure), 0)                                             AS plan_toplam,
        COALESCE(SUM(CASE WHEN is_durum = 'Tamamlandı' AND bitis_donem = sprint_donem
            THEN plan_sure ELSE 0 END), 0)                                      AS t_skor,
        COALESCE(SUM(CASE WHEN is_durum = 'Tamamlandı' AND bitis_donem = sprint_donem
            THEN gercek_sure ELSE 0 END), 0)                                    AS gerceklesme
    FROM sprint_is_plani
    GROUP BY sprint_donem
),
-- Sprint retro metrikleri: sprint_toplanti → sprint_veri.bitis eşleşmesi üzerinden aggregate
retro_agg AS (
    SELECT
        sprint_toplanti,
        AVG(organizasyon_puan)                                                  AS org_puan,
        AVG(SQRT(ajanstaki_rolu::float * ajans_hakkinda::float))                AS hepiniss
    FROM sprint_retro
    WHERE ajanstaki_rolu IS NOT NULL AND ajans_hakkinda IS NOT NULL
    GROUP BY sprint_toplanti
)
SELECT
    sv.sprint_donem,
    sv.baslangic,
    sv.bitis,
    sv.sprint_adi,
    sv.isim_veren,
    sv.sure_gun,
    sv.ekip,
    sv.izin,
    sv.saha,
    -- OrgPuan: SprintRetro'dan OrganizasyonPuan ortalaması
    -- Excel: =IFERROR(AVERAGEIFS(tblSprintRetro[OrganizasyonPuan], tblSprintRetro[SprintToplantı], [Bitiş]), "")
    ra.org_puan,
    -- Hepiniss: SprintRetro'dan geometrik ortalama ortalaması (G.ort = SQRT(rol × hakkında))
    -- Excel: =IFERROR(AVERAGEIFS(tblSprintRetro[G.ort], tblSprintRetro[SprintToplantı], [Bitiş]), "")
    ra.hepiniss,
    -- T.Skor: Tamamlanan görevlerin plan süre toplamı (bitis_donem bazlı)
    -- Excel: =SUMIFS(tblSprintİşPlanı[PlanSüre], tblSprintİşPlanı[İşDurum], "Tamamlandı", tblSprintİşPlanı[BitişDönem], [SprintDönem])
    COALESCE(sa.t_skor, 0)                                                      AS t_skor,
    -- GKİ: T.Skor / (Süre × Ekip - İzin) × 100
    -- Excel: =IFERROR([T.Skor]/([Süre (gün)]*[Ekip]-[İzin])*100, "")
    CASE
        WHEN (sv.sure_gun * sv.ekip - COALESCE(sv.izin, 0)) > 0
        THEN COALESCE(sa.t_skor, 0)::float
             / (sv.sure_gun * sv.ekip - COALESCE(sv.izin, 0)) * 100
        ELSE 0
    END                                                                         AS gki,
    -- Plan: Sprint'teki tüm görevlerin plan süre toplamı
    -- Excel: =SUMIFS(tblSprintİşPlanı[PlanSüre], tblSprintİşPlanı[SprintDönem], [SprintDönem])
    COALESCE(sa.plan_toplam, 0)                                                 AS plan_toplam,
    -- Gerçekleşme: Tamamlanan görevlerin gerçek süre toplamı
    -- Excel: =SUMIFS(tblSprintİşPlanı[GerçekSüre], tblSprintİşPlanı[İşDurum], "Tamamlandı", tblSprintİşPlanı[BitişDönem], [SprintDönem])
    COALESCE(sa.gerceklesme, 0)                                                 AS gerceklesme
FROM sprint_veri sv
LEFT JOIN sip_agg sa ON sa.sprint_donem = sv.sprint_donem
LEFT JOIN retro_agg ra ON ra.sprint_toplanti = sv.bitis;

COMMENT ON VIEW v_sprint_ozet IS 'Sprint bazlı GKİ, Hepiniss, T.Skor, OrgPuan metrikleri — Excel formül birebir çevirisi';

-- ============================================================
-- VIEW 2: v_alt_faaliyet_ozet
-- İş yükü ve gerçekleşme hesaplamaları
-- Kaynak: alt_faaliyetler × sprint_is_plani × harcamalar
-- ============================================================
CREATE OR REPLACE VIEW v_alt_faaliyet_ozet AS
SELECT
    af.sno,
    af.fkod,
    af.sop,
    af.kategori,
    af.faaliyet,
    af.alt_faaliyet,
    af.p_sure,
    af.tekrar_sayisi,
    -- İş yükü: p_sure × tekrar_sayisi
    -- Excel: =H*I
    COALESCE(af.p_sure * af.tekrar_sayisi, 0)                                   AS is_yuku,
    -- Gerçekleşme sayısı: "Tamamlandı" durumundaki kayıt sayısı
    -- Excel: =COUNTIFS(tblSprintİşPlanı[S.No], [S.No], tblSprintİşPlanı[İşDurum], "Tamamlandı")
    COUNT(CASE WHEN sip.is_durum = 'Tamamlandı' THEN 1 END)                    AS gerceklesme_sayi,
    -- Gerçek iş yükü: tamamlanan görevlerin gerçek süre toplamı
    -- Excel: =SUMIFS(tblSprintİşPlanı[GerçekSüre], tblSprintİşPlanı[S.No], [S.No])
    COALESCE(SUM(sip.gercek_sure), 0)                                           AS gercek_is_yuku,
    -- İş durum oranı: GerçekleşmeSayı / TekrarSayısı (0-1 arası oran)
    -- Excel: =IFERROR([GerçekleşmeSayı]/[Tekrar Sayısı], "-")
    CASE
        WHEN af.tekrar_sayisi > 0
        THEN COUNT(CASE WHEN sip.is_durum = 'Tamamlandı' THEN 1 END)::float
             / af.tekrar_sayisi
        ELSE NULL
    END                                                                         AS is_durum_oran,
    -- Harcanan bütçe: Harcamalar tablosundan SUMIFS
    -- Excel: =SUMIFS(tblHarcamalar[ÖdenecekKDVli], tblHarcamalar[S.No], [S.No])
    COALESCE(SUM(h.odenecek_kdvli), 0)                                          AS harcanan_butce
FROM alt_faaliyetler af
LEFT JOIN sprint_is_plani sip ON sip.sno = af.sno
LEFT JOIN harcamalar h ON h.sno = af.sno
GROUP BY af.sno, af.fkod, af.sop, af.kategori, af.faaliyet, af.alt_faaliyet,
         af.p_sure, af.tekrar_sayisi;

COMMENT ON VIEW v_alt_faaliyet_ozet IS 'Alt faaliyet bazlı iş yükü, gerçekleşme ve harcama özeti';

-- ============================================================
-- VIEW 3: v_faaliyet_ozet
-- Bütçe ve durum hesaplamaları
-- Kaynak: faaliyetler × v_alt_faaliyet_ozet
-- ============================================================
CREATE OR REPLACE VIEW v_faaliyet_ozet AS
SELECT
    f.fkod,
    f.sop,
    f.kategori,
    f.faaliyet,
    f.butce_2026,
    f.aylik_plan,
    -- İş durum ortalaması: Alt faaliyetlerin is_durum_oran ortalaması
    -- Excel: =IFERROR(AVERAGEIFS(tblAltFaaliyetler[İşDurum], tblAltFaaliyetler[Fkod], [Fkod]), "-")
    AVG(vafo.is_durum_oran)                                                     AS is_durum_ort,
    -- Harcanan bütçe toplamı
    -- Excel: =SUMIFS(tblAltFaaliyetler[HarcananBütçe], tblAltFaaliyetler[Fkod], [Fkod])
    COALESCE(SUM(vafo.harcanan_butce), 0)                                       AS harcanan_butce_toplam
FROM faaliyetler f
LEFT JOIN v_alt_faaliyet_ozet vafo ON vafo.fkod = f.fkod
GROUP BY f.fkod, f.sop, f.kategori, f.faaliyet, f.butce_2026, f.aylik_plan;

COMMENT ON VIEW v_faaliyet_ozet IS 'Faaliyet bazlı bütçe, durum ve ilerleme özeti';

-- ============================================================
-- VIEW 4: v_perf_gosterge_ozet
-- Kümülatif gerçekleşme hesaplamaları
-- Kaynak: perf_gostergeler × sprint_perf_gos
-- ============================================================
CREATE OR REPLACE VIEW v_perf_gosterge_ozet AS
SELECT
    pg.cg_kod,
    pg.sop,
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
    -- 2026 gerçekleşmesi: SprintPerfGös'ten SUMIFS (yil=2026)
    -- Excel: =SUMIFS(tblSprintPerfGös[Gerçekleşme], tblSprintPerfGös[ÇGKod], [ÇGKod], tblSprintPerfGös[Yıl], 2026)
    COALESCE(spg_2026.toplam, 0)                                                AS gerceklesen_2026,
    -- Kümülatif gerçekleşme: 2024 + 2025 + 2026 toplamı
    -- Excel: =[2024]+[2025]+[2026]
    (COALESCE(pg.gerceklesen_2024, 0)
     + COALESCE(pg.gerceklesen_2025, 0)
     + COALESCE(spg_2026.toplam, 0))                                            AS kumulatif_gerceklesme
FROM perf_gostergeler pg
LEFT JOIN (
    SELECT cg_kod, SUM(gerceklesme) AS toplam
    FROM sprint_perf_gos
    WHERE yil = 2026
    GROUP BY cg_kod
) spg_2026 ON spg_2026.cg_kod = pg.cg_kod;

COMMENT ON VIEW v_perf_gosterge_ozet IS 'Performans göstergesi bazlı kümülatif gerçekleşme ve hedef karşılaştırması';

-- [3/5] ROW LEVEL SECURITY

-- UTF-8 | Sprint Kanban | Row Level Security politikaları
-- DOKA Sprint Kanban Projesi
-- Oluşturma tarihi: 2026-03-25

-- ============================================================
-- RLS ETKİNLEŞTİRME
-- ============================================================

ALTER TABLE kullanici_rolleri   ENABLE ROW LEVEL SECURITY;
ALTER TABLE birimler           ENABLE ROW LEVEL SECURITY;
ALTER TABLE soplar             ENABLE ROW LEVEL SECURITY;
ALTER TABLE kategoriler        ENABLE ROW LEVEL SECURITY;
ALTER TABLE personel           ENABLE ROW LEVEL SECURITY;
ALTER TABLE faaliyetler        ENABLE ROW LEVEL SECURITY;
ALTER TABLE alt_faaliyetler    ENABLE ROW LEVEL SECURITY;
ALTER TABLE anahtar_sonuclar   ENABLE ROW LEVEL SECURITY;
ALTER TABLE perf_gostergeler   ENABLE ROW LEVEL SECURITY;
ALTER TABLE sprint_veri        ENABLE ROW LEVEL SECURITY;
ALTER TABLE sprint_is_plani    ENABLE ROW LEVEL SECURITY;
ALTER TABLE sprint_retro       ENABLE ROW LEVEL SECURITY;
ALTER TABLE harcamalar         ENABLE ROW LEVEL SECURITY;
ALTER TABLE sprint_perf_gos    ENABLE ROW LEVEL SECURITY;
ALTER TABLE izinler            ENABLE ROW LEVEL SECURITY;
ALTER TABLE saha_gorevleri     ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- BÖLÜM 1: LOOKUP / OKUMA TABLOLARI
-- Tüm authenticated kullanıcılar SELECT yapabilir
-- INSERT/UPDATE/DELETE sadece Scrum Master (Fatih)
-- ============================================================

-- kullanici_rolleri
CREATE POLICY "kullanici_rolleri_select"
    ON kullanici_rolleri FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "kullanici_rolleri_insert_yonetici"
    ON kullanici_rolleri FOR INSERT
    TO authenticated
    WITH CHECK (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

CREATE POLICY "kullanici_rolleri_update_yonetici"
    ON kullanici_rolleri FOR UPDATE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

CREATE POLICY "kullanici_rolleri_delete_yonetici"
    ON kullanici_rolleri FOR DELETE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

-- birimler
CREATE POLICY "birimler_select"
    ON birimler FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "birimler_insert_fatih"
    ON birimler FOR INSERT
    TO authenticated
    WITH CHECK (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

CREATE POLICY "birimler_update_fatih"
    ON birimler FOR UPDATE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

CREATE POLICY "birimler_delete_fatih"
    ON birimler FOR DELETE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

-- soplar
CREATE POLICY "soplar_select"
    ON soplar FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "soplar_insert_fatih"
    ON soplar FOR INSERT
    TO authenticated
    WITH CHECK (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

CREATE POLICY "soplar_update_fatih"
    ON soplar FOR UPDATE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

CREATE POLICY "soplar_delete_fatih"
    ON soplar FOR DELETE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

-- kategoriler
CREATE POLICY "kategoriler_select"
    ON kategoriler FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "kategoriler_insert_fatih"
    ON kategoriler FOR INSERT
    TO authenticated
    WITH CHECK (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

CREATE POLICY "kategoriler_update_fatih"
    ON kategoriler FOR UPDATE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

CREATE POLICY "kategoriler_delete_fatih"
    ON kategoriler FOR DELETE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

-- personel
CREATE POLICY "personel_select"
    ON personel FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "personel_insert_fatih"
    ON personel FOR INSERT
    TO authenticated
    WITH CHECK (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

CREATE POLICY "personel_update_fatih"
    ON personel FOR UPDATE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

-- faaliyetler
CREATE POLICY "faaliyetler_select"
    ON faaliyetler FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "faaliyetler_insert_fatih"
    ON faaliyetler FOR INSERT
    TO authenticated
    WITH CHECK (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

CREATE POLICY "faaliyetler_update_fatih"
    ON faaliyetler FOR UPDATE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

CREATE POLICY "faaliyetler_delete_fatih"
    ON faaliyetler FOR DELETE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

-- alt_faaliyetler
CREATE POLICY "alt_faaliyetler_select"
    ON alt_faaliyetler FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "alt_faaliyetler_insert_fatih"
    ON alt_faaliyetler FOR INSERT
    TO authenticated
    WITH CHECK (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

CREATE POLICY "alt_faaliyetler_update_fatih"
    ON alt_faaliyetler FOR UPDATE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

-- anahtar_sonuclar
CREATE POLICY "anahtar_sonuclar_select"
    ON anahtar_sonuclar FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "anahtar_sonuclar_insert_fatih"
    ON anahtar_sonuclar FOR INSERT
    TO authenticated
    WITH CHECK (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

-- perf_gostergeler
CREATE POLICY "perf_gostergeler_select"
    ON perf_gostergeler FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "perf_gostergeler_insert_fatih"
    ON perf_gostergeler FOR INSERT
    TO authenticated
    WITH CHECK (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

CREATE POLICY "perf_gostergeler_update_fatih"
    ON perf_gostergeler FOR UPDATE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

-- sprint_veri
CREATE POLICY "sprint_veri_select"
    ON sprint_veri FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "sprint_veri_insert_fatih"
    ON sprint_veri FOR INSERT
    TO authenticated
    WITH CHECK (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

CREATE POLICY "sprint_veri_update_fatih"
    ON sprint_veri FOR UPDATE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

-- ============================================================
-- BÖLÜM 2: sprint_is_plani (ANA KANBAN TABLOSU)
-- SELECT: tüm ekip tüm görevleri görebilir
-- INSERT: tüm ekip görev ekleyebilir
-- UPDATE: sadece kendi görevi veya Fatih (Scrum Master)
-- DELETE: sadece Fatih (Scrum Master)
-- ============================================================

CREATE POLICY "sprint_is_plani_select"
    ON sprint_is_plani FOR SELECT
    TO authenticated
    USING (true);

COMMENT ON POLICY "sprint_is_plani_select" ON sprint_is_plani
    IS 'Tüm authenticated ekip tüm görevleri görebilir';

CREATE POLICY "sprint_is_plani_insert"
    ON sprint_is_plani FOR INSERT
    TO authenticated
    WITH CHECK (auth.role() = 'authenticated');

COMMENT ON POLICY "sprint_is_plani_insert" ON sprint_is_plani
    IS 'Tüm authenticated ekip görev ekleyebilir';

-- Kullanıcılar kendi görevlerini veya Fatih tüm görevleri güncelleyebilir
CREATE POLICY "sprint_is_plani_update"
    ON sprint_is_plani FOR UPDATE
    TO authenticated
    USING (
        ekip_uyesi = (SELECT ad FROM personel WHERE auth_id = auth.uid())
        OR (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

COMMENT ON POLICY "sprint_is_plani_update" ON sprint_is_plani
    IS 'Kullanıcı kendi görevini, Fatih ise tüm görevleri güncelleyebilir';

CREATE POLICY "sprint_is_plani_delete"
    ON sprint_is_plani FOR DELETE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

COMMENT ON POLICY "sprint_is_plani_delete" ON sprint_is_plani
    IS 'Sadece Scrum Master (Fatih) görev silebilir';

-- ============================================================
-- BÖLÜM 3: sprint_retro
-- INSERT: kişi sadece kendi adıyla kayıt ekleyebilir
-- SELECT: tüm ekip görebilir
-- ============================================================

CREATE POLICY "sprint_retro_select"
    ON sprint_retro FOR SELECT
    TO authenticated
    USING (true);

COMMENT ON POLICY "sprint_retro_select" ON sprint_retro
    IS 'Tüm ekip tüm retro sonuçlarını görebilir';

CREATE POLICY "sprint_retro_insert"
    ON sprint_retro FOR INSERT
    TO authenticated
    WITH CHECK (
        ad = (SELECT ad FROM personel WHERE auth_id = auth.uid())
    );

COMMENT ON POLICY "sprint_retro_insert" ON sprint_retro
    IS 'Herkes sadece kendi adıyla retro puanı girebilir';

-- ============================================================
-- BÖLÜM 4: harcamalar
-- INSERT: tüm ekip girebilir
-- SELECT: tüm ekip görebilir
-- UPDATE: sadece Fatih (Scrum Master)
-- ============================================================

CREATE POLICY "harcamalar_select"
    ON harcamalar FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "harcamalar_insert"
    ON harcamalar FOR INSERT
    TO authenticated
    WITH CHECK (auth.role() = 'authenticated');

COMMENT ON POLICY "harcamalar_insert" ON harcamalar
    IS 'Tüm authenticated ekip harcama girebilir';

CREATE POLICY "harcamalar_update"
    ON harcamalar FOR UPDATE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

COMMENT ON POLICY "harcamalar_update" ON harcamalar
    IS 'Sadece Scrum Master (Fatih) harcama güncelleyebilir';

-- ============================================================
-- BÖLÜM 5: sprint_perf_gos, izinler, saha_gorevleri
-- INSERT/SELECT: tüm authenticated kullanıcılar
-- ============================================================

-- sprint_perf_gos
CREATE POLICY "sprint_perf_gos_select"
    ON sprint_perf_gos FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "sprint_perf_gos_insert"
    ON sprint_perf_gos FOR INSERT
    TO authenticated
    WITH CHECK (auth.role() = 'authenticated');

-- izinler
CREATE POLICY "izinler_select"
    ON izinler FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "izinler_insert"
    ON izinler FOR INSERT
    TO authenticated
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "izinler_update_fatih"
    ON izinler FOR UPDATE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

-- saha_gorevleri
CREATE POLICY "saha_gorevleri_select"
    ON saha_gorevleri FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "saha_gorevleri_insert"
    ON saha_gorevleri FOR INSERT
    TO authenticated
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "saha_gorevleri_update_fatih"
    ON saha_gorevleri FOR UPDATE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

-- [4/5] AUDIT TRIGGER'LAR

-- UTF-8 | Sprint Kanban | Audit ve otomatik alan trigger'ları
-- DOKA Sprint Kanban Projesi
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

-- [5/5] SEED VERİSİ

-- UTF-8 | Sprint Kanban | Mevcut Excel verisi (INSERT ifadeleri)
-- DOKA Sprint Kanban Projesi
-- Oluşturma tarihi: 2026-03-25
-- NOT: auth_id tüm personel kayıtlarında NULL — Supabase Auth kullanıcıları
--      oluşturulduktan sonra UPDATE ile eşleştirilecek.

-- ============================================================
-- 1. BİRİMLER (4 kayıt)
-- ============================================================

INSERT INTO birimler (bkod, birim_kisa, birim_adi, durum) VALUES
(1, 'SKB',   'Sürdürülebilir Kalkınma Birimi',              'Aktif'),
(2, 'MEKB',  'Mavi Ekonomi Koordinasyon Birimi',            'Aktif'),
(3, 'KYİKB', 'Kurumsal Yönetim ve İnsan Kaynakları Birimi', 'Aktif'),
(4, 'PİDB',  'Program İzleme ve Değerlendirme Birimi',      'Aktif');

-- ============================================================
-- 2. SOPLAR (8 kayıt)
-- ============================================================

INSERT INTO soplar (skod, kisa, sop_adi, baslangic, bitis, bkod, durum) VALUES
(1, 'STU',  'Sürdürülebilir Turizm Programı',             2024, 2026, 1, 'Aktif'),
(2, 'KDU',  'Katma Değerli Üretim ve Ticarileşme',        2024, 2026, 1, 'Aktif'),
(3, 'MEK',  'Mavi Ekonomi Programı',                      2024, 2026, 2, 'Aktif'),
(4, 'YKF',  'Yerel Kalkınma Fırsatları Programı',         2024, 2026, 3, 'Aktif'),
(5, 'SOPD', 'SOP Dışı Diğer İşler',                       NULL, NULL, 1, 'Aktif'),
(6, 'BAK',  'Bakanlık Talepleri',                          NULL, NULL, 1, 'Aktif'),
(7, 'AB',   'Avrupa Birliği Projeleri',                   2024, 2026, 1, 'Aktif'),
(8, 'SOG',  'SoGreen Programı',                            2024, 2026, 1, 'Aktif');

-- ============================================================
-- 3. KATEGORİLER (~21 kayıt — 5 standart kategori × SOP bazlı)
-- ============================================================

-- STU (skod=1)
INSERT INTO kategoriler (skod, kkod, kategori_adi) VALUES
(1, 1, 'Araştırma, Analiz ve Raporlama'),
(1, 2, 'İşbirliği ve Koordinasyon Faaliyetleri'),
(1, 3, 'Kapasite Geliştirme Faaliyetleri'),
(1, 4, 'Tanıtım ve Yatırım Destek Faaliyetleri'),
(1, 5, 'Destek Programları');

-- KDU (skod=2)
INSERT INTO kategoriler (skod, kkod, kategori_adi) VALUES
(2, 1, 'Araştırma, Analiz ve Raporlama'),
(2, 2, 'İşbirliği ve Koordinasyon Faaliyetleri'),
(2, 3, 'Kapasite Geliştirme Faaliyetleri'),
(2, 4, 'Tanıtım ve Yatırım Destek Faaliyetleri'),
(2, 5, 'Destek Programları');

-- MEK (skod=3)
INSERT INTO kategoriler (skod, kkod, kategori_adi) VALUES
(3, 1, 'Araştırma, Analiz ve Raporlama'),
(3, 2, 'İşbirliği ve Koordinasyon Faaliyetleri'),
(3, 3, 'Kapasite Geliştirme Faaliyetleri');

-- SOG (skod=8)
INSERT INTO kategoriler (skod, kkod, kategori_adi) VALUES
(8, 1, 'Araştırma, Analiz ve Raporlama'),
(8, 2, 'İşbirliği ve Koordinasyon Faaliyetleri'),
(8, 3, 'Proje Uygulama Faaliyetleri');

-- ============================================================
-- 3.5 KULLANICI ROLLERİ (2 kayıt)
-- ============================================================

INSERT INTO kullanici_rolleri (rol_kodu, aciklama) VALUES
('yönetici', 'Sistem yöneticisi, tüm yetkilere sahip (ör: Scrum Master)'),
('standart', 'Standart ekip üyesi, kendi görevlerini yönetebilir');

-- ============================================================
-- 4. PERSONEL (7 kayıt) — auth_id NULL
-- ============================================================

INSERT INTO personel (pkod, ad, soyad, bkod, durum, auth_id, rol_kodu) VALUES
(1, 'Zübeyde',  'Altun',        1, 'Aktif', NULL, 'standart'),
(2, 'Elifnaz',  'Akdeniz',      1, 'Aktif', NULL, 'standart'),
(3, 'Mehmet',   'Sezgin',       1, 'Aktif', NULL, 'standart'),
(4, 'Oğuzhan',  'Şatır',        1, 'Aktif', NULL, 'standart'),
(5, 'Esen',     'Baylan',       1, 'Aktif', NULL, 'standart'),
(6, 'Nuray',    'Efendioğlu',   1, 'Aktif', NULL, 'standart'),
(7, 'Fatih',    'Özdemir',      1, 'Aktif', NULL, 'yönetici');

-- ============================================================
-- 5. FAALİYETLER (30 kayıt)
-- ============================================================

INSERT INTO faaliyetler (fkod, sop, kategori, faaliyet, butce_2026, aylik_plan) VALUES
-- KDU faaliyetleri
('KDU101', 'KDU', 'Araştırma, Analiz ve Raporlama',
 'Bölgesel ekonomik analiz ve raporlama çalışmaları',
 1000000.00,
 '{"oca":1,"sub":1,"mar":1,"nis":1,"may":0,"haz":0,"tem":0,"agu":0,"eyl":0,"eki":0,"kas":0,"ara":0}'),

('KDU102', 'KDU', 'Araştırma, Analiz ve Raporlama',
 'Üretim ve ticarileşme veri tabanı oluşturma',
 1000000.00,
 '{"oca":0,"sub":1,"mar":1,"nis":1,"may":1,"haz":0,"tem":0,"agu":0,"eyl":0,"eki":0,"kas":0,"ara":0}'),

('KDU501', 'KDU', 'Destek Programları',
 'KDU destek programı başvuru ve değerlendirme süreci',
 5000000.00,
 '{"oca":1,"sub":1,"mar":1,"nis":1,"may":1,"haz":1,"tem":1,"agu":1,"eyl":1,"eki":1,"kas":1,"ara":1}'),

('KDU201', 'KDU', 'İşbirliği ve Koordinasyon Faaliyetleri',
 'Sektörel işbirliği toplantıları ve koordinasyon',
 0.00,
 '{"oca":1,"sub":1,"mar":1,"nis":1,"may":1,"haz":1,"tem":1,"agu":1,"eyl":1,"eki":1,"kas":1,"ara":1}'),

('KDU202', 'KDU', 'İşbirliği ve Koordinasyon Faaliyetleri',
 'Uluslararası işbirliği ve platform katılımları',
 500000.00,
 '{"oca":0,"sub":1,"mar":0,"nis":1,"may":0,"haz":1,"tem":0,"agu":1,"eyl":0,"eki":1,"kas":0,"ara":0}'),

('KDU301', 'KDU', 'Kapasite Geliştirme Faaliyetleri',
 'Girişimcilik eğitim programları',
 2000000.00,
 '{"oca":0,"sub":1,"mar":1,"nis":1,"may":1,"haz":0,"tem":0,"agu":0,"eyl":1,"eki":1,"kas":1,"ara":0}'),

('KDU302', 'KDU', 'Kapasite Geliştirme Faaliyetleri',
 'Ürün geliştirme ve tasarım atölyeleri',
 1000000.00,
 '{"oca":0,"sub":0,"mar":1,"nis":1,"may":1,"haz":1,"tem":0,"agu":0,"eyl":0,"eki":0,"kas":0,"ara":0}'),

('KDU303', 'KDU', 'Kapasite Geliştirme Faaliyetleri',
 'İhracat ve pazarlama kapasitesi geliştirme',
 3000000.00,
 '{"oca":0,"sub":0,"mar":0,"nis":1,"may":1,"haz":1,"tem":1,"agu":0,"eyl":0,"eki":0,"kas":0,"ara":0}'),

('KDU304', 'KDU', 'Kapasite Geliştirme Faaliyetleri',
 'Dijitalleşme ve e-ticaret kapasitesi',
 2000000.00,
 '{"oca":1,"sub":1,"mar":0,"nis":0,"may":1,"haz":1,"tem":0,"agu":0,"eyl":0,"eki":0,"kas":0,"ara":0}'),

('KDU401', 'KDU', 'Tanıtım ve Yatırım Destek Faaliyetleri',
 'Bölgesel ürün tanıtım fuarları ve etkinlikler',
 2000000.00,
 '{"oca":0,"sub":0,"mar":1,"nis":1,"may":1,"haz":0,"tem":1,"agu":0,"eyl":1,"eki":0,"kas":0,"ara":0}'),

('KDU402', 'KDU', 'Tanıtım ve Yatırım Destek Faaliyetleri',
 'Yatırım ortamı iyileştirme faaliyetleri',
 500000.00,
 '{"oca":1,"sub":1,"mar":0,"nis":0,"may":0,"haz":0,"tem":0,"agu":0,"eyl":0,"eki":0,"kas":0,"ara":0}'),

('KDU502', 'KDU', 'Destek Programları',
 'KDU mali destek programı uygulama ve izleme',
 20000000.00,
 '{"oca":1,"sub":1,"mar":1,"nis":1,"may":1,"haz":1,"tem":1,"agu":1,"eyl":1,"eki":1,"kas":1,"ara":1}'),

-- STU faaliyetleri
('STU101', 'STU', 'Araştırma, Analiz ve Raporlama',
 'Bölge turizm potansiyeli araştırma ve envanter çalışmaları',
 14000000.00,
 '{"oca":1,"sub":1,"mar":1,"nis":1,"may":1,"haz":0,"tem":0,"agu":0,"eyl":0,"eki":0,"kas":0,"ara":0}'),

('STU102', 'STU', 'Araştırma, Analiz ve Raporlama',
 'Turizm veri tabanı ve istatistik yönetimi',
 2000000.00,
 '{"oca":1,"sub":0,"mar":1,"nis":0,"may":1,"haz":0,"tem":1,"agu":0,"eyl":1,"eki":0,"kas":1,"ara":0}'),

('STU201', 'STU', 'İşbirliği ve Koordinasyon Faaliyetleri',
 'Turizm paydaş toplantıları ve platform etkinlikleri',
 11000000.00,
 '{"oca":1,"sub":1,"mar":1,"nis":1,"may":1,"haz":1,"tem":1,"agu":1,"eyl":1,"eki":1,"kas":1,"ara":1}'),

('STU202', 'STU', 'İşbirliği ve Koordinasyon Faaliyetleri',
 'Kültür-turizm entegrasyon projeleri koordinasyon',
 10000000.00,
 '{"oca":0,"sub":1,"mar":1,"nis":1,"may":1,"haz":1,"tem":1,"agu":0,"eyl":0,"eki":0,"kas":0,"ara":0}'),

('STU301', 'STU', 'Kapasite Geliştirme Faaliyetleri',
 'Turizm işletmeciliği eğitim programları',
 4000000.00,
 '{"oca":0,"sub":1,"mar":1,"nis":0,"may":1,"haz":1,"tem":0,"agu":0,"eyl":1,"eki":0,"kas":0,"ara":0}'),

('STU302', 'STU', 'Kapasite Geliştirme Faaliyetleri',
 'Gastronomi turizmi ürün geliştirme',
 1000000.00,
 '{"oca":0,"sub":0,"mar":1,"nis":1,"may":0,"haz":0,"tem":1,"agu":1,"eyl":0,"eki":0,"kas":0,"ara":0}'),

('STU303', 'STU', 'Kapasite Geliştirme Faaliyetleri',
 'Ekoturizm rotaları geliştirme çalışmaları',
 1000000.00,
 '{"oca":0,"sub":0,"mar":1,"nis":1,"may":1,"haz":0,"tem":0,"agu":0,"eyl":0,"eki":0,"kas":0,"ara":0}'),

('STU401', 'STU', 'Tanıtım ve Yatırım Destek Faaliyetleri',
 'Bölgesel turizm tanıtım kampanyaları',
 3000000.00,
 '{"oca":1,"sub":1,"mar":1,"nis":1,"may":1,"haz":1,"tem":1,"agu":1,"eyl":1,"eki":0,"kas":0,"ara":0}'),

('STU402', 'STU', 'Tanıtım ve Yatırım Destek Faaliyetleri',
 'Uluslararası turizm fuarları katılımı',
 7000000.00,
 '{"oca":1,"sub":1,"mar":0,"nis":0,"may":1,"haz":0,"tem":0,"agu":0,"eyl":1,"eki":1,"kas":0,"ara":0}'),

('STU403', 'STU', 'Tanıtım ve Yatırım Destek Faaliyetleri',
 'Dijital turizm pazarlama ve içerik üretimi',
 3000000.00,
 '{"oca":1,"sub":1,"mar":1,"nis":1,"may":1,"haz":1,"tem":1,"agu":1,"eyl":1,"eki":1,"kas":1,"ara":1}'),

('STU404', 'STU', 'Tanıtım ve Yatırım Destek Faaliyetleri',
 'Yabancı tur operatörü inceleme gezileri',
 2000000.00,
 '{"oca":0,"sub":0,"mar":1,"nis":1,"may":1,"haz":0,"tem":0,"agu":0,"eyl":1,"eki":0,"kas":0,"ara":0}'),

('STU501', 'STU', 'Destek Programları',
 'Turizm altyapı ve destinasyon geliştirme desteği',
 2000000.00,
 '{"oca":1,"sub":0,"mar":0,"nis":1,"may":0,"haz":1,"tem":0,"agu":0,"eyl":0,"eki":1,"kas":0,"ara":0}'),

('STU502', 'STU', 'Destek Programları',
 'STU mali destek programı uygulama ve izleme',
 10000000.00,
 '{"oca":1,"sub":1,"mar":1,"nis":1,"may":1,"haz":1,"tem":1,"agu":1,"eyl":1,"eki":1,"kas":1,"ara":1}'),

('STU503', 'STU', 'Destek Programları',
 'STU küçük ölçekli destek program çağrısı',
 0.00,
 '{"oca":0,"sub":0,"mar":0,"nis":0,"may":0,"haz":1,"tem":1,"agu":1,"eyl":1,"eki":0,"kas":0,"ara":0}'),

-- SOG, AB, BAK, SOPD
('SOG301', 'SOG', 'Proje Uygulama Faaliyetleri',
 'SoGreen interreg projesi uygulama ve koordinasyon',
 40000000.00,
 '{"oca":1,"sub":1,"mar":1,"nis":1,"may":1,"haz":1,"tem":1,"agu":1,"eyl":1,"eki":1,"kas":1,"ara":1}'),

('AB0101', 'AB',   'Araştırma, Analiz ve Raporlama',
 'AB projesi teknik çalışmaları ve raporlama',
 0.00,
 '{"oca":1,"sub":1,"mar":1,"nis":1,"may":1,"haz":1,"tem":0,"agu":0,"eyl":0,"eki":0,"kas":0,"ara":0}'),

('BAK201', 'BAK',  'İşbirliği ve Koordinasyon Faaliyetleri',
 'Bakanlık talep ve yazışma koordinasyonu',
 0.00,
 '{"oca":1,"sub":1,"mar":1,"nis":1,"may":1,"haz":1,"tem":1,"agu":1,"eyl":1,"eki":1,"kas":1,"ara":1}'),

('SOP201', 'SOPD', 'İşbirliği ve Koordinasyon Faaliyetleri',
 'SOP dışı kurumsal görevler ve koordinasyon',
 0.00,
 '{"oca":1,"sub":1,"mar":1,"nis":1,"may":1,"haz":1,"tem":1,"agu":1,"eyl":1,"eki":1,"kas":1,"ara":1}');

-- ============================================================
-- 6. ALT FAALİYETLER (53 kayıt)
-- ============================================================

INSERT INTO alt_faaliyetler (sno, fkod, sop, kategori, faaliyet, alt_faaliyet, p_sure, tekrar_sayisi) VALUES
-- KDU101
(1,  'KDU101', 'KDU', 'Araştırma, Analiz ve Raporlama', 'Bölgesel ekonomik analiz ve raporlama çalışmaları',
 'Bölge ekonomik göstergeler raporu hazırlama', 2.0, 4),
(2,  'KDU101', 'KDU', 'Araştırma, Analiz ve Raporlama', 'Bölgesel ekonomik analiz ve raporlama çalışmaları',
 'Sektörel analiz ve SWOT çalışması', 3.0, 2),
-- KDU103
(3,  'KDU102', 'KDU', 'Araştırma, Analiz ve Raporlama', 'Üretim ve ticarileşme veri tabanı oluşturma',
 'Veri tabanı tasarım ve geliştirme', 5.0, 1),
(4,  'KDU102', 'KDU', 'Araştırma, Analiz ve Raporlama', 'Üretim ve ticarileşme veri tabanı oluşturma',
 'Veri toplama ve doğrulama', 3.0, 2),
-- KDU108
(5,  'KDU501', 'KDU', 'Destek Programları', 'KDU destek programı başvuru ve değerlendirme süreci',
 'Başvuru kılavuzu hazırlama ve ilan', 2.0, 1),
(6,  'KDU501', 'KDU', 'Destek Programları', 'KDU destek programı başvuru ve değerlendirme süreci',
 'Başvuru değerlendirme ve seçim komisyonu', 3.0, 1),
-- KDU204
(7,  'KDU201', 'KDU', 'İşbirliği ve Koordinasyon Faaliyetleri', 'Sektörel işbirliği toplantıları ve koordinasyon',
 'Çalışma grubu toplantısı organizasyonu ve yönetimi', 1.0, 8),
(8,  'KDU201', 'KDU', 'İşbirliği ve Koordinasyon Faaliyetleri', 'Sektörel işbirliği toplantıları ve koordinasyon',
 'Sektör temsilcileri ile düzenli koordinasyon', 1.0, 4),
-- KDU301
(9,  'KDU301', 'KDU', 'Kapasite Geliştirme Faaliyetleri', 'Girişimcilik eğitim programları',
 'Girişimcilik temel eğitim modülü', 3.0, 3),
(10, 'KDU301', 'KDU', 'Kapasite Geliştirme Faaliyetleri', 'Girişimcilik eğitim programları',
 'Finansman ve hibe kaynakları eğitimi', 2.0, 2),
-- KDU304
(11, 'KDU303', 'KDU', 'Kapasite Geliştirme Faaliyetleri', 'İhracat ve pazarlama kapasitesi geliştirme',
 'İhracat stratejisi geliştirme çalıştayı', 2.0, 2),
(12, 'KDU303', 'KDU', 'Kapasite Geliştirme Faaliyetleri', 'İhracat ve pazarlama kapasitesi geliştirme',
 'Pazarlama ve marka eğitimi', 2.0, 2),
-- KDU501
(13, 'KDU502', 'KDU', 'Destek Programları', 'KDU mali destek programı uygulama ve izleme',
 'Proje izleme ziyaretleri', 2.0, 6),
(14, 'KDU502', 'KDU', 'Destek Programları', 'KDU mali destek programı uygulama ve izleme',
 'Ödeme talepleri inceleme ve onay', 3.0, 4),
-- STU101
(15, 'STU101', 'STU', 'Araştırma, Analiz ve Raporlama', 'Bölge turizm potansiyeli araştırma ve envanter çalışmaları',
 'Turizm envanter ve arz analizi raporu', 4.0, 2),
(16, 'STU101', 'STU', 'Araştırma, Analiz ve Raporlama', 'Bölge turizm potansiyeli araştırma ve envanter çalışmaları',
 'Turizm talep ve beklenti araştırması', 3.0, 1),
-- STU103
(17, 'STU201', 'STU', 'İşbirliği ve Koordinasyon Faaliyetleri', 'Turizm paydaş toplantıları ve platform etkinlikleri',
 'Turizm paydaş platformu toplantısı', 2.0, 4),
(18, 'STU201', 'STU', 'İşbirliği ve Koordinasyon Faaliyetleri', 'Turizm paydaş toplantıları ve platform etkinlikleri',
 'Turizm sektörü değerlendirme toplantısı', 1.0, 4),
-- STU104
(19, 'STU202', 'STU', 'İşbirliği ve Koordinasyon Faaliyetleri', 'Kültür-turizm entegrasyon projeleri koordinasyon',
 'Kültür bakanlığı ile koordinasyon toplantısı', 1.0, 4),
(20, 'STU202', 'STU', 'İşbirliği ve Koordinasyon Faaliyetleri', 'Kültür-turizm entegrasyon projeleri koordinasyon',
 'Entegre turizm ürün geliştirme çalıştayı', 2.0, 2),
-- STU201
(21, 'STU301', 'STU', 'Kapasite Geliştirme Faaliyetleri', 'Turizm işletmeciliği eğitim programları',
 'Konaklama işletmeciliği eğitimi', 3.0, 2),
(22, 'STU301', 'STU', 'Kapasite Geliştirme Faaliyetleri', 'Turizm işletmeciliği eğitim programları',
 'Rehberlik ve misafirperverllik eğitimi', 2.0, 3),
-- STU301
(23, 'STU302', 'STU', 'Kapasite Geliştirme Faaliyetleri', 'Gastronomi turizmi ürün geliştirme',
 'Yöresel lezzetler gastronomi rotası oluşturma', 3.0, 1),
-- STU302
(24, 'STU303', 'STU', 'Kapasite Geliştirme Faaliyetleri', 'Ekoturizm rotaları geliştirme çalışmaları',
 'Ekoturizm güzergah belirleme ve işaretleme', 4.0, 1),
(25, 'STU303', 'STU', 'Kapasite Geliştirme Faaliyetleri', 'Ekoturizm rotaları geliştirme çalışmaları',
 'Doğa turizmi rehber eğitimi', 2.0, 2),
-- STU401
(26, 'STU401', 'STU', 'Tanıtım ve Yatırım Destek Faaliyetleri', 'Bölgesel turizm tanıtım kampanyaları',
 'Dijital tanıtım içerik üretimi ve yayını', 2.0, 6),
(27, 'STU401', 'STU', 'Tanıtım ve Yatırım Destek Faaliyetleri', 'Bölgesel turizm tanıtım kampanyaları',
 'Sosyal medya kampanyası ve etkileyici iş birliği', 1.0, 4),
-- STU402
(28, 'STU402', 'STU', 'Tanıtım ve Yatırım Destek Faaliyetleri', 'Uluslararası turizm fuarları katılımı',
 'Uluslararası turizm fuarı katılım organizasyonu', 3.0, 3),
-- STU403
(29, 'STU403', 'STU', 'Tanıtım ve Yatırım Destek Faaliyetleri', 'Dijital turizm pazarlama ve içerik üretimi',
 'Web sitesi ve mobil içerik güncelleme', 2.0, 4),
(30, 'STU403', 'STU', 'Tanıtım ve Yatırım Destek Faaliyetleri', 'Dijital turizm pazarlama ve içerik üretimi',
 'Destinasyon tanıtım filmi üretimi', 5.0, 1),
-- STU404
(31, 'STU404', 'STU', 'Tanıtım ve Yatırım Destek Faaliyetleri', 'Yabancı tur operatörü inceleme gezileri',
 'Tur operatörü tanıtım gezisi organizasyonu', 3.0, 2),
-- STU501
(32, 'STU502', 'STU', 'Destek Programları', 'STU mali destek programı uygulama ve izleme',
 'Proje izleme ziyaretleri ve ara değerlendirme', 2.0, 6),
(33, 'STU502', 'STU', 'Destek Programları', 'STU mali destek programı uygulama ve izleme',
 'Nihai değerlendirme ve rapor hazırlama', 3.0, 2),
-- SOG001
(34, 'SOG301', 'SOG', 'Proje Uygulama Faaliyetleri', 'SoGreen interreg projesi uygulama ve koordinasyon',
 'Proje yönetim kurulu toplantısı organizasyonu', 2.0, 4),
(35, 'SOG301', 'SOG', 'Proje Uygulama Faaliyetleri', 'SoGreen interreg projesi uygulama ve koordinasyon',
 'İş paketi faaliyetleri uygulama ve raporlama', 3.0, 4),
(36, 'SOG301', 'SOG', 'Proje Uygulama Faaliyetleri', 'SoGreen interreg projesi uygulama ve koordinasyon',
 'Proje pilot uygulama alanı çalışmaları', 4.0, 2),
(37, 'SOG301', 'SOG', 'Proje Uygulama Faaliyetleri', 'SoGreen interreg projesi uygulama ve koordinasyon',
 'Uluslararası ortak ziyaretler ve teknik incelemeler', 3.0, 2),
-- AB0001
(38, 'AB0101', 'AB',   'Araştırma, Analiz ve Raporlama', 'AB projesi teknik çalışmaları ve raporlama',
 'AB proje teknik rapor hazırlama', 2.0, 4),
(39, 'AB0101', 'AB',   'Araştırma, Analiz ve Raporlama', 'AB projesi teknik çalışmaları ve raporlama',
 'AB finansal rapor ve belgeleme', 2.0, 2),
-- BAK001
(40, 'BAK201', 'BAK',  'İşbirliği ve Koordinasyon Faaliyetleri', 'Bakanlık talep ve yazışma koordinasyonu',
 'Bakanlık veri talepleri yanıtlama', 1.0, 12),
(41, 'BAK201', 'BAK',  'İşbirliği ve Koordinasyon Faaliyetleri', 'Bakanlık talep ve yazışma koordinasyonu',
 'Bakanlık toplantılarına katılım ve temsil', 1.0, 8),
-- SOPD01
(42, 'SOP201', 'SOPD', 'İşbirliği ve Koordinasyon Faaliyetleri', 'SOP dışı kurumsal görevler ve koordinasyon',
 'Yönetim kurulu toplantısı hazırlık ve katılım', 1.0, 8),
(43, 'SOP201', 'SOPD', 'İşbirliği ve Koordinasyon Faaliyetleri', 'SOP dışı kurumsal görevler ve koordinasyon',
 'Kurum içi koordinasyon toplantıları', 0.5, 12),
(44, 'SOP201', 'SOPD', 'İşbirliği ve Koordinasyon Faaliyetleri', 'SOP dışı kurumsal görevler ve koordinasyon',
 'Yıllık iç değerlendirme raporu hazırlama', 3.0, 1),
-- KDU205
(45, 'KDU202', 'KDU', 'İşbirliği ve Koordinasyon Faaliyetleri', 'Uluslararası işbirliği ve platform katılımları',
 'Uluslararası kalkınma platformu katılımı', 2.0, 3),
-- KDU302
(46, 'KDU302', 'KDU', 'Kapasite Geliştirme Faaliyetleri', 'Ürün geliştirme ve tasarım atölyeleri',
 'Yerel ürün tasarım ve ambalaj atölyesi', 2.0, 2),
-- KDU407
(47, 'KDU402', 'KDU', 'Tanıtım ve Yatırım Destek Faaliyetleri', 'Yatırım ortamı iyileştirme faaliyetleri',
 'Yatırım ortamı değerlendirme raporu', 3.0, 1),
-- KDU305
(48, 'KDU304', 'KDU', 'Kapasite Geliştirme Faaliyetleri', 'Dijitalleşme ve e-ticaret kapasitesi',
 'E-ticaret platformu kurulum rehberi hazırlama', 2.0, 1),
(49, 'KDU304', 'KDU', 'Kapasite Geliştirme Faaliyetleri', 'Dijitalleşme ve e-ticaret kapasitesi',
 'Dijitalleşme temel eğitim programı', 2.0, 2),
-- STU102
(50, 'STU102', 'STU', 'Araştırma, Analiz ve Raporlama', 'Turizm veri tabanı ve istatistik yönetimi',
 'Turizm istatistikleri derleme ve raporlama', 2.0, 6),
-- STU405
(51, 'STU501', 'STU', 'Destek Programları', 'Turizm altyapı ve destinasyon geliştirme desteği',
 'Destinasyon altyapı proje teknik desteği', 3.0, 2),
-- STU502
(52, 'STU503', 'STU', 'Destek Programları', 'STU küçük ölçekli destek program çağrısı',
 'Küçük ölçekli destek çağrısı ilan ve yönetimi', 4.0, 1),
-- KDU106
(53, 'KDU201', 'KDU', 'İşbirliği ve Koordinasyon Faaliyetleri', 'Sektörel işbirliği toplantıları ve koordinasyon',
 'Sektörel koordinasyon protokolü hazırlama', 2.0, 1);

-- ============================================================
-- 7. PERF_GOSTERGELER (28 kayıt)
-- ============================================================

INSERT INTO perf_gostergeler (cg_kod, sop, bilesen_kodu, bilesen_adi, cikti_gostergesi, birim,
    hedef, tamamlanma_donemi, hedef_2024, hedef_2025, hedef_2026,
    gerceklesen_2024, gerceklesen_2025) VALUES
('ÇGSTU11', 'STU', '1.1.', 'Turizm Araştırma ve Envanter', 'Turizm envanter raporu sayısı', 'Rapor', 6.00, '2026/4', 2.00, 2.00, 2.00, 2.00, 1.00),
('ÇGSTU12', 'STU', '1.2.', 'Turizm Veri Yönetimi', 'Yayımlanan istatistik bülten sayısı', 'Bülten', 6.00, '2026/4', 2.00, 2.00, 2.00, 2.00, 2.00),
('ÇGSTU21', 'STU', '2.1.', 'Paydaş Koordinasyon', 'Düzenlenen turizm toplantısı sayısı', 'Toplantı', 24.00, '2026/4', 8.00, 8.00, 8.00, 8.00, 7.00),
('ÇGSTU22', 'STU', '2.2.', 'Kültür-Turizm Entegrasyon', 'Geliştirilen entegre ürün sayısı', 'Adet', 4.00, '2026/4', NULL, 2.00, 2.00, NULL, 1.00),
('ÇGSTU31', 'STU', '3.1.', 'Turizm Kapasite Geliştirme', 'Eğitim alan katılımcı sayısı', 'Kişi', 450.00, '2026/4', 150.00, 150.00, 150.00, 145.00, 138.00),
('ÇGSTU41', 'STU', '4.1.', 'Turizm Tanıtım', 'Tanıtım içerik ve materyal üretim adedi', 'Adet', 60.00, '2026/4', 20.00, 20.00, 20.00, 22.00, 18.00),
('ÇGSTU42', 'STU', '4.2.', 'Uluslararası Fuar Katılımı', 'Katılınan uluslararası fuar/etkinlik sayısı', 'Adet', 9.00, '2026/4', 3.00, 3.00, 3.00, 3.00, 2.00),
('ÇGKDU11', 'KDU', '1.1.', 'Ekonomik Analiz', 'Hazırlanan ekonomik analiz raporu', 'Rapor', 12.00, '2026/4', 4.00, 4.00, 4.00, 4.00, 3.00),
('ÇGKDU21', 'KDU', '2.1.', 'Sektörel İşbirliği', 'Gerçekleştirilen işbirliği toplantısı', 'Toplantı', 36.00, '2026/4', 12.00, 12.00, 12.00, 11.00, 10.00),
('ÇGKDU31', 'KDU', '3.1.', 'Kapasite Geliştirme', 'Eğitim/çalıştay katılımcı sayısı', 'Kişi', 600.00, '2026/4', 200.00, 200.00, 200.00, 198.00, 185.00),
('ÇGKDU32', 'KDU', '3.2.', 'Girişimcilik Geliştirme', 'Desteklenen girişim sayısı', 'Adet', 30.00, '2026/4', 10.00, 10.00, 10.00, 9.00, 8.00),
('ÇGKDU41', 'KDU', '4.1.', 'Tanıtım ve Pazarlama', 'Gerçekleştirilen tanıtım etkinliği', 'Adet', 15.00, '2026/4', 5.00, 5.00, 5.00, 5.00, 4.00),
('ÇGKDU51', 'KDU', '5.1.', 'Mali Destek', 'Desteklenen proje sayısı', 'Proje', 60.00, '2026/4', 20.00, 20.00, 20.00, 18.00, 17.00),
('ÇGKDU52', 'KDU', '5.2.', 'Mali Destek Tutarı', 'Aktarılan toplam destek tutarı (TL)', 'TL', 60000000.00, '2026/4', 20000000.00, 20000000.00, 20000000.00, 19500000.00, 18200000.00),
('ÇGSOG11', 'SOG', '1.1.', 'SoGreen Proje Yönetimi', 'Gerçekleştirilen proje yönetim kurulu toplantısı', 'Toplantı', 12.00, '2026/4', 4.00, 4.00, 4.00, 4.00, 3.00),
('ÇGSOG12', 'SOG', '1.2.', 'SoGreen Pilot Uygulama', 'Tamamlanan pilot uygulama sayısı', 'Adet', 6.00, '2026/4', 2.00, 2.00, 2.00, 1.00, 2.00),
('ÇGSOG21', 'SOG', '2.1.', 'SoGreen Uluslararası İşbirliği', 'Gerçekleştirilen uluslararası ortak ziyareti', 'Ziyaret', 6.00, '2026/4', 2.00, 2.00, 2.00, 2.00, 1.00),
('ÇGAB11',  'AB',  '1.1.', 'AB Proje Raporlama', 'Teslim edilen teknik rapor sayısı', 'Rapor', 12.00, '2026/4', 4.00, 4.00, 4.00, 4.00, 3.00),
('ÇGMEK11', 'MEK', '1.1.', 'Mavi Ekonomi Araştırma', 'Hazırlanan mavi ekonomi raporu', 'Rapor', 6.00, '2026/4', 2.00, 2.00, 2.00, 2.00, 1.00),
('ÇGMEK21', 'MEK', '2.1.', 'Mavi Ekonomi İşbirliği', 'Mavi ekonomi koordinasyon toplantısı', 'Toplantı', 12.00, '2026/4', 4.00, 4.00, 4.00, 4.00, 3.00),
('ÇGSTU51', 'STU', '5.1.', 'Turizm Mali Destek', 'Desteklenen turizm projesi sayısı', 'Proje', 30.00, '2026/4', 10.00, 10.00, 10.00, 9.00, 8.00),
('ÇGSTU52', 'STU', '5.2.', 'Turizm Destek Tutarı', 'Aktarılan turizm destek tutarı (TL)', 'TL', 30000000.00, '2026/4', 10000000.00, 10000000.00, 10000000.00, 9800000.00, 9200000.00),
('ÇGKDU22', 'KDU', '2.2.', 'Küme ve Ağ Geliştirme', 'Oluşturulan iş birliği ağı/küme sayısı', 'Adet', 6.00, '2026/4', 2.00, 2.00, 2.00, 2.00, 1.00),
('ÇGSTU32', 'STU', '3.2.', 'Turizm Rehber Eğitimi', 'Sertifikalı rehber sayısı', 'Kişi', 90.00, '2026/4', 30.00, 30.00, 30.00, 28.00, 25.00),
('ÇGSOG31', 'SOG', '3.1.', 'SoGreen Yeşil Altyapı', 'Tamamlanan yeşil altyapı çıktısı', 'Adet', 3.00, '2026/4', 1.00, 1.00, 1.00, 0.00, 1.00),
('ÇGKDU12', 'KDU', '1.2.', 'Sektörel Veri Tabanı', 'Güncellenen sektörel veri tabanı', 'Adet', 3.00, '2026/4', 1.00, 1.00, 1.00, 1.00, 1.00),
('ÇGSTU43', 'STU', '4.3.', 'Film ve Medya Tanıtım', 'Üretilen tanıtım filmi/video sayısı', 'Adet', 6.00, '2026/4', 2.00, 2.00, 2.00, 2.00, 1.00),
('ÇGKDU33', 'KDU', '3.3.', 'E-ticaret Kapasitesi', 'E-ticarete başlayan işletme sayısı', 'İşletme', 30.00, '2026/4', 10.00, 10.00, 10.00, 8.00, 7.00);

-- ============================================================
-- 8. SPRINT_VERİ (17 kayıt: 4 aktif + 13 şablon)
-- GKİ doğrulaması:
-- Sprint 1: 66 / (20*4 - 13) * 100 = 66/67*100 ≈ 98.51
-- Sprint 2: 59 / (14*5 - 2)  * 100 = 59/68*100 ≈ 86.76
-- Sprint 3: 66 / (14*5 - 2)  * 100 = 66/68*100 ≈ 97.06
-- Sprint 4:  5 / (14*5 - 16) * 100 =  5/54*100 ≈  9.26
-- ============================================================

INSERT INTO sprint_veri (sprint_donem, baslangic, bitis, sprint_adi, isim_veren, sure_gun, ekip, izin, saha) VALUES
(1,  '2026-01-01', '2026-01-30', 'Middle', 'Oğuzhan', 20, 4, 13, 0),
(2,  '2026-02-02', '2026-02-20', 'Zemu',   'Mehmet',  14, 5,  2, 0),
(3,  '2026-02-23', '2026-03-13', 'Maison', 'Elifnaz', 14, 5,  2, 0),
(4,  '2026-03-16', '2026-04-03', 'House',  'Nuray',   14, 5, 16, 0),
-- Şablon sprint dönemleri (5-17)
(5,  '2026-04-06', '2026-04-24', NULL, NULL, 14, 5, 0, 0),
(6,  '2026-04-27', '2026-05-15', NULL, NULL, 14, 5, 0, 0),
(7,  '2026-05-18', '2026-06-05', NULL, NULL, 14, 5, 0, 0),
(8,  '2026-06-08', '2026-06-26', NULL, NULL, 14, 5, 0, 0),
(9,  '2026-06-29', '2026-07-17', NULL, NULL, 14, 5, 0, 0),
(10, '2026-07-20', '2026-08-07', NULL, NULL, 14, 5, 0, 0),
(11, '2026-08-10', '2026-08-28', NULL, NULL, 14, 5, 0, 0),
(12, '2026-08-31', '2026-09-18', NULL, NULL, 14, 5, 0, 0),
(13, '2026-09-21', '2026-10-09', NULL, NULL, 14, 5, 0, 0),
(14, '2026-10-12', '2026-10-30', NULL, NULL, 14, 5, 0, 0),
(15, '2026-11-02', '2026-11-20', NULL, NULL, 14, 5, 0, 0),
(16, '2026-11-23', '2026-12-11', NULL, NULL, 14, 5, 0, 0),
(17, '2026-12-14', '2027-01-01', NULL, NULL, 14, 5, 0, 0);

-- ============================================================
-- 9. SPRINT_IS_PLANI (102 kayıt) ⭐ KRİTİK
-- GKİ doğrulaması için bitis_donem ve plan_sure kontrol:
-- Sprint 1 (bitis_donem=1, Tamamlandı): plan_sure toplamı = 66
-- Sprint 2 (bitis_donem=2, Tamamlandı): plan_sure toplamı = 59
-- Sprint 3 (bitis_donem=3, Tamamlandı): plan_sure toplamı = 66
-- Sprint 4 (bitis_donem=4, Tamamlandı): plan_sure toplamı = 5
-- ============================================================

-- SPRINT 1 — 35 görev (tümü Tamamlandı, bitis_donem=1, toplam plan_sure=66)
INSERT INTO sprint_is_plani
(sprint_donem, bitis_donem, sprint_faaliyetleri, sno, plan_sure, is_durum,
 baslama_t, tamamlanma_t, ekip_uyesi, gercek_sure) VALUES
(1, 1, 'Bölge ekonomik göstergeler raporu hazırlama (Q1)',          1,  2.0, 'Tamamlandı', '2026-01-05', '2026-01-08', 'Elifnaz', 2.0),
(1, 1, 'Sektörel analiz ve SWOT çalışması',                         2,  3.0, 'Tamamlandı', '2026-01-06', '2026-01-10', 'Zübeyde', 3.5),
(1, 1, 'Çalışma grubu toplantısı organizasyonu ve yönetimi (1)',    7,  1.0, 'Tamamlandı', '2026-01-07', '2026-01-07', 'Fatih',   1.0),
(1, 1, 'Çalışma grubu toplantısı organizasyonu ve yönetimi (2)',    7,  1.0, 'Tamamlandı', '2026-01-14', '2026-01-14', 'Fatih',   1.0),
(1, 1, 'Sektör temsilcileri ile düzenli koordinasyon (1)',          8,  1.0, 'Tamamlandı', '2026-01-09', '2026-01-09', 'Elifnaz', 1.0),
(1, 1, 'Girişimcilik temel eğitim modülü (Ocak)',                   9,  3.0, 'Tamamlandı', '2026-01-12', '2026-01-15', 'Mehmet',  3.0),
(1, 1, 'Proje izleme ziyaretleri (KDU501) - 1',                    13,  2.0, 'Tamamlandı', '2026-01-08', '2026-01-09', 'Oğuzhan', 2.0),
(1, 1, 'Bakanlık veri talepleri yanıtlama (1)',                    40,  1.0, 'Tamamlandı', '2026-01-05', '2026-01-05', 'Fatih',   1.0),
(1, 1, 'Bakanlık veri talepleri yanıtlama (2)',                    40,  1.0, 'Tamamlandı', '2026-01-12', '2026-01-12', 'Fatih',   1.0),
(1, 1, 'Bakanlık veri talepleri yanıtlama (3)',                    40,  1.0, 'Tamamlandı', '2026-01-19', '2026-01-19', 'Fatih',   1.0),
(1, 1, 'Bakanlık toplantılarına katılım (1)',                      41,  1.0, 'Tamamlandı', '2026-01-10', '2026-01-10', 'Fatih',   1.0),
(1, 1, 'Bakanlık toplantılarına katılım (2)',                      41,  1.0, 'Tamamlandı', '2026-01-22', '2026-01-22', 'Fatih',   1.0),
(1, 1, 'Yönetim kurulu toplantısı hazırlık (1)',                   42,  1.0, 'Tamamlandı', '2026-01-14', '2026-01-14', 'Zübeyde', 1.0),
(1, 1, 'Kurum içi koordinasyon toplantısı (1)',                    43,  0.5, 'Tamamlandı', '2026-01-07', '2026-01-07', 'Mehmet',  0.5),
(1, 1, 'Kurum içi koordinasyon toplantısı (2)',                    43,  0.5, 'Tamamlandı', '2026-01-14', '2026-01-14', 'Mehmet',  0.5),
(1, 1, 'Kurum içi koordinasyon toplantısı (3)',                    43,  0.5, 'Tamamlandı', '2026-01-21', '2026-01-21', 'Mehmet',  0.5),
(1, 1, 'Turizm paydaş platformu toplantısı (1)',                   17,  2.0, 'Tamamlandı', '2026-01-16', '2026-01-17', 'Elifnaz', 2.0),
(1, 1, 'Dijital tanıtım içerik üretimi (1)',                       26,  2.0, 'Tamamlandı', '2026-01-05', '2026-01-06', 'Zübeyde', 2.0),
(1, 1, 'Dijital tanıtım içerik üretimi (2)',                       26,  2.0, 'Tamamlandı', '2026-01-19', '2026-01-20', 'Zübeyde', 2.0),
(1, 1, 'Sosyal medya kampanyası (1)',                              27,  1.0, 'Tamamlandı', '2026-01-08', '2026-01-08', 'Oğuzhan', 1.0),
(1, 1, 'Sosyal medya kampanyası (2)',                              27,  1.0, 'Tamamlandı', '2026-01-15', '2026-01-15', 'Oğuzhan', 1.0),
(1, 1, 'Web sitesi ve mobil içerik güncelleme (1)',                29,  2.0, 'Tamamlandı', '2026-01-12', '2026-01-13', 'Oğuzhan', 2.5),
(1, 1, 'Proje izleme ziyaretleri (STU501) - 1',                   32,  2.0, 'Tamamlandı', '2026-01-20', '2026-01-21', 'Elifnaz', 2.0),
(1, 1, 'SoGreen proje yönetim kurulu toplantısı - 1',             34,  2.0, 'Tamamlandı', '2026-01-23', '2026-01-24', 'Zübeyde', 2.0),
(1, 1, 'AB proje teknik rapor hazırlama - 1',                     38,  2.0, 'Tamamlandı', '2026-01-05', '2026-01-07', 'Mehmet',  2.0),
(1, 1, 'Turizm istatistikleri derleme (1)',                        50,  2.0, 'Tamamlandı', '2026-01-09', '2026-01-10', 'Nuray',   2.0),
(1, 1, 'Turizm istatistikleri derleme (2)',                        50,  2.0, 'Tamamlandı', '2026-01-23', '2026-01-24', 'Nuray',   2.0),
(1, 1, 'Ödeme talepleri inceleme (1)',                             14,  3.0, 'Tamamlandı', '2026-01-13', '2026-01-15', 'Fatih',   3.0),
(1, 1, 'İş paketi faaliyetleri uygulama (1)',                     35,  3.0, 'Tamamlandı', '2026-01-07', '2026-01-09', 'Zübeyde', 3.0),
(1, 1, 'Veri toplama ve doğrulama (1)',                            4,  3.0, 'Tamamlandı', '2026-01-14', '2026-01-16', 'Elifnaz', 3.0),
(1, 1, 'Turizm sektörü değerlendirme toplantısı (1)',             18,  1.0, 'Tamamlandı', '2026-01-28', '2026-01-28', 'Fatih',   1.0),
(1, 1, 'Sektörel koordinasyon protokolü hazırlama',               53,  2.0, 'Tamamlandı', '2026-01-19', '2026-01-22', 'Mehmet',  2.0),
(1, 1, 'Kültür bakanlığı ile koordinasyon (1)',                   19,  1.0, 'Tamamlandı', '2026-01-26', '2026-01-26', 'Nuray',   1.0),
(1, 1, 'Finansman ve hibe kaynakları eğitimi (1)',                10,  2.0, 'Tamamlandı', '2026-01-21', '2026-01-23', 'Elifnaz', 2.0),
(1, 1, 'Nihai değerlendirme raporu - ön hazırlık',                33,  3.0, 'Tamamlandı', '2026-01-26', '2026-01-30', 'Nuray',   3.0),
-- Ek görevler Sprint 1 (+7.5 gün → toplam 66.0)
(1, 1, 'Turizm envanter raporu hazırlama - ön çalışma',          15,  2.0, 'Tamamlandı', '2026-01-05', '2026-01-06', 'Nuray',   2.0),
(1, 1, 'Proje pilot uygulama ön araştırma (SOG)',                36,  2.0, 'Tamamlandı', '2026-01-21', '2026-01-22', 'Zübeyde', 2.0),
(1, 1, 'Turizm talep araştırması - veri toplama',                16,  2.0, 'Tamamlandı', '2026-01-13', '2026-01-14', 'Mehmet',  2.0),
(1, 1, 'AB finansal rapor hazırlama - 1',                        39,  1.5, 'Tamamlandı', '2026-01-27', '2026-01-28', 'Mehmet',  1.5);
-- Sprint 1 plan_sure toplamı: 58.5 + 2+2+2+1.5 = 66.0 ✓

-- SPRINT 2 — 30 görev (büyük çoğunluğu Tamamlandı, bitis_donem=2, toplam plan_sure=59)
INSERT INTO sprint_is_plani
(sprint_donem, bitis_donem, sprint_faaliyetleri, sno, plan_sure, is_durum,
 baslama_t, tamamlanma_t, ekip_uyesi, gercek_sure) VALUES
(2, 2, 'Bölge ekonomik göstergeler raporu hazırlama (Q1) - tamamlama', 1, 2.0, 'Tamamlandı', '2026-02-03', '2026-02-04', 'Elifnaz', 2.0),
(2, 2, 'Çalışma grubu toplantısı (3)',                                  7, 1.0, 'Tamamlandı', '2026-02-04', '2026-02-04', 'Fatih',   1.0),
(2, 2, 'Çalışma grubu toplantısı (4)',                                  7, 1.0, 'Tamamlandı', '2026-02-11', '2026-02-11', 'Fatih',   1.0),
(2, 2, 'Sektör temsilcileri koordinasyon (2)',                          8, 1.0, 'Tamamlandı', '2026-02-06', '2026-02-06', 'Elifnaz', 1.0),
(2, 2, 'Girişimcilik temel eğitim modülü (Şubat)',                     9, 3.0, 'Tamamlandı', '2026-02-09', '2026-02-12', 'Mehmet',  3.0),
(2, 2, 'Proje izleme ziyaretleri (KDU501) - 2',                       13, 2.0, 'Tamamlandı', '2026-02-05', '2026-02-06', 'Oğuzhan', 2.0),
(2, 2, 'Bakanlık veri talepleri (4)',                                  40, 1.0, 'Tamamlandı', '2026-02-03', '2026-02-03', 'Fatih',   1.0),
(2, 2, 'Bakanlık veri talepleri (5)',                                  40, 1.0, 'Tamamlandı', '2026-02-10', '2026-02-10', 'Fatih',   1.0),
(2, 2, 'Bakanlık toplantılarına katılım (3)',                          41, 1.0, 'Tamamlandı', '2026-02-06', '2026-02-06', 'Fatih',   1.0),
(2, 2, 'Kurum içi koordinasyon toplantısı (4)',                        43, 0.5, 'Tamamlandı', '2026-02-04', '2026-02-04', 'Mehmet',  0.5),
(2, 2, 'Kurum içi koordinasyon toplantısı (5)',                        43, 0.5, 'Tamamlandı', '2026-02-11', '2026-02-11', 'Mehmet',  0.5),
(2, 2, 'Turizm paydaş platformu toplantısı (2)',                       17, 2.0, 'Tamamlandı', '2026-02-13', '2026-02-14', 'Elifnaz', 2.0),
(2, 2, 'Turizm sektörü değerlendirme toplantısı (2)',                  18, 1.0, 'Tamamlandı', '2026-02-18', '2026-02-18', 'Fatih',   1.0),
(2, 2, 'Dijital tanıtım içerik üretimi (3)',                           26, 2.0, 'Tamamlandı', '2026-02-03', '2026-02-04', 'Zübeyde', 2.0),
(2, 2, 'Dijital tanıtım içerik üretimi (4)',                           26, 2.0, 'Tamamlandı', '2026-02-17', '2026-02-18', 'Zübeyde', 2.5),
(2, 2, 'Sosyal medya kampanyası (3)',                                  27, 1.0, 'Tamamlandı', '2026-02-05', '2026-02-05', 'Oğuzhan', 1.0),
(2, 2, 'Proje izleme ziyaretleri (STU501) - 2',                       32, 2.0, 'Tamamlandı', '2026-02-09', '2026-02-10', 'Elifnaz', 2.0),
(2, 2, 'SoGreen iş paketi faaliyetleri (2)',                          35, 3.0, 'Tamamlandı', '2026-02-04', '2026-02-06', 'Zübeyde', 3.0),
(2, 2, 'AB proje teknik rapor - 2',                                   38, 2.0, 'Tamamlandı', '2026-02-03', '2026-02-05', 'Mehmet',  2.0),
(2, 2, 'Turizm istatistikleri (3)',                                    50, 2.0, 'Tamamlandı', '2026-02-06', '2026-02-07', 'Nuray',   2.0),
(2, 2, 'Ödeme talepleri inceleme (2)',                                 14, 3.0, 'Tamamlandı', '2026-02-10', '2026-02-12', 'Fatih',   3.0),
(2, 2, 'Kültür bakanlığı ile koordinasyon (2)',                        19, 1.0, 'Tamamlandı', '2026-02-13', '2026-02-13', 'Nuray',   1.0),
(2, 2, 'Entegre turizm ürün geliştirme çalıştayı - 1',               20, 2.0, 'Tamamlandı', '2026-02-16', '2026-02-17', 'Elifnaz', 2.0),
(2, 2, 'Konaklama işletmeciliği eğitimi (1)',                         21, 3.0, 'Tamamlandı', '2026-02-09', '2026-02-11', 'Mehmet',  3.5),
(2, 2, 'Web sitesi ve mobil içerik güncelleme (2)',                   29, 2.0, 'Tamamlandı', '2026-02-03', '2026-02-04', 'Oğuzhan', 2.0),
(2, 2, 'Yönetim kurulu toplantısı hazırlık (2)',                      42, 1.0, 'Tamamlandı', '2026-02-11', '2026-02-11', 'Zübeyde', 1.0),
(2, 2, 'Uluslararası turizm fuarı katılım organizasyonu (1)',         28, 3.0, 'Tamamlandı', '2026-02-04', '2026-02-06', 'Zübeyde', 3.0),
(2, 2, 'İhracat stratejisi geliştirme çalıştayı (1)',                 11, 2.0, 'Tamamlandı', '2026-02-16', '2026-02-17', 'Elifnaz', 2.0),
(2, 2, 'Veri tabanı tasarım ve geliştirme',                            3, 5.0, 'Tamamlandı', '2026-02-03', '2026-02-09', 'Mehmet',  5.5),
(2, 2, 'Finansman ve hibe eğitimi (2)',                               10, 2.0, 'Tamamlandı', '2026-02-18', '2026-02-19', 'Nuray',   2.0),
-- Ek görevler Sprint 2 (+4 gün → toplam 59.0)
(2, 2, 'Turizm istatistikleri hazırlık ve derleme (2)',            50, 2.0, 'Tamamlandı', '2026-02-16', '2026-02-17', 'Nuray',   2.0),
(2, 2, 'Destinasyon altyapı teknik destek - ön görüşme',           51, 2.0, 'Tamamlandı', '2026-02-10', '2026-02-11', 'Elifnaz', 2.0);
-- Sprint 2 plan_sure toplamı: 55 + 2+2 = 59.0 ✓

-- SPRINT 3 — 25 görev (karışık durumlar, bitis_donem=3 Tamamlandı toplamı=66)
INSERT INTO sprint_is_plani
(sprint_donem, bitis_donem, sprint_faaliyetleri, sno, plan_sure, is_durum,
 baslama_t, inceleme_t, tamamlanma_t, ekip_uyesi, gercek_sure) VALUES
(3, 3, 'Çalışma grubu toplantısı (5)',                              7,  1.0, 'Tamamlandı', '2026-02-25', NULL, '2026-02-25', 'Fatih',   1.0),
(3, 3, 'Çalışma grubu toplantısı (6)',                              7,  1.0, 'Tamamlandı', '2026-03-04', NULL, '2026-03-04', 'Fatih',   1.0),
(3, 3, 'Bakanlık veri talepleri (6)',                              40,  1.0, 'Tamamlandı', '2026-02-24', NULL, '2026-02-24', 'Fatih',   1.0),
(3, 3, 'Bakanlık veri talepleri (7)',                              40,  1.0, 'Tamamlandı', '2026-03-03', NULL, '2026-03-03', 'Fatih',   1.0),
(3, 3, 'Bakanlık toplantılarına katılım (4)',                      41,  1.0, 'Tamamlandı', '2026-03-05', NULL, '2026-03-05', 'Fatih',   1.0),
(3, 3, 'Kurum içi koordinasyon (6)',                               43,  0.5, 'Tamamlandı', '2026-02-25', NULL, '2026-02-25', 'Mehmet',  0.5),
(3, 3, 'Kurum içi koordinasyon (7)',                               43,  0.5, 'Tamamlandı', '2026-03-04', NULL, '2026-03-04', 'Mehmet',  0.5),
(3, 3, 'Proje izleme ziyaretleri (KDU501) - 3',                   13,  2.0, 'Tamamlandı', '2026-03-02', NULL, '2026-03-03', 'Oğuzhan', 2.0),
(3, 3, 'Girişimcilik temel eğitim modülü (Mart)',                   9,  3.0, 'Tamamlandı', '2026-03-09', NULL, '2026-03-12', 'Mehmet',  3.0),
(3, 3, 'Dijital tanıtım içerik üretimi (5)',                       26,  2.0, 'Tamamlandı', '2026-02-24', NULL, '2026-02-25', 'Zübeyde', 2.0),
(3, 3, 'SoGreen proje yönetim kurulu (2)',                         34,  2.0, 'Tamamlandı', '2026-03-06', NULL, '2026-03-07', 'Zübeyde', 2.0),
(3, 3, 'SoGreen iş paketi faaliyetleri (3)',                       35,  3.0, 'Tamamlandı', '2026-02-23', NULL, '2026-02-26', 'Zübeyde', 3.0),
(3, 3, 'AB proje teknik rapor - 3',                                38,  2.0, 'Tamamlandı', '2026-02-24', NULL, '2026-02-26', 'Mehmet',  2.0),
(3, 3, 'Turizm istatistikleri (4)',                                50,  2.0, 'Tamamlandı', '2026-02-24', NULL, '2026-02-25', 'Nuray',   2.0),
(3, 3, 'Ödeme talepleri inceleme (3)',                             14,  3.0, 'Tamamlandı', '2026-03-03', NULL, '2026-03-05', 'Fatih',   3.0),
(3, 3, 'Proje izleme ziyaretleri (STU501) - 3',                   32,  2.0, 'Tamamlandı', '2026-03-09', NULL, '2026-03-10', 'Elifnaz', 2.0),
(3, 3, 'Sosyal medya kampanyası (4)',                              27,  1.0, 'Tamamlandı', '2026-02-26', NULL, '2026-02-26', 'Oğuzhan', 1.0),
(3, 3, 'Turizm paydaş platformu toplantısı (3)',                   17,  2.0, 'Tamamlandı', '2026-03-06', NULL, '2026-03-07', 'Elifnaz', 2.0),
(3, 3, 'Turizm sektörü değerlendirme toplantısı (3)',              18,  1.0, 'Tamamlandı', '2026-03-11', NULL, '2026-03-11', 'Fatih',   1.0),
(3, 3, 'Kültür bakanlığı koordinasyon (3)',                        19,  1.0, 'Tamamlandı', '2026-03-05', NULL, '2026-03-05', 'Nuray',   1.0),
(3, 3, 'Rehberlik ve misafirperverllik eğitimi (1)',               22,  2.0, 'Tamamlandı', '2026-03-02', NULL, '2026-03-04', 'Elifnaz', 2.0),
(3, 3, 'Uluslararası kalkınma platformu katılımı (1)',             45,  2.0, 'Tamamlandı', '2026-02-27', NULL, '2026-02-28', 'Elifnaz', 2.0),
(3, 3, 'Yerel ürün tasarım ve ambalaj atölyesi (1)',               46,  2.0, 'Tamamlandı', '2026-03-03', NULL, '2026-03-04', 'Zübeyde', 2.0),
(3, 3, 'İhracat stratejisi geliştirme çalıştayı (2)',              11,  2.0, 'Tamamlandı', '2026-03-10', NULL, '2026-03-11', 'Nuray',   2.0),
(3, 3, 'Yönetim kurulu toplantısı hazırlık (3)',                   42,  1.0, 'Tamamlandı', '2026-03-11', NULL, '2026-03-11', 'Zübeyde', 1.0);
-- Sprint 3 plan_sure toplamı: 1+1+1+1+1+0.5+0.5+2+3+2+2+3+2+2+3+2+1+2+1+1+2+2+2+2+1 = 42.0 ← eksik 24
-- Düzeltme: sprint_donem=3 içinde bitis_donem=3 olan tüm Tamamlandı kayıtlar toplamı 66 olacak
-- Ek kayıtlar aşağıda eklendi

-- SPRINT 3 — ek görevler (toplamı 66'ya tamamlamak için +24 gün)
INSERT INTO sprint_is_plani
(sprint_donem, bitis_donem, sprint_faaliyetleri, sno, plan_sure, is_durum,
 baslama_t, inceleme_t, tamamlanma_t, ekip_uyesi, gercek_sure) VALUES
(3, 3, 'Web sitesi ve mobil içerik güncelleme (3)',                29,  2.0, 'Tamamlandı', '2026-03-02', NULL, '2026-03-03', 'Oğuzhan', 2.0),
(3, 3, 'Turizm envanter ve arz analizi raporu hazırlama',          15,  4.0, 'Tamamlandı', '2026-02-23', NULL, '2026-02-27', 'Elifnaz', 4.0),
(3, 3, 'Proje pilot uygulama alanı çalışmaları - 1',              36,  4.0, 'Tamamlandı', '2026-03-02', NULL, '2026-03-05', 'Zübeyde', 4.5),
(3, 3, 'Sektör temsilcileri koordinasyon (3)',                      8,  1.0, 'Tamamlandı', '2026-02-25', NULL, '2026-02-25', 'Elifnaz', 1.0),
(3, 3, 'Pazarlama ve marka eğitimi (1)',                           12,  2.0, 'Tamamlandı', '2026-03-04', NULL, '2026-03-05', 'Mehmet',  2.0),
(3, 3, 'Yatırım ortamı değerlendirme raporu',                      47,  3.0, 'Tamamlandı', '2026-02-24', NULL, '2026-02-27', 'Fatih',   3.0),
(3, 3, 'E-ticaret platformu kurulum rehberi hazırlama',            48,  2.0, 'Tamamlandı', '2026-03-09', NULL, '2026-03-10', 'Mehmet',  2.0),
(3, 3, 'Destinasyon altyapı proje teknik desteği (1)',             51,  3.0, 'Tamamlandı', '2026-03-03', NULL, '2026-03-05', 'Nuray',   3.0),
(3, 3, 'Uluslararası ortak ziyaret (SOG) - 1',                    37,  3.0, 'Tamamlandı', '2026-03-09', NULL, '2026-03-11', 'Zübeyde', 3.0),
-- Son ek: 1 gün eksik (+1 → toplam 66)
(3, 3, 'Sektör temsilcileri koordinasyon (4)',                      8,  1.0, 'Tamamlandı', '2026-03-11', NULL, '2026-03-11', 'Elifnaz', 1.0);
-- Sprint 3 ek kayıtlar: 2+4+4+1+2+3+2+3+3+1 = 25
-- Sprint 3 toplam: 41 + 25 = 66 ✓

-- SPRINT 4 — 12 görev (5 Tamamlandı bitis_donem=4, plan_sure toplamı=5; geri kalan başlamadı)
INSERT INTO sprint_is_plani
(sprint_donem, bitis_donem, sprint_faaliyetleri, sno, plan_sure, is_durum,
 baslama_t, inceleme_t, tamamlanma_t, ekip_uyesi, gercek_sure) VALUES
-- Tamamlanan görevler (plan_sure toplamı = 5)
(4, 4, 'Bakanlık veri talepleri (8)',            40,  1.0, 'Tamamlandı', '2026-03-17', NULL, '2026-03-17', 'Fatih',   1.0),
(4, 4, 'Bakanlık veri talepleri (9)',            40,  1.0, 'Tamamlandı', '2026-03-24', NULL, '2026-03-24', 'Fatih',   1.0),
(4, 4, 'Kurum içi koordinasyon (8)',             43,  0.5, 'Tamamlandı', '2026-03-18', NULL, '2026-03-18', 'Mehmet',  0.5),
(4, 4, 'Kurum içi koordinasyon (9)',             43,  0.5, 'Tamamlandı', '2026-03-25', NULL, '2026-03-25', 'Mehmet',  0.5),
(4, 4, 'Çalışma grubu toplantısı (7)',            7,  1.0, 'Tamamlandı', '2026-03-18', NULL, '2026-03-18', 'Fatih',   1.0),
(4, 4, 'Bakanlık toplantılarına katılım (5)',    41,  1.0, 'Tamamlandı', '2026-03-19', NULL, '2026-03-19', 'Fatih',   1.0),
-- Devam eden / başlamamış görevler
(4, NULL, 'Çalışma grubu toplantısı (8)',         7,  1.0, 'Başladı',    '2026-03-25', NULL, NULL, 'Fatih',   NULL),
(4, NULL, 'Girişimcilik temel eğitim (Nisan)',    9,  3.0, NULL,          NULL, NULL, NULL, 'Mehmet',  NULL),
(4, NULL, 'Proje izleme ziyaretleri (KDU501)-4', 13,  2.0, NULL,          NULL, NULL, NULL, 'Oğuzhan', NULL),
(4, NULL, 'Dijital tanıtım içerik üretimi (6)',  26,  2.0, 'İncelemede', '2026-03-17', '2026-03-20', NULL, 'Zübeyde', NULL),
(4, NULL, 'SoGreen iş paketi faaliyetleri (4)',  35,  3.0, 'Başladı',    '2026-03-16', NULL, NULL, 'Zübeyde', NULL),
(4, NULL, 'Turizm istatistikleri (5)',            50,  2.0, NULL,          NULL, NULL, NULL, 'Nuray',   NULL);
-- Sprint 4 Tamamlandı bitis_donem=4: 1+1+0.5+0.5+1+1 = 5.0 ✓

-- ============================================================
-- 10. ANAHTAR SONUCLAR (91 kayıt — sno bazlı)
-- ============================================================

-- sno=1 (KDU101 - Bölge ekonomik göstergeler raporu)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(1, 1, 'TR90 bölgesi ekonomik göstergeler raporu yayımlandı'),
(1, 2, 'Sektörel büyüme verileri güncellendi'),
(1, 3, 'Karar alıcılara sunum gerçekleştirildi');

-- sno=2 (KDU101 - Sektörel analiz SWOT)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(2, 1, 'SWOT analizi raporu tamamlandı'),
(2, 2, 'Öncelikli sektörler belirlendi');

-- sno=3 (KDU103 - Veri tabanı tasarım)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(3, 1, 'Veri tabanı tasarım dokümanı hazırlandı'),
(3, 2, 'Üretim veri tabanı test ortamında çalışıyor'),
(3, 3, 'Kullanıcı kabul testi tamamlandı');

-- sno=4 (KDU103 - Veri toplama)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(4, 1, 'En az 50 işletmeden veri toplandı'),
(4, 2, 'Veri kalite kontrolü yapıldı');

-- sno=5 (KDU108 - Başvuru kılavuzu)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(5, 1, 'Başvuru kılavuzu yayımlandı'),
(5, 2, 'Tanıtım duyurusu yapıldı');

-- sno=6 (KDU108 - Değerlendirme komisyonu)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(6, 1, 'Komisyon üyeleri belirlendi'),
(6, 2, 'Değerlendirme kriterleri onaylandı'),
(6, 3, 'Seçim sonuçları açıklandı');

-- sno=7 (KDU204 - Çalışma grubu toplantısı)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(7, 1, 'Toplantı tutanakları hazırlandı'),
(7, 2, 'Eylem maddeleri takibe alındı');

-- sno=8 (KDU204 - Sektör temsilcileri koordinasyon)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(8, 1, 'Sektör geri bildirimleri derlendi'),
(8, 2, 'Koordinasyon raporu hazırlandı');

-- sno=9 (KDU301 - Girişimcilik eğitimi)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(9, 1, 'En az 20 girişimci eğitime katıldı'),
(9, 2, 'Eğitim memnuniyet anketi tamamlandı'),
(9, 3, 'Sertifikalar verildi');

-- sno=10 (KDU301 - Finansman eğitimi)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(10, 1, 'Hibe kaynakları rehberi hazırlandı'),
(10, 2, 'Eğitim katılımcı hedefi aşıldı');

-- sno=11 (KDU304 - İhracat stratejisi)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(11, 1, 'İhracat eylem planı oluşturuldu'),
(11, 2, 'Pilot firma seçildi');

-- sno=12 (KDU304 - Pazarlama eğitimi)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(12, 1, 'Marka eğitimi tamamlandı'),
(12, 2, 'Katılımcı sertifika aldı');

-- sno=13 (KDU501 - Proje izleme)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(13, 1, 'İzleme ziyareti raporu hazırlandı'),
(13, 2, 'Sorunlar tespit edildi ve çözüme kavuşturuldu');

-- sno=14 (KDU501 - Ödeme talepleri)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(14, 1, 'Ödeme talepleri incelendi'),
(14, 2, 'Onaylanan ödemeler sisteme girildi'),
(14, 3, 'Ret gerekçeleri yazıldı');

-- sno=15 (STU101 - Turizm envanter raporu)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(15, 1, 'Turizm tesisleri envanteri güncellendi'),
(15, 2, 'Kapasite analizi raporu yayımlandı');

-- sno=16 (STU101 - Turizm talep araştırması)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(16, 1, 'Anket çalışması tamamlandı'),
(16, 2, 'Araştırma raporu yayımlandı');

-- sno=17 (STU103 - Turizm paydaş platformu)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(17, 1, 'Platform toplantısı gerçekleştirildi'),
(17, 2, 'Karar ve öneriler raporlandı');

-- sno=18 (STU103 - Değerlendirme toplantısı)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(18, 1, 'Sektör değerlendirme sonuçları paylaşıldı');

-- sno=19 (STU104 - Kültür bakanlığı koordinasyon)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(19, 1, 'Bakanlık ile koordinasyon toplantısı gerçekleştirildi'),
(19, 2, 'Ortak eylem planı oluşturuldu');

-- sno=20 (STU104 - Entegre turizm ürün)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(20, 1, 'Kültür-turizm entegre ürün tanımları yapıldı'),
(20, 2, 'Pilot rota belirlendi');

-- sno=21 (STU201 - Konaklama eğitimi)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(21, 1, 'Konaklama eğitimi tamamlandı'),
(21, 2, 'Sertifika töreni gerçekleştirildi');

-- sno=22 (STU201 - Rehberlik eğitimi)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(22, 1, 'Rehberlik eğitimi katılımcı hedefi tutturuldu'),
(22, 2, 'Eğitim memnuniyeti %80 üzerinde');

-- sno=23 (STU301 - Gastronomi rotası)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(23, 1, 'Gastronomi rotası haritası oluşturuldu'),
(23, 2, 'Ürün katalog tasarlandı');

-- sno=24 (STU302 - Ekoturizm güzergah)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(24, 1, 'Ekoturizm güzergahları belirlendi'),
(24, 2, 'Tabela ve işaretleme yapıldı');

-- sno=25 (STU302 - Doğa turizmi rehber eğitimi)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(25, 1, 'Doğa turizmi eğitimi tamamlandı'),
(25, 2, 'Sertifikalı rehber sayısı arttı');

-- sno=26 (STU401 - Dijital tanıtım içerik)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(26, 1, 'Dijital içerik üretildi ve yayımlandı'),
(26, 2, 'Erişim hedefi aşıldı');

-- sno=27 (STU401 - Sosyal medya kampanyası)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(27, 1, 'Sosyal medya kampanyası başlatıldı'),
(27, 2, 'Etkileyici iş birlikleri sağlandı');

-- sno=28 (STU402 - Uluslararası fuar)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(28, 1, 'Fuar stand kurulumu tamamlandı'),
(28, 2, 'Yabancı tur operatörü görüşmesi yapıldı'),
(28, 3, 'Fuar katılım raporu hazırlandı');

-- sno=29 (STU403 - Web sitesi içerik)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(29, 1, 'Web sitesi içeriği güncellendi'),
(29, 2, 'Mobil uyumluluk doğrulandı');

-- sno=30 (STU403 - Tanıtım filmi)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(30, 1, 'Senaryo onaylandı'),
(30, 2, 'Film çekimi tamamlandı'),
(30, 3, 'Film yayına alındı');

-- sno=31 (STU404 - Tur operatörü gezisi)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(31, 1, 'Tur operatörü grubu bölgeyi ziyaret etti'),
(31, 2, 'Tur paket teklifleri alındı');

-- sno=32 (STU501 - Proje izleme STU)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(32, 1, 'Ziyaret raporu hazırlandı'),
(32, 2, 'Proje uygulaması sorunsuz devam ediyor');

-- sno=33 (STU501 - Nihai değerlendirme)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(33, 1, 'Nihai değerlendirme raporu hazırlandı'),
(33, 2, 'Sonuçlar karar alıcılara sunuldu');

-- sno=34 (SOG001 - YK toplantısı)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(34, 1, 'YK toplantısı gerçekleştirildi'),
(34, 2, 'Toplantı tutanakları tüm ortaklara iletildi');

-- sno=35 (SOG001 - İş paketi faaliyetleri)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(35, 1, 'İş paketi çıktıları tamamlandı'),
(35, 2, 'Raporlama platformuna yüklendi');

-- sno=36 (SOG001 - Pilot uygulama)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(36, 1, 'Pilot uygulama alanı faaliyete geçirildi'),
(36, 2, 'İzleme verileri toplandı');

-- sno=37 (SOG001 - Uluslararası ortak ziyaret)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(37, 1, 'Ortak ziyaret gerçekleştirildi'),
(37, 2, 'İşbirliği tutanağı imzalandı');

-- sno=38 (AB0001 - AB teknik rapor)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(38, 1, 'Teknik rapor teslim edildi'),
(38, 2, 'Ortak değerlendirme toplantısı yapıldı');

-- sno=39 (AB0001 - AB finansal rapor)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(39, 1, 'Finansal rapor hazırlandı'),
(39, 2, 'Belgeler koordinatör kuruma gönderildi');

-- sno=40 (BAK001 - Bakanlık veri talepleri)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(40, 1, 'Talep zamanında yanıtlandı'),
(40, 2, 'Yanıt kayıt altına alındı');

-- sno=41 (BAK001 - Bakanlık toplantı katılımı)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(41, 1, 'Toplantıya katılım sağlandı'),
(41, 2, 'Toplantı notları ilgililere iletildi');

-- sno=42 (SOPD01 - YK toplantısı)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(42, 1, 'YK toplantısı hazırlıkları tamamlandı'),
(42, 2, 'Gündeme ilişkin belgeler hazırlandı');

-- sno=43 (SOPD01 - Kurum içi koordinasyon)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(43, 1, 'Haftalık koordinasyon toplantısı yapıldı');

-- sno=44 (SOPD01 - Yıllık değerlendirme raporu)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(44, 1, 'Yıllık iç değerlendirme raporu tamamlandı'),
(44, 2, 'Yönetim onayına sunuldu');

-- sno=45 (KDU205 - Uluslararası platform)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(45, 1, 'Platform toplantısına katılım sağlandı'),
(45, 2, 'İşbirliği fırsatları raporlandı');

-- sno=46 (KDU302 - Yerel ürün tasarım atölyesi)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(46, 1, 'Atölye gerçekleştirildi'),
(46, 2, 'Prototip ürün tasarımları oluşturuldu');

-- sno=47 (KDU407 - Yatırım ortamı raporu)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(47, 1, 'Yatırım engelleri raporu tamamlandı'),
(47, 2, 'Politika önerileri sunuldu');

-- sno=48 (KDU305 - E-ticaret rehberi)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(48, 1, 'E-ticaret rehberi yayımlandı'),
(48, 2, 'İşletmelerle paylaşıldı');

-- sno=49 (KDU305 - Dijitalleşme eğitimi)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(49, 1, 'Dijitalleşme eğitimi tamamlandı'),
(49, 2, 'Sertifika verildi');

-- sno=50 (STU102 - Turizm istatistikleri)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(50, 1, 'İstatistik bülteni yayımlandı'),
(50, 2, 'Veri tabanı güncellendi');

-- sno=51 (STU405 - Destinasyon altyapı desteği)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(51, 1, 'Teknik destek sağlandı'),
(51, 2, 'Altyapı iyileştirme raporu hazırlandı');

-- sno=52 (STU502 - Küçük ölçekli destek)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(52, 1, 'Çağrı ilan edildi'),
(52, 2, 'Başvurular değerlendirildi'),
(52, 3, 'Seçim sonuçları açıklandı');

-- sno=53 (KDU204 - Koordinasyon protokolü)
INSERT INTO anahtar_sonuclar (sno, as_no, anahtar_sonuc) VALUES
(53, 1, 'Koordinasyon protokolü taslağı hazırlandı'),
(53, 2, 'Paydaşlardan görüş alındı'),
(53, 3, 'Protokol onaylandı ve imzalandı');

-- ============================================================
-- 11. SPRINT_RETRO (29 kayıt)
-- Sprint 1: bitis=2026-01-30 → 7 kayıt
-- Sprint 2: bitis=2026-02-20 → 7 kayıt
-- Sprint 3: bitis=2026-03-13 → 7 kayıt
-- Sprint 4: bitis=2026-04-03 → henüz başlamadı → 0 kayıt
-- Ek: geçmiş (önceki yıl) retro = 8 kayıt
-- ============================================================

-- Sprint 1 retro (7 kayıt)
INSERT INTO sprint_retro (tarih, ad, sprint_toplanti, organizasyon_puan, ajanstaki_rolu, ajans_hakkinda, durum) VALUES
('2026-01-30 14:00:00', 'Zübeyde',  '2026-01-30', 9, 8, 9, 'Tamamlandı'),
('2026-01-30 14:05:00', 'Elifnaz',  '2026-01-30', 8, 9, 8, 'Tamamlandı'),
('2026-01-30 14:08:00', 'Mehmet',   '2026-01-30', 9, 8, 8, 'Tamamlandı'),
('2026-01-30 14:12:00', 'Oğuzhan',  '2026-01-30', 7, 7, 8, 'Tamamlandı'),
('2026-01-30 14:15:00', 'Esen',     '2026-01-30', 8, 8, 9, 'Tamamlandı'),
('2026-01-30 14:20:00', 'Nuray',    '2026-01-30', 9, 9, 8, 'Tamamlandı'),
('2026-01-30 14:25:00', 'Fatih',    '2026-01-30', 8, 8, 8, 'Tamamlandı');

-- Sprint 2 retro (7 kayıt)
INSERT INTO sprint_retro (tarih, ad, sprint_toplanti, organizasyon_puan, ajanstaki_rolu, ajans_hakkinda, durum) VALUES
('2026-02-20 14:00:00', 'Zübeyde',  '2026-02-20', 7, 8, 8, 'Tamamlandı'),
('2026-02-20 14:04:00', 'Elifnaz',  '2026-02-20', 8, 7, 8, 'Tamamlandı'),
('2026-02-20 14:08:00', 'Mehmet',   '2026-02-20', 7, 8, 7, 'Tamamlandı'),
('2026-02-20 14:11:00', 'Oğuzhan',  '2026-02-20', 6, 7, 7, 'Tamamlandı'),
('2026-02-20 14:14:00', 'Esen',     '2026-02-20', 7, 7, 8, 'Tamamlandı'),
('2026-02-20 14:18:00', 'Nuray',    '2026-02-20', 8, 8, 7, 'Tamamlandı'),
('2026-02-20 14:22:00', 'Fatih',    '2026-02-20', 7, 7, 7, 'Tamamlandı');

-- Sprint 3 retro (7 kayıt)
INSERT INTO sprint_retro (tarih, ad, sprint_toplanti, organizasyon_puan, ajanstaki_rolu, ajans_hakkinda, durum) VALUES
('2026-03-13 14:00:00', 'Zübeyde',  '2026-03-13', 9, 9, 8, 'Tamamlandı'),
('2026-03-13 14:04:00', 'Elifnaz',  '2026-03-13', 8, 8, 9, 'Tamamlandı'),
('2026-03-13 14:08:00', 'Mehmet',   '2026-03-13', 9, 8, 8, 'Tamamlandı'),
('2026-03-13 14:11:00', 'Oğuzhan',  '2026-03-13', 8, 8, 8, 'Tamamlandı'),
('2026-03-13 14:14:00', 'Esen',     '2026-03-13', 9, 9, 9, 'Tamamlandı'),
('2026-03-13 14:18:00', 'Nuray',    '2026-03-13', 8, 8, 8, 'Tamamlandı'),
('2026-03-13 14:22:00', 'Fatih',    '2026-03-13', 9, 8, 9, 'Tamamlandı');

-- Ek geçmiş retro kayıtları (8 kayıt — farklı sprint toplantı tarihleri)
INSERT INTO sprint_retro (tarih, ad, sprint_toplanti, organizasyon_puan, ajanstaki_rolu, ajans_hakkinda, durum) VALUES
('2025-12-31 15:00:00', 'Zübeyde',  '2025-12-31', 8, 8, 7, 'Tamamlandı'),
('2025-12-31 15:05:00', 'Elifnaz',  '2025-12-31', 7, 8, 8, 'Tamamlandı'),
('2025-12-31 15:10:00', 'Mehmet',   '2025-12-31', 8, 7, 8, 'Tamamlandı'),
('2025-12-31 15:14:00', 'Oğuzhan',  '2025-12-31', 7, 7, 7, 'Tamamlandı'),
('2025-12-31 15:18:00', 'Esen',     '2025-12-31', 8, 8, 8, 'Tamamlandı'),
('2025-12-31 15:22:00', 'Nuray',    '2025-12-31', 8, 9, 8, 'Tamamlandı'),
('2025-12-31 15:25:00', 'Fatih',    '2025-12-31', 7, 8, 7, 'Tamamlandı'),
('2025-12-31 15:28:00', 'Zübeyde',  '2025-12-10', 8, 7, 8, 'Tamamlandı');

-- ============================================================
-- 12. HARCAMALAR (8 kayıt)
-- ============================================================

INSERT INTO harcamalar (sprint_donem, sprint_faaliyet, sno, aciklama, harcama_onay_kodu,
    onay_tarihi, odeme_donem, odenecek_kdvli, durum) VALUES
(1, 'SoGreen proje yönetim kurulu toplantısı', 34, 'Ulaşım ve konaklama giderleri', 'ONY-2026-001',
 '2026-01-31', '2026.Oca', 15000.00, 'Onaylandı'),
(1, 'Girişimcilik temel eğitim modülü', 9, 'Eğitim materyalleri ve salon kirası', 'ONY-2026-002',
 '2026-01-31', '2026.Oca', 8500.00, 'Onaylandı'),
(2, 'Uluslararası turizm fuarı katılım organizasyonu', 28, 'Stand ve katılım ücretleri', 'ONY-2026-003',
 '2026-02-21', '2026.Şub', 45000.00, 'Onaylandı'),
(2, 'Konaklama işletmeciliği eğitimi', 21, 'Eğitim ücreti ve katılımcı ulaşımı', 'ONY-2026-004',
 '2026-02-21', '2026.Şub', 12000.00, 'Onaylandı'),
(3, 'SoGreen pilot uygulama alanı çalışmaları', 36, 'Malzeme ve ekipman alımı', 'ONY-2026-005',
 '2026-03-14', '2026.Mar', 28000.00, 'Onaylandı'),
(3, 'AB proje teknik rapor hazırlama', 38, 'Tercüme ve baskı giderleri', 'ONY-2026-006',
 '2026-03-14', '2026.Mar', 5500.00, 'Onaylandı'),
(3, 'Uluslararası ortak ziyaret SOG', 37, 'Uluslararası uçak bileti ve konaklama', 'ONY-2026-007',
 '2026-03-15', '2026.Mar', 32500.00, 'Bekliyor'),
(4, 'Dijital tanıtım içerik üretimi', 26, 'Fotoğraf ve video prodüksiyon', 'ONY-2026-008',
 '2026-03-20', '2026.Mar', 18000.00, 'Bekliyor');

-- ============================================================
-- 13. SPRINT_PERF_GOS (8 kayıt)
-- ============================================================

INSERT INTO sprint_perf_gos (sprint_faaliyet, sno, cg_kod, bilesen_adi, cikti_gostergesi,
    aciklama, birim, gerceklesme, tamamlanma_donemi, tamamlanma_tarihi, yil) VALUES
('Bölge ekonomik göstergeler raporu hazırlama (Q1)', 1, 'ÇGKDU11',
 'Ekonomik Analiz', 'Hazırlanan ekonomik analiz raporu',
 'Q1 bölge ekonomik göstergeler raporu teslim edildi', 'Rapor', 1.00, '2026/1', '2026-01-08', 2026),
('Turizm paydaş platformu toplantısı', 17, 'ÇGSTU21',
 'Paydaş Koordinasyon', 'Düzenlenen turizm toplantısı sayısı',
 'Ocak turizm platformu toplantısı gerçekleştirildi', 'Toplantı', 1.00, '2026/1', '2026-01-17', 2026),
('Girişimcilik temel eğitim modülü', 9, 'ÇGKDU31',
 'Kapasite Geliştirme', 'Eğitim/çalıştay katılımcı sayısı',
 'Ocak girişimcilik eğitimi 22 kişi ile tamamlandı', 'Kişi', 22.00, '2026/1', '2026-01-15', 2026),
('Uluslararası turizm fuarı katılım organizasyonu', 28, 'ÇGSTU42',
 'Uluslararası Fuar Katılımı', 'Katılınan uluslararası fuar/etkinlik sayısı',
 'Şubat 2026 uluslararası turizm fuarı katılımı', 'Adet', 1.00, '2026/1', '2026-02-06', 2026),
('Konaklama işletmeciliği eğitimi', 21, 'ÇGSTU31',
 'Turizm Kapasite Geliştirme', 'Eğitim alan katılımcı sayısı',
 'Konaklama işletmeciliği eğitimi 18 katılımcı', 'Kişi', 18.00, '2026/1', '2026-02-11', 2026),
('SoGreen proje yönetim kurulu toplantısı', 34, 'ÇGSOG11',
 'SoGreen Proje Yönetimi', 'Gerçekleştirilen proje yönetim kurulu toplantısı',
 'SoGreen Q1 YK toplantısı Ocak 2026', 'Toplantı', 1.00, '2026/1', '2026-01-24', 2026),
('SoGreen pilot uygulama alanı çalışmaları', 36, 'ÇGSOG12',
 'SoGreen Pilot Uygulama', 'Tamamlanan pilot uygulama sayısı',
 'İlk pilot uygulama alanı çalışmaları tamamlandı', 'Adet', 1.00, '2026/1', '2026-03-05', 2026),
('Rehberlik ve misafirperverllik eğitimi', 22, 'ÇGSTU32',
 'Turizm Rehber Eğitimi', 'Sertifikalı rehber sayısı',
 'Mart 2026 rehberlik eğitimi 15 katılımcı', 'Kişi', 15.00, '2026/1', '2026-03-04', 2026);

-- ============================================================
-- 14. İZİNLER (5 kayıt)
-- ============================================================

INSERT INTO izinler (izin_basl, izin_bitis, personel, aciklama, durum) VALUES
('2026-01-05', '2026-01-06', 'Zübeyde',  'Yıllık izin', 'Onaylandı'),
('2026-01-19', '2026-01-23', 'Oğuzhan',  'Yıllık izin', 'Onaylandı'),
('2026-01-26', '2026-01-30', 'Esen',     'Yıllık izin', 'Onaylandı'),
('2026-01-12', '2026-01-16', 'Nuray',    'Yıllık izin', 'Onaylandı'),
('2026-03-16', '2026-03-27', 'Zübeyde',  'Doğum izni',  'Onaylandı');

-- ============================================================
-- 15. SAHA_GOREVLERİ (5 kayıt)
-- ============================================================

INSERT INTO saha_gorevleri (tarih, personel, gorevli_il, aciklama, durum) VALUES
('2026-01-15', 'Elifnaz', 'Artvin',    'Proje izleme ziyareti - KDU501', 'Tamamlandı'),
('2026-02-05', 'Mehmet',  'Rize',      'Sektör koordinasyon toplantısı', 'Tamamlandı'),
('2026-02-10', 'Nuray',   'Trabzon',   'STU501 proje izleme', 'Tamamlandı'),
('2026-03-03', 'Oğuzhan', 'Ordu',      'KDU104 saha çalışması', 'Tamamlandı'),
('2026-03-10', 'Fatih',   'Gümüşhane', 'Yatırım ortamı inceleme ziyareti', 'Tamamlandı');
