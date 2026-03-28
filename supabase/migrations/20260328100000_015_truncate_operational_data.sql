-- 015_truncate_operational_data.sql
-- Operasyonel verileri sil, lookup tabloları koru
-- Korunanlar: birimler, kategori_tipleri, kullanici_rolleri, personel, soplar

BEGIN;

-- 1. Bağımlı leaf tablolar önce
TRUNCATE TABLE harcamalar        RESTART IDENTITY CASCADE;
TRUNCATE TABLE sprint_perf_gos   RESTART IDENTITY CASCADE;
TRUNCATE TABLE sprint_retro      RESTART IDENTITY CASCADE;
TRUNCATE TABLE izinler           RESTART IDENTITY CASCADE;
TRUNCATE TABLE saha_gorevleri    RESTART IDENTITY CASCADE;

-- 2. Ara tablolar
TRUNCATE TABLE sprint_is_plani   RESTART IDENTITY CASCADE;
TRUNCATE TABLE anahtar_sonuclar  RESTART IDENTITY CASCADE;
TRUNCATE TABLE alt_faaliyetler   RESTART IDENTITY CASCADE;
TRUNCATE TABLE sprint_veri       RESTART IDENTITY CASCADE;

-- 3. Ana operasyonel tablolar
TRUNCATE TABLE faaliyetler       RESTART IDENTITY CASCADE;
TRUNCATE TABLE perf_gostergeler  RESTART IDENTITY CASCADE;

COMMIT;
