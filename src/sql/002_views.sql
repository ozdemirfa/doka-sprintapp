-- UTF-8 | Sprint Kanban | Hesaplanan alan view'ları
-- TR90 Kalkınma Ajansı Sprint Kanban Projesi
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
