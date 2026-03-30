-- 030_seed_sprint_retro.sql
-- Gerçek form yanıtları: inputs/sprint_retro.csv
-- pkod → ad dönüşümü personel tablosundan subquery ile yapılır
-- aort (CSV hesaplamalı alan) tabloda saklanmaz

BEGIN;

-- sprint_retro.ad migration 007'de drop edildi; pkod FK ile insert yapılır
INSERT INTO sprint_retro (tarih, pkod, sprint_toplanti, organizasyon_puan, ajanstaki_rolu, ajans_hakkinda, durum)
VALUES
    -- Sprint 1 (30.01.2026) — 5 yanıt
    ('2026-01-30 14:27:00', 5, '2026-01-30', 8, 6, 5, NULL),
    ('2026-01-30 14:28:00', 3, '2026-01-30', 6, 7, 6, NULL),
    ('2026-01-30 14:28:00', 4, '2026-01-30', 9, 7, 6, NULL),
    ('2026-01-30 14:29:00', 1, '2026-01-30', 8, 7, 7, NULL),
    ('2026-01-30 14:42:00', 2, '2026-01-30', 9, 7, 7, NULL),

    -- Sprint 2 (20.02.2026) — 4 yanıt (Elifnaz 23.02'de gönderdi)
    ('2026-02-20 13:20:00', 4, '2026-02-20', 10, 7, 7, NULL),
    ('2026-02-20 13:58:00', 1, '2026-02-20',  7, 5, 6, NULL),
    ('2026-02-20 14:38:00', 3, '2026-02-20',  7, 6, 6, NULL),
    ('2026-02-23 08:19:00', 2, '2026-02-20',  8, 7, 7, NULL),

    -- Sprint 3 (13.03.2026) — 3 yanıt
    ('2026-03-13 08:47:00', 4, '2026-03-13', 10, 7, 7, NULL),
    ('2026-03-13 08:47:00', 1, '2026-03-13',  5, 6, 6, NULL),
    ('2026-03-13 08:53:00', 6, '2026-03-13', 10, 7, 7, NULL);

COMMIT;
