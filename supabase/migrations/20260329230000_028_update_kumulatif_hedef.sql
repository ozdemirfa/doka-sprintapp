-- 028_update_kumulatif_hedef.sql
-- inputs/perf_gos.csv → perf_gostergeler.kumulatif_hedef güncelleme
-- Hem STU hem KDU kayıtlarının kumulatif_hedef değerleri CSV'deki Hedef kolonundan alındı.

BEGIN;

UPDATE perf_gostergeler SET kumulatif_hedef = 8   WHERE cg_kod = 'CGSTU11';
UPDATE perf_gostergeler SET kumulatif_hedef = 4   WHERE cg_kod = 'CGSTU12';
UPDATE perf_gostergeler SET kumulatif_hedef = 3   WHERE cg_kod = 'CGSTU13';
UPDATE perf_gostergeler SET kumulatif_hedef = 20  WHERE cg_kod = 'CGSTU14';
UPDATE perf_gostergeler SET kumulatif_hedef = 1   WHERE cg_kod = 'CGSTU17';
UPDATE perf_gostergeler SET kumulatif_hedef = 4   WHERE cg_kod = 'CGSTU21';
UPDATE perf_gostergeler SET kumulatif_hedef = 12  WHERE cg_kod = 'CGSTU31';
UPDATE perf_gostergeler SET kumulatif_hedef = 3   WHERE cg_kod = 'CGSTU32';
UPDATE perf_gostergeler SET kumulatif_hedef = 3   WHERE cg_kod = 'CGSTU42';
UPDATE perf_gostergeler SET kumulatif_hedef = 12  WHERE cg_kod = 'CGSTU45';
UPDATE perf_gostergeler SET kumulatif_hedef = 5   WHERE cg_kod = 'CGSTU43';
UPDATE perf_gostergeler SET kumulatif_hedef = 2   WHERE cg_kod = 'CGSTU41';
UPDATE perf_gostergeler SET kumulatif_hedef = 3   WHERE cg_kod = 'CGSTU44';
UPDATE perf_gostergeler SET kumulatif_hedef = 4   WHERE cg_kod = 'CGSTU52';
UPDATE perf_gostergeler SET kumulatif_hedef = 3   WHERE cg_kod = 'CGSTU51';

UPDATE perf_gostergeler SET kumulatif_hedef = 1   WHERE cg_kod = 'CGKDU11';
UPDATE perf_gostergeler SET kumulatif_hedef = 2   WHERE cg_kod = 'CGKDU13';
UPDATE perf_gostergeler SET kumulatif_hedef = 12  WHERE cg_kod = 'CGKDU14';
UPDATE perf_gostergeler SET kumulatif_hedef = 2   WHERE cg_kod = 'CGKDU16';
UPDATE perf_gostergeler SET kumulatif_hedef = 1   WHERE cg_kod = 'CGKDU17';
UPDATE perf_gostergeler SET kumulatif_hedef = 2   WHERE cg_kod = 'CGKDU24';
UPDATE perf_gostergeler SET kumulatif_hedef = 2   WHERE cg_kod = 'CGKDU25';
UPDATE perf_gostergeler SET kumulatif_hedef = 3   WHERE cg_kod = 'CGKDU32';
UPDATE perf_gostergeler SET kumulatif_hedef = 20  WHERE cg_kod = 'CGKDU31';
UPDATE perf_gostergeler SET kumulatif_hedef = 1   WHERE cg_kod = 'CGKDU34';
UPDATE perf_gostergeler SET kumulatif_hedef = 15  WHERE cg_kod = 'CGKDU41';
UPDATE perf_gostergeler SET kumulatif_hedef = 1   WHERE cg_kod = 'CGKDU46';
UPDATE perf_gostergeler SET kumulatif_hedef = 2   WHERE cg_kod = 'CGKDU51';

-- perf_gost_yillik: KDU kayıtları daha önce hedef=NULL olduğundan eklenmemişti, şimdi ekleniyor
INSERT INTO perf_gost_yillik (perf_gostergeler_id, cg_kod, yil, hedef, gerceklesen)
SELECT id, cg_kod, 2026, kumulatif_hedef, NULL
FROM perf_gostergeler
WHERE cg_kod LIKE 'CGKDU%'
ON CONFLICT (cg_kod, yil) DO UPDATE SET hedef = EXCLUDED.hedef;

-- CGSTU17 de daha önce NULL'dı, güncelle
INSERT INTO perf_gost_yillik (perf_gostergeler_id, cg_kod, yil, hedef, gerceklesen)
SELECT id, cg_kod, 2026, kumulatif_hedef, NULL
FROM perf_gostergeler
WHERE cg_kod = 'CGSTU17'
ON CONFLICT (cg_kod, yil) DO UPDATE SET hedef = EXCLUDED.hedef;

COMMIT;
