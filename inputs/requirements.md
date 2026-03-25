# Sprint Kanban — Web Uygulaması Gereksinim Dokümanı

> **Hedef:** Excel tabanlı sprint yönetim sistemini Supabase + Vanilla JS web uygulamasına dönüştürmek
> **Tarih:** 2026-03-25

---

## 1. PROJE ÖZETİ

TR90 Kalkınma Ajansı, SOP (Sonuç Odaklı Program) bazlı faaliyetlerini 3 haftalık sprint döngüleriyle yönetiyor. Mevcut sistem bir Excel (.xlsm) dosyasında VBA makrolarıyla çalışıyor. Bu proje, sistemi çok kullanıcılı, gerçek zamanlı bir web uygulamasına taşıyacak.

### 1.1 Temel Kullanıcı Hikayeleri

- Scrum Master (Fatih) sprint iş planını oluşturur, görevleri ekip üyelerine atar
- Ekip üyeleri (Zübeyde, Elifnaz, Mehmet, Oğuzhan, Nuray, Esen, Fatih) görevlerini Kanban board üzerinde sürükleyerek durumlarını günceller
- Sprint sonunda retrospektif puanlar girilir, GKİ ve Hepiniss otomatik hesaplanır
- Yönetim, performans göstergelerini ve bütçe durumunu dashboard üzerinden izler

---

## 2. VERİTABANI ŞEMASI

Excel dosyasında 14 sayfa (tablo) bulunmaktadır. Aşağıda her tablonun tam yapısı, alanları, veri tipleri ve ilişkileri detaylıca açıklanmıştır.

### 2.1 Lookup Tabloları

#### `birimler` (Kaynak: Listeler sayfası, A-D sütunları)

| Alan | Tip | Kısıtlama | Açıklama |
|------|-----|-----------|----------|
| bkod | INTEGER | PK | Birim kodu |
| birim_kisa | VARCHAR(10) | NOT NULL, UNIQUE | Kısa ad (SKB, MEKB, KYİKB, PİDB) |
| birim_adi | VARCHAR(100) | NOT NULL | Tam ad |
| durum | VARCHAR(10) | DEFAULT 'Aktif' | Aktif / Pasif |

**Mevcut Veri (4 kayıt):**
- 1: SKB — Sürdürülebilir Kalkınma
- 2: MEKB — Mavi Ekonomi
- 3: KYİKB — Kurumsal Yönetim ve İnsan Kaynakları
- 4: PİDB — Program İzleme ve Değerlendirme

#### `soplar` (Kaynak: Listeler sayfası, F-L sütunları)

| Alan | Tip | Kısıtlama | Açıklama |
|------|-----|-----------|----------|
| skod | INTEGER | PK | SOP kodu |
| kisa | VARCHAR(10) | NOT NULL, UNIQUE | Kısa ad (STU, KDU, MEK, YKF, SOPD, BAK, AB, SOG) |
| sop_adi | VARCHAR(100) | NOT NULL | Tam program adı |
| baslangic | INTEGER | | Başlangıç yılı |
| bitis | INTEGER | | Bitiş yılı |
| bkod | INTEGER | FK → birimler.bkod | Bağlı birim |
| durum | VARCHAR(10) | DEFAULT 'Aktif' | |

**Mevcut Veri (8 kayıt):**
- 1: STU — Sürdürülebilir Turizm (Birim: SKB)
- 2: KDU — Katma Değerli Üretim ve Ticarileşme (Birim: SKB)
- 3: MEK — Mavi Ekonomi (Birim: MEKB)
- 4: YKF — Yerel Kalkınma Fırsatları (Birim: KYİKB)
- 5: SOPD — SOP dışı diğer işler
- 6: BAK — Bakanlık Talepleri
- 7: AB — Avrupa Birliği Projeleri
- 8: SOG — SoGreen Programı

#### `kategoriler` (Kaynak: Listeler sayfası, N-P sütunları)

| Alan | Tip | Kısıtlama | Açıklama |
|------|-----|-----------|----------|
| skod | INTEGER | PK (composite), FK → soplar.skod | |
| kkod | INTEGER | PK (composite) | Kategori kodu |
| kategori_adi | VARCHAR(200) | NOT NULL | |

**Mevcut Veri (5 standart kategori, SOP bazında tekrarlanır):**
1. Araştırma, Analiz ve Raporlama
2. İşbirliği ve Koordinasyon Faaliyetleri
3. Kapasite Geliştirme Faaliyetleri
4. Tanıtım ve Yatırım Destek Faaliyetleri
5. Destek Programları

#### `personel` (Kaynak: Listeler sayfası, R-V sütunları)

| Alan | Tip | Kısıtlama | Açıklama |
|------|-----|-----------|----------|
| pkod | INTEGER | PK | Personel kodu |
| ad | VARCHAR(50) | NOT NULL | |
| soyad | VARCHAR(50) | NOT NULL | |
| bkod | INTEGER | FK → birimler.bkod | Bağlı birim |
| durum | VARCHAR(10) | DEFAULT 'Aktif' | |
| auth_id | UUID | FK → auth.users.id, UNIQUE | Supabase Auth eşleşmesi |

**Mevcut Veri (7 kayıt):**
- 1: Zübeyde Altun (Birim: 1-SKB)
- 2: Elifnaz Akdeniz (Birim: 1-SKB)
- 3: Mehmet Sezgin (Birim: 1-SKB)
- 4: Oğuzhan Şatır (Birim: 1-SKB)
- 5: Esen Baylan (Birim: 1-SKB)
- 6: Nuray Efendioğlu (Birim: 1-SKB)
- 7: Fatih Özdemir (Birim: 1-SKB)

