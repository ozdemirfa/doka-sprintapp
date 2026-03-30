-- 023_seed_sprint_veri.sql
-- inputs/sprint_veri.csv → sprint_veri (INSERT + UPDATE mevcut kayıtlar)

BEGIN;

INSERT INTO sprint_veri
  (sprint_donem, baslangic, bitis, sprint_adi, isim_veren, sure_gun, ekip)
VALUES
  (1, '2026-01-01', '2026-01-30', 'Middle', 'Anonim', 20, 4),
  (2, '2026-02-02', '2026-02-20', 'Zemu', 'Anonim', 14, 5),
  (3, '2026-02-23', '2026-03-13', 'Maison', 'Anonim', 14, 5),
  (4, '2026-03-16', '2026-04-03', 'House', 'Anonim', 14, 5),
  (5, '2026-04-06', '2026-04-24', 'KahveDünya', 'Anonim', 14, 5),
  (6, '2026-04-27', '2026-05-15', 'Boi', 'Anonim', 14, 5),
  (7, '2026-05-18', '2026-06-05', 'Ganita', 'Anonim', 14, 5),
  (8, '2026-06-08', '2026-06-26', 'Botanik', 'Anonim', 14, 5),
  (9, '2026-06-29', '2026-07-17', 'Melanzane', 'Anonim', 14, 5),
  (10, '2026-07-20', '2026-08-07', NULL, NULL, 14, 5),
  (11, '2026-08-10', '2026-08-28', NULL, NULL, 14, 5),
  (12, '2026-08-31', '2026-09-18', NULL, NULL, 14, 5),
  (13, '2026-09-21', '2026-10-09', NULL, NULL, 14, 5),
  (14, '2026-10-12', '2026-10-30', NULL, NULL, 14, 5),
  (15, '2026-11-02', '2026-11-20', NULL, NULL, 14, 5),
  (16, '2026-11-23', '2026-12-11', NULL, NULL, 14, 5),
  (17, '2026-12-14', '2026-12-31', NULL, NULL, 18, 5)
ON CONFLICT (sprint_donem) DO UPDATE SET
  baslangic  = EXCLUDED.baslangic,
  bitis      = EXCLUDED.bitis,
  sprint_adi = EXCLUDED.sprint_adi,
  isim_veren = EXCLUDED.isim_veren,
  sure_gun   = EXCLUDED.sure_gun,
  ekip       = EXCLUDED.ekip;

COMMIT;
