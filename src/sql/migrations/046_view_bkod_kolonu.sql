-- ============================================================
-- Migration 046 — View'lara bkod kolonu (S4 / Birim Filtre Server-Side)
-- Tarih: 2026-05-19
--
-- Amaç:
--   Birim filtreli sayfalar (perf-ozet, faaliyetler, performans,
--   harcamalar, izinler, sprint-ozet) için kırılgan client-side
--   sopBkodMap[r.sop] === birimFilter filtresinden kurtul; sorgu
--   seviyesinde .eq('bkod', N) ile filtre yapılabilsin.
--
-- Yaklaşım:
--   1. v_perf_gosterge_ozet'e bkod ekle (zaten JOIN soplar s var)
--   2. v_faaliyet_ozet'e bkod ekle (JOIN soplar s ekle)
--   3. v_alt_faaliyet_ozet'e bkod ekle (JOIN faaliyetler→soplar)
--   4. v_harcama_ozet yeni view oluştur (harcamalar + sprint_is_plani.andaki_birim)
--   5. v_izin_ozet yeni view oluştur (izinler + personel.bkod)
--
-- Idempotency:
--   - 1-3: CREATE OR REPLACE VIEW (kolon SIRASI mevcut sonuna +bkod)
--   - 4-5: DROP VIEW IF EXISTS + CREATE VIEW (yeni view)
--
-- RLS:
--   - View RLS'i kaynak tabloların RLS'inden devralır; ekstra policy yok.
--   - View'lara security barrier eklemiyoruz; mevcut davranış korunur.
-- ============================================================

-- ──────────────────────────────────────────────────────────────
-- 1. v_perf_gosterge_ozet — bkod ekle
--    Kaynak: 027_rename_perf_columns.sql (en güncel)
--    JOIN soplar s ON s.skod = pg.skod  zaten var, sadece s.bkod SELECT
-- ──────────────────────────────────────────────────────────────

CREATE OR REPLACE VIEW v_perf_gosterge_ozet AS
SELECT
    pg.id,
    pg.cg_kod,
    pg.skod,
    pg.kkod,
    pg.pg_sira,
    pg.bilesen_kodu,
    pg.bilesen_adi,
    pg.cikti_gostergesi,
    pg.birim,
    pg.kumulatif_hedef,
    pg.planlanan_tamamlanma_donemi,
    pg.katki_sonuc_gostergesi,
    pg.aciklama,
    s.kisa                          AS sop,
    s.baslangic                     AS baslangic,
    s.bitis                         AS bitis,
    COALESCE(pgy_2024.hedef,        0) AS hedef_2024,
    COALESCE(pgy_2024.gerceklesen,  0) AS gerceklesen_2024,
    COALESCE(pgy_2025.hedef,        0) AS hedef_2025,
    COALESCE(pgy_2025.gerceklesen,  0) AS gerceklesen_2025,
    COALESCE(pgy_2026.hedef,        0) AS hedef_2026,
    COALESCE(spg_2026.toplam,       0) AS gerceklesen_2026,
    (COALESCE(pgy_2024.gerceklesen, 0)
     + COALESCE(pgy_2025.gerceklesen, 0)
     + COALESCE(spg_2026.toplam,    0)) AS kumulatif_gerceklesme,
    -- ── 046: birim filtre için bkod (server-side .eq('bkod', N) için) ──
    s.bkod                          AS bkod
FROM perf_gostergeler pg
LEFT JOIN soplar s
       ON s.skod = pg.skod
LEFT JOIN perf_gost_yillik pgy_2024
       ON pgy_2024.cg_kod = pg.cg_kod AND pgy_2024.yil = 2024
LEFT JOIN perf_gost_yillik pgy_2025
       ON pgy_2025.cg_kod = pg.cg_kod AND pgy_2025.yil = 2025
LEFT JOIN perf_gost_yillik pgy_2026
       ON pgy_2026.cg_kod = pg.cg_kod AND pgy_2026.yil = 2026
LEFT JOIN (
    SELECT cg_kod, SUM(gerceklesme) AS toplam
    FROM sprint_perf_gos
    WHERE yil = 2026
    GROUP BY cg_kod
) spg_2026 ON spg_2026.cg_kod = pg.cg_kod;

