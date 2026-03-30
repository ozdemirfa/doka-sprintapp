-- 022_seed_sprint_perf_gos.sql
-- inputs/sprint_perf_gos.csv → sprint_perf_gos tablosu

BEGIN;

INSERT INTO sprint_perf_gos
  (sprint_is_plani_id, cg_kod, aciklama, gerceklesme,
   tamamlanma_donemi, tamamlanma_tarihi, yil)
VALUES
  (5, 'CGSTU41', 'Kış Yüzme Şenliği 18-19 Ocak 2026 tarihlerinde düzenlendi.', 1.00, '2026/1', '2026-01-28', 2026),
  (21, 'CGSTU41', 'Kardan Adam şenliği tamamlandı', 1.00, '2026/1', '2026-01-30', 2026),
  (24, 'CGSTU42', 'FITUR26 Madrid Turizm Fuarına katılım sağlandı. 21-24.01.2026', 1.00, '2026/1', '2026-01-25', 2026),
  (35, 'CGSTU41', '46. Trabzon yarı Maratonu Promosyon malzemeleri hazırlandı', 1.00, '2026/1', NULL, 2026),
  (6, 'CGSTU41', 'Uzungöl kış şenliği desteklendi.', 1.00, '2026/1', NULL, 2026),
  (62, 'CGSTU42', 'ITB Berlin Fuarı''na katılım sağlandı.', 1.00, '2026/1', '2026-03-11', 2026),
  (65, 'CGSTU14', 'Artvin macera turizmi konsept master plan hazırlandı', 1.00, '2026/1', '2026-03-11', 2026),
  (89, 'CGSTU45', 'DiscoverKaçkar ve GreenCorridors broşürleri hazırlatıldı.', 2.00, '2026/1', '2026-03-06', 2026);

COMMIT;
