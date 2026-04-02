-- ============================================================
-- Migration 023: sop_birim çoka-çok ilişki tablosu
-- ============================================================

-- SOP ↔ Birim çoka-çok ilişki tablosu
CREATE TABLE IF NOT EXISTS sop_birim (
  skod  INTEGER NOT NULL REFERENCES soplar(skod)   ON DELETE CASCADE,
  bkod  INTEGER NOT NULL REFERENCES birimler(bkod) ON DELETE CASCADE,
  PRIMARY KEY (skod, bkod)
);

-- Mevcut soplar.bkod verilerinden başlangıç seed
INSERT INTO sop_birim (skod, bkod)
  SELECT skod, bkod FROM soplar WHERE bkod IS NOT NULL
ON CONFLICT DO NOTHING;

-- RLS
ALTER TABLE sop_birim ENABLE ROW LEVEL SECURITY;

CREATE POLICY "sop_birim_select" ON sop_birim
  FOR SELECT USING (true);

CREATE POLICY "sop_birim_modify" ON sop_birim
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM personel
      WHERE auth_id = auth.uid()
        AND rol_kodu = 'yönetici'
    )
  );
