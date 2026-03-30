-- ============================================================
-- Migration 030 — Audit Log: Tüm işlem kayıtları
-- Tarih: 2026-03-30
-- Tüm operasyonel tablolarda INSERT/UPDATE/DELETE işlemlerini
-- audit_log tablosuna kaydeden trigger sistemi.
-- ============================================================

-- ── 1. audit_log tablosu ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS audit_log (
    id              BIGSERIAL       PRIMARY KEY,
    islem_zamani    TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    tablo_adi       VARCHAR(100)    NOT NULL,
    islem_turu      VARCHAR(10)     NOT NULL CHECK (islem_turu IN ('INSERT','UPDATE','DELETE')),
    etkilenen_alanlar TEXT[],
    onceki_veri     JSONB,
    sonraki_veri    JSONB,
    kullanici_id    UUID
);

COMMENT ON TABLE audit_log IS 'Tüm tablolardaki INSERT/UPDATE/DELETE işlemlerinin kaydı';
COMMENT ON COLUMN audit_log.islem_zamani    IS 'İşlem gerçekleşme zamanı (UTC)';
COMMENT ON COLUMN audit_log.tablo_adi       IS 'Etkilenen tablo adı';
COMMENT ON COLUMN audit_log.islem_turu      IS 'INSERT, UPDATE veya DELETE';
COMMENT ON COLUMN audit_log.etkilenen_alanlar IS 'UPDATE için değişen kolon adları listesi';
COMMENT ON COLUMN audit_log.onceki_veri     IS 'UPDATE/DELETE için önceki satır verisi (JSON)';
COMMENT ON COLUMN audit_log.sonraki_veri    IS 'INSERT/UPDATE için sonraki satır verisi (JSON)';
COMMENT ON COLUMN audit_log.kullanici_id    IS 'auth.uid() — işlemi yapan kullanıcı';

