-- ============================================================
-- Migration 017: Audit Log Sistemi
-- UTF-8 | DOKA Sprint Kanban
-- Tarih: 2026-03-31
-- ============================================================
-- Bu migration tüm kritik tablolara audit log desteği ekler.
-- Her INSERT/UPDATE/DELETE işlemi audit_log tablosuna kaydedilir.
-- Kaydedilen bilgiler: tablo, işlem tipi, kayıt ID, önceki veri,
-- sonraki veri, sadece değişen alanlar, kullanıcı adı, işlem zamanı.
-- ============================================================

-- ============================================================
-- BÖLÜM 1: audit_log tablosu
-- ============================================================
CREATE TABLE IF NOT EXISTS audit_log (
    id              BIGSERIAL PRIMARY KEY,
    tablo           TEXT NOT NULL,
    islem           TEXT NOT NULL CHECK (islem IN ('INSERT', 'UPDATE', 'DELETE')),
    kayit_id        TEXT,
    onceki_veri     JSONB,
    sonraki_veri    JSONB,
    degisen_alanlar JSONB,   -- sadece değişen key'ler (UPDATE için)
    kullanici_ad    TEXT,
    islem_zamani    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_log_tablo       ON audit_log(tablo);
CREATE INDEX IF NOT EXISTS idx_audit_log_islem_zaman ON audit_log(islem_zamani DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_kayit_id    ON audit_log(kayit_id);

ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;

-- SELECT: yalnızca yönetici
DROP POLICY IF EXISTS "audit_log_select_yonetici" ON audit_log;
CREATE POLICY "audit_log_select_yonetici"
    ON audit_log FOR SELECT
    TO authenticated
    USING (
        (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    );

-- INSERT: authenticated kullanıcılar (trigger SECURITY DEFINER ile çalışır)
DROP POLICY IF EXISTS "audit_log_insert_authenticated" ON audit_log;
CREATE POLICY "audit_log_insert_authenticated"
    ON audit_log FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- ============================================================
-- BÖLÜM 2: fn_audit_log() trigger fonksiyonu
-- ============================================================
CREATE OR REPLACE FUNCTION fn_audit_log()
RETURNS TRIGGER AS $$
DECLARE
    v_kullanici_ad  TEXT;
    v_kayit_id      TEXT;
    v_onceki        JSONB;
    v_sonraki       JSONB;
    v_degisen       JSONB := '{}';
    v_key           TEXT;
BEGIN
    -- Kullanıcı adını al
    BEGIN
        SELECT ad || ' ' || soyad INTO v_kullanici_ad
        FROM personel
        WHERE auth_id = auth.uid()
        LIMIT 1;
    EXCEPTION WHEN OTHERS THEN
        v_kullanici_ad := NULL;
    END;

    IF TG_OP = 'INSERT' THEN
        v_sonraki  := to_jsonb(NEW);
        v_kayit_id := (v_sonraki->>'id');

    ELSIF TG_OP = 'UPDATE' THEN
        v_onceki   := to_jsonb(OLD);
        v_sonraki  := to_jsonb(NEW);
        v_kayit_id := (v_sonraki->>'id');

        -- Sadece değişen alanları hesapla
        FOR v_key IN SELECT key FROM jsonb_each(v_sonraki)
        LOOP
            IF (v_onceki->v_key) IS DISTINCT FROM (v_sonraki->v_key) THEN
                v_degisen := v_degisen || jsonb_build_object(
                    v_key, jsonb_build_object(
                        'onceki', v_onceki->v_key,
                        'sonraki', v_sonraki->v_key
                    )
                );
            END IF;
        END LOOP;

    ELSIF TG_OP = 'DELETE' THEN
        v_onceki   := to_jsonb(OLD);
        v_kayit_id := (v_onceki->>'id');
    END IF;

    INSERT INTO audit_log (
        tablo, islem, kayit_id,
        onceki_veri, sonraki_veri, degisen_alanlar,
        kullanici_ad, islem_zamani
    ) VALUES (
        TG_TABLE_NAME,
        TG_OP,
        v_kayit_id,
        v_onceki,
        v_sonraki,
        CASE WHEN TG_OP = 'UPDATE' THEN v_degisen ELSE NULL END,
        v_kullanici_ad,
        NOW()
    );

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- BÖLÜM 3: Trigger'ları tablolara uygula
-- ============================================================

-- faaliyetler
DROP TRIGGER IF EXISTS trg_audit_faaliyetler ON faaliyetler;
CREATE TRIGGER trg_audit_faaliyetler
    AFTER INSERT OR UPDATE OR DELETE ON faaliyetler
    FOR EACH ROW EXECUTE FUNCTION fn_audit_log();

-- alt_faaliyetler
DROP TRIGGER IF EXISTS trg_audit_alt_faaliyetler ON alt_faaliyetler;
CREATE TRIGGER trg_audit_alt_faaliyetler
    AFTER INSERT OR UPDATE OR DELETE ON alt_faaliyetler
    FOR EACH ROW EXECUTE FUNCTION fn_audit_log();

-- soplar
DROP TRIGGER IF EXISTS trg_audit_soplar ON soplar;
CREATE TRIGGER trg_audit_soplar
    AFTER INSERT OR UPDATE OR DELETE ON soplar
    FOR EACH ROW EXECUTE FUNCTION fn_audit_log();

-- sprint_is_plani
DROP TRIGGER IF EXISTS trg_audit_sprint_is_plani ON sprint_is_plani;
CREATE TRIGGER trg_audit_sprint_is_plani
    AFTER INSERT OR UPDATE OR DELETE ON sprint_is_plani
    FOR EACH ROW EXECUTE FUNCTION fn_audit_log();

-- sprint_veri
DROP TRIGGER IF EXISTS trg_audit_sprint_veri ON sprint_veri;
CREATE TRIGGER trg_audit_sprint_veri
    AFTER INSERT OR UPDATE OR DELETE ON sprint_veri
    FOR EACH ROW EXECUTE FUNCTION fn_audit_log();

-- sprint_perf_gos
DROP TRIGGER IF EXISTS trg_audit_sprint_perf_gos ON sprint_perf_gos;
CREATE TRIGGER trg_audit_sprint_perf_gos
    AFTER INSERT OR UPDATE OR DELETE ON sprint_perf_gos
    FOR EACH ROW EXECUTE FUNCTION fn_audit_log();

-- perf_gostergeler
DROP TRIGGER IF EXISTS trg_audit_perf_gostergeler ON perf_gostergeler;
CREATE TRIGGER trg_audit_perf_gostergeler
    AFTER INSERT OR UPDATE OR DELETE ON perf_gostergeler
    FOR EACH ROW EXECUTE FUNCTION fn_audit_log();

-- harcamalar
DROP TRIGGER IF EXISTS trg_audit_harcamalar ON harcamalar;
CREATE TRIGGER trg_audit_harcamalar
    AFTER INSERT OR UPDATE OR DELETE ON harcamalar
    FOR EACH ROW EXECUTE FUNCTION fn_audit_log();

-- izinler
DROP TRIGGER IF EXISTS trg_audit_izinler ON izinler;
CREATE TRIGGER trg_audit_izinler
    AFTER INSERT OR UPDATE OR DELETE ON izinler
    FOR EACH ROW EXECUTE FUNCTION fn_audit_log();

-- saha_gorevleri
DROP TRIGGER IF EXISTS trg_audit_saha_gorevleri ON saha_gorevleri;
CREATE TRIGGER trg_audit_saha_gorevleri
    AFTER INSERT OR UPDATE OR DELETE ON saha_gorevleri
    FOR EACH ROW EXECUTE FUNCTION fn_audit_log();

-- ============================================================
-- BÖLÜM 4: DOĞRULAMA
-- ============================================================
-- Çalıştırma sonrası kontrol:
--   SELECT COUNT(*) FROM audit_log;                         → 0
--   SELECT * FROM pg_trigger WHERE tgname LIKE 'trg_audit%'; → 10 satır
--   SELECT * FROM audit_log ORDER BY islem_zamani DESC LIMIT 5; → 0 (henüz kayıt yok)