---

### 2.2 Ana İş Tabloları

#### `faaliyetler` (Kaynak: Faaliyetler sayfası — 30 kayıt)

| Alan | Tip | Kısıtlama | Açıklama |
|------|-----|-----------|----------|
| fkod | VARCHAR(10) | PK | Faaliyet kodu (ör: KDU101, STU401) |
| sop | VARCHAR(10) | FK → soplar.kisa | SOP kısa kodu |
| kategori | VARCHAR(200) | | Kategori adı |
| faaliyet | VARCHAR(500) | NOT NULL | Faaliyet açıklaması |
| butce_2026 | DECIMAL(15,2) | DEFAULT 0 | 2026 yılı bütçesi (TL) |
| oca–ara | BOOLEAN/INTEGER | | Aylık plan (12 sütun) — her ay için planlama bayrağı |

**Hesaplanan Alanlar (Excel formülleri → SQL view):**
- `is_durum` = AltFaaliyetler tablosundaki İşDurum ortalaması (AVERAGEIFS)
  - Excel: `=IFERROR(AVERAGEIFS(tblAltFaaliyetler[İşDurum], tblAltFaaliyetler[Fkod], [Fkod]), "-")`
- `harcanan_butce` = AltFaaliyetler tablosundaki HarcananBütçe toplamı (SUMIFS)
  - Excel: `=SUMIFS(tblAltFaaliyetler[HarcananBütçe], tblAltFaaliyetler[Fkod], [Fkod])`

**Aylık Planlama Yaklaşımı:**
Excel'de H-S sütunları (Oca-Ara) aylık faaliyet planlamasını gösteriyor. PostgreSQL'de bu ya JSONB alanı ya da ayrı `faaliyet_aylik_plan(fkod, ay, deger)` tablosu olarak modellenebilir. **Tercih: JSONB** — `aylik_plan JSONB DEFAULT '{}'` şeklinde `{"oca": 1, "sub": 0, ...}` formatında.

**Mevcut Fkod'lar ve Bütçeler:**
- KDU101, KDU103 (₺1M), KDU108 (₺5M), KDU204, KDU205 (₺500K), KDU301 (₺2M), KDU302 (₺1M), KDU304 (₺3M), KDU305 (₺2M), KDU406 (₺2M), KDU407 (₺500K), KDU501 (₺20M)
- STU101 (₺14M), STU102 (₺2M), STU103 (₺11M), STU104 (₺10M), STU201 (₺4M), STU301 (₺1M), STU302 (₺1M), STU401 (₺3M), STU402 (₺7M), STU403 (₺3M), STU404 (₺2M), STU405 (₺2M), STU501 (₺10M), STU502 (₺0)
- SOG001 (₺40M), AB0001, BAK001, SOPD01 (bütçesiz)

#### `alt_faaliyetler` (Kaynak: AltFaaliyetler sayfası — 53 kayıt)

| Alan | Tip | Kısıtlama | Açıklama |
|------|-----|-----------|----------|
| sno | INTEGER | PK | Sıra numarası (unique) |
| fkod | VARCHAR(10) | FK → faaliyetler.fkod | Bağlı faaliyet |
| sop | VARCHAR(10) | | SOP kısa kodu |
| kategori | VARCHAR(200) | | |
| faaliyet | VARCHAR(500) | | Ana faaliyet adı |
| alt_faaliyet | VARCHAR(500) | NOT NULL | Alt faaliyet açıklaması |
| anahtar_sonuclar | TEXT | | Beklenen anahtar sonuçlar |
| p_sure | DECIMAL(5,1) | | Planlanan süre (gün) |
| tekrar_sayisi | INTEGER | | Yıl içi tekrar sayısı |

**Hesaplanan Alanlar (SQL view):**
- `is_yuku` = p_sure × tekrar_sayisi
  - Excel: `=H*I`
- `gerceklesme_sayi` = SprintİşPlanı'nda "Tamamlandı" durumundaki kayıt sayısı
  - Excel: `=COUNTIFS(tblSprintİşPlanı[S.No], [S.No], tblSprintİşPlanı[İşDurum], "Tamamlandı")`
- `gercek_is_yuku` = SprintİşPlanı'ndaki GerçekSüre toplamı
  - Excel: `=SUMIFS(tblSprintİşPlanı[GerçekSüre], tblSprintİşPlanı[S.No], [S.No])`
- `is_durum` = GerçekleşmeSayı / TekrarSayısı (0-1 arası oran)
  - Excel: `=IFERROR([GerçekleşmeSayı]/[Tekrar Sayısı], "-")`
- `harcanan_butce` = Harcamalar tablosundaki toplam
  - Excel: `=SUMIFS(tblHarcamalar[ÖdenecekKDVli], tblHarcamalar[S.No], [S.No])`

#### `sprint_veri` (Kaynak: SprintVeri sayfası — 17 dönem tanımlı, 4'ü aktif)

| Alan | Tip | Kısıtlama | Açıklama |
|------|-----|-----------|----------|
| sprint_donem | INTEGER | PK | Sprint dönem numarası (1, 2, 3, ...) |
| baslangic | DATE | NOT NULL | Sprint başlangıç tarihi |
| bitis | DATE | NOT NULL | Sprint bitiş tarihi |
| sprint_adi | VARCHAR(50) | | Sprint ismi (ör: Middle, Zemu, Maison, House) |
| isim_veren | VARCHAR(50) | | İsmi veren kişi |
| sure_gun | INTEGER | | Sprint süresi (gün cinsinden, genellikle 14 veya 20) |
| ekip | INTEGER | | Ekip üye sayısı |
| izin | INTEGER | DEFAULT 0 | Toplam izin gün sayısı |
| saha | INTEGER | DEFAULT 0 | Toplam saha görev gün sayısı |