-- Index: sorgu performansı için
CREATE INDEX IF NOT EXISTS idx_audit_log_tablo ON audit_log(tablo_adi);
CREATE INDEX IF NOT EXISTS idx_audit_log_zaman ON audit_log(islem_zamani DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_kullanici ON audit_log(kullanici_id);

-- ── 2. Trigger fonksiyonu ──────────────────────────────────────
CREATE OR REPLACE FUNCTION fn_audit_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    degisen_alanlar TEXT[] := NULL;
    onceki          JSONB  := NULL;
    sonraki         JSONB  := NULL;
    kolon           TEXT;
BEGIN
    IF TG_OP = 'INSERT' THEN
        sonraki := to_jsonb(NEW);

    ELSIF TG_OP = 'UPDATE' THEN
        onceki  := to_jsonb(OLD);
        sonraki := to_jsonb(NEW);
        -- Sadece değişen alanları bul
        degisen_alanlar := ARRAY(
            SELECT key
            FROM jsonb_each(onceki) o
            WHERE o.value IS DISTINCT FROM (sonraki->o.key)
        );

    ELSIF TG_OP = 'DELETE' THEN
        onceki := to_jsonb(OLD);
    END IF;

    INSERT INTO audit_log (
        islem_zamani,
        tablo_adi,
        islem_turu,
        etkilenen_alanlar,
        onceki_veri,
        sonraki_veri,
        kullanici_id
    ) VALUES (
        NOW(),
        TG_TABLE_NAME,
        TG_OP,
        degisen_alanlar,
        onceki,
        sonraki,
        auth.uid()
    );

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$;

COMMENT ON FUNCTION fn_audit_trigger() IS 'Genel audit trigger fonksiyonu — tüm tablolara eklenir';

-- ── 3. Trigger'ları operasyonel tablolara ekle ─────────────────

-- faaliyetler
DROP TRIGGER IF EXISTS trg_audit_faaliyetler ON faaliyetler;
CREATE TRIGGER trg_audit_faaliyetler
    AFTER INSERT OR UPDATE OR DELETE ON faaliyetler
    FOR EACH ROW EXECUTE FUNCTION fn_audit_trigger();

-- alt_faaliyetler
DROP TRIGGER IF EXISTS trg_audit_alt_faaliyetler ON alt_faaliyetler;
CREATE TRIGGER trg_audit_alt_faaliyetler
    AFTER INSERT OR UPDATE OR DELETE ON alt_faaliyetler
    FOR EACH ROW EXECUTE FUNCTION fn_audit_trigger();

-- sprint_is_plani
DROP TRIGGER IF EXISTS trg_audit_sprint_is_plani ON sprint_is_plani;
CREATE TRIGGER trg_audit_sprint_is_plani
    AFTER INSERT OR UPDATE OR DELETE ON sprint_is_plani
    FOR EACH ROW EXECUTE FUNCTION fn_audit_trigger();

-- sprint_perf_gos
DROP TRIGGER IF EXISTS trg_audit_sprint_perf_gos ON sprint_perf_gos;
CREATE TRIGGER trg_audit_sprint_perf_gos
    AFTER INSERT OR UPDATE OR DELETE ON sprint_perf_gos
    FOR EACH ROW EXECUTE FUNCTION fn_audit_trigger();

-- perf_gostergeler
DROP TRIGGER IF EXISTS trg_audit_perf_gostergeler ON perf_gostergeler;
CREATE TRIGGER trg_audit_perf_gostergeler
    AFTER INSERT OR UPDATE OR DELETE ON perf_gostergeler
    FOR EACH ROW EXECUTE FUNCTION fn_audit_trigger();

-- perf_gost_yillik
DROP TRIGGER IF EXISTS trg_audit_perf_gost_yillik ON perf_gost_yillik;
CREATE TRIGGER trg_audit_perf_gost_yillik
    AFTER INSERT OR UPDATE OR DELETE ON perf_gost_yillik
    FOR EACH ROW EXECUTE FUNCTION fn_audit_trigger();

-- harcamalar
DROP TRIGGER IF EXISTS trg_audit_harcamalar ON harcamalar;
CREATE TRIGGER trg_audit_harcamalar
    AFTER INSERT OR UPDATE OR DELETE ON harcamalar
    FOR EACH ROW EXECUTE FUNCTION fn_audit_trigger();

-- izinler
DROP TRIGGER IF EXISTS trg_audit_izinler ON izinler;
CREATE TRIGGER trg_audit_izinler
    AFTER INSERT OR UPDATE OR DELETE ON izinler
    FOR EACH ROW EXECUTE FUNCTION fn_audit_trigger();

-- saha_gorevleri
DROP TRIGGER IF EXISTS trg_audit_saha_gorevleri ON saha_gorevleri;
CREATE TRIGGER trg_audit_saha_gorevleri
    AFTER INSERT OR UPDATE OR DELETE ON saha_gorevleri
    FOR EACH ROW EXECUTE FUNCTION fn_audit_trigger();

-- sprint_veri
DROP TRIGGER IF EXISTS trg_audit_sprint_veri ON sprint_veri;
CREATE TRIGGER trg_audit_sprint_veri
    AFTER INSERT OR UPDATE OR DELETE ON sprint_veri
    FOR EACH ROW EXECUTE FUNCTION fn_audit_trigger();

-- soplar
DROP TRIGGER IF EXISTS trg_audit_soplar ON soplar;
CREATE TRIGGER trg_audit_soplar
    AFTER INSERT OR UPDATE OR DELETE ON soplar
    FOR EACH ROW EXECUTE FUNCTION fn_audit_trigger();

-- ── 4. RLS: audit_log için erişim politikaları ─────────────────
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;

-- Tüm authenticated kullanıcılar okuyabilir
CREATE POLICY "audit_log_select"
    ON audit_log FOR SELECT
    TO authenticated
    USING (TRUE);

-- Sadece trigger (SECURITY DEFINER) yazabilir — doğrudan INSERT yasak
CREATE POLICY "audit_log_insert_trigger_only"
    ON audit_log FOR INSERT
    TO authenticated
    WITH CHECK (FALSE);
