-- 029_seed_perf_gost_yillik.sql
-- inputs/perf_gost_yillik.csv → perf_gost_yillik tablosuna eksik kayıt ekleme
-- 2024, 2025, 2026 yılları için hedef ve gerceklesen verileri yüklendi.
-- ON CONFLICT DO NOTHING: tabloda zaten olan kayıtlara dokunulmaz.

BEGIN;

INSERT INTO perf_gost_yillik (perf_gostergeler_id, cg_kod, yil, hedef, gerceklesen)
SELECT pg.id, d.cg_kod, d.yil, d.hedef, d.gerceklesen
FROM (
  VALUES
  -- 2024
  ('CGSTU11'::text, 2024::int, 2::numeric,  6::numeric),
  ('CGSTU12',       2024,      2,            1),
  ('CGSTU13',       2024,      2,            2),
  ('CGSTU14',       2024,      5,            1),
  ('CGSTU17',       2024,      NULL::numeric, NULL::numeric),
  ('CGSTU21',       2024,      NULL,         NULL),
  ('CGSTU31',       2024,      4,            NULL),
  ('CGSTU32',       2024,      NULL,         NULL),
  ('CGSTU42',       2024,      1,            1),
  ('CGSTU45',       2024,      4,            1),
  ('CGSTU43',       2024,      1,            6),
  ('CGSTU41',       2024,      1,            NULL),
  ('CGSTU44',       2024,      1,            NULL),
  ('CGSTU52',       2024,      1,            1),
  ('CGSTU51',       2024,      1,            2),
  ('CGKDU11',       2024,      NULL,         NULL),
  ('CGKDU13',       2024,      NULL,         5),
  ('CGKDU14',       2024,      NULL,         12),
  ('CGKDU16',       2024,      NULL,         NULL),
  ('CGKDU17',       2024,      NULL,         NULL),
  ('CGKDU24',       2024,      NULL,         8),
  ('CGKDU25',       2024,      NULL,         NULL),
  ('CGKDU32',       2024,      NULL,         2),
  ('CGKDU31',       2024,      NULL,         NULL),
  ('CGKDU34',       2024,      NULL,         NULL),
  ('CGKDU41',       2024,      NULL,         17),
  ('CGKDU46',       2024,      NULL,         NULL),
  ('CGKDU51',       2024,      NULL,         1),
  -- 2025
  ('CGSTU11',       2025,      3,            20),
  ('CGSTU12',       2025,      3,            4),
  ('CGSTU13',       2025,      2,            2),
  ('CGSTU14',       2025,      5,            2),
  ('CGSTU17',       2025,      1,            NULL),
  ('CGSTU21',       2025,      1,            1),
  ('CGSTU31',       2025,      4,            7),
  ('CGSTU32',       2025,      2,            2),
  ('CGSTU42',       2025,      1,            3),
  ('CGSTU45',       2025,      4,            5),
  ('CGSTU43',       2025,      2,            3),
  ('CGSTU41',       2025,      1,            2),
  ('CGSTU44',       2025,      1,            5),
  ('CGSTU52',       2025,      1,            1),
  ('CGSTU51',       2025,      1,            1),
  ('CGKDU11',       2025,      1,            1),
  ('CGKDU13',       2025,      2,            3),
  ('CGKDU14',       2025,      12,           NULL),
  ('CGKDU16',       2025,      2,            2),
  ('CGKDU17',       2025,      1,            NULL),
  ('CGKDU24',       2025,      2,            3),
  ('CGKDU25',       2025,      2,            6),
  ('CGKDU32',       2025,      3,            3),
  ('CGKDU31',       2025,      20,           20),
  ('CGKDU34',       2025,      1,            1),
  ('CGKDU41',       2025,      15,           NULL),
  ('CGKDU46',       2025,      1,            2),
  ('CGKDU51',       2025,      2,            2),
  -- 2026
  ('CGSTU11',       2026,      3,            NULL),
  ('CGSTU12',       2026,      NULL,         NULL),
  ('CGSTU13',       2026,      NULL,         NULL),
  ('CGSTU14',       2026,      10,           1),
  ('CGSTU17',       2026,      NULL,         NULL),
  ('CGSTU21',       2026,      NULL,         NULL),
  ('CGSTU31',       2026,      4,            NULL),
  ('CGSTU32',       2026,      1,            NULL),
  ('CGSTU42',       2026,      1,            2),
  ('CGSTU45',       2026,      4,            2),
  ('CGSTU43',       2026,      2,            NULL),
  ('CGSTU41',       2026,      NULL,         4),
  ('CGSTU44',       2026,      1,            NULL),
  ('CGSTU52',       2026,      2,            NULL),
  ('CGSTU51',       2026,      1,            NULL),
  ('CGKDU11',       2026,      NULL,         NULL),
  ('CGKDU13',       2026,      NULL,         NULL),
  ('CGKDU14',       2026,      NULL,         NULL),
  ('CGKDU16',       2026,      NULL,         NULL),
  ('CGKDU17',       2026,      NULL,         NULL),
  ('CGKDU24',       2026,      NULL,         NULL),
  ('CGKDU25',       2026,      NULL,         NULL),
  ('CGKDU32',       2026,      NULL,         NULL),
  ('CGKDU31',       2026,      NULL,         NULL),
  ('CGKDU34',       2026,      NULL,         NULL),
  ('CGKDU41',       2026,      NULL,         NULL),
  ('CGKDU46',       2026,      NULL,         NULL),
  ('CGKDU51',       2026,      NULL,         NULL)
) AS d(cg_kod, yil, hedef, gerceklesen)
JOIN perf_gostergeler pg ON pg.cg_kod = d.cg_kod
ON CONFLICT (cg_kod, yil) DO NOTHING;

COMMIT;