**Sprint Döngüsü Hesaplama (otomatik):**
- Başlangıç = Önceki sprint bitiş + 3 gün
  - Excel: `=C[önceki]+3`
- Bitiş = Başlangıç + 18 gün
  - Excel: `=[Başlangıç]+18`

**Hesaplanan Alanlar (SQL view `v_sprint_ozet`):**
- `org_puan` = SprintRetro'daki OrganizasyonPuan ortalaması
  - Excel: `=IFERROR(AVERAGEIFS(tblSprintRetro[OrganizasyonPuan], tblSprintRetro[SprintToplantı], [Bitiş]), "")`
- `hepiniss` = SprintRetro'daki G.ort ortalaması
  - Excel: `=IFERROR(AVERAGEIFS(tblSprintRetro[G.ort], tblSprintRetro[SprintToplantı], [Bitiş]), "")`
- `t_skor` = Tamamlanan görevlerin PlanSüre toplamı
  - Excel: `=SUMIFS(tblSprintİşPlanı[PlanSüre], tblSprintİşPlanı[İşDurum], "Tamamlandı", tblSprintİşPlanı[BitişDönem], [SprintDönem])`
- `gki` = T.Skor / (Süre × Ekip - İzin) × 100
  - Excel: `=IFERROR([T.Skor]/([Süre (gün)]*[Ekip]-[İzin])*100, "")`
- `plan` = Sprint'teki tüm görevlerin PlanSüre toplamı
  - Excel: `=SUMIFS(tblSprintİşPlanı[PlanSüre], tblSprintİşPlanı[SprintDönem], [SprintDönem])`
- `gerceklesme` = Tamamlanan görevlerin GerçekSüre toplamı
  - Excel: `=SUMIFS(tblSprintİşPlanı[GerçekSüre], tblSprintİşPlanı[İşDurum], "Tamamlandı", tblSprintİşPlanı[BitişDönem], [SprintDönem])`

**Mevcut Veri (ilk 4 sprint):**
| Dönem | Tarih | Ad | Süre | Ekip | GKİ | Plan | T.Skor | İzin |
|-------|-------|----|------|------|-----|------|--------|------|
| 1 | 01.01-30.01.2026 | Middle | 20 gün | 4 | 98.5 | 83 | 66 | 13 |
| 2 | 02.02-20.02.2026 | Zemu | 14 gün | 5 | 86.8 | 67 | 59 | 2 |
| 3 | 23.02-13.03.2026 | Maison | 14 gün | 5 | 97.1 | 63 | 66 | 2 |
| 4 | 16.03-03.04.2026 | House | 14 gün | 5 | 9.3 | 30 | 5 | 16 |

#### `sprint_is_plani` ⭐ (Kaynak: SprintİşPlanı sayfası — 102 kayıt, **ANA KANBAN TABLOSU**)

| Alan | Tip | Kısıtlama | Açıklama |
|------|-----|-----------|----------|
| id | SERIAL | PK | Otomatik artan ID |
| sprint_donem | INTEGER | FK → sprint_veri.sprint_donem | Görevin ait olduğu sprint |
| bitis_donem | INTEGER | | Görevin tamamlandığı/bitirildiği sprint dönemi |
| sprint_faaliyetleri | VARCHAR(500) | NOT NULL | Görev açıklaması |
| sno | INTEGER | FK → alt_faaliyetler.sno | Bağlı alt faaliyet |
| plan_sure | DECIMAL(5,1) | | Planlanan süre (gün) |
| is_durum | VARCHAR(20) | | Kanban durumu — **aşağıya bakınız** |
| baslama_t | DATE | | Başlama tarihi |
| inceleme_t | DATE | | İncelemeye alınma tarihi |
| tamamlanma_t | DATE | | Tamamlanma tarihi |
| ekip_uyesi | VARCHAR(50) | | Atanan ekip üyesi adı |
| gercek_sure | DECIMAL(5,1) | | Gerçekleşen süre (gün) |
| guncel_tarih | DATE | | Son güncelleme tarihi |
| guncelleyen | VARCHAR(50) | | Son güncelleyen kullanıcı (ör: fatih.ozdemir) |
| performans_gostergeler | TEXT | | İlişkili performans göstergeleri |

**Hesaplanan Alan:**
- `harcanan_butce` = Harcamalar tablosundan çekilen toplam
  - Excel: `=SUMIFS(tblHarcamalar[ÖdenecekKDVli], tblHarcamalar[S.No], [S.No], tblHarcamalar[SprintDönem], [SprintDönem], tblHarcamalar[Sprint Faaliyet], [Sprint Faaliyetleri])`

**İşDurum (Kanban Kolonları) — ENUM:**
```
'Başladı'      → Kanban: "Devam Ediyor"
'İncelemede'   → Kanban: "İncelemede"
'Tamamlandı'   → Kanban: "Tamamlandı"
NULL           → Kanban: "Backlog"
```

**Mevcut Dağılım (102 kayıt):**
- Sprint 1: ~35 görev (tümü Tamamlandı)
- Sprint 2: ~30 görev (büyük çoğunluğu Tamamlandı)
- Sprint 3: ~25 görev (karışık durumlar)
- Sprint 4: ~12 görev (çoğu henüz başlamamış)

**EkipÜyesi Dağılımı:** Elifnaz, Zübeyde, Mehmet, Oğuzhan, Nuray, Fatih

#### `harcamalar` (Kaynak: Harcamalar sayfası — 8 kayıt)