COMMENT ON VIEW v_perf_gosterge_ozet IS '027 + 046: PG özet view, birim filtre için bkod kolonu dahil';

-- ──────────────────────────────────────────────────────────────
-- 2. v_faaliyet_ozet — bkod ekle
--    Mevcut (016_rename_butce_column): JOIN soplar yok
--    Eklenen: LEFT JOIN soplar s ON s.skod = f.skod  →  s.bkod
-- ──────────────────────────────────────────────────────────────

DROP VIEW IF EXISTS v_faaliyet_ozet;
CREATE VIEW v_faaliyet_ozet AS
SELECT
    f.id,
    f.fkod,
    f.skod,
    f.kkod,
    f.faaliyet,
    f.sop_butce,
    AVG(vafo.is_durum_oran)               AS is_durum_ort,
    COALESCE(SUM(vafo.harcanan_butce), 0) AS harcanan_butce_toplam,
    -- ── 046: birim filtre için bkod ──
    s.bkod                                AS bkod
FROM faaliyetler f
LEFT JOIN v_alt_faaliyet_ozet vafo ON vafo.fkod = f.fkod
LEFT JOIN soplar s                ON s.skod    = f.skod
GROUP BY f.id, f.fkod, f.skod, f.kkod, f.faaliyet, f.sop_butce, s.bkod;

COMMENT ON VIEW v_faaliyet_ozet IS '016 + 046: faaliyet özet view, birim filtre için bkod kolonu dahil';

-- ──────────────────────────────────────────────────────────────
-- 3. v_alt_faaliyet_ozet — bkod ekle (faaliyetler → soplar üzerinden)
--    Mevcut (008_revisions2): JOIN soplar yok
--    Eklenen: LEFT JOIN faaliyetler ON fkod, LEFT JOIN soplar ON skod
--
--    Önemli: v_faaliyet_ozet, v_alt_faaliyet_ozet'i içeriyor.
--    PostgreSQL CREATE OR REPLACE VIEW dependent kolonları silmeye izin
--    vermiyor; ama biz EKLİYORUZ, silmiyoruz. Yine de DROP CASCADE
--    yerine sıralı DROP + CREATE kullanacağız.
-- ──────────────────────────────────────────────────────────────

-- v_faaliyet_ozet zaten yukarıda yeniden oluşturuldu, sıralı drop güvenli
DROP VIEW IF EXISTS v_faaliyet_ozet;
DROP VIEW IF EXISTS v_alt_faaliyet_ozet;

CREATE VIEW v_alt_faaliyet_ozet AS
SELECT
    af.sno,
    af.fkod,
    af.alt_faaliyet,
    af.anahtar_sonuclar,
    af.p_sure,
    af.tekrar_sayisi,
    COALESCE(af.p_sure * af.tekrar_sayisi, 0)                           AS is_yuku,
    COUNT(si.id)                                                         AS gerceklesme_sayi,
    COALESCE(SUM(si.gercek_sure), 0)                                    AS gercek_is_yuku,
    COALESCE(SUM(h.odenecek_kdvli), 0)                                  AS harcanan_butce,
    CASE
        WHEN af.tekrar_sayisi > 0
        THEN ROUND(COUNT(si.id)::DECIMAL / af.tekrar_sayisi::NUMERIC, 2)
        ELSE NULL
    END                                                                  AS is_durum_oran,
    -- ── 046: birim filtre için bkod ──
    s.bkod                                                              AS bkod
FROM alt_faaliyetler af
LEFT JOIN sprint_is_plani si ON si.sno = af.sno
LEFT JOIN harcamalar h        ON h.sprint_is_plani_id = si.id
LEFT JOIN faaliyetler f       ON f.fkod = af.fkod
LEFT JOIN soplar s            ON s.skod = f.skod
GROUP BY af.sno, af.fkod, af.alt_faaliyet, af.anahtar_sonuclar,
         af.p_sure, af.tekrar_sayisi, s.bkod;

