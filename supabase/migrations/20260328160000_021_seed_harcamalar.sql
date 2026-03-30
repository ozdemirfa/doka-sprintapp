-- 021_seed_harcamalar.sql
-- inputs/harcamalar.csv → harcamalar tablosu

BEGIN;

INSERT INTO harcamalar
  (aciklama, harcama_onay_kodu, onay_tarihi, odeme_donem,
   odenecek_kdvli, guncel_tarih, guncelleyen, sprint_is_plani_id)
VALUES
  (NULL, '45', '2026-01-06', '2026.Oca', 144000.00, '2026-02-02', 'elifnaz.gulcan', 5),
  (NULL, '51', '2026-01-15', '2026.Oca', 240000.00, '2026-02-04', 'fatih.ozdemir', 21),
  ('euro hesap ödendi/€ kur 51 olarak TL çevrildi.', '47', '2026-01-06', '2026.Sub', 331500.00, '2026-03-19', 'fatih.ozdemir', 34),
  ('Ara ödeme yapıldı, tamamı fuar sonrası ödenecek.', '49', '2026-01-06', '2026.Sub', 536400.00, '2026-02-18', 'elifnaz.gulcan', 17),
  ('Yarış bitiminde ödendi.', '55', '2026-01-20', '2026.Sub', 146916.00, '2026-02-26', 'fatih.ozdemir', 35),
  ('kesin ödeme KDV hariç şekilde yapıldı', '49', '2026-01-06', '2026.Mar', 1043000.00, '2026-03-19', 'fatih.ozdemir', 63),
  ('ara ödeme kdv dahil gerçekleştirildi', '49', '2026-01-06', '2026.Sub', 473337.24, '2026-03-19', 'fatih.ozdemir', 63),
  (NULL, '258', '2025-11-18', '2026.Mar', 1290000.00, '2026-03-13', 'mehmet.sezgin', 65);

COMMIT;
