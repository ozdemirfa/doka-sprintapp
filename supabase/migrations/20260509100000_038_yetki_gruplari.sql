-- ============================================================
-- Supabase migration 038 (mirror of src/sql/024_yetki_gruplari.sql)
-- Modern Yetki Yönetimi — Çoka-Çok Grup + Tablo İzin Matrisi
-- UTF-8 | DOKA Sprint Kanban
-- Tarih: 2026-05-09 (mirror'a alındı: 2026-05-18)
-- ============================================================
-- Bu migration mevcut tek-rol (personel.rol_kodu) sistemine ek olarak
-- aşağıdaki esnek yapıyı kurar:
--   * yetki_grubu             — adlandırılmış izin grupları
--   * personel_yetki_grubu    — kullanıcı ↔ grup (M2M)
--   * yetki_grubu_tablo_izni  — grup → tablo (okuma/yazma/güncelleme/silme)
--   * yetki_tablo_katalog     — admin UI'da listelenecek tabloların kataloğu
--
-- Geriye uyum: mevcut RLS politikaları korunur (040'ta OR genişletmesi yapılır).
--
-- IDEMPOTENCY GUARD (mirror eklemesi — src/sql/024'te yok):
-- Bu migration prod DB'ye daha önce Dashboard SQL Editor üzerinden elle
-- uygulanmış olabilir. Re-run'da "policy already exists" hatasını önlemek için
-- her CREATE POLICY öncesi DROP POLICY IF EXISTS çalıştırılır.
-- ============================================================

-- ── 1. Yetki Grubu ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS yetki_grubu (
  id            BIGSERIAL PRIMARY KEY,
  ad            VARCHAR(60) NOT NULL UNIQUE,
  aciklama      TEXT,
  sistem_grubu  BOOLEAN     NOT NULL DEFAULT FALSE,
  aktif         BOOLEAN     NOT NULL DEFAULT TRUE,
  olusturulma   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON COLUMN yetki_grubu.sistem_grubu IS 'TRUE ise silinemez/yeniden adlandırılamaz (yönetici, standart, izleyici, gs, başkan).';

-- ── 2. Personel ↔ Yetki Grubu (M2M) ─────────────────────────
CREATE TABLE IF NOT EXISTS personel_yetki_grubu (
  personel_pkod  INTEGER     NOT NULL REFERENCES personel(pkod)    ON DELETE CASCADE,
  yetki_grubu_id BIGINT      NOT NULL REFERENCES yetki_grubu(id)   ON DELETE CASCADE,
  atayan_pkod    INTEGER     REFERENCES personel(pkod),
  atanma_tarihi  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (personel_pkod, yetki_grubu_id)
);

CREATE INDEX IF NOT EXISTS idx_pyg_personel ON personel_yetki_grubu(personel_pkod);
CREATE INDEX IF NOT EXISTS idx_pyg_grup     ON personel_yetki_grubu(yetki_grubu_id);

-- ── 3. Grup → Tablo İzin Matrisi ────────────────────────────
CREATE TABLE IF NOT EXISTS yetki_grubu_tablo_izni (
  yetki_grubu_id BIGINT      NOT NULL REFERENCES yetki_grubu(id) ON DELETE CASCADE,
  tablo_adi      VARCHAR(64) NOT NULL,
  okuma          BOOLEAN     NOT NULL DEFAULT FALSE,
  yazma          BOOLEAN     NOT NULL DEFAULT FALSE,  -- INSERT
  guncelleme     BOOLEAN     NOT NULL DEFAULT FALSE,  -- UPDATE
  silme          BOOLEAN     NOT NULL DEFAULT FALSE,  -- DELETE
  PRIMARY KEY (yetki_grubu_id, tablo_adi)
);

CREATE INDEX IF NOT EXISTS idx_ygti_tablo ON yetki_grubu_tablo_izni(tablo_adi);

-- ── 4. Tablo Kataloğu (admin UI) ────────────────────────────
CREATE TABLE IF NOT EXISTS yetki_tablo_katalog (
  tablo_adi    VARCHAR(64)  PRIMARY KEY,
  goruntu_adi  VARCHAR(120) NOT NULL,
  aciklama     TEXT,
  kategori     VARCHAR(40)  NOT NULL DEFAULT 'Genel',
  sira         INTEGER      NOT NULL DEFAULT 100
);

COMMENT ON TABLE yetki_tablo_katalog IS 'Admin UI''da yetki matrisi için listelenecek tablolar.';

-- ── 5. RLS — yetki yönetimi tablolarına kim erişir ──────────
ALTER TABLE yetki_grubu             ENABLE ROW LEVEL SECURITY;
ALTER TABLE personel_yetki_grubu    ENABLE ROW LEVEL SECURITY;
ALTER TABLE yetki_grubu_tablo_izni  ENABLE ROW LEVEL SECURITY;
ALTER TABLE yetki_tablo_katalog     ENABLE ROW LEVEL SECURITY;

-- SELECT policy'leri için idempotency guard
DROP POLICY IF EXISTS "yetki_grubu_select"             ON yetki_grubu;
DROP POLICY IF EXISTS "personel_yetki_grubu_select"    ON personel_yetki_grubu;
DROP POLICY IF EXISTS "yetki_grubu_tablo_izni_select"  ON yetki_grubu_tablo_izni;
DROP POLICY IF EXISTS "yetki_tablo_katalog_select"     ON yetki_tablo_katalog;

-- SELECT: tüm authenticated (kullanıcı kendi gruplarını ve kataloğu görmeli)
CREATE POLICY "yetki_grubu_select"
  ON yetki_grubu FOR SELECT TO authenticated USING (TRUE);

CREATE POLICY "personel_yetki_grubu_select"
  ON personel_yetki_grubu FOR SELECT TO authenticated USING (TRUE);

CREATE POLICY "yetki_grubu_tablo_izni_select"
  ON yetki_grubu_tablo_izni FOR SELECT TO authenticated USING (TRUE);

CREATE POLICY "yetki_tablo_katalog_select"
  ON yetki_tablo_katalog FOR SELECT TO authenticated USING (TRUE);

-- _modify policy'leri için idempotency guard + (re-)create
-- Not: Migration 041 (yetki_rls_fixes) bu _modify policy'lerini DROP edip
-- ayrık INSERT/UPDATE/DELETE policy'leri ile değiştirir. 038→041 zinciri
-- doğru sırayla çalışırsa güvenli son durum elde edilir.
DO $$
DECLARE
  t TEXT;
BEGIN
  FOR t IN SELECT unnest(ARRAY[
    'yetki_grubu',
    'personel_yetki_grubu',
    'yetki_grubu_tablo_izni',
    'yetki_tablo_katalog'
  ])
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS "%s_modify" ON %I', t, t);
    EXECUTE format($f$
      CREATE POLICY "%s_modify" ON %I FOR ALL TO authenticated
        USING (
          (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
        )
        WITH CHECK (
          (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
        );
    $f$, t, t);
  END LOOP;
END $$;