COMMENT ON VIEW v_alt_faaliyet_ozet IS '008 + 046: alt faaliyet özet view, birim filtre için bkod kolonu dahil';

-- v_faaliyet_ozet'i (alt_faaliyet'e bağımlı olduğu için) yeniden oluştur
CREATE VIEW v_faaliyet_ozet AS
SELECT
    f.id,
    f.fkod,
    f.skod,
    f.kkod,
    f.faaliyet,
    f.sop_butce,
    AVG(vafo.is_durum_oran)               AS is_durum_ort,
    COALESCE(SUM(vafo.harcanan_butce), 0) AS harcanan_butce_toplam,
    s.bkod                                AS bkod
FROM faaliyetler f
LEFT JOIN v_alt_faaliyet_ozet vafo ON vafo.fkod = f.fkod
LEFT JOIN soplar s                ON s.skod    = f.skod
GROUP BY f.id, f.fkod, f.skod, f.kkod, f.faaliyet, f.sop_butce, s.bkod;

COMMENT ON VIEW v_faaliyet_ozet IS '016 + 046: faaliyet özet view, birim filtre için bkod kolonu dahil';

-- ──────────────────────────────────────────────────────────────
-- 4. v_harcama_ozet — yeni view
--    Frontend (harcamalar.html) doğrudan harcamalar tablosundan okuyor;
--    birim filtresi yapabilmek için sprint_is_plani.andaki_birim üzerinden
--    bkod, ayrıca isim eşleme için sprint_faaliyet bilgisi sağlanıyor.
-- ──────────────────────────────────────────────────────────────

DROP VIEW IF EXISTS v_harcama_ozet;
CREATE VIEW v_harcama_ozet AS
SELECT
    h.id,
    h.sprint_donem,
    h.sprint_faaliyet,
    h.sno,
    h.aciklama,
    h.harcama_onay_kodu,
    h.onay_tarihi,
    h.odeme_donem,
    h.odenecek_kdvli,
    h.durum,
    h.guncel_tarih,
    h.guncelleyen,
    h.created_at,
    h.sprint_is_plani_id,
    -- ── 046: birim filtre için bkod (sprint_is_plani.andaki_birim) ──
    sip.andaki_birim                AS bkod,
    sip.pkod                        AS pkod
FROM harcamalar h
LEFT JOIN sprint_is_plani sip ON sip.id = h.sprint_is_plani_id;

COMMENT ON VIEW v_harcama_ozet IS '046: harcamalar özet view; bkod = sprint_is_plani.andaki_birim';

-- ──────────────────────────────────────────────────────────────
-- 5. v_izin_ozet — yeni view
--    Frontend (izinler.html) doğrudan izinler tablosundan okuyor;
--    birim filtresi yapabilmek için personel.bkod üzerinden bkod.
-- ──────────────────────────────────────────────────────────────

DROP VIEW IF EXISTS v_izin_ozet;
CREATE VIEW v_izin_ozet AS
SELECT
    iz.id,
    iz.izin_basl,
    iz.izin_bitis,
    iz.pkod,
    iz.aciklama,
    iz.durum,
    iz.izin_gun_sayi,
    iz.tur,
    iz.created_at,
    -- ── 046: birim filtre için bkod (personel.bkod) ──
    p.bkod                          AS bkod
FROM izinler iz
LEFT JOIN personel p ON p.pkod = iz.pkod;

COMMENT ON VIEW v_izin_ozet IS '046: izinler özet view; bkod = personel.bkod (izin sahibi)';

-- ──────────────────────────────────────────────────────────────
-- 6. DOĞRULAMA SORGULARI (yorum satırı, manuel)
-- ──────────────────────────────────────────────────────────────
-- SELECT bkod FROM v_perf_gosterge_ozet LIMIT 1;
-- SELECT bkod FROM v_faaliyet_ozet LIMIT 1;
-- SELECT bkod FROM v_alt_faaliyet_ozet LIMIT 1;
-- SELECT bkod FROM v_harcama_ozet LIMIT 1;
-- SELECT bkod FROM v_izin_ozet LIMIT 1;
-- ──────────────────────────────────────────────────────────────
