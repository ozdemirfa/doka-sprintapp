-- 030_seed_sprint_retro.sql
-- Gerçek form yanıtları: inputs/sprint_retro.csv
-- pkod → ad dönüşümü personel tablosundan subquery ile yapılır
-- aort (CSV hesaplamalı alan) tabloda saklanmaz

BEGIN;

INSERT INTO sprint_retro (tarih, ad, sprint_toplanti, organizasyon_puan, ajanstaki_rolu, ajans_hakkinda, durum)
SELECT
    v.tarih,
    p.ad,
    v.sprint_toplanti,
    v.organizasyon_puan,
    v.ajanstaki_rolu,
    v.ajans_hakkinda,
    v.durum
FROM (VALUES
    -- Sprint 1 (30.01.2026) — 5 yanıt
    ('2026-01-30 14:27:00'::TIMESTAMP, 5, '2026-01-30'::DATE,  8,  6, 5, NULL::VARCHAR(20)),
    ('2026-01-30 14:28:00'::TIMESTAMP, 3, '2026-01-30'::DATE,  6,  7, 6, NULL),
    ('2026-01-30 14:28:00'::TIMESTAMP, 4, '2026-01-30'::DATE,  9,  7, 6, NULL),
    ('2026-01-30 14:29:00'::TIMESTAMP, 1, '2026-01-30'::DATE,  8,  7, 7, NULL),
    ('2026-01-30 14:42:00'::TIMESTAMP, 2, '2026-01-30'::DATE,  9,  7, 7, NULL),

    -- Sprint 2 (20.02.2026) — 4 yanıt (Elifnaz 23.02'de gönderdi)
    ('2026-02-20 13:20:00'::TIMESTAMP, 4, '2026-02-20'::DATE, 10,  7, 7, NULL),
    ('2026-02-20 13:58:00'::TIMESTAMP, 1, '2026-02-20'::DATE,  7,  5, 6, NULL),
    ('2026-02-20 14:38:00'::TIMESTAMP, 3, '2026-02-20'::DATE,  7,  6, 6, NULL),
    ('2026-02-23 08:19:00'::TIMESTAMP, 2, '2026-02-20'::DATE,  8,  7, 7, NULL),

    -- Sprint 3 (13.03.2026) — 3 yanıt
    ('2026-03-13 08:47:00'::TIMESTAMP, 4, '2026-03-13'::DATE, 10,  7, 7, NULL),
    ('2026-03-13 08:47:00'::TIMESTAMP, 1, '2026-03-13'::DATE,  5,  6, 6, NULL),
    ('2026-03-13 08:53:00'::TIMESTAMP, 6, '2026-03-13'::DATE, 10,  7, 7, NULL)
) AS v(tarih, pkod, sprint_toplanti, organizasyon_puan, ajanstaki_rolu, ajans_hakkinda, durum)
JOIN personel p ON p.pkod = v.pkod;

COMMIT;
