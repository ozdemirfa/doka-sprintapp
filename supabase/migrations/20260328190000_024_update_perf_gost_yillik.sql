-- 024_update_perf_gost_yillik.sql
-- sprint_perf_gos.gerceklesme toplamını perf_gost_yillik.gerceklesen'e yaz

UPDATE perf_gost_yillik pgy
SET gerceklesen = agg.toplam
FROM (
    SELECT cg_kod, yil, SUM(gerceklesme) AS toplam
    FROM sprint_perf_gos
    WHERE gerceklesme IS NOT NULL
    GROUP BY cg_kod, yil
) agg
WHERE pgy.cg_kod = agg.cg_kod
  AND pgy.yil    = agg.yil;
