-- ============================================================
-- Migration 011: perf_gost_yillik Tablosu
-- UTF-8 | DOKA Sprint Kanban
-- Tarih: 2026-03-29
-- ============================================================
-- AMAÇ: perf_gostergeler'deki hedef_2024/2025/2026 ve
-- gerceklesen_2024/2025/2026 yıllık değerleri normalize eder.
-- Yeni tablo yıl bazlı filtrelemeye imkân tanır.
--
-- NOT: hedef_*/gerceklesen_* kolonları perf_gostergeler'de
-- geriye dönük uyumluluk için KORUNUR — ileriki migration'da kaldırılacak.
--
-- 2026 gerceklesen → NULL olarak seed edilir.
-- Gerçek değer sprint_perf_gos üzerinden v_perf_gosterge_ozet view'ından alınır.
-- ============================================================

-- BÖLÜM 1: TABLO OLUŞTUR
-- ============================================================
CREATE TABLE IF NOT EXISTS perf_gost_yillik (
    id                  SERIAL          PRIMARY KEY,
    perf_gostergeler_id INTEGER         NOT NULL REFERENCES perf_gostergeler(id) ON DELETE CASCADE,
    cg_kod              VARCHAR(20)     NOT NULL REFERENCES perf_gostergeler(cg_kod) ON DELETE CASCADE,
    yil                 INTEGER         NOT NULL,
    hedef               DECIMAL(10,2),
    gerceklesen         DECIMAL(10,2),
    CONSTRAINT uq_perf_gost_yillik_cg_yil UNIQUE (cg_kod, yil)
);

CREATE INDEX IF NOT EXISTS idx_perf_gost_yillik_cg_kod ON perf_gost_yillik(cg_kod);
CREATE INDEX IF NOT EXISTS idx_perf_gost_yillik_yil    ON perf_gost_yillik(yil);

COMMENT ON TABLE perf_gost_yillik IS 'Performans göstergesi başına yıllık hedef ve gerçekleşme';
COMMENT ON COLUMN perf_gost_yillik.gerceklesen IS '2026 için NULL — sprint_perf_gos üzerinden view''dan hesaplanır';

-- BÖLÜM 2: SEED — 2024 verisi
-- ============================================================
INSERT INTO perf_gost_yillik (perf_gostergeler_id, cg_kod, yil, hedef, gerceklesen)
SELECT id, cg_kod, 2024, hedef_2024, gerceklesen_2024
FROM perf_gostergeler
WHERE hedef_2024 IS NOT NULL OR gerceklesen_2024 IS NOT NULL
ON CONFLICT (cg_kod, yil) DO NOTHING;

-- BÖLÜM 3: SEED — 2025 verisi
-- ============================================================
INSERT INTO perf_gost_yillik (perf_gostergeler_id, cg_kod, yil, hedef, gerceklesen)
SELECT id, cg_kod, 2025, hedef_2025, gerceklesen_2025
FROM perf_gostergeler
WHERE hedef_2025 IS NOT NULL OR gerceklesen_2025 IS NOT NULL
ON CONFLICT (cg_kod, yil) DO NOTHING;

-- BÖLÜM 4: SEED — 2026 hedef verisi (gerceklesen = NULL, view'dan compute edilir)
-- ============================================================
INSERT INTO perf_gost_yillik (perf_gostergeler_id, cg_kod, yil, hedef, gerceklesen)
SELECT id, cg_kod, 2026, hedef_2026, NULL
FROM perf_gostergeler
WHERE hedef_2026 IS NOT NULL
ON CONFLICT (cg_kod, yil) DO NOTHING;

-- BÖLÜM 5: ROW LEVEL SECURITY
-- ============================================================
ALTER TABLE perf_gost_yillik ENABLE ROW LEVEL SECURITY;

-- SELECT: tüm authenticated kullanıcılar
DROP POLICY IF EXISTS "perf_gost_yillik_select" ON perf_gost_yillik;
CREATE POLICY "perf_gost_yillik_select"
    ON perf_gost_yillik FOR SELECT
    TO authenticated
    USING (true);

-- INSERT: yalnızca yöneticiler
DROP POLICY IF EXISTS "perf_gost_yillik_insert_yonetici" ON perf_gost_yillik;
CREATE POLICY "perf_gost_yillik_insert_yonetici"
    ON perf_gost_yillik FOR INSERT
    TO authenticated
    WITH CHECK (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

-- UPDATE: yalnızca yöneticiler
DROP POLICY IF EXISTS "perf_gost_yillik_update_yonetici" ON perf_gost_yillik;
CREATE POLICY "perf_gost_yillik_update_yonetici"
    ON perf_gost_yillik FOR UPDATE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    )
    WITH CHECK (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

-- DELETE: yalnızca yöneticiler
DROP POLICY IF EXISTS "perf_gost_yillik_delete_yonetici" ON perf_gost_yillik;
CREATE POLICY "perf_gost_yillik_delete_yonetici"
    ON perf_gost_yillik FOR DELETE
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

-- ============================================================
-- DOĞRULAMA SORGULARI
-- ============================================================
-- 1. Yıl başına satır sayısı:
--    SELECT yil, COUNT(*) FROM perf_gost_yillik GROUP BY yil ORDER BY yil;
--    → 2024, 2025, 2026 için satır bulunmalı
--
-- 2. 2026 gerceklesen NULL mu?
--    SELECT COUNT(*) FROM perf_gost_yillik WHERE yil = 2026 AND gerceklesen IS NOT NULL;
--    → 0 olmalı
--
-- 3. RLS politikaları:
--    SELECT policyname, cmd FROM pg_policies WHERE tablename = 'perf_gost_yillik';
--    → 4 politika: select, insert, update, delete
-- ============================================================
