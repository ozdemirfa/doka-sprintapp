-- 017_seed_faaliyetler.sql
-- inputs/faaliyetler.csv verilerini faaliyetler tablosuna yükler
-- Trigger devre dışı bırakılarak orijinal fkod değerleri korunur

BEGIN;

ALTER TABLE faaliyetler DISABLE TRIGGER trg_faaliyetler_fkod;

INSERT INTO faaliyetler (skod, kkod, faaliyet, fkod, fsirano) VALUES
  (7, 6, 'Avrupa Birliği Projeleri', 'ABP601', 1),
  (6, 6, 'Bakanlık Talepleri', 'BAK601', 1),
  (2, 1, 'Rekabetçi Sektörler KOBİ Profil Analizi', 'KDU101', 1),
  (2, 1, 'Hedef pazar analizi', 'KDU103', 3),
  (2, 1, 'Eylem Planları', 'KDU108', 8),
  (2, 2, 'Ulusal ve uluslararası fonlara proje geliştirilmesi', 'KDU204', 4),
  (2, 2, 'Yeşil Dönüşüm Stratejisi ve Eylem Planı kapsamındaki iş birliği faaliyetleri', 'KDU205', 5),
  (2, 3, 'Yalın üretim ve dijital dönüşüm alanında insan kaynağı geliştirme', 'KDU301', 1),
  (2, 3, 'Yalın üretim ve dijital dönüşüme yönelik iyi uygulama ziyaretleri ve tecrübe paylaşımı', 'KDU302', 2),
  (2, 3, 'Kadın kooperatifleri kalkınma liderleri programı', 'KDU304', 4),
  (2, 3, 'Export Hub Programı', 'KDU305', 5),
  (2, 4, 'Yatırım fizibiliteleri sunumu, B2B Organizasyonları', 'KDU406', 6),
  (2, 4, 'Rekabetçi Sektörler KOBİ Profil Analizi Lansmanı', 'KDU407', 7),
  (2, 5, 'Teknik Destek', 'KDU501', 1),
  (8, 6, 'SoGreen Projesi', 'SOG601', 1),
  (5, 6, 'SOP dışı diğer işler', 'SDD601', 1),
  (1, 1, 'Doğa ve kültür turizmi temasında deneyim odaklı ürünlerin, rotaların, destinasyonların araştırılması ve geliştirilmesi', 'STU101', 1),
  (1, 1, 'Hedef pazar analizlerinin yapılması', 'STU102', 2),
  (1, 1, 'Kurumsal kimlik, markalaşma ve tanıtım stratejilerinin oluşturulması', 'STU103', 3),
  (1, 1, 'Turizm master planlarının, planlara yönelik yatırım fizibiliteleri ve ön fizibilitelerin hazırlanması', 'STU104', 4),
  (1, 2, 'Deneyim odaklı doğa ve kültür turizmi kapsamında ürün, festival, şenlik, rekreatif aktivite, organizasyon, rota ve destinasyon planlaması gerçekleştirecek ve bunları geliştirecek çalışma grupları oluşturulması', 'STU201', 1),
  (1, 3, 'Sektörel uzmanlaşmaya yönelik eğitim/webinar/farkındalık toplantıları gerçekleştirilmesi', 'STU301', 1),
  (1, 3, 'Katma değerli turizm alanında iyi uygulama örneklerinin incelenmesi', 'STU302', 2),
  (1, 4, 'Kültür-turizm festivalleri ve spor organizasyonları düzenlenmesi', 'STU401', 1),
  (1, 4, 'Fuarlar, Tanıtım Amaçlı Lansman (Roadshow) Organizasyonları', 'STU402', 2),
  (1, 4, 'Fam-trip ve tanıtım turu etkinlikleri düzenlenmesi', 'STU403', 3),
  (1, 4, 'Doğrudan yabancı yatırım çekmeye yönelik B2B, yatırım turu, yatırımcı zirvesi katılımı/düzenlenmesi', 'STU404', 4),
  (1, 4, 'Dijital tanıtım içerikleri ve basılı tanıtım materyallerinin hazırlanması', 'STU405', 5),
  (1, 5, 'Teknik Destek', 'STU501', 1),
  (1, 5, 'Güdümlü Proje Desteği ve Mali Destek', 'STU502', 2);

ALTER TABLE faaliyetler ENABLE TRIGGER trg_faaliyetler_fkod;

COMMIT;
