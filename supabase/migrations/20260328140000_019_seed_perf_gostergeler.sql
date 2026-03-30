-- 019_seed_perf_gostergeler.sql
-- inputs/perf_gostergeler.csv → perf_gostergeler + perf_gost_yillik (2026)

BEGIN;

-- Trigger devre dışı: cg_kod ve bilesen_kodu manuel girilecek
ALTER TABLE perf_gostergeler DISABLE TRIGGER trg_perf_gostergeler_cg_kod;

INSERT INTO perf_gostergeler
  (cg_kod, skod, kkod, pg_sira, bilesen_kodu, bilesen_adi,
   cikti_gostergesi, birim, hedef,
   tamamlanma_donemi, katki_sonuc_gostergesi)
VALUES
  ('CGSTU11', 1, 1, 1, '1.1.', 'Doğa ve kültür turizmi temasında deneyim odaklı ürünlerin, rotaların, destinasyonların araştırılması ve geliştirilmesi', 'Doğa ve kültür temalı, deneyim odaklı ürün sayısı', 'Adet', 8.0, '2026/4', '1'),
  ('CGSTU12', 1, 1, 2, '1.2.', 'Hedef pazar analizlerinin yapılması', 'Analiz Sayısı', 'Adet', 4.0, '2026/2', '1,2'),
  ('CGSTU13', 1, 1, 3, '1.3.', 'Kurumsal kimlik, markalaşma ve tanıtım stratejilerinin oluşturulması', 'Stratejik doküman sayısı', 'Adet', 3.0, '2026/4', '3'),
  ('CGSTU14', 1, 1, 4, '1.4.', 'Turizm master planlarının, planlara yönelik yatırım fizibiliteleri ve ön fizibilitelerin hazırlanması', 'Master plan/fizibilite/ön fizibilite sayısı', 'Adet', 20.0, '2026/4', '2'),
  ('CGSTU17', 1, 1, 7, '1.7.', 'Turizm altyapılarının iyileştirilmesine yönelik alternatif finansman kaynaklarının çalışılması, model geliştirilmesi', 'Alternatif finansman kaynağı sayısı', 'Adet', NULL, '2026/4', '2'),
  ('CGSTU21', 1, 2, 1, '2.1.', 'Deneyim odaklı doğa ve kültür turizmi kapsamında ürün, festival, şenlik, rekreatif aktivite, organizasyon, rota ve destinasyon planlaması gerçekleştirecek ve bunları geliştirecek çalışma grupları oluşturulması', 'Odak grup toplantı sayısı', 'Adet', 4.0, '2026/4', '1'),
  ('CGSTU31', 1, 3, 1, '3.1.', 'Sektörel uzmanlaşmaya yönelik eğitim/webinar/farkındalık toplantıları gerçekleştirilmesi', 'Düzenlenen eğitim/farkındalık faaliyeti/webinar sayısı', 'Adet', 12.0, '2026/4', '1,2,3,4'),
  ('CGSTU32', 1, 3, 2, '3.2.', 'Katma değerli turizm alanında iyi uygulama örneklerinin incelenmesi', 'İncelenen iyi uygulama örneği sayısı', 'Adet', 3.0, '2026/4', '1,2,3,4'),
  ('CGSTU42', 1, 4, 2, '4.2.', 'Fuarlar, Tanıtım Amaçlı Lansman (Roadshow) Organizasyonları', 'Lansman (Roadshow) ve fuar sayısı', 'Adet', 3.0, '2026/4', '3'),
  ('CGSTU45', 1, 4, 5, '4.5.', 'Dijital tanıtım içerikleri ve basılı tanıtım materyallerinin hazırlanması', 'Hazırlanan içerik sayısı / basılan materyal sayısı', 'Adet', 12.0, '2026/4', '3,4'),
  ('CGSTU43', 1, 4, 3, '4.3.', 'Fam-trip ve tanıtım turu etkinlikleri düzenlenmesi', 'Fam-trip ve tanıtım etkinliği sayısı', 'Adet', 5.0, '2026/4', '3'),
  ('CGSTU41', 1, 4, 1, '4.1.', 'Kültür-turizm festivalleri ve spor organizasyonları düzenlenmesi', 'Düzenlenen/destek verilen organizasyon sayısı', 'Adet', 2.0, '2026/4', '2'),
  ('CGSTU44', 1, 4, 4, '4.4.', 'Doğrudan yabancı yatırım çekmeye yönelik B2B, yatırım turu, yatırımcı zirvesi katılımı/düzenlenmesi', 'Katılım sağlanan B2B, yatırım turu, yatırımcı zirvesi vb. organizasyon sayısı', 'Adet', 3.0, '2026/4', '1,2,3'),
  ('CGSTU52', 1, 5, 2, '5.2.', 'Güdümlü Proje Desteği ve Mali Destek', 'MDP ve Güdümlü Proje sayısı', 'Adet', 4.0, '2026/4', '1,2,3,4'),
  ('CGSTU51', 1, 5, 1, '5.1.', 'Teknik Destek', 'Program sayısı', 'Adet', 3.0, '2026/4', '4'),
  ('CGKDU11', 2, 1, 1, '1.1.', 'Rekabetçi Sektörler KOBİ Profil Analizi', 'Analiz Raporu', 'Adet', NULL, '2026/4', '1,2,3'),
  ('CGKDU13', 2, 1, 3, '1.3.', 'Hedef pazar analizi', 'Analiz Raporu', 'Adet', NULL, '2026/4', '1'),
  ('CGKDU14', 2, 1, 4, '1.4.', 'İlçe temelli yatırım fırsatları analizi', 'Rapor Sayısı', 'Adet', NULL, '2026/4', '1,2,3,4'),
  ('CGKDU16', 2, 1, 6, '1.6.', 'Fizibilite / Ön fizibilitelerin hazırlanması', 'Rapor Sayısı', 'Adet', NULL, '2026/4', '4'),
  ('CGKDU17', 2, 1, 7, '1.7.', 'Rekabetçi sektörlerde yatırımlara uygun yeni sanayi alanları oluşturma çalışmaları', 'Rapor Sayısı', 'Adet', NULL, '2025/4', '4'),
  ('CGKDU24', 2, 2, 4, '2.4.', 'Ulusal ve uluslararası fonlara proje geliştirilmesi', 'Proje başvuru sayısı', 'Adet', NULL, '2026/4', '1,2,3,4'),
  ('CGKDU25', 2, 2, 5, '2.5.', 'Yeşil Dönüşüm Stratejisi ve Eylem Planı kapsamındaki iş birliği faaliyetleri', 'Toplantı/Organizasyon sayısı', 'Adet', NULL, '2026/4', '2,4'),
  ('CGKDU32', 2, 3, 2, '3.2.', 'Yalın üretim ve dijital dönüşüme yönelik iyi uygulama ziyaretleri ve tecrübe paylaşımı', 'Organizasyon sayısı', 'Kişi', NULL, '2026/4', '1,2'),
  ('CGKDU31', 2, 3, 1, '3.1.', 'Yalın üretim ve dijital dönüşüm alanında danışman havuzu geliştirme', 'Eğitime katılan kişi sayısı', 'Adet', NULL, '2026/4', '1,2'),
  ('CGKDU34', 2, 3, 4, '3.4.', 'Kadın kooperatifleri kalkınma liderleri programı', 'Uygulanan Program Sayısı', 'Adet', NULL, '2026/4', '1,2,3,4'),
  ('CGKDU41', 2, 4, 1, '4.1.', 'ARGE ve tasarım merkezleri hakkında KOBİ''lerin ve kooperatiflerin bilgilendirilmesi', 'Bilgilendirilen KOBİ/Kooperatif sayısı', 'Adet', NULL, '2026/4', '3,4'),
  ('CGKDU46', 2, 4, 6, '4.6.', 'Yatırım fizibiliteleri sunumu, B2B Organizasyonları', 'Organizasyon sayısı', 'Adet', NULL, '2026/4', '4'),
  ('CGKDU51', 2, 5, 1, '5.1.', 'Teknik Destek', 'İlan edilen program sayısı', 'Adet', NULL, '2026/4', '1,2,3,4');

ALTER TABLE perf_gostergeler ENABLE TRIGGER trg_perf_gostergeler_cg_kod;

-- perf_gost_yillik: 2026 hedef kayıtları (hedef_2026 kolonu kaldırıldığından hedef kullanılır)
INSERT INTO perf_gost_yillik (perf_gostergeler_id, cg_kod, yil, hedef, gerceklesen)
SELECT id, cg_kod, 2026, hedef, NULL
FROM perf_gostergeler
WHERE hedef IS NOT NULL
ON CONFLICT (cg_kod, yil) DO NOTHING;

COMMIT;
