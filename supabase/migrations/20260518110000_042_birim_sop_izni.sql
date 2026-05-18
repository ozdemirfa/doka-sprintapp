-- ============================================================
-- Migration 042: birim_sop_izni — Birim-bazlı SOP Yetki Matrisi
-- UTF-8 NoBOM | DOKA Sprint Kanban
-- Tarih: 2026-05-18
-- Sprint: S3 (Birim-bazlı SOP Görünürlüğü)
-- ============================================================
-- Amaç:
--   Bir birime hangi SOP'ları okuma/yazma/silme yetkisiyle göreceğini
--   tanımlayan matris tablosu. Mevcut sop_birim (M2M visibility) tablosu
--   ile aynı zamanda yaşar: sop_birim hangi SOP'un hangi birime "ait"
--   olduğunu gösterir, birim_sop_izni ise o birimin üyelerinin SOP üzerinde
--   ne yapabileceğini matris olarak tutar.
--
-- Şema:
--   PK: (bkod, skod)
--   okuma   BOOLEAN — SOP'u liste / detay olarak görebilir
--   yazma   BOOLEAN — SOP altındaki kayıtları (faaliyet, perf gos vb.) ekler/günceller
--   silme   BOOLEAN — SOP altındaki kayıtları siler
--
-- RLS:
--   SELECT: authenticated (matrise herkes okuyabilir — UI matrisi için)
--   INSERT/UPDATE/DELETE: yönetici VEYA current_user_has_permission('birim_sop_izni','yazma'|'guncelleme'|'silme')
--
-- İdempotency: CREATE IF NOT EXISTS + DROP POLICY IF EXISTS + CREATE
-- ============================================================

BEGIN;

-- ── 1. Tablo ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS birim_sop_izni (
  bkod    INTEGER NOT NULL REFERENCES birimler(bkod) ON DELETE CASCADE,
  skod    INTEGER NOT NULL REFERENCES soplar(skod)   ON DELETE CASCADE,
  okuma   BOOLEAN NOT NULL DEFAULT TRUE,
  yazma   BOOLEAN NOT NULL DEFAULT FALSE,
  silme   BOOLEAN NOT NULL DEFAULT FALSE,
  olusturulma TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  guncelleme  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (bkod, skod)
);

CREATE INDEX IF NOT EXISTS idx_birim_sop_izni_bkod ON birim_sop_izni(bkod);
CREATE INDEX IF NOT EXISTS idx_birim_sop_izni_skod ON birim_sop_izni(skod);

COMMENT ON TABLE birim_sop_izni IS
  'S3: Birim × SOP × {okuma,yazma,silme} matrisi. Bir personelin gördüğü/etkileşime girdiği SOP listesi, kendi birimi üzerinden bu tablodan türetilir.';
COMMENT ON COLUMN birim_sop_izni.okuma IS 'TRUE: bu birimin üyeleri bu SOP''u listele/detay görebilir.';
COMMENT ON COLUMN birim_sop_izni.yazma IS 'TRUE: bu birimin üyeleri SOP altında kayıt ekler/günceller.';
COMMENT ON COLUMN birim_sop_izni.silme IS 'TRUE: bu birimin üyeleri SOP altında kayıt siler.';

-- updated_at trigger (mevcut pattern)
CREATE OR REPLACE FUNCTION fn_touch_birim_sop_izni()
RETURNS TRIGGER AS $$
BEGIN
  NEW.guncelleme = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_touch_birim_sop_izni ON birim_sop_izni;
CREATE TRIGGER trg_touch_birim_sop_izni
  BEFORE UPDATE ON birim_sop_izni
  FOR EACH ROW EXECUTE FUNCTION fn_touch_birim_sop_izni();

-- ── 2. RLS ──────────────────────────────────────────────────
ALTER TABLE birim_sop_izni ENABLE ROW LEVEL SECURITY;

-- SELECT: tüm authenticated kullanıcılar matrisin tamamını okuyabilir
-- (UI matrisinin yüklenebilmesi için; hassas bir bilgi değil — sadece yetki bayrakları)
DROP POLICY IF EXISTS "birim_sop_izni_select" ON birim_sop_izni;
CREATE POLICY "birim_sop_izni_select"
  ON birim_sop_izni FOR SELECT TO authenticated USING (TRUE);

-- INSERT
DROP POLICY IF EXISTS "birim_sop_izni_insert" ON birim_sop_izni;
CREATE POLICY "birim_sop_izni_insert"
  ON birim_sop_izni FOR INSERT TO authenticated
  WITH CHECK (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('birim_sop_izni', 'yazma')
  );

-- UPDATE
DROP POLICY IF EXISTS "birim_sop_izni_update" ON birim_sop_izni;
CREATE POLICY "birim_sop_izni_update"
  ON birim_sop_izni FOR UPDATE TO authenticated
  USING (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('birim_sop_izni', 'guncelleme')
  )
  WITH CHECK (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('birim_sop_izni', 'guncelleme')
  );

-- DELETE
DROP POLICY IF EXISTS "birim_sop_izni_delete" ON birim_sop_izni;
CREATE POLICY "birim_sop_izni_delete"
  ON birim_sop_izni FOR DELETE TO authenticated
  USING (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('birim_sop_izni', 'silme')
  );

-- ── 3. Audit ────────────────────────────────────────────────
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'fn_audit_log') THEN
    DROP TRIGGER IF EXISTS trg_audit_birim_sop_izni ON birim_sop_izni;
    CREATE TRIGGER trg_audit_birim_sop_izni
      AFTER INSERT OR UPDATE OR DELETE ON birim_sop_izni
      FOR EACH ROW EXECUTE FUNCTION fn_audit_log();
  END IF;
END $$;

-- ── 4. Yetki katalogu (admin UI için tabloyu listeye ekle) ──
INSERT INTO yetki_tablo_katalog (tablo_adi, goruntu_adi, aciklama, kategori, sira)
VALUES (
  'birim_sop_izni',
  'Birim-SOP İzin Matrisi',
  'Birim bazlı SOP okuma/yazma/silme yetkilerini yönetir (S3).',
  'Yetki',
  90
)
ON CONFLICT (tablo_adi) DO NOTHING;

COMMIT;
