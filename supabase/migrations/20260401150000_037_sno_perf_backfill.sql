-- ============================================================
-- Migration 037: sprint_is_plani.sno + performans_gostergeler backfill
-- Kaynak: inputs/sprint_is_plani.csv
-- Tarih: 2026-04-01
--
-- 034 import sno ve performans_gostergeler kolonlarını atlamıştı.
-- 020 seed'deki CSV→DB sno eşlemesi:
--   CSV 77 → DB 54 (Diğer görevler/genel)
--   CSV 78 → DB 55 (Diğer görevler 2)
--   CSV 79 → DB 56 (AB ve uluslararası proje)
--   CSV 80 → DB 57 (SoGreen proje görevleri)
-- ============================================================

-- ──────────────────────────────────────────────────────────────
-- 1. sno backfill
-- ──────────────────────────────────────────────────────────────

UPDATE sprint_is_plani AS sip
SET sno = v.sno
FROM (VALUES
  -- Sprint 1
  (1, 'FITUR Madrid Sunumu Hazırlanacak',                                                                              19),
  (1, 'Erasmus+ programı incelenerek uygun çağrılar tespit edilecek, proje fikri geliştirilecek',                       44),
  (1, 'Erasmus+ programına sunulacak projenin özeti çıkarılacak',                                                       44),
  (1, 'Discover Kaçkar süreci sunumu hazırlanacak',                                                                    54),
  (1, 'Kış yüzme şenliği satınlama yapılacak',                                                                         45),
  (1, 'Uzungöl kış şenliği satınalma yapılacak',                                                                       45),
  (1, 'Dijital içerik çekim satınalması yapılacak',                                                                    27),
  (1, 'Turizm Mükemmeliyet Merkezi makalesi hazırlanacak',                                                             54),
  (1, 'SoGreen güdümlü proje önerileri hazırlanacak',                                                                  57),
  (1, 'KOBİ profil analizi sonuç raporu değerlendirilecek',                                                            46),
  (1, 'TD künyesi hazırlanacak',                                                                                       43),
  (1, 'SeedGuard final raporu hazırlanacak',                                                                           56),
  (1, 'Ünye Manyetik Kum Raporu İncelenecek',                                                                         41),
  (1, 'UNWTO Affiliate Membership başvuru formu hazırlanacak',                                                         13),
  (1, 'ITB China sözleşme imzalandı, TGA''ya iletildi.',                                                              22),
  (1, 'ITB Berlin için sözleşme ve teknik şartname hazırlandı.',                                                       20),
  (1, 'Discover Kaçkar süreç raporu hazırlandı.',                                                                       8),
  (1, 'Tıbbi aromatik bitkiler hakkında ön araştırma yapıldı ve kurumlarla görüşüldü.',                                 31),
  (1, 'Kardan Adam Şenliği satın alma yapılacak',                                                                      45),
  (1, 'Ekoturizm teması bilgi notu hazırlanacak',                                                                       6),
  (1, 'FITUR Madrid Katılım Sağlandı',                                                                                 19),
  (1, 'SiberVatan 2026 DOKA-KTÜ işbirliği protokolü imzalandı.',                                                      54),
  (1, 'SiberVatan için 8 üniversite ve yüklenici firma ile görüşüldü eğitim süreci planlandı.',                        54),
  (1, 'SiberVatan öğrencilerinin soruları cevaplandırıldı.',                                                           54),
  (1, 'BAKKA tarafından düzenlenen 2 adet SiberVatan toplantısına katılım sağlandı.',                                  54),
  (1, 'SOGEP 2026 Programına proje önerileri hazırlandı.',                                                             54),
  (1, 'Veri Analizi Okulu eğitimlerine katılındı.',                                                                    54),
  (1, 'SiberVatan ''Beyaz Şapkalı Hacker ve CTF Eğitimi'' T. Şartnamesi hazırlandı ve teklifler alındı.',              54),
  (1, 'SiberVatan Hackviser lisans tedariği için DMO''dan alım ve piyasa fiyat araştırması yapıldı.',                  54),
  (1, 'SiberVatan Giresun, Ordu, Rize illerinin protokolleri hazırlandı.',                                             54),
  (1, 'Kültür Yayınları-Telif Eser Sözleşmesi üzerinde çalışıldı ve son hali verildi.',                               54),
  (1, 'Trabzon AFAD ile ''Afet Farkındalık Eğitimi'' planlaması yapıldı ve eğitime katılındı.',                        54),
  (1, 'SiberVatan 6 ildeki tüm öğrencilerin Telegram kanallarına katılması sağlandı.',                                 54),
  -- Sprint 2
  (2, 'KTÜ''de SOGreen GPD Sunumu  yapılacak',                                                                        57),
  (2, 'Trabzon festival ve etkinlik bilgi notu hazırlanacak',                                                          47),
  (2, 'Artvin TBA kurum ziyaretleri yapılacak',                                                                        31),
  (2, 'Kültür Yayınları: Şahrah ticaret yolu sözleşme süreci tamamlandı.',                                            54),
  (2, 'Sibervatan yüzyüze eğitim satınalma tamamlandı ve iş başlatıldı.',                                             54),
  (2, 'KTÜ''de SoGreen GDP toplantısına katılım sağlanacak',                                                          57),
  (2, 'Ünye Manyetik Kum Raporu Bilgilendirme Toplantısı için hazırlık yapılacak ve toplantıya katılım sağlanacak',   41),
  (2, 'Trabzon Valisi için Fındık Tarımı Bilgi Notu hazırlanacak',                                                    54),
  (2, 'Destek Programı kurgusu tasarlanacak',                                                                          43),
  (2, 'Discover Kaçkar 2. Aşama Teknik Şartname hazırlanacak',                                                         8),
  (2, 'Gümüşhane Turizm Master Planı için Sözleşme imzalanacak',                                                       9),
  (2, 'ITB Berlin TGA stant satın alması yapılacak',                                                                   20),
  (2, '46. Trabzon yarı Maratonu Satın alma tamamlanacak',                                                             48),
  (2, 'ITB Berlin için promosyon malzemeleri hazırlanacak',                                                            20),
  (2, 'Discover Kaçkar Teknik şartnamesi hazırlanacak',                                                                8),
  (2, 'Rize Valisi''ne sunulmak üzere, imzalanacak yeni protokol için bilgi notu hazırlanacak',                         8),
  (2, 'Turizm Mükemmeliyet Merkezi makalesi gözden geçirildi.',                                                       54),
  (2, 'Teknik Destek Programı tasarlanacak',                                                                           43),
  (2, 'DOKAP davetlisi olarak kooperatifler hakkında İzmir saha ziyareti gerçekleştirildi.',                           54),
  (2, 'Turizm almanak oluşturulmaya başlandı.',                                                                        54),
  (2, 'Erasmus+ proje: projenin özeti çıkarılacak',                                                                    44),
  (2, 'Erasmus+ proje: proje özeti potansiyel ortaklara gönderilecek',                                                 44),
  (2, 'Erasmus+ proje: potansiyel ortaklar ile görüşmelere başlanacak',                                                44),
  (2, 'Veri Analizi Okulunda 2 Modülün eğitimlerine katılım sağlanacak',                                              54),
  (2, 'Yeşil Sertifika Eğitimine katılım sağlanacak alınacak',                                                        54),
  (2, 'Siber Vatan Giresun yüz yüze eğitimi hazırlıkları, iş ve işlemleri yürütüldü.',                                54),
  (2, 'Siber Vatan Gümüşhane yüz yüze eğitimi hazırlıkları, iş ve işlemleri yürütüldü.',                             54),
  (2, 'UNDP-Sivil Katılım Projesi Antalya Çalıştayına katılım sağlanacak.',                                           54),
  (2, 'Veri Analizi Okulu eğitimlerine katılım sağlandı.',                                                            54),
  -- Sprint 3
  (3, 'Erasmus + proje: potansiyel ortakların rolleri belirlenecek',                                                   44),
  (3, 'Erasmus + proje: bölge paydaşları ve rolleri belirlenecek',                                                     44),
  (3, 'Veri Analizi Okulu-Temel İstatistik ve Hesaplamalı Sosyal Bilimler modülleri eğitimlerine katılım sağlanacak',  54),
  (3, 'Yeşil Sertifika Eğitimine katılım sağlanacak',                                                                 54),
  (3, 'Yöresel Ürünler Sıfır Hata Eğitim modülü oluşturulacak',                                                       43),
  (3, 'Yalın Dönüşüm temasında finansman desteği programı kurgulanacak',                                              57),
  (3, 'SoGreen Ayder Proje Hazırlığı',                                                                                57),
  (3, 'SoGreen Proje Hazırlığı Destek (KTÜ , Gümüşhane Üni)',                                                        57),
  (3, 'TR90 ve Discover Kaçkar Destinasyonları Tanıtım İçerikleri Teknik Şartnamesi hazırlanacak.',                    27),
  (3, 'BRIGHT Projesi Başlangıç hazırlıkları',                                                                        56),
  (3, 'ITB Berlin Fuarı''na katılım sağlandı',                                                                        20),
  (3, 'ITB Berlin stant tasarım ve kurulum satın alması yapıldı',                                                      20),
  (3, 'EBRD Sürdürülebilirlik Eğitimine katılım sağlanacak',                                                          54),
  (3, 'Artvin Macera Turizmi Master Plan Ön Hazırlık',                                                                51),
  (3, 'Artvin kış turizmi fizibilitesi satın alma işlemlerine başlandı',                                               52),
  (3, 'KADİM mentör havuzu seçim kriterleri belirlendi.',                                                              38),
  (3, 'Turim Mükemmeliyet Merkezi makalesi tamamlandı',                                                               54),
  (3, 'SoGreen Proje tanıtımı ve proje yazımına destek olundu',                                                       53),
  (3, 'Bölge tanıtım broşürleri hazırlanacak',                                                                        50),
  (3, 'DOKA Hafıza Giresun Kültür Varlığı eseri ödeme işlemleri yapıldı.',                                            54),
  (3, 'UNDP Sivil Katılım Projesi Eylem Planı üzerinde çalışıldı.',                                                   54),
  (3, 'VAO-Panel Veri Analizi ve İstatistik modülleri eğitimleri.',                                                   54),
  (3, 'EBRD Sürdürülebilirlik Eğitimine katılı sağlandı.',                                                            54),
  (3, 'Siber Vatan Trabzon eğitimleri hazırlıkları, iş ve işlemleri yapıldı.',                                        54),
  (3, 'Siber Vatan Ordu öğrenci transferi organizasyonu ve konaklaması iş ve işlemleri yapıldı.',                      54),
  -- Sprint 4
  (4, 'TR90 Turizm Destinasyonları satınalma işlemleri yapılacak.',                                                    27),
  (4, 'Discover Kaçkar Destinasyonları satınalma işlemleri yapılacak.',                                                27),
  (4, 'SiberVatan Ordu konaklama hizmet alımı ödeme işlemleri yapılacak.',                                            54),
  (4, '81 İl 81 Ürün rehberi incelenecek ve yapılacaklar listesi oluşturulacak.',                                      55),
  (4, 'SOP''lar incelenecek.',                                                                                        54),
  (4, 'Kültür Yayınları telif hakkı mevzuat araştırması yapılacak.',                                                  54),
  (4, 'Düzköy Turizm Master Planı satınalması yapılacak',                                                             49),
  (4, 'SiberVatan Trabzon Üni yazıları ve Artvin Eğitimi hazırlık işlemleri yapılacak.',                               54),
  (4, 'VAO-Panel Veri Analizi ve İstatistik modülleri eğitimleri.',                                                   54),
  (4, 'Erasmus + projesi ortakların wp,pm,çıktı ve bütçe ayrıntıları netleştirilecek',                                44),
  (4, 'Erasmus + projesi application form hazırlanacak',                                                              44),
  (4, 'Veri Analizi Okulu-Temel İstatistik ve Hesaplamalı Sosyal Bilimler eğitimlerine katılım sağlanacak',           54),
  (4, 'Yeşil Sertifika eğitimine katılım sağlanacak',                                                                 54),
  (4, 'BRIGHT Projesi - Cahul Açılış Toplantısı Hazırlığı',                                                          56),
  (4, 'BRIGHT Projesi Proje Takip İşlemleri',                                                                         56)
) AS v(sprint_donem, sprint_faaliyetleri, sno)
WHERE sip.sprint_donem = v.sprint_donem
  AND sip.sprint_faaliyetleri = v.sprint_faaliyetleri
  AND sip.sno IS NULL;