| Alan | Tip | Kısıtlama | Açıklama |
|------|-----|-----------|----------|
| id | SERIAL | PK | |
| sprint_donem | INTEGER | FK → sprint_veri.sprint_donem | |
| sprint_faaliyet | VARCHAR(500) | | Faaliyet açıklaması |
| sno | INTEGER | FK → alt_faaliyetler.sno | |
| aciklama | TEXT | | Ek açıklama |
| harcama_onay_kodu | VARCHAR(20) | | Onay belge numarası |
| onay_tarihi | DATE | | |
| odeme_donem | VARCHAR(20) | | Ödeme dönemi (ör: 2026.Oca, 2026.Sub) |
| odenecek_kdvli | DECIMAL(15,2) | NOT NULL | KDV dahil tutar (TL) |
| guncel_tarih | DATE | | |
| guncelleyen | VARCHAR(50) | | |
| durum | VARCHAR(20) | | |

**Doğrulama Formülü (dashboard'da gösterilecek):**
- `fark` = SUM(sprint_is_plani.harcanan_butce) - SUM(harcamalar.odenecek_kdvli)
  - Excel: `=SUM(tblSprintİşPlanı[HarcananBütçe])-SUM(tblHarcamalar[ÖdenecekKDVli])`

#### `perf_gostergeler` (Kaynak: PerfGösterge sayfası — 28 kayıt)

| Alan | Tip | Kısıtlama | Açıklama |
|------|-----|-----------|----------|
| cg_kod | VARCHAR(20) | PK | Çıktı göstergesi kodu (ör: ÇGSTU11, ÇGKDU21) |
| sop | VARCHAR(10) | FK → soplar.kisa | |
| bilesen_kodu | VARCHAR(10) | | Bileşen numarası (ör: 1.1., 1.2.) |
| bilesen_adi | VARCHAR(500) | | |
| cikti_gostergesi | VARCHAR(500) | | Gösterge açıklaması |
| birim | VARCHAR(20) | | Ölçü birimi (Adet, Rapor, vb.) |
| hedef | DECIMAL(10,2) | | Toplam hedef değer |
| tamamlanma_donemi | VARCHAR(10) | | Hedef tamamlanma dönemi (ör: 2026/4) |
| katki_sonuc_gostergesi | VARCHAR(500) | | |
| hedef_2024 | DECIMAL(10,2) | | |
| hedef_2025 | DECIMAL(10,2) | | |
| hedef_2026 | DECIMAL(10,2) | | |
| gerceklesen_2024 | DECIMAL(10,2) | | |
| gerceklesen_2025 | DECIMAL(10,2) | | |

**Hesaplanan Alanlar:**
- `kumulatif_gerceklesme` = gerceklesen_2024 + gerceklesen_2025 + gerceklesen_2026
  - Excel: `=[2024]+[2025]+[2026]`
- `gerceklesen_2026` = SprintPerfGös tablosundan SUMIFS
  - Excel: `=SUMIFS(tblSprintPerfGös[Gerçekleşme], tblSprintPerfGös[ÇGKod], [ÇGKod], tblSprintPerfGös[Yıl], 2026)`

#### `sprint_perf_gos` (Kaynak: SprintPerfGös sayfası — 8 kayıt)

| Alan | Tip | Kısıtlama | Açıklama |
|------|-----|-----------|----------|
| id | SERIAL | PK | |
| sprint_faaliyet | VARCHAR(500) | | Hangi sprint faaliyetinden geldiği |
| sno | INTEGER | FK → alt_faaliyetler.sno | |
| cg_kod | VARCHAR(20) | FK → perf_gostergeler.cg_kod | |
| bilesen_adi | VARCHAR(500) | | |
| cikti_gostergesi | VARCHAR(500) | | |
| aciklama | TEXT | | Gerçekleşme açıklaması |
| birim | VARCHAR(20) | | |
| gerceklesme | DECIMAL(10,2) | | Gerçekleşme miktarı |
| tamamlanma_donemi | VARCHAR(10) | | Çeyrek/dönem (ör: 2026/1) |
| tamamlanma_tarihi | DATE | | |
| yil | INTEGER | | Yıl (2026) |

#### `izinler` (Kaynak: İzinler sayfası — 5 kayıt)

| Alan | Tip | Kısıtlama | Açıklama |
|------|-----|-----------|----------|
| id | SERIAL | PK | |
| izin_basl | DATE | NOT NULL | İzin başlangıcı |
| izin_bitis | DATE | NOT NULL | İzin bitişi |
| personel | VARCHAR(50) | | Personel adı |
| aciklama | VARCHAR(200) | | İzin türü (Yıllık izin vb.) |
| durum | VARCHAR(20) | | |

#### `saha_gorevleri` (Kaynak: TR90Saha sayfası — 5 kayıt)

| Alan | Tip | Kısıtlama | Açıklama |
|------|-----|-----------|----------|
| id | SERIAL | PK | |
| tarih | DATE | NOT NULL | Görev tarihi |
| personel | VARCHAR(50) | | |
| gorevli_il | VARCHAR(50) | | İl adı (Artvin, Rize, Ordu, Gümüşhane vb.) |
| aciklama | TEXT | | |
| durum | VARCHAR(20) | | |

#### `anahtar_sonuclar` (Kaynak: AnahtarSonuclar sayfası — 91 kayıt)

| Alan | Tip | Kısıtlama | Açıklama |
|------|-----|-----------|----------|
| sno | INTEGER | PK (composite), FK → alt_faaliyetler.sno | Alt faaliyet sıra no |
| as_no | INTEGER | PK (composite) | Anahtar sonuç sıra no |
| anahtar_sonuc | VARCHAR(500) | NOT NULL | Sonuç açıklaması |
| durum | VARCHAR(20) | DEFAULT 'Aktif' | |

#### `sprint_retro` (Kaynak: SprintRetro sayfası — 29 kayıt)

| Alan | Tip | Kısıtlama | Açıklama |
|------|-----|-----------|----------|
| id | SERIAL | PK | |
| tarih | TIMESTAMP | | Yanıt zamanı |
| ad | VARCHAR(50) | | Personel adı |
| sprint_toplanti | DATE | | Sprint toplantı tarihi (sprint_veri.bitis ile eşleşir) |
| organizasyon_puan | INTEGER | | 1-10 arası organizasyon puanı |
| ajanstaki_rolu | INTEGER | | 1-10 arası rol memnuniyeti |
| ajans_hakkinda | INTEGER | | 1-10 arası genel memnuniyet |
| durum | VARCHAR(20) | | |

**Hesaplanan Alan:**
- `g_ort` = GEOMEAN(ajanstaki_rolu, ajans_hakkinda)
  - Excel: `=GEOMEAN([AjanstakiRolü], [AjansHakkında])`
  - PostgreSQL: `SQRT(ajanstaki_rolu * ajans_hakkinda)`

---

## 3. HESAPLANAN ALANLAR — SQL VIEWS

Aşağıdaki view'lar Excel'deki formül mantığını birebir web'e taşır.

### 3.1 `v_sprint_ozet` (SprintVeri hesaplamaları)

```sql
CREATE OR REPLACE VIEW v_sprint_ozet AS
SELECT
  sv.sprint_donem,
  sv.baslangic,
  sv.bitis,
  sv.sprint_adi,
  sv.sure_gun,
  sv.ekip,
  sv.izin,
  sv.saha,
  -- OrgPuan: SprintRetro'dan OrganizasyonPuan ortalaması
  AVG(sr.organizasyon_puan) AS org_puan,
  -- Hepiniss: SprintRetro'dan geometrik ortalama ortalaması
  AVG(SQRT(sr.ajanstaki_rolu * sr.ajans_hakkinda)) AS hepiniss,
  -- T.Skor: Tamamlanan görevlerin plan süre toplamı
  COALESCE(SUM(CASE WHEN sip.is_durum = 'Tamamlandı' AND sip.bitis_donem = sv.sprint_donem
    THEN sip.plan_sure END), 0) AS t_skor,
  -- GKİ: T.Skor / (Süre × Ekip - İzin) × 100
  CASE WHEN (sv.sure_gun * sv.ekip - COALESCE(sv.izin, 0)) > 0
    THEN COALESCE(SUM(CASE WHEN sip.is_durum = 'Tamamlandı' AND sip.bitis_donem = sv.sprint_donem
      THEN sip.plan_sure END), 0)::float
      / (sv.sure_gun * sv.ekip - COALESCE(sv.izin, 0)) * 100
    ELSE 0 END AS gki,
  -- Plan: Sprint'teki tüm görevlerin plan süre toplamı
  COALESCE(SUM(sip.plan_sure), 0) AS plan_toplam,
  -- Gerçekleşme: Tamamlanan görevlerin gerçek süre toplamı
  COALESCE(SUM(CASE WHEN sip.is_durum = 'Tamamlandı' AND sip.bitis_donem = sv.sprint_donem
    THEN sip.gercek_sure END), 0) AS gerceklesme
FROM sprint_veri sv
LEFT JOIN sprint_is_plani sip ON sip.sprint_donem = sv.sprint_donem
LEFT JOIN sprint_retro sr ON sr.sprint_toplanti = sv.bitis
GROUP BY sv.sprint_donem, sv.baslangic, sv.bitis, sv.sprint_adi,
         sv.sure_gun, sv.ekip, sv.izin, sv.saha;
```

### 3.2 `v_alt_faaliyet_ozet` (AltFaaliyetler hesaplamaları)

```sql
CREATE OR REPLACE VIEW v_alt_faaliyet_ozet AS
SELECT
  af.sno,
  af.fkod,
  af.alt_faaliyet,
  af.p_sure,
  af.tekrar_sayisi,
  COALESCE(af.p_sure * af.tekrar_sayisi, 0) AS is_yuku,
  COUNT(CASE WHEN sip.is_durum = 'Tamamlandı' THEN 1 END) AS gerceklesme_sayi,
  COALESCE(SUM(sip.gercek_sure), 0) AS gercek_is_yuku,
  CASE WHEN af.tekrar_sayisi > 0
    THEN COUNT(CASE WHEN sip.is_durum = 'Tamamlandı' THEN 1 END)::float / af.tekrar_sayisi
    ELSE NULL END AS is_durum_oran,
  COALESCE(SUM(h.odenecek_kdvli), 0) AS harcanan_butce
FROM alt_faaliyetler af
LEFT JOIN sprint_is_plani sip ON sip.sno = af.sno
LEFT JOIN harcamalar h ON h.sno = af.sno
GROUP BY af.sno, af.fkod, af.alt_faaliyet, af.p_sure, af.tekrar_sayisi;
```

### 3.3 `v_faaliyet_ozet` (Faaliyetler hesaplamaları)

```sql
CREATE OR REPLACE VIEW v_faaliyet_ozet AS
SELECT
  f.fkod,
  f.sop,
  f.faaliyet,
  f.butce_2026,
  AVG(vafo.is_durum_oran) AS is_durum_ort,
  SUM(vafo.harcanan_butce) AS harcanan_butce_toplam
FROM faaliyetler f
LEFT JOIN v_alt_faaliyet_ozet vafo ON vafo.fkod = f.fkod
GROUP BY f.fkod, f.sop, f.faaliyet, f.butce_2026;
```

### 3.4 `v_perf_gosterge_ozet` (PerfGösterge hesaplamaları)

```sql
CREATE OR REPLACE VIEW v_perf_gosterge_ozet AS
SELECT
  pg.*,
  (COALESCE(pg.gerceklesen_2024, 0) + COALESCE(pg.gerceklesen_2025, 0)
   + COALESCE(spg_2026.toplam, 0)) AS kumulatif_gerceklesme,
  COALESCE(spg_2026.toplam, 0) AS gerceklesen_2026
FROM perf_gostergeler pg
LEFT JOIN (
  SELECT cg_kod, SUM(gerceklesme) AS toplam
  FROM sprint_perf_gos WHERE yil = 2026
  GROUP BY cg_kod
) spg_2026 ON spg_2026.cg_kod = pg.cg_kod;
```

---

## 4. SAYFA VE FONKSİYON GEREKSİNİMLERİ

### 4.1 Ana Sayfa — Kanban Board (`index.html`) ⭐ KRİTİK

**Veri Kaynağı:** `sprint_is_plani` tablosu

**4 Kolon:**
1. **Backlog** — `is_durum IS NULL`
2. **Devam Ediyor** — `is_durum = 'Başladı'`
3. **İncelemede** — `is_durum = 'İncelemede'`
4. **Tamamlandı** — `is_durum = 'Tamamlandı'`

**Kart İçeriği:**
- Sprint Faaliyeti adı (başlık)
- S.No (alt faaliyet referansı)
- PlanSüre (gün)
- EkipÜyesi (avatar veya isim)
- BaşlamaT / TamamlanmaT tarihleri
- HarcananBütçe (varsa)

**Etkileşimler:**
- Drag & drop ile kolon değiştirme → `is_durum` güncellenir
- Kolon değiştiğinde otomatik tarih ataması:
  - Backlog → Başladı: `baslama_t = NOW()`
  - Başladı → İncelemede: `inceleme_t = NOW()`
  - İncelemede → Tamamlandı: `tamamlanma_t = NOW()`
- Sprint dönemi dropdown filtresi (sprint_veri tablosundan)
- EkipÜyesi filtresi
- Yeni görev ekleme modal'ı
- Görev detay modal'ı (düzenleme)
- `guncel_tarih` ve `guncelleyen` her güncelleme sırasında otomatik set edilir

**Realtime:** Supabase Realtime subscription ile çoklu kullanıcı — bir kişi kartı sürüklediğinde diğer kullanıcılar anlık güncellemeyi görür.

### 4.2 Faaliyetler Sayfası (`pages/faaliyetler.html`)

**Veri Kaynağı:** `v_faaliyet_ozet` view, `alt_faaliyetler`, `anahtar_sonuclar`

**Özellikler:**
- SOP bazında gruplanmış faaliyet listesi (tree/accordion yapısı)
- Her faaliyet altında: alt faaliyetler listesi
- Her alt faaliyet yanında: İşDurum progress bar (0-100%)
- Bütçe kolonları: 2026Bütçe vs HarcananBütçe (bar chart veya progress)
- Aylık plan takvimi (Oca-Ara — faaliyet bazlı Gantt-benzeri görünüm)
- Anahtar sonuçlar accordion'u (alt faaliyet detayında)
- Yeni faaliyet / alt faaliyet ekleme

### 4.3 Performans Dashboard (`pages/performans.html`)

**Veri Kaynağı:** `v_perf_gosterge_ozet` view, `sprint_perf_gos`

**Özellikler:**
- SOP bazında performans göstergeleri tablosu
- Hedef vs Gerçekleşme bar chart (yıl bazlı: 2024, 2025, 2026)
- Kümülatif ilerleme göstergesi (gauge chart veya progress ring)
- Sprint bazlı performans girdisi ekleme formu
- Tamamlanma dönemi takibi (2026/1, 2026/2, 2026/3, 2026/4)

### 4.4 Sprint Özet Sayfası (`pages/sprint-ozet.html`)

**Veri Kaynağı:** `v_sprint_ozet` view

**Özellikler:**
- Sprint dönemleri tablosu (tüm metriklerle)
- **GKİ Trend Grafiği** — çizgi grafik (mevcut Excel'de Grf.GKİ chart sheet olarak var)
- **Hepiniss Trend Grafiği** — sprint bazlı çizgi grafik
- Plan vs Gerçekleşme karşılaştırma grafiği (bar chart)
- OrgPuan trend grafiği
- Sprint karşılaştırma metrikleri (kart yapısında)

### 4.5 Sprint Retrospektif Formu (`pages/retro.html`)

**Veri Kaynağı:** `sprint_retro`

**Özellikler:**
- Sprint toplantısı seçimi (dropdown)
- Form alanları:
  - OrganizasyonPuan (1-10 slider)
  - AjanstakiRolü (1-10 slider)
  - AjansHakkında (1-10 slider)
- G.ort otomatik hesaplama (GEOMEAN = √(Rol × Hakkında))
- Geçmiş retrospektif sonuçları tablosu
- Kişi bazlı trend analizi

### 4.6 Harcamalar Sayfası (`pages/harcamalar.html`)

**Veri Kaynağı:** `harcamalar`

**Özellikler:**
- Harcama listesi tablosu (filtrelenebilir: sprint, dönem, durum)
- Yeni harcama giriş formu
- SprintİşPlanı-Harcama fark kontrolü (doğrulama formülü)
- Ödeme dönemi bazlı toplam özet
- SOP/Faaliyet bazlı bütçe kullanım raporu

### 4.7 İzinler & Saha Görevleri (Sprint Özet içinde veya ayrı)

**Özellikler:**
- İzin giriş formu (personel, tarih aralığı, tür)
- Saha görevi giriş formu (personel, tarih, il, açıklama)
- Sprint dönemi bazlı otomatik toplam hesaplama (sprint_veri.izin ve sprint_veri.saha alanlarını günceller)
- Takvim görünümü (isteğe bağlı)

---

## 5. AUTH & YETKİLENDİRME

### 5.1 Supabase Auth

- Email/password login
- `personel` tablosundaki `auth_id` alanı `auth.users.id` ile eşleşir
- Kullanıcı adı formatı: `ad.soyad` (ör: fatih.ozdemir, zubeyde.altun)

### 5.2 Row Level Security (RLS)

```sql
-- Herkes kendi sprint görevlerini görebilir
CREATE POLICY "Kullanıcılar kendi görevlerini görür"
  ON sprint_is_plani FOR SELECT
  USING (true);  -- Tüm ekip tüm görevleri görebilir

-- Sadece kendi görevlerini veya Scrum Master güncelleyebilir
CREATE POLICY "Kullanıcılar kendi görevlerini günceller"
  ON sprint_is_plani FOR UPDATE
  USING (
    ekip_uyesi = (SELECT ad FROM personel WHERE auth_id = auth.uid())
    OR (SELECT ad FROM personel WHERE auth_id = auth.uid()) = 'Fatih'
  );

-- Sprint retro: herkes kendi puanını girer
CREATE POLICY "Retro kendi puanı"
  ON sprint_retro FOR INSERT
  WITH CHECK (
    ad = (SELECT ad FROM personel WHERE auth_id = auth.uid())
  );

-- Harcamalar: sadece yetkili kişiler
CREATE POLICY "Harcama girişi"
  ON harcamalar FOR INSERT
  WITH CHECK (true);  -- Tüm ekip girebilir, Scrum Master onaylar
```

### 5.3 Otomatik Alanlar (PostgreSQL Trigger)

```sql
-- Her güncelleme sırasında guncel_tarih ve guncelleyen otomatik set
CREATE OR REPLACE FUNCTION update_audit_fields()
RETURNS TRIGGER AS $$
BEGIN
  NEW.guncel_tarih = NOW();
  NEW.guncelleyen = (SELECT ad || '.' || soyad FROM personel WHERE auth_id = auth.uid());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sprint_is_plani_audit
  BEFORE UPDATE ON sprint_is_plani
  FOR EACH ROW EXECUTE FUNCTION update_audit_fields();
```

---

## 6. TEKNİK MİMARİ

### 6.1 Proje Yapısı

```
sprint-kanban/
├── index.html                  # Kanban Board (ana sayfa)
├── login.html                  # Giriş sayfası
├── pages/
│   ├── faaliyetler.html        # Faaliyet listesi & bütçe
│   ├── performans.html         # Performans göstergeleri
│   ├── retro.html              # Sprint retrospektif formu
│   ├── harcamalar.html         # Harcama kayıtları
│   ├── sprint-ozet.html        # Sprint özet & grafikler
│   └── izinler.html            # İzin & saha görevleri
├── css/
│   └── style.css               # Tailwind veya özel CSS
├── js/
│   ├── supabase-client.js      # Supabase bağlantı config
│   ├── kanban.js               # Drag & drop mantığı
│   ├── auth.js                 # Login/logout/session
│   ├── charts.js               # Chart.js grafik fonksiyonları
│   └── utils.js                # Ortak yardımcı fonksiyonlar
├── sql/
│   ├── 001_schema.sql          # Tablo oluşturma
│   ├── 002_views.sql           # Hesaplanan alan view'ları
│   ├── 003_rls.sql             # Row Level Security
│   ├── 004_triggers.sql        # Audit trigger'ları
│   └── seed.sql                # Mevcut Excel verisi
├── .env.example                # SUPABASE_URL, SUPABASE_ANON_KEY
└── README.md
```

### 6.2 Teknoloji Stack

| Katman | Teknoloji | Neden |
|--------|-----------|-------|
| Frontend | Vanilla HTML/CSS/JS | Basitlik, hızlı deploy |
| CSS Framework | Tailwind CSS (CDN) | Utility-first, hızlı stil |
| Drag & Drop | SortableJS | Hafif, güvenilir kanban |
| Grafikler | Chart.js | GKİ, Hepiniss, bütçe grafikleri |
| Backend/DB | Supabase (PostgreSQL) | Auth + DB + Realtime + API hepsi bir arada |
| Realtime | Supabase Realtime | Kanban anlık güncelleme |
| Deploy | GitHub Pages veya Vercel | Static site, ücretsiz |

### 6.3 Supabase Client Config

```javascript
// js/supabase-client.js
import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js/+esm'

const supabaseUrl = 'YOUR_SUPABASE_URL'
const supabaseKey = 'YOUR_SUPABASE_ANON_KEY'
export const supabase = createClient(supabaseUrl, supabaseKey)
```

---

## 7. SEED DATA

Mevcut Excel verisinin tamamı `seed.sql` dosyasına aktarılmalıdır. Kritik tablolar ve kayıt sayıları:

| Tablo | Kayıt Sayısı | Öncelik |
|-------|-------------|---------|
| birimler | 4 | Önce |
| soplar | 8 | Önce |
| kategoriler | ~21 | Önce |
| personel | 7 | Önce |
| faaliyetler | 30 | Önce |
| alt_faaliyetler | 53 | Önce |
| perf_gostergeler | 28 | Önce |
| sprint_veri | 4 (aktif) + 13 (boş şablon) | Önce |
| sprint_is_plani | 102 | ⭐ Kritik |
| harcamalar | 8 | Sonra |
| sprint_perf_gos | 8 | Sonra |
| izinler | 5 | Sonra |
| saha_gorevleri | 5 | Sonra |
| anahtar_sonuclar | 91 | Sonra |
| sprint_retro | 29 | Sonra |

**NOT:** Türkçe karakterler (İ, ş, ö, ğ, ü, ç, Ş, Ö, Ğ, Ü, Ç) korunmalıdır. Tüm SQL dosyaları UTF-8 encoding ile yazılmalıdır.

---

## 8. ÖNCELİK SIRASI (UYGULAMA ADIMLARI)

| Adım | Görev | Çıktı | Bağımlılık |
|------|-------|-------|------------|
| 1 | DB şeması oluştur (14 tablo) | `sql/001_schema.sql` | — |
| 2 | View'ları oluştur (4 view) | `sql/002_views.sql` | Adım 1 |
| 3 | RLS politikaları | `sql/003_rls.sql` | Adım 1 |
| 4 | Trigger'lar | `sql/004_triggers.sql` | Adım 1 |
| 5 | Seed data (Excel → SQL INSERT) | `sql/seed.sql` | Adım 1 |
| 6 | Supabase client + Auth | `js/supabase-client.js`, `js/auth.js`, `login.html` | — |
| 7 | **Kanban Board** (ana sayfa) | `index.html`, `js/kanban.js` | Adım 1-6 |
| 8 | Sprint Özet sayfası + grafikler | `pages/sprint-ozet.html`, `js/charts.js` | Adım 7 |
| 9 | Faaliyetler sayfası | `pages/faaliyetler.html` | Adım 7 |
| 10 | Performans dashboard | `pages/performans.html` | Adım 7 |
| 11 | Retro formu | `pages/retro.html` | Adım 7 |
| 12 | Harcamalar sayfası | `pages/harcamalar.html` | Adım 7 |
| 13 | İzinler & Saha | `pages/izinler.html` | Adım 7 |
| 14 | Deploy config + README | `.env.example`, `README.md` | Adım 7-13 |

---

## 9. KABUL KRİTERLERİ

### 9.1 Fonksiyonel

- [ ] Kanban board'da drag & drop çalışıyor, kolon değiştiğinde `is_durum` doğru güncelleniyor
- [ ] Sprint filtresi çalışıyor — sadece seçili sprint'in görevleri görünüyor
- [ ] GKİ hesaplaması Excel ile birebir aynı sonucu veriyor (Sprint 1: ~98.5, Sprint 2: ~86.8)
- [ ] Hepiniss hesaplaması doğru (GEOMEAN tabanlı)
- [ ] Yeni görev eklenebiliyor, mevcut görev düzenlenebiliyor
- [ ] Harcama girişi yapılabiliyor, bütçe toplamları doğru
- [ ] Performans göstergeleri hedef/gerçekleşme doğru gösteriyor
- [ ] Retrospektif puanlar girildikten sonra otomatik hesaplama yapılıyor

### 9.2 Teknik

- [ ] Supabase Auth ile giriş/çıkış çalışıyor
- [ ] RLS aktif — kullanıcılar sadece yetkili oldukları verileri güncelleyebiliyor
- [ ] Realtime — birden fazla kullanıcı aynı anda board'u görebiliyor
- [ ] Tüm view'lar doğru hesaplama yapıyor
- [ ] Audit trigger'lar çalışıyor (guncel_tarih, guncelleyen)
- [ ] Responsive tasarım (mobil + masaüstü)
- [ ] Türkçe karakter desteği sorunsuz

### 9.3 Veri Bütünlüğü

- [ ] Excel'deki 102 sprint iş planı kaydı eksiksiz aktarılmış
- [ ] Excel'deki formül sonuçları ile SQL view sonuçları eşleşiyor
- [ ] Foreign key ilişkileri doğru tanımlanmış
- [ ] Seed data'da veri kaybı yok

---

## 10. DİKKAT EDİLECEK NOKTALAR

1. **Türkçe Karakter Dönüşümü:** Tablo ve sütun adlarında Türkçe karakter kullanılmamalı. Excel'deki `İşDurum` → `is_durum`, `Güncelleyen` → `guncelleyen` şeklinde snake_case Latin karaktere çevrilmeli.

2. **BitişDönem vs SprintDönem:** Sprint iş planında bir görev bir sprint'te başlayıp farklı bir sprint'te tamamlanabilir. `bitis_donem` alanı bu durumu yönetir. GKİ hesaplamasında `bitis_donem` kullanılır.

3. **NULL İşDurum = Backlog:** Excel'de boş bırakılan İşDurum alanları Kanban'da Backlog kolonuna düşer.

4. **Hepiniss Formülü:** Excel GEOMEAN fonksiyonu kullanıyor. PostgreSQL'de eşdeğeri `SQRT(a * b)` (2 değer için). Genel formül: `EXP(AVG(LN(value)))`.

5. **Sprint Tarihleri Otomatik:** Her yeni sprint'in başlangıcı önceki bitiş + 3 gün, süresi 18 gün. Bu mantık backend'de veya frontend'de uygulanabilir.

6. **Aylık Plan Sütunları:** Faaliyetler tablosundaki Oca-Ara sütunları JSONB olarak modellenecek. Bu, frontend'de Gantt-benzeri bir görünüm sağlar.

7. **Supabase Ücretsiz Plan Limitleri:** 500 MB DB, 50K MAU, 2 GB bandwidth — bu proje için yeterli.

8. **Excel Harcama Formülü:** `H4: =6500*51` gibi satır içi hesaplamalar var (€ kuru × miktar). Web'de bu tür hesaplamalar frontend'de yapılabilir veya sadece sonuç değeri kaydedilir.
