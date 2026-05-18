-- ============================================================
-- Migration 044: SOP-katmanlı RLS — soplar tablosu SELECT filtresi
-- UTF-8 NoBOM | DOKA Sprint Kanban
-- Tarih: 2026-05-18
-- Sprint: S3 (Birim-bazlı SOP Görünürlüğü)
-- ============================================================
-- Amaç:
--   Mevcut "soplar_select TO authenticated USING (true)" politikasını
--   birim_sop_izni matrisi üzerinden daraltmak. Yönetici ve admin
--   permission'a sahip kullanıcılar her şeyi görür; diğer kullanıcılar
--   sadece kendi birim(ler)inde "okuma" yetkisi olan SOP'ları görür.
--
-- Defense-in-depth:
--   faaliyetler.skod ve perf_gostergeler.skod doğrudan soplar(skod)'a
--   FK ile bağlı (007_revisions sonrası). SELECT politikalarını da
--   SOP-permission OR-katmanı ile sertleştiriyoruz.
--
-- Stratejik karar:
--   alt_faaliyetler, sprint_is_plani, harcamalar, sprint_perf_gos
--   tablolarında direkt skod FK'si yok — bunlar sno/cg_kod üzerinden
--   alt_faaliyetler/perf_gostergeler'a bağlanır. Onların görünürlüğü
--   üst tablonun (faaliyetler/perf_gostergeler) SELECT politikası
--   üzerinden join filter ile dolaylı olarak daralır. V1'de yeterli;
--   V2'de direkt RLS predicate'i eklenebilir.
--
-- İdempotency: DROP POLICY IF EXISTS + CREATE POLICY pattern.
-- Geriye uyum: 045 seed (tüm birim×SOP okuma=TRUE) mevcut görünürlüğü korur.
-- ============================================================

BEGIN;

-- ── 1. soplar tablosunda SELECT politikası ──────────────────
-- Mevcut: USING (true) — herkes tüm SOP'ları görür
-- Yeni: yönetici OR current_user_has_sop_permission(skod, 'okuma')
DROP POLICY IF EXISTS "soplar_select" ON soplar;
CREATE POLICY "soplar_select"
  ON soplar FOR SELECT TO authenticated
  USING (
    -- Yönetici by-pass (helper'da da var ama policy bazında kısa-devre)
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_sop_permission(skod, 'okuma')
  );

COMMENT ON POLICY "soplar_select" ON soplar IS
  'S3 — Birim-bazlı SOP görünürlüğü: yönetici tüm SOP''ları görür, diğer kullanıcılar birim_sop_izni.okuma=TRUE kayıtlarını.';

-- ── 2. faaliyetler SELECT — SOP-bağımlı sertleştirme ───────
-- faaliyetler.skod doğrudan soplar(skod)'a FK (007_revisions); basit OR-katmanı
DROP POLICY IF EXISTS "faaliyetler_select" ON faaliyetler;
CREATE POLICY "faaliyetler_select"
  ON faaliyetler FOR SELECT TO authenticated
  USING (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR skod IS NULL
    OR current_user_has_sop_permission(skod, 'okuma')
  );

COMMENT ON POLICY "faaliyetler_select" ON faaliyetler IS
  'S3 — faaliyet.skod kullanıcının okuma yetkisi olan SOP olmalı (yönetici bypass).';

-- ── 3. perf_gostergeler SELECT — SOP-bağımlı sertleştirme ──
-- perf_gostergeler.skod doğrudan soplar(skod)'a FK (007_revisions); basit OR-katmanı
DROP POLICY IF EXISTS "perf_gostergeler_select" ON perf_gostergeler;
CREATE POLICY "perf_gostergeler_select"
  ON perf_gostergeler FOR SELECT TO authenticated
  USING (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR skod IS NULL
    OR current_user_has_sop_permission(skod, 'okuma')
  );

COMMENT ON POLICY "perf_gostergeler_select" ON perf_gostergeler IS
  'S3 — Performans göstergeleri SOP''a bağlı görünürlük; yönetici bypass.';

-- ── 4. faaliyetler INSERT/DELETE — SOP-yazma katmanı (permissive) ─
-- Mevcut faaliyetler_modify_extended (026) yönetici VEYA permission('faaliyetler','*')
-- veriyor. Bu ek katman, kullanıcının birimine atanmış SOP'larda SOP-bazlı
-- yazma izni varsa onu da kabul eder (permissive ekleme).
DROP POLICY IF EXISTS "faaliyetler_sop_yazma" ON faaliyetler;
CREATE POLICY "faaliyetler_sop_yazma"
  ON faaliyetler FOR INSERT TO authenticated
  WITH CHECK (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR (
      skod IS NOT NULL
      AND current_user_has_sop_permission(skod, 'yazma')
    )
  );

DROP POLICY IF EXISTS "faaliyetler_sop_silme" ON faaliyetler;
CREATE POLICY "faaliyetler_sop_silme"
  ON faaliyetler FOR DELETE TO authenticated
  USING (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR (
      skod IS NOT NULL
      AND current_user_has_sop_permission(skod, 'silme')
    )
  );

COMMIT;