-- ──────────────────────────────────────────────────────────────
-- 2. performans_gostergeler backfill (6 satır)
-- ──────────────────────────────────────────────────────────────

UPDATE sprint_is_plani
SET performans_gostergeler = 'CGSTU41'
WHERE sprint_donem = 1
  AND sprint_faaliyetleri = 'Kış yüzme şenliği satınlama yapılacak'
  AND performans_gostergeler IS NULL;

UPDATE sprint_is_plani
SET performans_gostergeler = 'CGSTU41'
WHERE sprint_donem = 1
  AND sprint_faaliyetleri = 'Kardan Adam Şenliği satın alma yapılacak'
  AND performans_gostergeler IS NULL;

UPDATE sprint_is_plani
SET performans_gostergeler = 'CGSTU42'
WHERE sprint_donem = 1
  AND sprint_faaliyetleri = 'FITUR Madrid Katılım Sağlandı'
  AND performans_gostergeler IS NULL;

UPDATE sprint_is_plani
SET performans_gostergeler = 'CGSTU41'
WHERE sprint_donem = 2
  AND sprint_faaliyetleri = '46. Trabzon yarı Maratonu Satın alma tamamlanacak'
  AND performans_gostergeler IS NULL;

UPDATE sprint_is_plani
SET performans_gostergeler = 'CGSTU42'
WHERE sprint_donem = 3
  AND sprint_faaliyetleri = 'ITB Berlin Fuarı''na katılım sağlandı'
  AND performans_gostergeler IS NULL;

UPDATE sprint_is_plani
SET performans_gostergeler = 'CGSTU45'
WHERE sprint_donem = 3
  AND sprint_faaliyetleri = 'Bölge tanıtım broşürleri hazırlanacak'
  AND performans_gostergeler IS NULL;

-- ──────────────────────────────────────────────────────────────
-- 3. Doğrulama
-- ──────────────────────────────────────────────────────────────

DO $$
DECLARE
  null_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO null_count
  FROM sprint_is_plani
  WHERE sno IS NULL;

  IF null_count > 0 THEN
    RAISE WARNING 'sprint_is_plani: % satırda sno hâlâ NULL — metin eşleşmesi başarısız olmuş olabilir.', null_count;
  ELSE
    RAISE NOTICE 'sprint_is_plani.sno backfill tamamlandı — tüm satırlar güncellendi.';
  END IF;
END $$;
